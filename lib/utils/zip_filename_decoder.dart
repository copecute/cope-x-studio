import 'dart:convert';
import 'dart:typed_data';

/// Giải mã tên file ZIP — hỗ trợ UTF-8, extra field Unicode Path (0x7075).
class ZipFilenameDecoder {
  static const _efsFlag = 0x800;
  static const _unicodePathExtraId = 0x7075;

  static String decode({
    required Uint8List nameBytes,
    required int flags,
    Uint8List? extra,
  }) {
    if (nameBytes.isEmpty) return '';

    final extraBytes = extra ?? Uint8List(0);
    final unicodePath = _readUnicodePathExtra(extraBytes);
    if (unicodePath != null && unicodePath.isNotEmpty) {
      return unicodePath;
    }

    if ((flags & _efsFlag) != 0) {
      return utf8.decode(nameBytes, allowMalformed: true);
    }

    if (_isValidUtf8(nameBytes)) {
      return utf8.decode(nameBytes);
    }

    return String.fromCharCodes(nameBytes);
  }

  static String? _readUnicodePathExtra(Uint8List extra) {
    var i = 0;
    while (i + 4 <= extra.length) {
      final header = ByteData.sublistView(extra, i);
      final id = header.getUint16(0, Endian.little);
      final size = header.getUint16(2, Endian.little);
      if (i + 4 + size > extra.length) break;

      if (id == _unicodePathExtraId && size > 5) {
        final dataStart = i + 4 + 5;
        final dataEnd = i + 4 + size;
        return utf8.decode(extra.sublist(dataStart, dataEnd), allowMalformed: true);
      }

      i += 4 + size;
    }
    return null;
  }

  static bool _isValidUtf8(Uint8List bytes) {
    try {
      utf8.decode(bytes);
      return true;
    } on FormatException {
      return false;
    }
  }
}
