part of gd;

/**
 * Encode a TGA image.  Used for debugging since TGA format isn't used much
 * these days.
 */
class TgaEncoder {
  TgaEncoder() {
  }

  List<int> encode(Image image) {
    _ByteBuffer out = new _ByteBuffer();

    List<int> header = new List<int>(18);
    header.fillRange(0, 18, 0);
    header[2] = 2;
    header[12] = image.width & 0xff;
    header[13] = (image.width >> 8) & 0xff;
    header[14] = image.height & 0xff;
    header[15] = (image.height >> 8) & 0xff;
    header[16] = 24;

    out.writeBytes(header);

    for (int y = image.height - 1; y >= 0; --y) {
      for (int x = 0; x < image.width; ++x) {
        int c = image.getPixel(x, y);
        int r = red(c);
        int g = green(c);
        int b = blue(c);
        out.writeByte(b);
        out.writeByte(g);
        out.writeByte(r);
      }
    }

    return out.buffer;
  }
}
