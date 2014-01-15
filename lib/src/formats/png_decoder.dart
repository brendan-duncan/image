part of image;

/**
 * Decode a PNG encoded image.
 */
class PngDecoder {
  Image decode(List<int> data) {
    Arc.InputBuffer input = new Arc.InputBuffer(data,
        byteOrder: Arc.BIG_ENDIAN);

    _PngHeader header;
    List<int> palette;
    List<int> transparency;
    List<int> imageData = [];
    int colors;
    bool hasAlphaChannel;
    int pixelBitlength;
    Image image;
    int format;

    List<int> pngHeader = input.readBytes(8);
    const PNG_HEADER = const [137, 80, 78, 71, 13, 10, 26, 10];
    for (int i = 0; i < 8; ++i) {
      if (pngHeader[i] != PNG_HEADER[i]) {
        throw new ImageException('Invalid PNG file');
      }
    }

    // Chunk Types:
    //
    // Primary chunks
    //
    // IHDR must be the first chunk; it contains the image's width, height,
    //      and bit depth.
    // PLTE contains the palette; list of colors.
    // IDAT contains the image, which may be split among multiple IDAT chunks.
    //      Such splitting increases filesize slightly, but makes it possible
    //      to generate a PNG in a streaming manner. The IDAT chunk contains
    //      the actual image data, which is the output stream of the
    //       compression algorithm.
    // IEND marks the image end.
    //
    // Secondary chunks
    //
    // bKGD gives the default background color. It is intended for use when
    //      there is no better choice available, such as in standalone image
    //      viewers (but not web browsers; see below for more details).
    // cHRM gives the chromaticity coordinates of the display primaries and
    //      white point.
    // gAMA specifies gamma.
    // hIST can store the histogram, or total amount of each color in the image.
    // iCCP is an ICC color profile.
    // iTXt contains UTF-8 text, compressed or not, with an optional language
    //      tag. iTXt chunk with the keyword 'XML:com.adobe.xmp' can contain
    //      Extensible Metadata Platform (XMP).
    // pHYs holds the intended pixel size and/or aspect ratio of the image.
    // sBIT (significant bits) indicates the color-accuracy of the source data.
    // sPLT suggests a palette to use if the full range of colors is
    //      unavailable.
    // sRGB indicates that the standard sRGB color space is used.
    // sTER stereo-image indicator chunk for stereoscopic images.[13]
    // tEXt can store text that can be represented in ISO/IEC 8859-1, with one
    //      name=value pair for each chunk.
    // tIME stores the time that the image was last changed.
    // tRNS contains transparency information. For indexed images, it stores
    //      alpha channel values for one or more palette entries. For truecolor
    //      and grayscale images, it stores a single pixel value that is to be
    //      regarded as fully transparent.
    // zTXt contains compressed text with the same limits as tEXt.
    while (true) {
      int chunkSize = input.readUint32();
      String section = new String.fromCharCodes(input.readBytes(4));

      switch (section) {
        case 'IHDR':
          header = new _PngHeader();
          header.width = input.readUint32();
          header.height = input.readUint32();
          header.bits = input.readByte();
          header.colorType = input.readByte();
          header.compressionMethod = input.readByte();
          header.filterMethod = input.readByte();
          header.interlaceMethod = input.readByte();

          if (![8, 16].contains(header.bits)) {
            throw new ImageException('Unsuported bit depth: ${header.bits}.');
          }

          if (![0, 2, 3, 4, 6].contains(header.colorType)) {
            throw new ImageException('Unsupported color type: ${header.colorType}.');
          }

          if (header.interlaceMethod != 0) {
            throw new ImageException('Unsupported interlace method: ${header.interlaceMethod}.');
          }
          break;
        case 'PLTE':
          palette = input.readBytes(chunkSize);
          break;
        case 'tRNS':
          transparency = input.readBytes(chunkSize);
          break;
        case 'IDAT':
          List<int> data = input.readBytes(chunkSize);
          imageData.addAll(data);
          break;
        case 'IEND':
          // End of the image.
          switch (header.colorType) {
            case GRAYSCALE:
            case INDEXED:
            case GRAYSCALE_ALPHA:
              colors = 1;
              break;
            case RGB:
            case RGBA:
              colors = 3;
              break;
          }

          hasAlphaChannel = header.colorType == GRAYSCALE_ALPHA ||
                            header.colorType == RGBA;
          colors = colors + (hasAlphaChannel ? 1 : 0);
          pixelBitlength = header.bits * colors;

          if (hasAlphaChannel || transparency != null) {
            format = Image.RGBA;
          } else {
            format = Image.RGB;
          }
          break;
        default:
          input.skip(chunkSize);
          break;
      }

      if (section == 'IEND') {
        break;
      }

      // CRC
      input.readUint32();

      if (input.isEOF) {
        throw new ImageException('Incomplete or corrupt PNG file');
      }
    }

    if (header == null) {
      throw new ImageException('Incomplete or corrupt PNG file');
    }

    image = new Image(header.width, header.height, format);

    List<int> uncompressed = new Arc.ZLibDecoder().decodeBytes(imageData);

    input = new Arc.InputBuffer(uncompressed, byteOrder: Arc.BIG_ENDIAN);

    int pixelBytes = pixelBitlength ~/ 8;

    /**
     * Get the color with the list of components.
     */
    int _getColor(List<int> c) {
      switch (header.colorType) {
        case GRAYSCALE:
          int g0;
          int g;
          switch (header.bits) {
            case 1:
              break;
            case 2:
              break;
            case 4:
              break;
            case 8:
              g0 = g = c[0];
              break;
            case 16:
              g0 = ((c[0] & 0xff) << 8) | (c[1] & 0xff);
              g = ((g0 / 0xffff) * 0xff).toInt();
              break;
          }
          if (transparency != null) {
            int a = ((transparency[0] & 0xff) << 24) | (transparency[1] & 0xff);
            if (g0 == a) {
              return getColor(g, g, g, 0);
            }
          }
          return getColor(g, g, g, 255);
        case RGB:
          int r, g, b;
          int r0, g0, b0;
          switch (header.bits) {
            case 1:
              break;
            case 2:
              break;
            case 4:
              break;
            case 8:
              r0 = r = c[0];
              g0 = g = c[1];
              b0 = b = c[2];
              break;
            case 16:
              r0 = ((c[0] & 0xff) << 8) | (c[1] & 0xff);
              r = ((r0 / 0xffff) * 0xff).toInt();

              g0 = ((c[2] & 0xff) << 8) | (c[3] & 0xff);
              g = ((g0 / 0xffff) * 0xff).toInt();

              b0 = ((c[4] & 0xff) << 8) | (c[5] & 0xff);
              b = ((b0 / 0xffff) * 0xff).toInt();
              break;
          }

          if (transparency != null) {
            int tr = ((transparency[0] & 0xff) << 8) | (transparency[1] & 0xff);
            int tg = ((transparency[2] & 0xff) << 8) | (transparency[3] & 0xff);
            int tb = ((transparency[4] & 0xff) << 8) | (transparency[5] & 0xff);
            if (r0 == tr && g0 == tg && b0 == tb) {
              return getColor(r, g, b, 0);
            }
          }

          return getColor(r, g, b, 255);
        case INDEXED:
          int i = c[0];
          int p = i * 3;
          int a = transparency != null && i < transparency.length ?
                  transparency[i] : 255;
          if (p >= palette.length) {
            return getColor(255, 255, 255, a);
          }
          return getColor(palette[p],
                          palette[p + 1],
                          palette[p + 2],
                          a);
        case GRAYSCALE_ALPHA:
          int g, a;
          switch (header.bits) {
            case 1:
              break;
            case 2:
              break;
            case 4:
              break;
            case 8:
              g = c[0];
              a = c[1];
              break;
            case 16:
              int g0 = ((c[0] & 0xff) << 8) | (c[1] & 0xff);
              g = ((g0 / 0xffff) * 0xff).toInt();

              int a0 = ((c[2] & 0xff) << 8) | (c[3] & 0xff);
              a = ((a0 / 0xffff) * 0xff).toInt();
              break;
          }

          return getColor(g, g, g, a);
        case RGBA:
          int r, g, b, a;
          switch (header.bits) {
            case 1:
              break;
            case 2:
              break;
            case 4:
              break;
            case 8:
              r = c[0];
              g = c[1];
              b = c[2];
              a = c[3];
              break;
            case 16:
              int r0 = ((c[0] & 0xff) << 8) | (c[1] & 0xff);
              r = ((r0 / 0xffff) * 0xff).toInt();

              int g0 = ((c[2] & 0xff) << 8) | (c[3] & 0xff);
              g = ((g0 / 0xffff) * 0xff).toInt();

              int b0 = ((c[4] & 0xff) << 8) | (c[5] & 0xff);
              b = ((b0 / 0xffff) * 0xff).toInt();

              int a0 = ((c[6] & 0xff) << 8) | (c[7] & 0xff);
              a = ((a0 / 0xffff) * 0xff).toInt();
              break;
          }

          return getColor(r, g, b, a);
      }

      throw new ImageException('Invalid color type: ${header.colorType}.');
    }

    // Before the image is compressed, it is filtered to improve compression.
    // Unfilter the image now.
    int pi = 0;
    int row = 0;
    while (!input.isEOF) {
      int code = input.readByte();
      switch (code) {
        case FILTER_NONE:
          for (int i = 0; i < header.width; i++) {
            image[pi++] = _getColor(input.readBytes(pixelBytes));
          }
          break;
        case FILTER_SUB:
          for (int i = 0; i < header.width; i++) {
            int x = _getColor(input.readBytes(pixelBytes));
            int a = (i == 0) ? 0 : image[pi - 1];
            image[pi++] = getColor((getRed(x) + getRed(a)) % 256,
                                   (getGreen(x) + getGreen(a)) % 256,
                                   (getBlue(x) + getBlue(a)) % 256,
                                   (getAlpha(x) + getAlpha(a)) % 256);
          }
          break;
        case FILTER_UP:
          for (int i = 0; i < header.width; i++) {
            int x = _getColor(input.readBytes(pixelBytes));
            int b = (row == 0) ? 0 : image.getPixel(i, row - 1);
            image[pi++] = getColor((getRed(x) + getRed(b)) % 256,
                                   (getGreen(x) + getGreen(b)) % 256,
                                   (getBlue(x) + getBlue(b)) % 256,
                                   (getAlpha(x) + getAlpha(b)) % 256);
          }
          break;
        case FILTER_AVERAGE:
          for (int i = 0; i < header.width; i++) {
            int x = _getColor(input.readBytes(pixelBytes));
            int a = (i == 0) ? 0 : image[pi - 1];
            int b = (row == 0) ? 0 : image.getPixel(i, row - 1);
            int ra = getRed(a);
            int rb = getRed(b);
            int ga = getGreen(a);
            int gb = getGreen(b);
            int ba = getBlue(a);
            int bb = getBlue(b);
            int aa = getAlpha(a);
            int ab = getAlpha(b);
            image[pi++] = getColor((getRed(x) + ((ra + rb) ~/ 2)) % 256,
                                   (getGreen(x) + ((ga + gb) ~/ 2)) % 256,
                                   (getBlue(x) + ((ba + bb) ~/ 2)) % 256,
                                   (getAlpha(x) + ((aa + ab) ~/ 2)) % 256);
          }
          break;
        case FILTER_PAETH:
          for (int i = 0; i < header.width; i++) {
            int x = _getColor(input.readBytes(pixelBytes));
            int a = (i == 0) ? 0 : image[pi - 1];
            int b = (row == 0) ? 0 : image.getPixel(i, row - 1);
            int c = (i == 0 || row == 0) ? 0 : image.getPixel(i - 1, row - 1);
            int ra = getRed(a);
            int rb = getRed(b);
            int rc = getRed(c);
            int ga = getGreen(a);
            int gb = getGreen(b);
            int gc = getGreen(c);
            int ba = getBlue(a);
            int bb = getBlue(b);
            int bc = getBlue(c);
            int aa = getAlpha(a);
            int ab = getAlpha(b);
            int ac = getAlpha(c);

            int pr = ra + rb - rc;
            int pg = ga + gb - gc;
            int pb = ba + bb - bc;
            int pa = aa + ab - ac;

            int pra = (pr - ra).abs();
            int prb = (pr - rb).abs();
            int prc = (pr - rc).abs();

            int rpaeth = 0;
            if (pra <= prb && pra <= prc) {
              rpaeth = ra;
            } else if (prb <= prc) {
              rpaeth = rb;
            } else {
              rpaeth = rc;
            }

            int pga = (pg - ga).abs();
            int pgb = (pg - gb).abs();
            int pgc = (pg - gc).abs();
            int gpaeth = 0;
            if (pga <= pgb && pga <= pgc) {
              gpaeth = ga;
            } else if (pgb <= pgc) {
              gpaeth = gb;
            } else {
              gpaeth = gc;
            }

            int pba = (pb - ba).abs();
            int pbb = (pb - bb).abs();
            int pbc = (pb - bc).abs();
            int bpaeth = 0;
            if (pba <= pbb && pba <= pbc) {
              bpaeth = ba;
            } else if (pbb <= pbc) {
              bpaeth = bb;
            } else {
              bpaeth = bc;
            }

            int paa = (pa - aa).abs();
            int pab = (pa - ab).abs();
            int pac = (pa - ac).abs();
            int apaeth = 0;
            if (paa <= pab && paa <= pac) {
              apaeth = aa;
            } else if (pab <= pac) {
              apaeth = ab;
            } else {
              apaeth = ac;
            }

            image[pi++] = getColor((getRed(x) + rpaeth) % 256,
                                   (getGreen(x) + gpaeth) % 256,
                                   (getBlue(x) + bpaeth) % 256,
                                   (getAlpha(x) + apaeth) % 256);
          }
          break;
        default:
          throw new ImageException('Invalid filter value');
      }
      row++;
    }

    return image;
  }

  static const int GRAYSCALE = 0;
  static const int RGB = 2;
  static const int INDEXED = 3;
  static const int GRAYSCALE_ALPHA = 4;
  static const int RGBA = 6;

  static const int FILTER_NONE = 0;
  static const int FILTER_SUB = 1;
  static const int FILTER_UP = 2;
  static const int FILTER_AVERAGE = 3;
  static const int FILTER_PAETH = 4;
}

class _PngHeader {
  int width;
  int height;
  int bits;
  int colorType;
  int compressionMethod;
  int filterMethod;
  int interlaceMethod;
}
