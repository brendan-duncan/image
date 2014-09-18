part of image;

class PvrtcEncoder {
  List<int> encodePvr(Image bitmap) {
    OutputBuffer output = new OutputBuffer();

    const PVR_TYPE_PVRTC2 = 0x18;
    const PVR_TYPE_PVRTC4 = 0x19;

    // PVRV2 Header
    int size = 44; // sizeof PVR header
    int mipmapCount = 1;
    int flags = PVR_TYPE_PVRTC4;
    int texdatasize = 0;
    int bpp = 4;
    int rmask = 0;
    int gmask = 0;
    int bmask = 0;
    int amask = 0;
    int magic = 0x21525650;
    int numtex = 1;

    output.writeUint32(size);
    output.writeUint32(bitmap.height);
    output.writeUint32(bitmap.width);
    output.writeUint32(mipmapCount);
    output.writeUint32(flags);
    output.writeUint32(texdatasize);
    output.writeUint32(bpp);
    output.writeUint32(rmask);
    output.writeUint32(gmask);
    output.writeUint32(bmask);
    output.writeUint32(amask);
    output.writeUint32(magic);
    output.writeUint32(numtex);

    output.writeBytes(encodeRgb4Bpp(bitmap));

    return output.getBytes();
  }

  List<int> encodeRgb4Bpp(Image bitmap) {
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

    var packetData = new Uint32List((bitmap.width * bitmap.height) ~/ 4);
    var packet = new PvrtcPacket(packetData);

    int maxIndex = 0;

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
        var cbb = _calculateBoundingBox(bitmapData, size, x, y);

        packet.setIndex(_getMortonNumber(x, y));
        maxIndex = Math.max(packet.index, maxIndex);

        packet.usePunchthroughAlpha = 0;
        packet.setColorARgb(cbb.min);
        packet.setColorBRgb(cbb.max);
      }
    }

    var p0 = new PvrtcPacket(packetData);
    var p1 = new PvrtcPacket(packetData);
    var p2 = new PvrtcPacket(packetData);
    var p3 = new PvrtcPacket(packetData);

    for(int y = 0; y < blocks; ++y) {
      for(int x = 0; x < blocks; ++x) {
        const factor = PvrtcPacket.BILINEAR_FACTORS;
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
            maxIndex = Math.max(p0.index, maxIndex);
            maxIndex = Math.max(p1.index, maxIndex);
            maxIndex = Math.max(p2.index, maxIndex);
            maxIndex = Math.max(p3.index, maxIndex);

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
              var p = new PvrtcColorRgb(r * 16, g * 16, b * 16);
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
        maxIndex = Math.max(packet.index, maxIndex);

        packet.modulationData = modulationData;
      }
    }

    return new Uint8List.view(packetData.buffer).sublist(0, maxIndex * 2 + 8);
  }

  int _rotateRight(int n, int d) {
    return (n >> d) | (n << (32 - d));
  }

  static PvrtcColorRgbBoundingBox _calculateBoundingBox(Uint8List data,
                                                        int size, int blockX,
                                                        int blockY) {
    int pi = blockY * 4 * size + blockX * 4;

    _pixel(i) {
      i = pi + i * 4;
      return new PvrtcColorRgb(data[i], data[i + 1], data[i + 2]);
    }

    var cbb = new PvrtcColorRgbBoundingBox(_pixel(0), _pixel(0));
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
