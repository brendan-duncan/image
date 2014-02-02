part of image;

/**
 * Decode a PNG encoded image.
 */
class PngDecoder extends Decoder {
  _PngHeader header;
  List<int> palette;
  List<int> transparency;
  List<int> colorLut;
  double gamma;

  /**
   * Is the given file a valid PNG image?
   */
  bool isValidFile(List<int> data) {
    Arc.InputStream input = new Arc.InputStream(data,
        byteOrder: Arc.BIG_ENDIAN);
    List<int> pngHeader = input.readBytes(8);
    const PNG_HEADER = const [137, 80, 78, 71, 13, 10, 26, 10];
    for (int i = 0; i < 8; ++i) {
      if (pngHeader[i] != PNG_HEADER[i]) {
        return false;
      }
    }

    return true;
  }

  Image decodeImage(List<int> data, {int frame: 0}) {
    Arc.InputStream input = new Arc.InputStream(data,
        byteOrder: Arc.BIG_ENDIAN);

    List<int> imageData = [];

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
      String chunkType = new String.fromCharCodes(input.readBytes(4));
      switch (chunkType) {
        case 'IHDR':
          Arc.InputStream hdr = new Arc.InputStream(input.readBytes(chunkSize),
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
          if (![GRAYSCALE, RGB, INDEXED,
                GRAYSCALE_ALPHA, RGBA].contains(header.colorType)) {
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

          int crc = input.readUint32();
          int computedCrc = _crc(chunkType, hdr.buffer);
          if (crc != computedCrc) {
            throw new ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'PLTE':
          palette = input.readBytes(chunkSize);
          int crc = input.readUint32();
          int computedCrc = _crc(chunkType, palette);
          if (crc != computedCrc) {
            throw new ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'tRNS':
          transparency = input.readBytes(chunkSize);
          int crc = input.readUint32();
          int computedCrc = _crc(chunkType, transparency);
          if (crc != computedCrc) {
            throw new ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'IDAT':
          List<int> data = input.readBytes(chunkSize);
          imageData.addAll(data);
          int crc = input.readUint32();
          int computedCrc = _crc(chunkType, data);
          if (crc != computedCrc) {
            throw new ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'IEND':
          // End of the image.
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
          } /*else {
            // TODO It seems viewers use a gamma of 0.75 when the gamma is
            // 10000, is it correct to do this?
            gamma = 0.75;
          }*/
          break;
        default:
          //print('Unhandled CHUNK $chunkType');
          input.skip(chunkSize);
          // CRC
          input.skip(4);
          break;
      }

      if (chunkType == 'IEND') {
        break;
      }

      if (input.isEOS) {
        throw new ImageException('Incomplete or corrupt PNG file');
      }
    }

    if (header == null) {
      throw new ImageException('Incomplete or corrupt PNG file');
    }

    int format;
    if (header.colorType == GRAYSCALE_ALPHA ||
        header.colorType == RGBA || transparency != null) {
      format = Image.RGBA;
    } else {
      format = Image.RGB;
    }

    Image image = new Image(header.width, header.height, format);

    List<int> uncompressed = new Arc.ZLibDecoder().decodeBytes(imageData);

    // input is the decompressed data.
    input = new Arc.InputStream(uncompressed, byteOrder: Arc.BIG_ENDIAN);

    // Set up a LUT to transform colors for gamma correction.
    colorLut = new List<int>(256);
    for (int i = 0; i < 256; ++i) {
      int c = i;
      if (gamma != null) {
        c = getGamma(c, gamma);
      }
      colorLut[i] = c;
    }

    // Apply the LUT to the palette, if necessary.
    if (palette != null && gamma != null) {
      for (int i = 0; i < palette.length; ++i) {
        palette[i] = colorLut[palette[i]];
      }
    }

    int w = header.width;
    int h = header.height;
    if (header.interlaceMethod != 0) {
      _processPass(input, image, 0, 0, 8, 8, (w + 7) >> 3, (h + 7) >> 3);
      _processPass(input, image, 4, 0, 8, 8, (w + 3) >> 3, (h + 7) >> 3);
      _processPass(input, image, 0, 4, 4, 8, (w + 3) >> 2, (h + 3) >> 3);
      _processPass(input, image, 2, 0, 4, 4, (w + 1) >> 2, (h + 3) >> 2);
      _processPass(input, image, 0, 2, 2, 4, (w + 1) >> 1, (h + 1) >> 2);
      _processPass(input, image, 1, 0, 2, 2, w >> 1, (h + 1) >> 1);
      _processPass(input, image, 0, 1, 1, 2, w, h >> 1);
    } else {
      _process(input, image);
    }

    return image;
  }

  Animation decodeAnimation(List<int> data) {
    Image image = decodeImage(data);
    if (image == null) {
      return null;
    }

    Animation anim = new Animation();
    anim.addFrame(image);

    return anim;
  }

  /**
   * Process a pass of an interlaced image.
   */
  void _processPass(Arc.InputStream input, Image image,
                    int xOffset, int yOffset, int xStep, int yStep,
                    int passWidth, int passHeight) {
    final int channels = (header.colorType == GRAYSCALE_ALPHA) ? 2 :
      (header.colorType == RGB) ? 3 :
        (header.colorType == RGBA) ? 4 : 1;

    final int pixelDepth = channels * header.bits;
    final int bpp = (pixelDepth + 7) >> 3;
    final int rowBytes = (pixelDepth * passWidth + 7) >> 3;

    final List<int> line = new List<int>.filled(rowBytes, 0);
    final List<List<int>> inData = [line, line];

    final List<int> pixel = [0, 0, 0, 0];

    int pi = 0;
    for (int srcY = 0, dstY = yOffset, ri = 0;
         srcY < passHeight; ++srcY, dstY += yStep, ri = 1 - ri) {
      int filterType = input.readByte();
      inData[ri] = input.readBytes(rowBytes);

      final List<int> row = inData[ri];
      final List<int> prevRow = inData[1 - ri];

      // Before the image is compressed, it was filtered to improve compression.
      // Reverse the filter now.
      _unfilter(filterType, bpp, row, prevRow);

      // Scanlines are always on byte boundaries, so for bit depths < 8,
      // reset the bit stream counter.
      _resetBits();

      Arc.InputStream rowInput = new Arc.InputStream(row,
          byteOrder: Arc.BIG_ENDIAN);

      final int blockHeight = xStep;
      final int blockWidth = xStep - xOffset;

      int yMax = Math.min(dstY + blockHeight, header.height);

      for (int srcX = 0, dstX = xOffset; srcX < passWidth;
           ++srcX, dstX += xStep) {
        _readPixel(rowInput, pixel);
        int c = _getColor(pixel);
        image.setPixel(dstX, dstY, c);

        if (blockWidth > 1 || blockHeight > 1) {
          int xMax = Math.min(dstX + blockWidth, header.width);
          int xPixels = xMax - dstX;
          for (int i = 0; i < blockHeight; ++i) {
            for (int j = 0; j < blockWidth; ++j) {
              image.setPixel(dstX + j, dstY + j, c);
            }
          }
        }
      }
    }
  }

  void _process(Arc.InputStream input, Image image) {
    final int channels = (header.colorType == GRAYSCALE_ALPHA) ? 2 :
      (header.colorType == RGB) ? 3 :
        (header.colorType == RGBA) ? 4 : 1;

    final int pixelDepth = channels * header.bits;

    final int w = header.width;
    final int h = header.height;

    final int rowBytes = (((w * pixelDepth + 7)) >> 3);
    final int bpp = (pixelDepth + 7) >> 3;

    final List<int> line = new List<int>.filled(rowBytes, 0);
    final List<List<int>> inData = [line, line];

    final List<int> pixel = [0, 0, 0, 0];

    for (int y = 0, pi = 0, ri = 0; y < h; ++y, ri = 1 - ri) {
      int filterType = input.readByte();
      inData[ri] = input.readBytes(rowBytes);

      List<int> row = inData[ri];
      List<int> prevRow = inData[1 - ri];

      // Before the image is compressed, it was filtered to improve compression.
      // Reverse the filter now.
      _unfilter(filterType, bpp, row, prevRow);

      // Scanlines are always on byte boundaries, so for bit depths < 8,
      // reset the bit stream counter.
      _resetBits();

      Arc.InputStream rowInput = new Arc.InputStream(inData[ri],
                                                     byteOrder: Arc.BIG_ENDIAN);

      for (int x = 0; x < w; ++x) {
        _readPixel(rowInput, pixel);
        image[pi++] = _getColor(pixel);
      }
    }
  }

  void _unfilter(int filterType, int bpp, List<int> row, List<int> prevRow) {
    final int rowBytes = row.length;

    switch (filterType) {
      case FILTER_NONE:
        break;
      case FILTER_SUB:
        for (int x = bpp; x < rowBytes; ++x) {
          row[x] = (row[x] + row[x - bpp]) & 0xff;
        }
        break;
      case FILTER_UP:
        for (int x = 0; x < rowBytes; ++x) {
          row[x] = (row[x] + prevRow[x]) & 0xff;
        }
        break;
      case FILTER_AVERAGE:
        for (int x = 0; x < rowBytes; ++x) {
          int a = x < bpp ? 0 : row[x - bpp];
          int b = prevRow[x];
          row[x] = (row[x] + ((a + b) >> 1)) & 0xff;
        }
        break;
      case FILTER_PAETH:
        for (int x = 0; x < rowBytes; ++x) {
          int a = x < bpp ? 0 : row[x - bpp];
          int b = prevRow[x];
          int c = x < bpp ? 0 : prevRow[x - bpp];

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

          row[x] = (row[x] + paeth) & 0xff;
        }
        break;
      default:
        throw new ImageException('Invalid filter value: ${filterType}');
    }
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
  int _readBits(Arc.InputStream input, int numBits) {
    if (numBits == 0) {
      return 0;
    }

    if (numBits == 8) {
      return input.readByte();
    }

    if (numBits == 16) {
      return input.readUint16();
    }

    // not enough buffer
    while (_bitBufferLen < numBits) {
      if (input.isEOS) {
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

    _bitBufferLen -= numBits;

    return octet;
  }

  /**
   * Read the next pixel from the input stream.
   */
  void _readPixel(Arc.InputStream input, List<int> pixel) {
    switch (header.colorType) {
      case GRAYSCALE:
        pixel[0] = _readBits(input, header.bits);
        return;
      case RGB:
        pixel[0] = _readBits(input, header.bits);
        pixel[1] = _readBits(input, header.bits);
        pixel[2] = _readBits(input, header.bits);
        return;
      case INDEXED:
        pixel[0] = _readBits(input, header.bits);
        return;
      case GRAYSCALE_ALPHA:
        pixel[0] = _readBits(input, header.bits);
        pixel[1] = _readBits(input, header.bits);
        return;
      case RGBA:
        pixel[0] = _readBits(input, header.bits);
        pixel[1] = _readBits(input, header.bits);
        pixel[2] = _readBits(input, header.bits);
        pixel[3] = _readBits(input, header.bits);
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
