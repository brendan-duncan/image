import 'dart:typed_data';

import '../../image/image.dart';
import '../../util/image_exception.dart';
import '../../util/output_buffer.dart';
import 'pvrtc_bit_utility.dart';
import 'pvrtc_color.dart';
import 'pvrtc_color_bounding_box.dart';
import 'pvrtc_packet.dart';

enum PvrtcFormat {
  auto,
  rgb2,
  rgba2,
  rgb4,
  rgba4
}

// Ported from Jeffrey Lim's PVRTC encoder/decoder,
// https://bitbucket.org/jthlim/pvrtccompressor
class PvrtcEncoder {
  Uint8List encodePvr(Image bitmap, { PvrtcFormat format = PvrtcFormat.auto }) {
    final output = OutputBuffer();

    Uint8List pvrtc;
    switch (format) {
      case PvrtcFormat.auto:
        if (bitmap.numChannels == 3) {
          pvrtc = encodeRgb4bpp(bitmap);
          format = PvrtcFormat.rgb4;
        } else {
          pvrtc = encodeRgba4bpp(bitmap);
          format = PvrtcFormat.rgba4;
        }
        break;
      case PvrtcFormat.rgb2:
        //pvrtc = encodeRgb2bpp(bitmap);
        pvrtc = encodeRgb4bpp(bitmap);
        break;
      case PvrtcFormat.rgba2:
        //pvrtc = encodeRgba2bpp(bitmap);
        pvrtc = encodeRgba4bpp(bitmap);
        break;
      case PvrtcFormat.rgb4:
        pvrtc = encodeRgb4bpp(bitmap);
        break;
      case PvrtcFormat.rgba4:
        pvrtc = encodeRgba4bpp(bitmap);
        break;
    }

    const version = 55727696;
    const flags = 0;
    final pixelFormat = format.index - 1;
    const channelOrder = 0;
    const colorSpace = 0;
    const channelType = 0;
    final height = bitmap.height;
    final width = bitmap.width;
    const depth = 1;
    const numSurfaces = 1;
    const numFaces = 1;
    const mipmapCount = 1;
    const metaDataSize = 0;

    output..writeUint32(version)
    ..writeUint32(flags)
    ..writeUint32(pixelFormat)
    ..writeUint32(channelOrder)
    ..writeUint32(colorSpace)
    ..writeUint32(channelType)
    ..writeUint32(height)
    ..writeUint32(width)
    ..writeUint32(depth)
    ..writeUint32(numSurfaces)
    ..writeUint32(numFaces)
    ..writeUint32(mipmapCount)
    ..writeUint32(metaDataSize)
    ..writeBytes(pvrtc);

    return output.getBytes();
  }

