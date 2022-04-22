import '../image.dart';
import 'draw_line.dart';
import 'package:qr/qr.dart';

/// Draw a QR code onto the image [dst]
/// 
/// The density can be 1 (low) through 10 (high)
/// Example QR site using this lib: https://kevmoo.github.io/qr.dart/
/// 
Image drawQr(Image dst, String data, 
    int qrPixelSide,
    {int density = 5, 
    int errorCorrectLevel = QrErrorCorrectLevel.M,
    int? dstX,
    int? dstY,
    int? color}) {
  dstX ??= 0;
  dstY ??= 0;
  color ??= 0xff000000;

  final qrCode = QrCode(density, errorCorrectLevel)
    ..addData(data);
  final qrImage = QrImage(qrCode);

  for (var x = 0; x < qrImage.moduleCount; x++) {
    for (var y = 0; y < qrImage.moduleCount; y++) {
      if (qrImage.isDark(y, x)) {
        drawQrPixel(dst, dstX + (x*qrPixelSide), dstY + (y*qrPixelSide), qrPixelSide, color);
      }
    }
  }
  return dst;
}

Image drawQrPixel(Image dst, int x, int y, int side, int color) {
  for (var row = 0; row < side; row++) {
    drawLine(dst, x, y+row, x+side, y+row, color);
  }
  return dst;
}
