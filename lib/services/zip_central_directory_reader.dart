import 'dart:io';
import 'dart:typed_data';

import 'package:cope_x_studio/models/zip_entry_meta.dart';
import 'package:cope_x_studio/utils/zip_filename_decoder.dart';

/// Đọc Central Directory của ZIP — chỉ đọc phần cuối file, không nạp toàn bộ archive vào RAM.
class ZipCentralDirectoryReader {
  static const _eocdSignature = 0x06054b50;
  static const _zip64LocatorSignature = 0x07064b50;
  static const _zip64EocdSignature = 0x06064b50;
  static const _cdSignature = 0x02014b50;
  static const _maxTail = 65536 + 22;
  static const _maxCdInMemory = 96 * 1024 * 1024;

  Future<List<ZipEntryMeta>> readEntries(String zipPath) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw FileSystemException('File không tồn tại', zipPath);
    }

    final length = await file.length();
    if (length < 22) {
      throw const FormatException('File ZIP không hợp lệ');
    }

    final raf = await file.open();
    try {
      final tailLen = length < _maxTail ? length : _maxTail;
      final tail = Uint8List(tailLen);
      await raf.setPosition(length - tailLen);
      await raf.readInto(tail);

      final eocdOffset = _findSignature(tail, _eocdSignature);
      if (eocdOffset == -1) {
        throw const FormatException('Không tìm thấy End of Central Directory');
      }

      final eocd = ByteData.sublistView(tail, eocdOffset);
      var entryCount = eocd.getUint16(10, Endian.little);
      var cdSize = eocd.getUint32(12, Endian.little);
      var cdOffset = eocd.getUint32(16, Endian.little);

      if (entryCount == 0xffff || cdOffset == 0xffffffff || cdSize == 0xffffffff) {
        final zip64 = _readZip64Eocd(raf, length, tail, eocdOffset);
        entryCount = zip64.$1;
        cdSize = zip64.$2;
        cdOffset = zip64.$3;
      }

      if (cdOffset < 0 || cdSize < 0 || cdOffset + cdSize > length) {
        throw const FormatException('Central Directory ZIP bị hỏng');
      }

      if (cdSize > _maxCdInMemory) {
        throw FormatException(
          'Central Directory quá lớn (${(cdSize / (1024 * 1024)).toStringAsFixed(0)} MB)',
        );
      }

      final cdBytes = Uint8List(cdSize);
      await raf.setPosition(cdOffset);
      final read = await raf.readInto(cdBytes);
      if (read != cdSize) {
        throw const FormatException('Không đọc đủ Central Directory');
      }

      return _parseCentralDirectory(cdBytes, entryCount);
    } finally {
      await raf.close();
    }
  }

  (int, int, int) _readZip64Eocd(RandomAccessFile raf, int fileLength, Uint8List tail, int eocdOffset) {
    final locatorOffset = _findSignature(tail, _zip64LocatorSignature);
    if (locatorOffset == -1) {
      throw const FormatException('ZIP64 locator không hợp lệ');
    }

    final locator = ByteData.sublistView(tail, locatorOffset);
    final zip64EocdOffset = _uint64ToInt(locator.getUint64(8, Endian.little));

    final header = Uint8List(12);
    raf.setPositionSync(zip64EocdOffset);
    raf.readIntoSync(header);

    final headerData = ByteData.sublistView(header);
    if (headerData.getUint32(0, Endian.little) != _zip64EocdSignature) {
      throw const FormatException('ZIP64 EOCD signature không hợp lệ');
    }

    final recordSize = headerData.getUint64(4, Endian.little);
    final readLen = (recordSize + 12).clamp(56, 65536).toInt();
    if (zip64EocdOffset + readLen > fileLength) {
      throw const FormatException('ZIP64 EOCD nằm ngoài file');
    }

    final fullRecord = Uint8List(readLen);
    raf.setPositionSync(zip64EocdOffset);
    raf.readIntoSync(fullRecord);
    final fullData = ByteData.sublistView(fullRecord);

    final entryCount = _uint64ToInt(fullData.getUint64(24, Endian.little));
    final cdSize = _uint64ToInt(fullData.getUint64(32, Endian.little));
    final cdOffset = _uint64ToInt(fullData.getUint64(40, Endian.little));
    return (entryCount, cdSize, cdOffset);
  }

  int _uint64ToInt(int value) => value;

  List<ZipEntryMeta> _parseCentralDirectory(Uint8List cdBytes, int entryCount) {
    final entries = <ZipEntryMeta>[];
    var offset = 0;

    while (offset + 46 <= cdBytes.length && entries.length < entryCount) {
      final header = ByteData.sublistView(cdBytes, offset);
      if (header.getUint32(0, Endian.little) != _cdSignature) break;

      final flags = header.getUint16(8, Endian.little);
      var uncompressedSize = header.getUint32(24, Endian.little);
      final nameLen = header.getUint16(28, Endian.little);
      final extraLen = header.getUint16(30, Endian.little);
      final commentLen = header.getUint16(32, Endian.little);
      final externalAttr = header.getUint32(38, Endian.little);

      final nameStart = offset + 46;
      final nameEnd = nameStart + nameLen;
      if (nameEnd > cdBytes.length) break;

      final nameBytes = cdBytes.sublist(nameStart, nameEnd);
      final extraStart = nameEnd;
      final extraEnd = extraStart + extraLen;
      final extraBytes = extraEnd <= cdBytes.length
          ? cdBytes.sublist(extraStart, extraEnd)
          : Uint8List(0);

      final name = ZipFilenameDecoder.decode(
        nameBytes: nameBytes,
        flags: flags,
        extra: extraBytes,
      );

      if (uncompressedSize == 0xffffffff && extraEnd <= cdBytes.length) {
        uncompressedSize = _readZip64ExtraSize(cdBytes.sublist(extraStart, extraEnd)) ?? uncompressedSize;
      }

      final isDir = name.endsWith('/') || (externalAttr & 0x10) != 0;
      var isEncrypted = (flags & 0x1) != 0;
      final isAes = extraEnd <= cdBytes.length &&
          _hasAesExtra(cdBytes.sublist(extraStart, extraEnd));
      if (isAes) isEncrypted = true;

      entries.add(
        ZipEntryMeta(
          name: name,
          uncompressedSize: uncompressedSize,
          isDirectory: isDir,
          isEncrypted: isEncrypted,
          isAesEncrypted: isAes,
        ),
      );

      offset = extraEnd + commentLen;
    }

    return entries;
  }

  bool _hasAesExtra(Uint8List extra) {
    var i = 0;
    while (i + 4 <= extra.length) {
      final id = ByteData.sublistView(extra, i).getUint16(0, Endian.little);
      final size = ByteData.sublistView(extra, i).getUint16(2, Endian.little);
      if (id == 0x9901) return true;
      if (i + 4 + size > extra.length) break;
      i += 4 + size;
    }
    return false;
  }

  int? _readZip64ExtraSize(Uint8List extra) {
    var i = 0;
    while (i + 4 <= extra.length) {
      final id = ByteData.sublistView(extra, i).getUint16(0, Endian.little);
      final size = ByteData.sublistView(extra, i).getUint16(2, Endian.little);
      if (i + 4 + size > extra.length) break;
      if (id == 0x0001 && size >= 8) {
        final raw = ByteData.sublistView(extra, i + 4).getUint64(0, Endian.little);
        if (raw > 0x7fffffffffffffff) return null;
        return raw.toInt();
      }
      i += 4 + size;
    }
    return null;
  }

  int _findSignature(Uint8List bytes, int signature) {
    for (var i = bytes.length - 4; i >= 0; i--) {
      if (ByteData.sublistView(bytes, i).getUint32(0, Endian.little) == signature) {
        return i;
      }
    }
    return -1;
  }
}
