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
    Image image;
    int format;
    double gamma;

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
          Arc.InputBuffer hdr = new Arc.InputBuffer(input.readBytes(chunkSize),
                                                    byteOrder: Arc.BIG_ENDIAN);
          header = new _PngHeader();
          header.width = hdr.readUint32();
          header.height = hdr.readUint32();
          header.bits = hdr.readByte();
          header.colorType = hdr.readByte();
          header.compressionMethod = hdr.readByte();
          header.filterMethod = hdr.readByte();
          header.interlaceMethod = hdr.readByte();

          // Validate some of the info in the header to make sure we support
          // the proposed image data.
          if (![GRAYSCALE, RGB, INDEXED, GRAYSCALE_ALPHA, RGBA].contains(header.colorType)) {
            throw new ImageException('Unsupported color type: ${header.colorType}.');
          }

          if (header.filterMethod != 0) {
            throw new ImageException('Unsupported filter method: ${header.filterMethod}');
          }

          switch (header.colorType) {
            case GRAYSCALE:
              if (![1, 2, 4, 8, 16].contains(header.bits)) {
                throw new ImageException('Unsuported bit depth: ${header.bits}.');
              }
              break;
            case RGB:
              if (![8, 16].contains(header.bits)) {
                throw new ImageException('Unsuported bit depth: ${header.bits}.');
              }
              break;
            case INDEXED:
              if (![1, 2, 4, 8].contains(header.bits)) {
                throw new ImageException('Unsuported bit depth: ${header.bits}.');
              }
              break;
            case GRAYSCALE_ALPHA:
              if (![8, 16].contains(header.bits)) {
                throw new ImageException('Unsuported bit depth: ${header.bits}.');
              }
              break;
            case RGBA:
              if (![8, 16].contains(header.bits)) {
                throw new ImageException('Unsuported bit depth: ${header.bits}.');
              }
              break;
          }

          if (header.interlaceMethod != 0) {
            throw new ImageException('Unsupported interlace method: ${header.interlaceMethod}.');
          }

          int crc = input.readUint32();
          int computedCrc = _crc(section, hdr.buffer);
          if (crc != computedCrc) {
            throw new ImageException('Invalid $section checksum');
          }
          break;
        case 'PLTE':
          palette = input.readBytes(chunkSize);
          int crc = input.readUint32();
          int computedCrc = _crc(section, palette);
          if (crc != computedCrc) {
            throw new ImageException('Invalid $section checksum');
          }
          break;
        case 'tRNS':
          transparency = input.readBytes(chunkSize);
          int crc = input.readUint32();
          int computedCrc = _crc(section, transparency);
          if (crc != computedCrc) {
            throw new ImageException('Invalid $section checksum');
          }
          break;
        case 'IDAT':
          List<int> data = input.readBytes(chunkSize);
          imageData.addAll(data);
          int crc = input.readUint32();
          int computedCrc = _crc(section, data);
          if (crc != computedCrc) {
            throw new ImageException('Invalid $section checksum');
          }
          break;
        case 'IEND':
          // End of the image.
          if (header.colorType == GRAYSCALE_ALPHA ||
              header.colorType == RGBA || transparency != null) {
            format = Image.RGBA;
          } else {
            format = Image.RGB;
          }
          // CRC
          input.skip(4);
          break;
        case 'gAMA':
          if (chunkSize != 4) {
            throw new ImageException('Invalid gAMA chunk');
          }
          int gammaInt = input.readUint32();
          int crc = input.readUint32();
          // A gamma of 1.0 doesn't have any affect, so pretend we didn't get
          // a gamma in that case.
          if (gammaInt != 100000) {
            gamma = gammaInt / 100000.0;
          }
          break;
        default:
          if (header.bits == 16 && header.colorType == GRAYSCALE) {
            print('**** Unhandled Chunk: $section ${chunkSize}');
          }
          input.skip(chunkSize);
          // CRC
          input.skip(4);
          break;
      }

      if (section == 'IEND') {
        break;
      }


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

    // Set up a LUT to transform colors for gamma correction.
    List<int> colorLut = new List<int>(256);
    for (int i = 0; i < 256; ++i) {
      int c = i;
      if (gamma != null) {
        c = getGamma(c, gamma);
      }
      colorLut[i] = c;
    }

    int numChannels = (header.colorType == GRAYSCALE) ? 1 :
      (header.colorType == GRAYSCALE_ALPHA ||
      header.colorType == RGBA) ? 4 : 3;
    if (transparency != null) {
      numChannels++;
    }

    /**
     * Read the next pixel from the input stream.
     */
    void _readPixel(Arc.InputBuffer input, List<int> pixel) {
      switch (header.colorType) {
        case GRAYSCALE:
          switch (header.bits) {
            case 1:
            case 2:
            case 4:
              pixel[0] = _readBits(input, header.bits);
              break;
            case 8:
              pixel[0] = input.readByte();
              break;
            case 16:
              pixel[0] = input.readUint16();
              break;
          }
          return;
        case RGB:
          switch (header.bits) {
            case 1:
            case 2:
            case 4:
              pixel[0] = _readBits(input, header.bits);
              pixel[1] = _readBits(input, header.bits);
              pixel[2] = _readBits(input, header.bits);
              break;
            case 8:
              pixel[0] = input.readByte();
              pixel[1] = input.readByte();
              pixel[2] = input.readByte();
              break;
            case 16:
              pixel[0] = input.readUint16();
              pixel[1] = input.readUint16();
              pixel[2] = input.readUint16();
              break;
          }
          return;
        case INDEXED:
          switch (header.bits) {
            case 1:
            case 2:
            case 4:
              pixel[0] = _readBits(input, header.bits);
              break;
            case 8:
              pixel[0] = input.readByte();
              break;
          }
          return;
        case GRAYSCALE_ALPHA:
          switch (header.bits) {
            case 1:
            case 2:
            case 4:
              pixel[0] = _readBits(input, header.bits);
              pixel[1] = _readBits(input, header.bits);
              break;
            case 8:
              pixel[0] = input.readByte();
              pixel[1] = input.readByte();
              break;
            case 16:
              pixel[0] = input.readUint16();
              pixel[1] = input.readUint16();
              break;
          }
          return;
        case RGBA:
          switch (header.bits) {
            case 1:
            case 2:
            case 4:
              pixel[0] = _readBits(input, header.bits);
              pixel[1] = _readBits(input, header.bits);
              pixel[2] = _readBits(input, header.bits);
              pixel[3] = _readBits(input, header.bits);
              break;
            case 8:
              pixel[0] = input.readByte();
              pixel[1] = input.readByte();
              pixel[2] = input.readByte();
              pixel[3] = input.readByte();
              break;
            case 16:
              pixel[0] = input.readUint16();
              pixel[1] = input.readUint16();
              pixel[2] = input.readUint16();
              pixel[3] = input.readUint16();
              break;
          }
          return;
      }

      throw new ImageException('Invalid color type: ${header.colorType}.');
    }

    /**
     * Get the color with the list of components.
     */
    int _getColor(List<int> raw) {
      switch (header.colorType) {
        case GRAYSCALE:
          int g;
          switch (header.bits) {
            case 1:
              g = _convert1to8(raw[0]);
              break;
            case 2:
              g = _convert2to8(raw[0]);
              break;
            case 4:
              g = _convert4to8(raw[0]);
              break;
            case 8:
              g = raw[0];
              break;
            case 16:
              g = _convert16to8(raw[0]);
              break;
          }

          g = colorLut[g];

          if (transparency != null) {
            int a = ((transparency[0] & 0xff) << 24) | (transparency[1] & 0xff);
            if (raw[0] == a) {
              return getColor(g, g, g, 0);
            }
          }

          return getColor(g, g, g, 255);
        case RGB:
          int r, g, b;
          switch (header.bits) {
            case 1:
              r = _convert1to8(raw[0]);
              g = _convert1to8(raw[1]);
              b = _convert1to8(raw[2]);
              break;
            case 2:
              r = _convert2to8(raw[0]);
              g = _convert2to8(raw[1]);
              b = _convert2to8(raw[2]);
              break;
            case 4:
              r = _convert4to8(raw[0]);
              g = _convert4to8(raw[1]);
              b = _convert4to8(raw[2]);
              break;
            case 8:
              r = raw[0];
              g = raw[1];
              b = raw[2];
              break;
            case 16:
              r = _convert16to8(raw[0]);
              g = _convert16to8(raw[1]);
              b = _convert16to8(raw[2]);
              break;
          }

          r = colorLut[r];
          g = colorLut[g];
          b = colorLut[b];

          if (transparency != null) {
            int tr = ((transparency[0] & 0xff) << 8) | (transparency[1] & 0xff);
            int tg = ((transparency[2] & 0xff) << 8) | (transparency[3] & 0xff);
            int tb = ((transparency[4] & 0xff) << 8) | (transparency[5] & 0xff);
            if (raw[0] == tr && raw[1] == tg && raw[2] == tb) {
              return getColor(r, g, b, 0);
            }
          }

          return getColor(r, g, b, 255);
        case INDEXED:
          int p = raw[0] * 3;

          int a = transparency != null &&
                  raw[0] < transparency.length ? transparency[raw[0]] : 255;

          if (p >= palette.length) {
            return getColor(255, 255, 255, a);
          }

          int r = colorLut[palette[p]];
          int g = colorLut[palette[p + 1]];
          int b = colorLut[palette[p + 2]];

          return getColor(r, g, b, a);
        case GRAYSCALE_ALPHA:
          int g, a;
          switch (header.bits) {
            case 1:
              g = _convert1to8(raw[0]);
              a = _convert1to8(raw[1]);
              break;
            case 2:
              g = _convert2to8(raw[0]);
              a = _convert2to8(raw[1]);
              break;
            case 4:
              g = _convert4to8(raw[0]);
              a = _convert4to8(raw[1]);
              break;
            case 8:
              g = raw[0];
              a = raw[1];
              break;
            case 16:
              g = _convert16to8(raw[0]);
              a = _convert16to8(raw[1]);
              break;
          }

          g = colorLut[g];
          a = colorLut[a];

          return getColor(g, g, g, a);
        case RGBA:
          int r, g, b, a;
          switch (header.bits) {
            case 1:
              r = _convert1to8(raw[0]);
              g = _convert1to8(raw[1]);
              b = _convert1to8(raw[2]);
              a = _convert1to8(raw[3]);
              break;
            case 2:
              r = _convert2to8(raw[0]);
              g = _convert2to8(raw[1]);
              b = _convert2to8(raw[2]);
              a = _convert2to8(raw[3]);
              break;
            case 4:
              r = _convert4to8(raw[0]);
              g = _convert4to8(raw[1]);
              b = _convert4to8(raw[2]);
              a = _convert4to8(raw[3]);
              break;
            case 8:
              r = raw[0];
              g = raw[1];
              b = raw[2];
              a = raw[3];
              break;
            case 16:
              r = _convert16to8(raw[0]);
              g = _convert16to8(raw[1]);
              b = _convert16to8(raw[2]);
              a = _convert16to8(raw[3]);
              break;
          }

          r = colorLut[r];
          g = colorLut[g];
          b = colorLut[b];
          a = colorLut[a];

          return getColor(r, g, b, a);
      }

      throw new ImageException('Invalid color type: ${header.colorType}.');
    }

    int bpp = (header.colorType == GRAYSCALE_ALPHA) ? 2 :
              (header.colorType == RGB) ? 3 :
              (header.colorType == RGBA) ? 4 : 1;

    final int lineSize = ((header.width * header.bits + 7)) ~/ 8 * bpp;

    final List<int> line = new List<int>.filled(lineSize, 0);
    final List<List<int>> inData = [line, line];

    // Before the image is compressed, it was filtered to improve compression.
    // Unfilter the image now.
    int pi = 0;
    for (int row = 0, id = 0; row < header.height; ++row, id = 1 - id) {
      int filterType = input.readByte();
      inData[id] = input.readBytes(lineSize);

      switch (filterType) {
        case FILTER_NONE:
          break;
        case FILTER_SUB:
          for (int i = bpp; i < lineSize; ++i) {
            inData[id][i] = (inData[id][i] + inData[id][i - bpp]) & 0xff;
          }
          break;
        case FILTER_UP:
          if (row > 0) {
            for (int i = 0; i < lineSize; ++i) {
              inData[id][i] = (inData[id][i] + inData[1 - id][i]) & 0xff;
            }
          }
          break;
        case FILTER_AVERAGE:
          for (int i = 0; i < lineSize; ++i) {
            int a = (i < bpp) ? 0 : inData[id][i - bpp];
            int b = (row == 0) ? 0 : inData[1 - id][i];
            inData[id][i] = (inData[id][i] + ((a + b) >> 1)) & 0xff;
          }
          break;
        case FILTER_PAETH:
          for (int i = 0; i < lineSize; ++i) {
            int a = (i < bpp) ? 0 : inData[id][i - bpp];
            int b = (row == 0) ? 0 : inData[1 - id][i];
            int c = (i < bpp || row == 0) ? 0 : inData[1 - id][i - bpp];

            int p = a + b - c;

            int pa = (p - a).abs();
            int pb = (p - b).abs();
            int pc = (p - c).abs();

            int paeth = 0;
            if (pa <= pb && pa <= pc) {
              paeth = a;
            } else if (pb <= pc) {
              paeth = b;
            } else {
              paeth = c;
            }

            inData[id][i] = (inData[id][i] + paeth) & 0xff;
          }
          break;
        default:
          throw new ImageException('Invalid filter value: ${filterType}');
      }

      _resetBits();

      Arc.InputBuffer rowInput = new Arc.InputBuffer(inData[id]);

      final List<int> pixel = [0, 0, 0, 0];

      for (int i = 0; i < header.width; i++) {
        _readPixel(rowInput, pixel);
        image[pi++] = _getColor(pixel);
      }
    }

    return image;
  }

  int _convert16to8(int c) {
    return c >> 8;
  }

  int _convert1to8(int c) {
    return (c == 0) ? 0 : 255;
  }

  int _convert2to8(int c) {
    return c * 85;
  }

  int _convert4to8(int c) {
    return c << 4;
  }

  /**
   * Return the CRC of the bytes
   */
  int _crc(String type, List<int> bytes) {
    int crc = Arc.getCrc32(type.codeUnits);
    return Arc.getCrc32(bytes, crc);
  }

  int _bitBuffer = 0;
  int _bitBufferLen = 0;

  void _resetBits() {
    _bitBuffer = 0;
    _bitBufferLen = 0;
  }

  /**
   * Read a number of bits from the input stream.
   */
  int _readBits(Arc.InputBuffer input, int numBits) {
    if (numBits == 0) {
      return 0;
    }

    // not enough buffer
    while (_bitBufferLen < numBits) {
      if (input.isEOF) {
        throw new ImageException('Invalid PNG data.');
      }

      // input byte
      int octet = input.readByte();

      // concat octet
      _bitBuffer = octet << _bitBufferLen;
      _bitBufferLen += 8;
    }

    // output byte
    int mask = (numBits == 1) ? 1 :
               (numBits == 2) ? 3 :
               (numBits == 4) ? 0xf :
               (numBits == 8) ? 0xff :
               (numBits == 16) ? 0xffff : 0;

    int octet = (_bitBuffer >> (_bitBufferLen - numBits)) & mask;

    //_bitBuffer >>= numBits;
    _bitBufferLen -= numBits;

    return octet;
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
