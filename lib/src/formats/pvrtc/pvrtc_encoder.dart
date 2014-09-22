part of image;

/**
 * Ported from Jeffrey Lim's PRTC encoder/decoder,
 * https://bitbucket.org/jthlim/pvrtccompressor
 */
class PvrtcEncoder {
  // PVR Format
  static const int PVR_AUTO = -1;
  static const int PVR_RGB_2BPP = 0;
  static const int PVR_RGBA_2BPP = 1;
  static const int PVR_RGB_4BPP = 2;
  static const int PVR_RGBA_4BPP = 3;

  Uint8List encodePvr(Image bitmap, {int format: PVR_AUTO}) {
    OutputBuffer output = new OutputBuffer();

    var pvrtc;
    if (format == PVR_AUTO) {
       if (bitmap.format == Image.RGB) {
        pvrtc = encodeRgb4Bpp(bitmap);
        format = PVR_RGB_4BPP;
      } else {
        pvrtc = encodeRgba4Bpp(bitmap);
        format = PVR_RGBA_4BPP;
      }
    } else if (format == PVR_RGB_2BPP) {
      //pvrtc = encodeRgb2Bpp(bitmap);
      pvrtc = encodeRgb4Bpp(bitmap);
    } else if (format == PVR_RGBA_2BPP) {
      //pvrtc = encodeRgba2Bpp(bitmap);
      pvrtc = encodeRgba4Bpp(bitmap);
    } else if (format == PVR_RGB_4BPP) {
      pvrtc = encodeRgb4Bpp(bitmap);
    } else if (format == PVR_RGBA_4BPP) {
      pvrtc = encodeRgba4Bpp(bitmap);
    }

    int version = 55727696;
    int flags = 0;
    int pixelFormat = format;
    int channelOrder = 0;
    int colorSpace = 0;
    int channelType = 0;
    int height = bitmap.height;
    int width = bitmap.width;
    int depth = 1;
    int numSurfaces = 1;
    int numFaces = 1;
    int mipmapCount = 1;
    int metaDataSize = 0;

    output.writeUint32(version);
    output.writeUint32(flags);
    output.writeUint32(pixelFormat);
    output.writeUint32(channelOrder);
    output.writeUint32(colorSpace);
    output.writeUint32(channelType);
    output.writeUint32(height);
    output.writeUint32(width);
    output.writeUint32(depth);
    output.writeUint32(numSurfaces);
    output.writeUint32(numFaces);
    output.writeUint32(mipmapCount);
    output.writeUint32(metaDataSize);

    output.writeBytes(pvrtc);

    return output.getBytes();
  }