  Uint8List encodeRgb4bpp(Image bitmap) {
    if (bitmap.width != bitmap.height) {
      throw ImageException('PVRTC requires a square image.');
    }

    if (!BitUtility.isPowerOf2(bitmap.width)) {
      throw ImageException('PVRTC requires a power-of-two sized image.');
    }

    final size = bitmap.width;
    final blocks = size ~/ 4;
    final blockMask = blocks - 1;

    // Allocate enough data for encoding the image.
    final outputData = Uint8List((bitmap.width * bitmap.height) ~/ 2);
    final packet = PvrtcPacket(outputData);
    final p0 = PvrtcPacket(outputData);
    final p1 = PvrtcPacket(outputData);
    final p2 = PvrtcPacket(outputData);
    final p3 = PvrtcPacket(outputData);

    for (var y = 0; y < blocks; ++y) {
      for (var x = 0; x < blocks; ++x) {
        final cbb = _calculateBoundingBoxRgb(bitmap, x, y);
        packet..setBlock(x, y)
        ..usePunchthroughAlpha = false
        ..setColorRgbA(cbb.min as PvrtcColorRgb)
        ..setColorRgbB(cbb.max as PvrtcColorRgb);
      }
    }

    const factors = PvrtcPacket.bilinearFactors;

    for (var y = 0, y4 = 0; y < blocks; ++y, y4 += 4) {
      for (var x = 0, x4 = 0; x < blocks; ++x, x4 += 4) {
        var factorIndex = 0;
        var modulationData = 0;

        for (var py = 0; py < 4; ++py) {
          final yOffset = (py < 2) ? -1 : 0;
          final y0 = (y + yOffset) & blockMask;
          final y1 = (y0 + 1) & blockMask;

          for (var px = 0; px < 4; ++px) {
            final xOffset = (px < 2) ? -1 : 0;
            final x0 = (x + xOffset) & blockMask;
            final x1 = (x0 + 1) & blockMask;

            p0.setBlock(x0, y0);
            p1.setBlock(x1, y0);
            p2.setBlock(x0, y1);
            p3.setBlock(x1, y1);

            final ca = p0.getColorRgbA() * factors[factorIndex][0] +
                p1.getColorRgbA() * factors[factorIndex][1] +
                p2.getColorRgbA() * factors[factorIndex][2] +
                p3.getColorRgbA() * factors[factorIndex][3];

            final cb = p0.getColorRgbB() * factors[factorIndex][0] +
                p1.getColorRgbB() * factors[factorIndex][1] +
                p2.getColorRgbB() * factors[factorIndex][2] +
                p3.getColorRgbB() * factors[factorIndex][3];

            //final pi = pixelIndex + ((py * size + px) * 4);
            final _p = bitmap.getPixel(x4 + px, y4 + py);
            final r = _p.r.toInt();
            final g = _p.g.toInt();
            final b = _p.b.toInt();

            final d = cb - ca;
            final p = PvrtcColorRgb(r * 16, g * 16, b * 16);
            final v = p - ca;

            // PVRTC uses weightings of 0, 3/8, 5/8 and 1
            // The boundaries for these are 3/16, 1/2 (=8/16), 13/16
            final projection = v.dotProd(d) * 16;
            final lengthSquared = d.dotProd(d);
            if (projection > 3 * lengthSquared) {
              modulationData++;
            }
            if (projection > 8 * lengthSquared) {
              modulationData++;
            }
            if (projection > 13 * lengthSquared) {
              modulationData++;
            }

            modulationData = BitUtility.rotateRight(modulationData, 2);

            factorIndex++;
          }
        }

        packet..setBlock(x, y)
        ..modulationData = modulationData;
      }
    }

    return outputData;
  }

