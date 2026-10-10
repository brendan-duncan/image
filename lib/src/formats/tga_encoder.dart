import 'dart:typed_data';

import '../color/format.dart';
import '../image/image.dart';
import '../image/pixel.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';

/// Encode a TGA image. This only supports the 24-bit and 32-bit uncompressed
/// formats.
class TgaEncoder extends Encoder {
  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    if (image.format != Format.uint8) {
      image = image.convert(format: Format.uint8);
    }
    final nc = image.palette?.numChannels ?? image.numChannels;
    // Grayscale+alpha is written as RGBA, and grayscale as RGB.
    final hasAlpha = nc == 4 || nc == 2;
    final bytesPerPixel = hasAlpha ? 4 : 3;
    final width = image.width;
    final height = image.height;

    final out = OutputBuffer(
        size: 18 + width * height * bytesPerPixel, bigEndian: true);

    final header = List<int>.filled(18, 0);
    header[2] = 2;
    header[12] = width & 0xff;
    header[13] = (width >> 8) & 0xff;
    header[14] = height & 0xff;
    header[15] = (height >> 8) & 0xff;
    header[16] = hasAlpha ? 32 : 24;

    out.writeBytes(header);

    // Rows are stored bottom to top, as BGR(A).
    final row = Uint8List(width * bytesPerPixel);
    if (!image.hasPalette) {
      final data = image.toUint8List();
      final stride = image.data!.rowStride;
      for (var y = height - 1; y >= 0; --y) {
        _swizzleRow(data, y * stride, nc, row, bytesPerPixel);
        out.writeBytes(row);
      }
    } else {
      Pixel? p;
      for (var y = height - 1; y >= 0; --y) {
        p = image.getPixel(0, y, p);
        for (var x = 0, i = 0; x < width; ++x, p.moveNext()) {
          row[i++] = p.b.toInt();
          row[i++] = p.g.toInt();
          row[i++] = p.r.toInt();
          if (hasAlpha) {
            row[i++] = p.a.toInt();
          }
        }
        out.writeBytes(row);
      }
    }

    return out.getBytes();
  }

  // Converts a row of nc channel pixels at offset o of src to BGR(A) in row.
  static void _swizzleRow(
      Uint8List src, int o, int nc, Uint8List row, int bytesPerPixel) {
    final n = row.length;
    for (var i = 0, s = o; i < n; i += bytesPerPixel, s += nc) {
      if (nc >= 3) {
        row[i] = src[s + 2];
        row[i + 1] = src[s + 1];
        row[i + 2] = src[s];
        if (bytesPerPixel == 4) {
          row[i + 3] = src[s + 3];
        }
      } else {
        final l = src[s];
        row[i] = l;
        row[i + 1] = l;
        row[i + 2] = l;
        if (bytesPerPixel == 4) {
          row[i + 3] = src[s + 1];
        }
      }
    }
  }
}
