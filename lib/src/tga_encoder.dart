part of image;

/**
 * Encode a Targa TGA image.  This only supports the 24-bit uncompressed format.
 */
class TgaEncoder {
  List<int> encode(Image image) {
    Arc.OutputBuffer out = new Arc.OutputBuffer(byteOrder: Arc.BIG_ENDIAN);

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
        int r = getRed(c);
        int g = getGreen(c);
        int b = getBlue(c);
        out.writeByte(b);
        out.writeByte(g);
        out.writeByte(r);
      }
    }

    return out.getBytes();
  }
}