  Uint8List encodeRgb4Bpp(Image bitmap) {
    if (bitmap.width != bitmap.height) {
      throw new ImageException('PVRTC requires a square image.');
    }

    if (!BitUtility.isPowerOf2(bitmap.width)) {
      throw new ImageException('PVRTC requires a power-of-two sized image.');
    }

    final int size = bitmap.width;
    final int blocks = size ~/ 4;
    final int blockMask = blocks - 1;

    var bitmapData = bitmap.getBytes();

    // Allocate enough data for encoding the image.
    var outputData = new Uint8List((bitmap.width * bitmap.height) ~/ 2);
    var packet = new PvrtcPacket(outputData);
    var p0 = new PvrtcPacket(outputData);
    var p1 = new PvrtcPacket(outputData);
    var p2 = new PvrtcPacket(outputData);
    var p3 = new PvrtcPacket(outputData);

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
        packet.setBlock(x, y);
        packet.usePunchthroughAlpha = 0;
        var cbb = _calculateBoundingBoxRgb(bitmap, x, y);
        packet.setColorRgbA(cbb.min);
        packet.setColorRgbB(cbb.max);
      }
    }

    const factors = PvrtcPacket.BILINEAR_FACTORS;

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
        int factorIndex = 0;
        final pixelIndex = (y * 4 * size + x * 4) * 4;

        int modulationData = 0;

        for (int py = 0; py < 4; ++py) {
          final int yOffset = (py < 2) ? -1 : 0;
          final int y0 = (y + yOffset) & blockMask;
          final int y1 = (y0 + 1) & blockMask;

          for(int px = 0; px < 4; ++px) {
            final int xOffset = (px < 2) ? -1 : 0;
            final int x0 = (x + xOffset) & blockMask;
            final int x1 = (x0 + 1) & blockMask;

            p0.setBlock(x0, y0);
            p1.setBlock(x1, y0);
            p2.setBlock(x0, y1);
            p3.setBlock(x1, y1);

            var ca = p0.getColorRgbA() * factors[factorIndex][0] +
                     p1.getColorRgbA() * factors[factorIndex][1] +
                     p2.getColorRgbA() * factors[factorIndex][2] +
                     p3.getColorRgbA() * factors[factorIndex][3];

            var cb = p0.getColorRgbB() * factors[factorIndex][0] +
                     p1.getColorRgbB() * factors[factorIndex][1] +
                     p2.getColorRgbB() * factors[factorIndex][2] +
                     p3.getColorRgbB() * factors[factorIndex][3];

            int pi = pixelIndex + ((py * size + px) * 4);
            int r = bitmapData[pi];
            int g = bitmapData[pi + 1];
            int b = bitmapData[pi + 2];

            var d = cb - ca;
            var p = new PvrtcColorRgb(r * 16, g * 16, b * 16);
            var v = p - ca;

            // PVRTC uses weightings of 0, 3/8, 5/8 and 1
            // The boundaries for these are 3/16, 1/2 (=8/16), 13/16
            int projection = v.dotProd(d) * 16;
            int lengthSquared = d.dotProd(d);
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

        packet.setBlock(x, y);
        packet.modulationData = modulationData;
      }
    }

    return outputData;
  }


  Uint8List encodeRgba4Bpp(Image bitmap) {
    if (bitmap.width != bitmap.height) {
      throw new ImageException('PVRTC requires a square image.');
    }

    if (!BitUtility.isPowerOf2(bitmap.width)) {
      throw new ImageException('PVRTC requires a power-of-two sized image.');
    }

    final int size = bitmap.width;
    final int blocks = size ~/ 4;
    final int blockMask = blocks - 1;

    var bitmapData = bitmap.getBytes();

    // Allocate enough data for encoding the image.
    var outputData = new Uint8List((bitmap.width * bitmap.height) ~/ 2);
    var packet = new PvrtcPacket(outputData);
    var p0 = new PvrtcPacket(outputData);
    var p1 = new PvrtcPacket(outputData);
    var p2 = new PvrtcPacket(outputData);
    var p3 = new PvrtcPacket(outputData);

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
        packet.setBlock(x, y);
        packet.usePunchthroughAlpha = 0;
        var cbb = _calculateBoundingBoxRgba(bitmap, x, y);
        packet.setColorRgbaA(cbb.min);
        packet.setColorRgbaB(cbb.max);
      }
    }

    const factors = PvrtcPacket.BILINEAR_FACTORS;

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
        int factorIndex = 0;
        final pixelIndex = (y * 4 * size + x * 4) * 4;

        int modulationData = 0;

        for (int py = 0; py < 4; ++py) {
          final int yOffset = (py < 2) ? -1 : 0;
          final int y0 = (y + yOffset) & blockMask;
          final int y1 = (y0 + 1) & blockMask;

          for(int px = 0; px < 4; ++px) {
            final int xOffset = (px < 2) ? -1 : 0;
            final int x0 = (x + xOffset) & blockMask;
            final int x1 = (x0 + 1) & blockMask;

            p0.setBlock(x0, y0);
            p1.setBlock(x1, y0);
            p2.setBlock(x0, y1);
            p3.setBlock(x1, y1);

            var ca = p0.getColorRgbaA() * factors[factorIndex][0] +
                     p1.getColorRgbaA() * factors[factorIndex][1] +
                     p2.getColorRgbaA() * factors[factorIndex][2] +
                     p3.getColorRgbaA() * factors[factorIndex][3];

            var cb = p0.getColorRgbaB() * factors[factorIndex][0] +
                     p1.getColorRgbaB() * factors[factorIndex][1] +
                     p2.getColorRgbaB() * factors[factorIndex][2] +
                     p3.getColorRgbaB() * factors[factorIndex][3];

            int pi = pixelIndex + ((py * size + px) * 4);
            int r = bitmapData[pi];
            int g = bitmapData[pi + 1];
            int b = bitmapData[pi + 2];
            int a = bitmapData[pi + 3];

            var d = cb - ca;
            var p = new PvrtcColorRgba(r * 16, g * 16, b * 16, a * 16);
            var v = p - ca;

            // PVRTC uses weightings of 0, 3/8, 5/8 and 1
            // The boundaries for these are 3/16, 1/2 (=8/16), 13/16
            int projection = v.dotProd(d) * 16;
            int lengthSquared = d.dotProd(d);

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

        packet.setBlock(x, y);
        packet.modulationData = modulationData;
      }
    }

    return outputData;
  }

  static PvrtcColorBoundingBox _calculateBoundingBoxRgb(Image bitmap,
                                                        int blockX,
                                                        int blockY) {
    int size = bitmap.width;
    int pi = (blockY * 4 * size + blockX * 4);

    _pixel(i) {
      int c = bitmap[pi + i];
      return new PvrtcColorRgb(getRed(c), getGreen(c), getBlue(c));
    }

    var cbb = new PvrtcColorBoundingBox(_pixel(0), _pixel(0));
    cbb.add(_pixel(1));
    cbb.add(_pixel(2));
    cbb.add(_pixel(3));

    cbb.add(_pixel(size));
    cbb.add(_pixel(size + 1));
    cbb.add(_pixel(size + 2));
    cbb.add(_pixel(size + 3));

    cbb.add(_pixel(2 * size));
    cbb.add(_pixel(2 * size + 1));
    cbb.add(_pixel(2 * size + 2));
    cbb.add(_pixel(2 * size + 3));

    cbb.add(_pixel(3 * size));
    cbb.add(_pixel(3 * size + 1));
    cbb.add(_pixel(3 * size + 2));
    cbb.add(_pixel(3 * size + 3));

    return cbb;
  }

  static PvrtcColorBoundingBox _calculateBoundingBoxRgba(Image bitmap,
                                                         int blockX,
                                                         int blockY) {
    int size = bitmap.width;
    int pi = (blockY * 4 * size + blockX * 4);

    _pixel(i) {
      int c = bitmap[pi + i];
      return new PvrtcColorRgba(getRed(c), getGreen(c), getBlue(c), getAlpha(c));
    }

    var cbb = new PvrtcColorBoundingBox(_pixel(0), _pixel(0));
    cbb.add(_pixel(1));
    cbb.add(_pixel(2));
    cbb.add(_pixel(3));

    cbb.add(_pixel(size));
    cbb.add(_pixel(size + 1));
    cbb.add(_pixel(size + 2));
    cbb.add(_pixel(size + 3));

    cbb.add(_pixel(2 * size));
    cbb.add(_pixel(2 * size + 1));
    cbb.add(_pixel(2 * size + 2));
    cbb.add(_pixel(2 * size + 3));

    cbb.add(_pixel(3 * size));
    cbb.add(_pixel(3 * size + 1));
    cbb.add(_pixel(3 * size + 2));
    cbb.add(_pixel(3 * size + 3));

    return cbb;
  }

  static void _getPacket(packet, packetData, index) {
    index *= 2;
    packet.modulationData = packetData[index];
    packet.colorData = packetData[index + 1];
  }

  static const MODULATION_LUT =
      const [ 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3 ];
}
