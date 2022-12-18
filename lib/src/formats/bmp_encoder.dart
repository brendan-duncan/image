import 'dart:typed_data';

import '../image/image.dart';
import '../util/output_buffer.dart';
import 'bmp/bmp_info.dart';
import 'encoder.dart';

/// Encode a BMP image.
class BmpEncoder extends Encoder {
  int _roundToMultiple(int x) {
    final y = x & 0x3;
    if (y == 0) {
      return x;
    }
    return x + 4 - y;
  }
  @override
  Uint8List encodeImage(Image image) {
    final out = OutputBuffer();

    var bpp = image.bitsPerChannel * image.data!.numChannels;
    if (bpp == 12) {
      bpp = 16;
    }

    final imageStride = image.rowStride;
    final fileStride = ((image.width * bpp + 31) ~/ 32) * 4;
    final rowPaddingSize = fileStride - imageStride;
    final rowPadding = rowPaddingSize > 0
        ? List<int>.filled(rowPaddingSize, 0xff) : null;

    final imageFileSize = fileStride * image.height;

    const headerSize = 54;
    const headerInfoSize = 40;
    final paletteSize = (image.palette?.numColors ?? 0) * 4;
    final origImageOffset = headerSize + paletteSize;
    final imageOffset = _roundToMultiple(origImageOffset);
    final gapSize = imageOffset - origImageOffset;
    final fileSize = imageFileSize + headerSize + paletteSize + gapSize;

    out.writeUint16(BmpFileHeader.bmpHeaderFiletype);
    out.writeUint32(fileSize);

    out.writeUint32(0); // reserved
    out.writeUint32(imageOffset); // offset to image data

    out.writeUint32(headerInfoSize);
    out.writeUint32(image.width);
    out.writeUint32(image.height);
    out.writeUint16(1); // planes
    out.writeUint16(bpp); // bits per pixel
    out.writeUint32(BmpCompression.none.index); // compression, none
    out.writeUint32(imageFileSize);
    out.writeUint32(0); // hr
    out.writeUint32(0); // vr
    out.writeUint32(0); // totalColors
    out.writeUint32(0); // importantColors

    if (bpp == 1 || bpp == 2 || bpp == 4 || bpp == 8) {
      if (image.hasPalette) {
        final palette = image.palette!;
        for (var pi = 0, l = palette.numColors; pi < l; ++pi) {
          out.writeByte(palette.getBlue(pi).toInt());
          out.writeByte(palette.getGreen(pi).toInt());
          out.writeByte(palette.getRed(pi).toInt());
          out.writeByte(0);
        }
      } else {
        if (bpp == 1) {
          out.writeByte(0);
          out.writeByte(0);
          out.writeByte(0);
          out.writeByte(0);

          out.writeByte(255);
          out.writeByte(255);
          out.writeByte(255);
          out.writeByte(0);
        } else if (bpp == 2) {
          for (var pi = 0; pi < 4; ++pi) {
            final v = pi * 85;
            out.writeByte(v);
            out.writeByte(v);
            out.writeByte(v);
            out.writeByte(0);
          }
        } else if (bpp == 4) {
          for (var pi = 0; pi < 16; ++pi) {
            final v = pi * 17;
            out.writeByte(v);
            out.writeByte(v);
            out.writeByte(v);
            out.writeByte(0);
          }
        } else if (bpp == 8) {
          for (var pi = 0; pi < 256; ++pi) {
            out.writeByte(pi);
            out.writeByte(pi);
            out.writeByte(pi);
            out.writeByte(0);
          }
        }
      }
    }

    // image data must be aligned to a 4 byte alignment. Pad the remaining
    // bytes until the image starts.
    var gap1 = gapSize;
    while (gap1-- > 0) {
      out.writeByte(0);
    }

    // Write image data
    if (bpp == 1 || bpp == 2 || bpp == 4 || bpp == 8) {
      var offset = image.lengthInBytes - imageStride;
      for (var y = 0, h = image.height; y < h; ++y) {
        final bytes = Uint8List.view(image.buffer, offset, imageStride);

        if (bpp == 1) {
          out.writeBytes(bytes);
        } else if (bpp == 2) {
          for (int xi = 0, l = bytes.length; xi < l; ++xi) {
            final b = bytes[xi];
            final left = b >> 4;
            final right = b & 0x0f;
            final rb = (right << 4) | left;
            out.writeByte(rb);
          }
        } else if (bpp == 4) {
          for (int xi = 0, l = bytes.length; xi < l; ++xi) {
            final b = bytes[xi];
            final b1 = b >> 4;
            final b2 = b & 0x0f;
            final rb = (b1 << 4) | b2;
            out.writeByte(rb);
          }
        } else {
          out.writeBytes(bytes);
        }

        if (rowPadding != null) {
          out.writeBytes(rowPadding);
        }

        offset -= imageStride;
      }

      return out.getBytes();
    }

    if (bpp == 16) {
      for (var h = image.height, y = h - 1; y >= 0; --y) {
        for (var x = 0, w = image.width; x < w; ++x) {
          final p = image.getPixel(x, y);
          final c = (p.r.toInt().clamp(0,15) << 10) |
              (p.g.toInt().clamp(0,15) << 5) |
              (p.b.toInt().clamp(0,15));
          out.writeUint16(c);
        }
        if (rowPadding != null) {
          out.writeBytes(rowPadding);
        }
      }
      return out.getBytes();
    }

    for (var h = image.height, y = h - 1; y >= 0; --y) {
      for (var x = 0, w = image.width; x < w; ++x) {
        final p = image.getPixel(x, y);
        out.writeByte(p.b.toInt());
        out.writeByte(p.g.toInt());
        out.writeByte(p.r.toInt());
        if (image.numChannels == 4) {
          out.writeByte(p.a.toInt());
        }
      }
      if (rowPadding != null) {
        out.writeBytes(rowPadding);
      }
    }

    return out.getBytes();
  }
}
