part of image;

/**
 * Ported from Jeffrey Lim's PRTC encoder/decoder,
 * https://bitbucket.org/jthlim/pvrtccompressor
 */
class PvrtcDecoder {
  Image decodeRgb4Bpp(int width, int height, TypedData data) {
    var result = new Image(width, height, Image.RGB);

    final int blocks = width ~/ 4;
    final int blockMask = blocks - 1;

    final packet = new PvrtcPacket(data);
    final p0 = new PvrtcPacket(data);
    final p1 = new PvrtcPacket(data);
    final p2 = new PvrtcPacket(data);
    final p3 = new PvrtcPacket(data);
    final c = new PvrtcColorRgb();
    const factors = PvrtcPacket.BILINEAR_FACTORS;
    const weights = PvrtcPacket.WEIGHTS;

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
        packet.setBlock(x, y);

        int mod = packet.modulationData;
        int weightIndex = 4 * packet.usePunchthroughAlpha;
        int factorIndex = 0;

        for (int py = 0; py < 4; ++py) {
          int yOffset = (py < 2) ? -1 : 0;
          int y0 = (y + yOffset) & blockMask;
          int y1 = (y0 + 1) & blockMask;
          int pyi = (py + y * 4) * width;

          for (int px = 0; px < 4; ++px) {
            int xOffset = (px < 2) ? -1 : 0;
            int x0 = (x + xOffset) & blockMask;
            int x1 = (x0 + 1) & blockMask;

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

            var w = weights[weightIndex + mod & 3];

            c.r = (ca.r * w[0] + cb.r * w[1]) >> 7;
            c.g = (ca.g * w[0] + cb.g * w[1]) >> 7;
            c.b = (ca.b * w[0] + cb.b * w[1]) >> 7;

            int pi = (pyi + (px + x * 4));

            result[pi] = getColor(c.r, c.g, c.b, 255);

            mod >>= 2;
            factorIndex++;
          }
        }
      }
    }

    return result;
  }

  Image decodeRgba4Bpp(int width, int height, TypedData data) {
    var result = new Image(width, height, Image.RGBA);

    final int blocks = width ~/ 4;
    final int blockMask = blocks - 1;

    final packet = new PvrtcPacket(data);
    final p0 = new PvrtcPacket(data);
    final p1 = new PvrtcPacket(data);
    final p2 = new PvrtcPacket(data);
    final p3 = new PvrtcPacket(data);
    final c = new PvrtcColorRgba();
    const factors = PvrtcPacket.BILINEAR_FACTORS;
    const weights = PvrtcPacket.WEIGHTS;

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
        packet.setBlock(x, y);

        int mod = packet.modulationData;
        int weightIndex = 4 * packet.usePunchthroughAlpha;
        int factorIndex = 0;

        for (int py = 0; py < 4; ++py) {
          int yOffset = (py < 2) ? -1 : 0;
          int y0 = (y + yOffset) & blockMask;
          int y1 = (y0 + 1) & blockMask;
          int pyi = (py + y * 4) * width;

          for (int px = 0; px < 4; ++px) {
            int xOffset = (px < 2) ? -1 : 0;
            int x0 = (x + xOffset) & blockMask;
            int x1 = (x0 + 1) & blockMask;

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

            var w = weights[weightIndex + mod & 3];

            c.r = (ca.r * w[0] + cb.r * w[1]) >> 7;
            c.g = (ca.g * w[0] + cb.g * w[1]) >> 7;
            c.b = (ca.b * w[0] + cb.b * w[1]) >> 7;
            c.a = (ca.a * w[2] + cb.a * w[3]) >> 7;

            int pi = (pyi + (px + x * 4));

            result[pi] = getColor(c.r, c.g, c.b, c.a);

            mod >>= 2;
            factorIndex++;
          }
        }
      }
    }

    return result;
  }
}