  Uint8List encodeRgba4bpp(Image bitmap) {
    if (bitmap.width != bitmap.height) {
      throw ImageException('PVRTC requires a square image.');
    }

    if (!BitUtility.isPowerOf2(bitmap.width)) {
      throw ImageException('PVRTC requires a power-of-two sized image.');
    }

    final size = bitmap.width;
    final blocks = size ~/ 4;
    final blockMask = blocks - 1;

    // Allocate enough data for encoding the image.
    final outputData = Uint8List((bitmap.width * bitmap.height) ~/ 2);
    final packet = PvrtcPacket(outputData);
    final p0 = PvrtcPacket(outputData);
    final p1 = PvrtcPacket(outputData);
    final p2 = PvrtcPacket(outputData);
    final p3 = PvrtcPacket(outputData);

    for (var y = 0, y4 = 0; y < blocks; ++y, y4 += 4) {
      for (var x = 0, x4 = 0; x < blocks; ++x, x4 += 4) {
        final cbb = _calculateBoundingBoxRgba(bitmap, x4, y4);
        packet..setBlock(x, y)
        ..usePunchthroughAlpha = false
        ..setColorRgbaA(cbb.min as PvrtcColorRgba)
        ..setColorRgbaB(cbb.max as PvrtcColorRgba);
      }
    }

    const factors = PvrtcPacket.bilinearFactors;

    for (var y = 0, y4 = 0; y < blocks; ++y, y4 += 4) {
      for (var x = 0, x4 = 0; x < blocks; ++x, x4 += 4) {
        var factorIndex = 0;
        var modulationData = 0;

        for (var py = 0; py < 4; ++py) {
          final yOffset = (py < 2) ? -1 : 0;
          final y0 = (y + yOffset) & blockMask;
          final y1 = (y0 + 1) & blockMask;

          for (var px = 0; px < 4; ++px) {
            final xOffset = (px < 2) ? -1 : 0;
            final x0 = (x + xOffset) & blockMask;
            final x1 = (x0 + 1) & blockMask;

            p0.setBlock(x0, y0);
            p1.setBlock(x1, y0);
            p2.setBlock(x0, y1);
            p3.setBlock(x1, y1);

            final ca = p0.getColorRgbaA() * factors[factorIndex][0] +
                p1.getColorRgbaA() * factors[factorIndex][1] +
                p2.getColorRgbaA() * factors[factorIndex][2] +
                p3.getColorRgbaA() * factors[factorIndex][3];

            final cb = p0.getColorRgbaB() * factors[factorIndex][0] +
                p1.getColorRgbaB() * factors[factorIndex][1] +
                p2.getColorRgbaB() * factors[factorIndex][2] +
                p3.getColorRgbaB() * factors[factorIndex][3];

            //final pi = pixelIndex + ((py * size + px) * 4);
            final bp = bitmap.getPixel(x4 + px, y4 + py);
            final r = bp.r as int;
            final g = bp.g as int;
            final b = bp.b as int;
            final a = bp.a as int;

            final d = cb - ca;
            final p = PvrtcColorRgba(r * 16, g * 16, b * 16, a * 16);
            final v = p - ca;

            // PVRTC uses weightings of 0, 3/8, 5/8 and 1
            // The boundaries for these are 3/16, 1/2 (=8/16), 13/16
            final projection = v.dotProd(d) * 16;
            final lengthSquared = d.dotProd(d);

            if (projection > 3 * lengthSquared) {
              modulationData++;
            }
            if (projection > 8 * lengthSquared) {
              modulationData++;
            }
            if (projection > 13 * lengthSquared) {
              modulationData++;
            }

            modulationData = BitUtility.rotateRight(modulationData, 2);

            factorIndex++;
          }
        }

        packet..setBlock(x, y)
        ..modulationData = modulationData;
      }
    }

    return outputData;
  }

  static PvrtcColorBoundingBox _calculateBoundingBoxRgb(Image bitmap,
      int blockX, int blockY) {

    PvrtcColorRgb _pixel(int x, int y) {
      final p = bitmap.getPixel(blockX + x, blockY + y);
      return PvrtcColorRgb(p.r as int, p.g as int, p.b as int);
    }

    final cbb = PvrtcColorBoundingBox(_pixel(0,0), _pixel(0,0))
    ..add(_pixel(1, 0))
    ..add(_pixel(2, 0))
    ..add(_pixel(3, 0))

    ..add(_pixel(0, 1))
    ..add(_pixel(1, 1))
    ..add(_pixel(1, 2))
    ..add(_pixel(1, 3))

    ..add(_pixel(2, 0))
    ..add(_pixel(2, 1))
    ..add(_pixel(2, 2))
    ..add(_pixel(2, 3))

    ..add(_pixel(3, 0))
    ..add(_pixel(3, 1))
    ..add(_pixel(3, 2))
    ..add(_pixel(3, 3));

    return cbb;
  }

  static PvrtcColorBoundingBox _calculateBoundingBoxRgba(Image bitmap,
      int blockX, int blockY) {

    PvrtcColorRgba _pixel(int x, int y) {
      final p = bitmap.getPixel(blockX + x, blockY + y);
      return PvrtcColorRgba(p.r as int, p.g as int, p.b as int, p.a as int);
    }

    final cbb = PvrtcColorBoundingBox(_pixel(0,0), _pixel(0,0))
    ..add(_pixel(1, 0))
    ..add(_pixel(2, 0))
    ..add(_pixel(3, 0))

    ..add(_pixel(0, 1))
    ..add(_pixel(1, 1))
    ..add(_pixel(1, 2))
    ..add(_pixel(1, 3))

    ..add(_pixel(2, 0))
    ..add(_pixel(2, 1))
    ..add(_pixel(2, 2))
    ..add(_pixel(2, 3))

    ..add(_pixel(3, 0))
    ..add(_pixel(3, 1))
    ..add(_pixel(3, 2))
    ..add(_pixel(3, 3));

    return cbb;
  }
}
