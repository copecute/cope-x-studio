import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

/// Tạo ảnh PNG QR code để dùng trong thông báo.
class QrImageUtils {
  QrImageUtils._();

  static Uint8List generatePng(String data, {int size = 256}) {
    return _renderQr(data, size);
  }

  /// QR cho BigPicture notification — căn giữa, safe zone 4 cạnh bằng nhau.
  static Uint8List generateNotificationPng(String data) {
    const canvasSize = 512;
    const pad = 96;
    const qrSize = canvasSize - pad * 2;

    final canvas = img.Image(width: canvasSize, height: canvasSize);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    final qrImage = img.decodePng(_renderQr(data, qrSize))!;
    img.compositeImage(canvas, qrImage, dstX: pad, dstY: pad);

    return Uint8List.fromList(img.encodePng(canvas));
  }

  static Uint8List _renderQr(String data, int size, {int quietZoneModules = 4}) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;
    final totalModules = moduleCount + quietZoneModules * 2;
    final cellSize = (size / totalModules).floor().clamp(1, size);
    final image = img.Image(width: size, height: size);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    for (var x = 0; x < moduleCount; x++) {
      for (var y = 0; y < moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          final px = (x + quietZoneModules) * cellSize;
          final py = (y + quietZoneModules) * cellSize;
          img.fillRect(
            image,
            x1: px,
            y1: py,
            x2: px + cellSize - 1,
            y2: py + cellSize - 1,
            color: img.ColorRgb8(0, 0, 0),
          );
        }
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }
}
