part of image;

class PvrtcEncoder {
  Uint8List EncodeRgb4Bpp(Image bitmap) {
    if (bitmap.width != bitmap.height) {
      throw new ImageException('PVRTC requires a square image (width == height).');
    }

    if (!_isPowerOfTwo(bitmap.width)) {
      throw new ImageException('PVRTC requires a power-of-two sized image.');
    }

    final int size = bitmap.width;
    final int blocks = size ~/ 4;
    final int blockMask = blocks - 1;

    var bitmapData = bitmap.getBytes();

    var packetData = new Uint32List((bitmap.width * bitmap.height) ~/ 2);
    var packet = new PvrTcPacket(packetData);

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
        var cbb = _calculateBoundingBox(bitmapData, size, x, y);

        packet.setIndex(_getMortonNumber(x, y));

        packet.usePunchthroughAlpha = 0;
        packet.colorA = cbb.min;
        packet.colorB = cbb.max;
      }
    }

    var p0 = new PvrTcPacket(packetData);
    var p1 = new PvrTcPacket(packetData);
    var p2 = new PvrTcPacket(packetData);
    var p3 = new PvrTcPacket(packetData);

    for(int y = 0; y < blocks; ++y) {
      for(int x = 0; x < blocks; ++x) {
        const factor = PvrTcPacket.BILINEAR_FACTORS;
        int factorIndex = 0;
        final pixelIndex = y * 4 * size + x * 4;

        int modulationData = 0;

        for (int py = 0; py < 4; ++py) {
          final int yOffset = (py < 2) ? -1 : 0;
          final int y0 = (y + yOffset) & blockMask;
          final int y1 = (y0 + 1) & blockMask;

          for(int px = 0; px < 4; ++px) {
            final int xOffset = (px < 2) ? -1 : 0;
            final int x0 = (x + xOffset) & blockMask;
            final int x1 = (x0 + 1) & blockMask;

            p0.setIndex(_getMortonNumber(x0, y0));
            p1.setIndex(_getMortonNumber(x1, y0));
            p2.setIndex(_getMortonNumber(x0, y1));
            p3.setIndex(_getMortonNumber(x1, y1));

            var ca = p0.getColorRgbA() * factor[factorIndex][0] +
                     p1.getColorRgbA() * factor[factorIndex][1] +
                     p2.getColorRgbA() * factor[factorIndex][2] +
                     p3.getColorRgbA() * factor[factorIndex][3];

            var cb = p0.getColorRgbB() * factor[factorIndex][0] +
                     p1.getColorRgbB() * factor[factorIndex][1] +
                     p2.getColorRgbB() * factor[factorIndex][2] +
                     p3.getColorRgbB() * factor[factorIndex][3];

            if (ca != cb) {
              int pi = pixelIndex + ((py * size + px) * 4);
              int r = bitmapData[pi];
              int g = bitmapData[pi + 1];
              int b = bitmapData[pi + 2];

              var d = cb - ca;
              var p = new PvrTcColorRgb(r * 16, g * 16, b * 16);
              var v = p - ca;

              int projection = v % d;
              int length = Math.sqrt(d % d).toInt();

              int weight = (16 * projection ~/ length).clamp(0, 15);
              modulationData |= MODULATION_LUT[weight];
            }

            modulationData = _rotateRight(modulationData, 2);

            factorIndex++;
          }
        }

        packet.setIndex(_getMortonNumber(x, y));
        packet.modulationData = modulationData;
      }
    }

    return new Uint8List.view(packetData.buffer);
  }

  int _rotateRight(int n, int d) {
    return (n >> d) | (n << (32 - d));
  }

  Uint8List EncodeRgba4Bpp(Image image) {
    return null;
  }

  static PvrTcColorRgbBoundingBox _calculateBoundingBox(Uint8List data,
                                                        int size, int blockX,
                                                        int blockY) {
    int pi = blockY * 4 * size + blockX * 4;

    _pixel(i) {
      i = pi + i * 4;
      return new PvrTcColorRgb(data[i], data[i + 1], data[i + 2]);
    }

    var cbb = new PvrTcColorRgbBoundingBox(_pixel(0), _pixel(0));
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

  static int _getMortonNumber(int x, int y) {
    return (_part1By1(y) << 1) + _part1By1(x);
  }

  // "Insert" a 0 bit after each of the 16 low bits of x
  static int _part1By1(int x) {
    x &= 0x0000ffff;                  // x = ---- ---- ---- ---- fedc ba98 7654 3210
    x = (x ^ (x <<  8)) & 0x00ff00ff; // x = ---- ---- fedc ba98 ---- ---- 7654 3210
    x = (x ^ (x <<  4)) & 0x0f0f0f0f; // x = ---- fedc ---- ba98 ---- 7654 ---- 3210
    x = (x ^ (x <<  2)) & 0x33333333; // x = --fe --dc --ba --98 --76 --54 --32 --10
    x = (x ^ (x <<  1)) & 0x55555555; // x = -f-e -d-c -b-a -9-8 -7-6 -5-4 -3-2 -1-0
    return x;
  }

  static bool _isPowerOfTwo(x) => (x & (x - 1)) == 0;

  static const MODULATION_LUT =
      const [ 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3 ];
}
