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
  Uint8List encode(Image image, { bool singleFrame = false }) {
    final out = OutputBuffer();

    var bpp = image.bitsPerChannel * image.data!.numChannels;
    if (bpp == 12) {
      bpp = 16;
    }

    final compression = bpp == 32 ? BmpCompression.bitfields
        : BmpCompression.none;

    final imageStride = image.rowStride;
    final fileStride = ((image.width * bpp + 31) ~/ 32) * 4;
    final rowPaddingSize = fileStride - imageStride;
    final rowPadding = rowPaddingSize > 0
        ? List<int>.filled(rowPaddingSize, 0xff) : null;

    final imageFileSize = fileStride * image.height;

    //final bitmaskSize = bpp == 32 ? 16 : 0;

    final headerInfoSize = bpp > 8 ? 124 : 40;
    final headerSize = headerInfoSize + 14;
    final paletteSize = (image.palette?.numColors ?? 0) * 4;
    final origImageOffset = headerSize + paletteSize;
    final imageOffset = _roundToMultiple(origImageOffset);
    //final imageOffset = origImageOffset;
    final gapSize = imageOffset - origImageOffset;
    final fileSize = imageFileSize + headerSize + paletteSize + gapSize;

    const sRgb = 0x73524742;

    out..writeUint16(BmpFileHeader.signature)
    ..writeUint32(fileSize)
    ..writeUint32(0) // reserved
    ..writeUint32(imageOffset) // offset to image data
    ..writeUint32(headerInfoSize)
    ..writeUint32(image.width)
    ..writeUint32(image.height)
    ..writeUint16(1) // planes
    ..writeUint16(bpp) // bits per pixel
    ..writeUint32(compression.index) // compression
    ..writeUint32(imageFileSize)
    ..writeUint32(11811) // hr
    ..writeUint32(11811) // vr
    ..writeUint32(bpp == 8 ? 255 : 0) // totalColors
    ..writeUint32(bpp == 8 ? 255 : 0); // importantColors

    if (bpp > 8) {
      out..writeUint32(0x00ff0000) // redMask
        ..writeUint32(0x0000ff00) // greenMask
        ..writeUint32(0x000000ff) // blueMask
        ..writeUint32(0xff000000) // alphaMask
        ..writeUint32(sRgb) // CSType
        ..writeUint32(0) // endpoints.red.x
        ..writeUint32(0) // endpoints.red.y
        ..writeUint32(0) // endpoints.red.z
        ..writeUint32(0) // endpoints.green.x
        ..writeUint32(0) // endpoints.green.y
        ..writeUint32(0) // endpoints.green.z
        ..writeUint32(0) // endpoints.blue.x
        ..writeUint32(0) // endpoints.blue.y
        ..writeUint32(0) // endpoints.blue.z
        ..writeUint32(0) // gammaRed
        ..writeUint32(0) // gammaGreen
        ..writeUint32(0) // gammaBlue
        ..writeUint32(2) // intent LCS_GM_GRAPHICS
        ..writeUint32(0) // profileData
        ..writeUint32(0) // profileSize
        ..writeUint32(0); // reserved
    }

    if (bpp == 1 || bpp == 2 || bpp == 4 || bpp == 8) {
      if (image.hasPalette) {
        final palette = image.palette!;
        final l = palette.numColors;
        for (var pi = 0; pi < l; ++pi) {
          out..writeByte(palette.getBlue(pi).toInt())
          ..writeByte(palette.getGreen(pi).toInt())
          ..writeByte(palette.getRed(pi).toInt())
          ..writeByte(0);
        }
      } else {
        if (bpp == 1) {
          out..writeByte(0)
          ..writeByte(0)
          ..writeByte(0)
          ..writeByte(0)

          ..writeByte(255)
          ..writeByte(255)
          ..writeByte(255)
          ..writeByte(0);
        } else if (bpp == 2) {
          for (var pi = 0; pi < 4; ++pi) {
            final v = pi * 85;
            out..writeByte(v)
            ..writeByte(v)
            ..writeByte(v)
            ..writeByte(0);
          }
        } else if (bpp == 4) {
          for (var pi = 0; pi < 16; ++pi) {
            final v = pi * 17;
            out..writeByte(v)
            ..writeByte(v)
            ..writeByte(v)
            ..writeByte(0);
          }
        } else if (bpp == 8) {
          for (var pi = 0; pi < 256; ++pi) {
            out..writeByte(pi)
            ..writeByte(pi)
            ..writeByte(pi)
            ..writeByte(0);
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
      final h = image.height;
      for (var y = 0; y < h; ++y) {
        final bytes = Uint8List.view(image.buffer, offset, imageStride);

        if (bpp == 1) {
          out.writeBytes(bytes);
        } else if (bpp == 2) {
          final l = bytes.length;
          for (var xi = 0; xi < l; ++xi) {
            final b = bytes[xi];
            final left = b >> 4;
            final right = b & 0x0f;
            final rb = (right << 4) | left;
            out.writeByte(rb);
          }
        } else if (bpp == 4) {
          final l = bytes.length;
          for (var xi = 0; xi < l; ++xi) {
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
      final h = image.height;
      final w = image.width;
      for (var y = h - 1; y >= 0; --y) {
        for (var x = 0; x < w; ++x) {
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

    final hasAlpha = image.numChannels == 4;
    final h = image.height;
    final w = image.width;
    for (var y = h - 1; y >= 0; --y) {
      for (var x = 0; x < w; ++x) {
        final p = image.getPixel(x, y);
        out..writeByte(p.b.toInt())
        ..writeByte(p.g.toInt())
        ..writeByte(p.r.toInt());
        if (hasAlpha) {
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
