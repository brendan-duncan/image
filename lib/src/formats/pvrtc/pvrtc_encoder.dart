part of image;

/**
 * Ported from Jeremy Lim's PRTC encoder/decoder,
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

    var pvrtc = encodeRgb4Bpp(bitmap);

    // Currently encoding to PVR2 format version.

    const PVR_TYPE_PVRTC2 = 0x18;
    const PVR_TYPE_PVRTC4 = 0x19;
    const PVR2_MAGIC = 0x21525650;

    // PVR2 Header
    int size = 44; // sizeof PVR header
    int mipmapCount = 1;
    int flags = PVR_TYPE_PVRTC4;
    int texdatasize = pvrtc.length;
    int bpp = 8;
    int rmask = 255;
    int gmask = 255;
    int bmask = 255;
    int amask = 255;
    int magic = PVR2_MAGIC;
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

    output.writeBytes(pvrtc);

    return output.getBytes();
  }

  Uint8List encodeRgb4Bpp(Image bitmap) {
    if (bitmap.width != bitmap.height) {
      throw new ImageException('PVRTC requires a square image.');
    }

    if (!_isPowerOfTwo(bitmap.width)) {
      throw new ImageException('PVRTC requires a power-of-two sized image.');
    }

    final int size = bitmap.width;
    final int blocks = size ~/ 4;
    final int blockMask = blocks - 1;

    var bitmapData = bitmap.getBytes();

    // Allocate enough data for encoding the image.
    var outputData = new Uint8List(bitmap.width * bitmap.height);
    var packet = new PvrtcPacket(outputData);
    var p0 = new PvrtcPacket(outputData);
    var p1 = new PvrtcPacket(outputData);
    var p2 = new PvrtcPacket(outputData);
    var p3 = new PvrtcPacket(outputData);

    int maxIndex = 0;

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
        var cbb = _calculateBoundingBox(bitmapData, size, x, y);

        packet.setBlock(x, y);
        maxIndex = Math.max(packet.index, maxIndex);

        packet.usePunchthroughAlpha = 0;
        packet.setColorA(cbb.min);
        packet.setColorB(cbb.max);
      }
    }

    const factors = PvrtcPacket.BILINEAR_FACTORS;

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
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

            p0.setBlock(x0, y0);
            p1.setBlock(x1, y0);
            p2.setBlock(x0, y1);
            p3.setBlock(x1, y1);
            maxIndex = Math.max(p0.index, maxIndex);
            maxIndex = Math.max(p1.index, maxIndex);
            maxIndex = Math.max(p2.index, maxIndex);
            maxIndex = Math.max(p3.index, maxIndex);

            var ca = p0.getColorA() * factors[factorIndex][0] +
                     p1.getColorA() * factors[factorIndex][1] +
                     p2.getColorA() * factors[factorIndex][2] +
                     p3.getColorA() * factors[factorIndex][3];

            var cb = p0.getColorB() * factors[factorIndex][0] +
                     p1.getColorB() * factors[factorIndex][1] +
                     p2.getColorB() * factors[factorIndex][2] +
                     p3.getColorB() * factors[factorIndex][3];

            if (ca != cb) {
              int pi = pixelIndex + ((py * size + px) * 4);
              int r = bitmapData[pi];
              int g = bitmapData[pi + 1];
              int b = bitmapData[pi + 2];

              var d = cb - ca;
              var p = new PvrtcColor(r * 16, g * 16, b * 16);
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

        packet.setBlock(x, y);
        maxIndex = Math.max(packet.index, maxIndex);

        packet.modulationData = modulationData;
      }
    }

    return outputData;
  }

  int _rotateRight(int n, int d) => (n >> d) | (n << (32 - d));

  static PvrtcColorBoundingBox _calculateBoundingBox(Uint8List data,
                                                     int size, int blockX,
                                                     int blockY) {
    int pi = blockY * 4 * size + blockX * 4;

    _pixel(i) {
      i = pi + i * 4;
      return new PvrtcColor(data[i], data[i + 1], data[i + 2]);
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

  static bool _isPowerOfTwo(x) => (x & (x - 1)) == 0;

  static const MODULATION_LUT =
      const [ 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3 ];
}
