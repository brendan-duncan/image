part of dart_image;

/**
 * Decode a PNG encoded image.
 */
class PngDecoder {
  Image decode(List<int> data) {
    _ByteBuffer bytes = new _ByteBuffer.fromList(data);

    _PngHeader header;
    List<int> palette;
    List<int> imageData = [];
    _PngTransparency transparency;
    int colors;
    bool hasAlphaChannel;
    int pixelBitlength;
    String colorSpace;
    Image image;

    List<int> pngHeader = bytes.readBytes(8);
    const PNG_HEADER = const [137, 80, 78, 71, 13, 10, 26, 10];
    for (int i = 0; i < 8; ++i) {
      if (pngHeader[i] != PNG_HEADER[i]) {
        throw 'Invalid PNG file';
      }
    }

    // Chunk Types:
    // IHDR must be the first chunk; it contains the image's width, height,
    //      and bit depth.[10]
    // PLTE contains the palette; list of colors.
    // IDAT contains the image, which may be split among multiple IDAT chunks.
    //      Such splitting increases filesize slightly, but makes it possible
    //      to generate a PNG in a streaming manner. The IDAT chunk contains
    //      the actual image data, which is the output stream of the
    //       compression algorithm.[11]
    // IEND marks the image end.
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
      int chunkSize = bytes.readUInt32();
      String section = new String.fromCharCodes(bytes.readBytes(4));

      switch (section) {
        case 'IHDR':
          header = new _PngHeader();
          header.width = bytes.readUInt32();
          header.height = bytes.readUInt32();
          header.bits = bytes.readByte();
          header.colorType = bytes.readByte();
          header.compressionMethod = bytes.readByte();
          header.filterMethod = bytes.readByte();
          header.interlaceMethod = bytes.readByte();

          int format = (header.colorType == 2) ? Image.RGB : Image.RGBA;
          image = new Image(header.width, header.height, format);
          break;
        case 'PLTE':
          palette = bytes.readBytes(chunkSize);
          break;
        case 'IDAT':
          var data = bytes.readBytes(chunkSize);
          imageData.addAll(data);
          break;
        case 'tRNS':
          transparency = new _PngTransparency();
          switch (header.colorType) {
            case 3: // Indexed
              transparency.indexed = bytes.readBytes(chunkSize);
              if (transparency.indexed.length < 255) {
                int num = 255 - transparency.indexed.length;
                for (int i = 0; i < num; ++i) {
                  transparency.indexed.add(255);
                }
              }
              break;
            case 0: // Grayscale
              transparency.grayscale = bytes.readBytes(chunkSize)[0];
              break;
            case 2: // Truecolor (RGB)
              transparency.rgb = bytes.readBytes(chunkSize);
              break;
          }
          break;
        case 'tEXt':
          /*List<int> text = bytes.readBytes(chunkSize);
          String key = new String.fromCharCodes(text);
          print(key);
          text[key] = String.fromCharCode.apply(String, text.slice(index + 1));
          */
          break;
        case 'IEND':
          // End of the image.
          switch (header.colorType) {
            case 0:
            case 3:
            case 4:
              colors = 1;
              break;
            case 2:
            case 6:
              colors = 3;
              break;
          }

          hasAlphaChannel = header.colorType == 4 || header.colorType == 6;
          colors = colors + (hasAlphaChannel ? 1 : 0);
          pixelBitlength = header.bits * colors;
          colorSpace = (colors == 1) ? 'DeviceGray' : 'DeviceRGB';
          break;
        default:
          bytes.skip(chunkSize);
          break;
      }

      if (section == 'IEND') {
        break;
      }

      // CRC
      bytes.skip(4);

      if (bytes.isEOF) {
        throw 'Incomplete or corrupt PNG file';
      }
    }

    if (header == null) {
      throw 'Incomplete or corrupt PNG file';
    }

    var zlib = new Io.ZLibDecoder();
    List<int> uncompressed = zlib.convert(imageData);

    bytes = new _ByteBuffer.fromList(uncompressed);

    int pixelBytes = pixelBitlength ~/ 8;

    // Before the image is compressed, it is filtered to improve compression.
    // Unfilter the image now.
    int pi = 0;
    int row = 0;
    while (!bytes.isEOF) {
      int code = bytes.readByte();
      switch (code) {
        case 0: // None
          for (int i = 0; i < header.width; i++) {
            image.buffer[pi++] = colorFromList(bytes.readBytes(pixelBytes));
          }
          break;
        case 1: // Sub
          for (int i = 0; i < header.width; i++) {
            int x = colorFromList(bytes.readBytes(pixelBytes));
            int a = (i == 0) ? 0 : image.buffer[pi - 1];
            image.buffer[pi++] = color((red(x) + red(a)) % 256,
                                       (green(x) + green(a)) % 256,
                                       (blue(x) + blue(a)) % 256,
                                       (alpha(x) + alpha(a)) % 256);
          }
          break;
        case 2: // Up
          for (int i = 0; i < header.width; i++) {
            int x = colorFromList(bytes.readBytes(pixelBytes));
            int b = (row == 0) ? 0 : image.getPixel(i, row - 1);
            image.buffer[pi++] = color((red(x) + red(b)) % 256,
                                       (green(x) + green(b)) % 256,
                                       (blue(x) + blue(b)) % 256,
                                       (alpha(x) + alpha(b)) % 256);
          }
          break;
        case 3: // Average
          for (int i = 0; i < header.width; i++) {
            int x = colorFromList(bytes.readBytes(pixelBytes));
            int a = (i == 0) ? 0 : image.buffer[pi - 1];
            int b = (row == 0) ? 0 : image.getPixel(i, row - 1);
            int ra = red(a);
            int rb = red(b);
            int ga = green(a);
            int gb = green(b);
            int ba = blue(a);
            int bb = blue(b);
            int aa = alpha(a);
            int ab = alpha(b);
            image.buffer[pi++] = color((red(x) + ((ra + rb) ~/ 2)) % 256,
                                       (green(x) + ((ga + gb) ~/ 2)) % 256,
                                       (blue(x) + ((ba + bb) ~/ 2)) % 256,
                                       (alpha(x) + ((aa + ab) ~/ 2)) % 256);
          }
          break;
        case 4: // Paeth
          for (int i = 0; i < header.width; i++) {
            int x = colorFromList(bytes.readBytes(pixelBytes));
            int a = (i == 0) ? 0 : image.buffer[pi - 1];
            int b = (row == 0) ? 0 : image.getPixel(i, row - 1);
            int c = (i == 0 || row == 0) ? 0 : image.getPixel(i - 1, row - 1);
            int ra = red(a);
            int rb = red(b);
            int rc = red(c);
            int ga = green(a);
            int gb = green(b);
            int gc = green(c);
            int ba = blue(a);
            int bb = blue(b);
            int bc = blue(c);
            int aa = alpha(a);
            int ab = alpha(b);
            int ac = alpha(c);

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

            image.buffer[pi++] = color((red(x) + rpaeth) % 256,
                                       (green(x) + gpaeth) % 256,
                                       (blue(x) + bpaeth) % 256,
                                       (alpha(x) + apaeth) % 256);
          }
          break;
        default:
          throw 'Invalid filter value';
      }
      row++;
    }

    return image;
  }
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

class _PngTransparency {
  int grayscale;
  List<int> rgb;
  List<int> indexed;
}
