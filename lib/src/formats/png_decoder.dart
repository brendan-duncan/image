import 'dart:math' as Math;

import 'package:archive/archive.dart';

import '../animation.dart';
import '../color.dart';
import '../image.dart';
import '../image_exception.dart';
import '../transform/copy_into.dart';
import '../util/input_buffer.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'png/png_frame.dart';
import 'png/png_info.dart';

/**
 * Decode a PNG encoded image.
 */
class PngDecoder extends Decoder {
  InternalPngInfo _info;

  /**
   * Is the given file a valid PNG image?
   */
  bool isValidFile(List<int> data) {
    InputBuffer input = new InputBuffer(data, bigEndian: true);
    InputBuffer pngHeader = input.readBytes(8);
    const PNG_HEADER = const [137, 80, 78, 71, 13, 10, 26, 10];
    for (int i = 0; i < 8; ++i) {
      if (pngHeader[i] != PNG_HEADER[i]) {
        return false;
      }
    }

    return true;
  }

  PngInfo get info => _info;

  /**
   * Start decoding the data as an animation sequence, but don't actually
   * process the frames until they are requested with decodeFrame.
   */
  DecodeInfo startDecode(List<int> data) {
    _input = new InputBuffer(data, bigEndian: true);

    InputBuffer pngHeader = _input.readBytes(8);
    const PNG_HEADER = const [137, 80, 78, 71, 13, 10, 26, 10];
    for (int i = 0; i < 8; ++i) {
      if (pngHeader[i] != PNG_HEADER[i]) {
        return null;
      }
    }

    while (true) {
      int inputPos = _input.position;
      int chunkSize = _input.readUint32();
      String chunkType = _input.readString(4);
      switch (chunkType) {
        case 'IHDR':
          InputBuffer hdr = new InputBuffer.from(_input.readBytes(chunkSize));
          List<int> hdrBytes = hdr.toUint8List();
          _info = new InternalPngInfo();
          _info.width = hdr.readUint32();
          _info.height = hdr.readUint32();
          _info.bits = hdr.readByte();
          _info.colorType = hdr.readByte();
          _info.compressionMethod = hdr.readByte();
          _info.filterMethod = hdr.readByte();
          _info.interlaceMethod = hdr.readByte();

          // Validate some of the info in the header to make sure we support
          // the proposed image data.
          if (![GRAYSCALE, RGB, INDEXED,
                GRAYSCALE_ALPHA, RGBA].contains(_info.colorType)) {
            return null;
          }

          if (_info.filterMethod != 0) {
            return null;
          }

          switch (_info.colorType) {
            case GRAYSCALE:
              if (![1, 2, 4, 8, 16].contains(_info.bits)) {
                return null;
              }
              break;
            case RGB:
              if (![8, 16].contains(_info.bits)) {
                return null;
              }
              break;
            case INDEXED:
              if (![1, 2, 4, 8].contains(_info.bits)) {
                return null;
              }
              break;
            case GRAYSCALE_ALPHA:
              if (![8, 16].contains(_info.bits)) {
                return null;
              }
              break;
            case RGBA:
              if (![8, 16].contains(_info.bits)) {
                return null;
              }
              break;
          }

          int crc = _input.readUint32();
          int computedCrc = _crc(chunkType, hdrBytes);
          if (crc != computedCrc) {
            throw new ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'PLTE':
          _info.palette = _input.readBytes(chunkSize).toUint8List();
          int crc = _input.readUint32();
          int computedCrc = _crc(chunkType, _info.palette);
          if (crc != computedCrc) {
            throw new ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'tRNS':
          _info.transparency = _input.readBytes(chunkSize).toUint8List();
          int crc = _input.readUint32();
          int computedCrc = _crc(chunkType, _info.transparency);
          if (crc != computedCrc) {
            throw new ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'IEND':
          // End of the image.
          _input.skip(4); // CRC
          break;
        case 'gAMA':
          if (chunkSize != 4) {
            throw new ImageException('Invalid gAMA chunk');
          }
          int gammaInt = _input.readUint32();
          _input.skip(4); // CRC
          // A gamma of 1.0 doesn't have any affect, so pretend we didn't get
          // a gamma in that case.
          if (gammaInt != 100000) {
            _info.gamma = gammaInt / 100000.0;
          }
          break;
        case 'IDAT':
          _info.idat.add(inputPos);
          _input.skip(chunkSize);
          _input.skip(4); // CRC
          break;
        case 'acTL': // Animation control chunk
          _info.numFrames = _input.readUint32();
          _info.repeat = _input.readUint32();
          _input.skip(4); // CRC
          break;
        case 'fcTL': // Frame control chunk
          PngFrame frame = new InternalPngFrame();
          _info.frames.add(frame);
          frame.sequenceNumber = _input.readUint32();
          frame.width = _input.readUint32();
          frame.height = _input.readUint32();
          frame.xOffset = _input.readUint32();
          frame.yOffset = _input.readUint32();
          frame.delayNum = _input.readUint16();
          frame.delayDen = _input.readUint16();
          frame.dispose = _input.readByte();
          frame.blend = _input.readByte();
          _input.skip(4); // CRC
          break;
        case 'fdAT':
          int sequenceNumber = _input.readUint32();
          InternalPngFrame frame = _info.frames.last;
          frame.fdat.add(inputPos);
          _input.skip(chunkSize - 4);
          _input.skip(4); // CRC
          break;
        case 'bKGD':
          if (_info.colorType == 3) {
            int paletteIndex = _input.readByte();
            chunkSize--;
            int p3 = paletteIndex * 3;
            int r = _info.palette[p3];
            int g = _info.palette[p3 + 1];
            int b = _info.palette[p3 + 2];
            _info.backgroundColor = Color.fromRgb(r, g, b);
          } else if (_info.colorType == 0 || _info.colorType == 4) {
            int gray = _input.readUint16();
            chunkSize -= 2;
          } else if (_info.colorType == 2 || _info.colorType ==6) {
            int r = _input.readUint16();
            int g = _input.readUint16();
            int b = _input.readUint16();
            chunkSize -= 24;
          }
          if (chunkSize > 0) {
            _input.skip(chunkSize);
          }
          _input.skip(4); // CRC
          break;
        default:
          _input.skip(chunkSize);
          _input.skip(4); // CRC
          break;
      }

      if (chunkType == 'IEND') {
        break;
      }

      if (_input.isEOS) {
        return null;
      }
    }

    return _info;
  }

  /**
   * The number of frames that can be decoded.
   */
  int numFrames() => _info != null ? _info.numFrames : 0;

  /**
   * Decode the frame (assuming [startDecode] has already been called).
   */
  Image decodeFrame(int frame) {
    if (_info == null) {
      return null;
    }

    List<int> imageData = [];

    int width = _info.width;
    int height = _info.height;

    if (!_info.isAnimated || frame == 0) {
      for (int i = 0, len = _info.idat.length; i < len; ++i) {
        _input.offset = _info.idat[i];
        int chunkSize = _input.readUint32();
        String chunkType = _input.readString(4);
        List<int> data = _input.readBytes(chunkSize).toUint8List();
        imageData.addAll(data);
        int crc = _input.readUint32();
        int computedCrc = _crc(chunkType, data);
        if (crc != computedCrc) {
          throw new ImageException('Invalid $chunkType checksum');
        }
      }
    } else {
      if (frame < 0 || frame >= _info.frames.length) {
        throw new ImageException('Invalid Frame Number: $frame');
      }

      InternalPngFrame f = _info.frames[frame];
      width = f.width;
      height = f.height;
      for (int i = 0; i < f.fdat.length; ++i) {
        _input.offset = f.fdat[i];
        int chunkSize = _input.readUint32();
        String chunkType = _input.readString(4);
        _input.skip(4); // sequence number
        List<int> data = _input.readBytes(chunkSize).toUint8List();
        imageData.addAll(data);
      }

      _frame = frame;
      _numFrames = _info.numFrames;
    }

    int format;
    if (_info.colorType == GRAYSCALE_ALPHA ||
        _info.colorType == RGBA || _info.transparency != null) {
      format = Image.RGBA;
    } else {
      format = Image.RGB;
    }

    Image image = new Image(width, height, format);

    List<int> uncompressed = new ZLibDecoder().decodeBytes(imageData);

    // input is the decompressed data.
    InputBuffer input = new InputBuffer(uncompressed, bigEndian: true);
    _resetBits();

    // Set up a LUT to transform colors for gamma correction.
    if (_info.colorLut == null) {
      _info.colorLut = new List<int>(256);
      for (int i = 0; i < 256; ++i) {
        int c = i;
        /*if (info.gamma != null) {
          c = (Math.pow((c / 255.0), info.gamma) * 255.0).toInt();
        }*/
        _info.colorLut[i] = c;
      }

      // Apply the LUT to the palette, if necessary.
      if (_info.palette != null && _info.gamma != null) {
        for (int i = 0; i < _info.palette.length; ++i) {
          _info.palette[i] = _info.colorLut[_info.palette[i]];
        }
      }
    }

    int origW = _info.width;
    int origH = _info.height;
    _info.width = width;
    _info.height = height;

    int w = width;
    int h = height;
    _progressY = 0;
    if (_info.interlaceMethod != 0) {
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

    _info.width = origW;
    _info.height = origH;

    return image;
  }

  Image decodeImage(List<int> data, {int frame: 0}) {
    if (startDecode(data) == null) {
      return null;
    }
    return decodeFrame(frame);
  }

  Animation decodeAnimation(List<int> data) {
    if (startDecode(data) == null) {
      return null;
    }

    Animation anim = new Animation();
    anim.width = _info.width;
    anim.height = _info.height;

    if (!_info.isAnimated) {
      Image image = decodeFrame(0);
      anim.addFrame(image);
      return anim;
    }

    int dispose = PngFrame.APNG_DISPOSE_OP_BACKGROUND;
    Image lastImage = new Image(_info.width, _info.height);
    for (int i = 0; i < _info.numFrames; ++i) {
      //_frame = i;
      if (lastImage == null) {
        lastImage = new Image(_info.width, _info.height);
      } else {
        lastImage = new Image.from(lastImage);
      }

      PngFrame frame = _info.frames[i];
      Image image = decodeFrame(i);
      if (image == null) {
        continue;
      }

      if (lastImage != null) {
        if (dispose == PngFrame.APNG_DISPOSE_OP_BACKGROUND ||
            dispose == PngFrame.APNG_DISPOSE_OP_PREVIOUS) {
          lastImage.fill(_info.backgroundColor);
        }
        copyInto(lastImage, image, dstX: frame.xOffset, dstY: frame.yOffset,
                 blend: frame.blend == PngFrame.APNG_BLEND_OP_OVER);
      } else {
        lastImage = image;
      }

      anim.addFrame(lastImage);

      dispose = frame.dispose;
    }

    return anim;
  }

  /**
   * Process a pass of an interlaced image.
   */
  void _processPass(InputBuffer input, Image image,
                    int xOffset, int yOffset, int xStep, int yStep,
                    int passWidth, int passHeight) {
    final int channels = (_info.colorType == GRAYSCALE_ALPHA) ? 2 :
      (_info.colorType == RGB) ? 3 :
        (_info.colorType == RGBA) ? 4 : 1;

    final int pixelDepth = channels * _info.bits;
    final int bpp = (pixelDepth + 7) >> 3;
    final int rowBytes = (pixelDepth * passWidth + 7) >> 3;

    final List<int> line = new List<int>.filled(rowBytes, 0);
    final List<List<int>> inData = [line, line];

    final List<int> pixel = [0, 0, 0, 0];

    int pi = 0;
    for (int srcY = 0, dstY = yOffset, ri = 0;
         srcY < passHeight; ++srcY, dstY += yStep, ri = 1 - ri, _progressY++) {
      int filterType = input.readByte();
      inData[ri] = input.readBytes(rowBytes).toUint8List();

      final List<int> row = inData[ri];
      final List<int> prevRow = inData[1 - ri];

      // Before the image is compressed, it was filtered to improve compression.
      // Reverse the filter now.
      _unfilter(filterType, bpp, row, prevRow);

      // Scanlines are always on byte boundaries, so for bit depths < 8,
      // reset the bit stream counter.
      _resetBits();

      InputBuffer rowInput = new InputBuffer(row, bigEndian: true);

      final int blockHeight = xStep;
      final int blockWidth = xStep - xOffset;

      int yMax = Math.min(dstY + blockHeight, _info.height);

      for (int srcX = 0, dstX = xOffset; srcX < passWidth;
           ++srcX, dstX += xStep) {
        _readPixel(rowInput, pixel);
        int c = _getColor(pixel);
        image.setPixel(dstX, dstY, c);

        if (blockWidth > 1 || blockHeight > 1) {
          int xMax = Math.min(dstX + blockWidth, _info.width);
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

  void _process(InputBuffer input, Image image) {
    final int channels = (_info.colorType == GRAYSCALE_ALPHA) ? 2 :
                         (_info.colorType == RGB) ? 3 :
                         (_info.colorType == RGBA) ? 4 : 1;

    final int pixelDepth = channels * _info.bits;

    final int w = _info.width;
    final int h = _info.height;

    final int rowBytes = (((w * pixelDepth + 7)) >> 3);
    final int bpp = (pixelDepth + 7) >> 3;

    final List<int> line = new List<int>.filled(rowBytes, 0);
    final List<List<int>> inData = [line, line];

    final List<int> pixel = [0, 0, 0, 0];

    for (int y = 0, pi = 0, ri = 0; y < h; ++y, ri = 1 - ri) {
      int filterType = input.readByte();
      inData[ri] = input.readBytes(rowBytes).toUint8List();

      List<int> row = inData[ri];
      List<int> prevRow = inData[1 - ri];

      // Before the image is compressed, it was filtered to improve compression.
      // Reverse the filter now.
      _unfilter(filterType, bpp, row, prevRow);

      // Scanlines are always on byte boundaries, so for bit depths < 8,
      // reset the bit stream counter.
      _resetBits();

      InputBuffer rowInput = new InputBuffer(inData[ri], bigEndian: true);

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
    int crc = getCrc32(type.codeUnits);
    return getCrc32(bytes, crc);
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
  int _readBits(InputBuffer input, int numBits) {
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
  void _readPixel(InputBuffer input, List<int> pixel) {
    switch (_info.colorType) {
      case GRAYSCALE:
        pixel[0] = _readBits(input, _info.bits);
        return;
      case RGB:
        pixel[0] = _readBits(input, _info.bits);
        pixel[1] = _readBits(input, _info.bits);
        pixel[2] = _readBits(input, _info.bits);
        return;
      case INDEXED:
        pixel[0] = _readBits(input, _info.bits);
        return;
      case GRAYSCALE_ALPHA:
        pixel[0] = _readBits(input, _info.bits);
        pixel[1] = _readBits(input, _info.bits);
        return;
      case RGBA:
        pixel[0] = _readBits(input, _info.bits);
        pixel[1] = _readBits(input, _info.bits);
        pixel[2] = _readBits(input, _info.bits);
        pixel[3] = _readBits(input, _info.bits);
        return;
    }

    throw new ImageException('Invalid color type: ${_info.colorType}.');
  }

  /**
   * Get the color with the list of components.
   */
  int _getColor(List<int> raw) {
    switch (_info.colorType) {
      case GRAYSCALE:
        int g;
        switch (_info.bits) {
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

        g = _info.colorLut[g];

        if (_info.transparency != null) {
          int a = ((_info.transparency[0] & 0xff) << 24) |
              (_info.transparency[1] & 0xff);
          if (raw[0] == a) {
            return getColor(g, g, g, 0);
          }
        }

        return getColor(g, g, g, 255);
      case RGB:
        int r, g, b;
        switch (_info.bits) {
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

        r = _info.colorLut[r];
        g = _info.colorLut[g];
        b = _info.colorLut[b];

        if (_info.transparency != null) {
          int tr = ((_info.transparency[0] & 0xff) << 8) |
              (_info.transparency[1] & 0xff);
          int tg = ((_info.transparency[2] & 0xff) << 8) |
              (_info.transparency[3] & 0xff);
          int tb = ((_info.transparency[4] & 0xff) << 8) |
              (_info.transparency[5] & 0xff);
          if (raw[0] == tr && raw[1] == tg && raw[2] == tb) {
            return getColor(r, g, b, 0);
          }
        }

        return getColor(r, g, b, 255);
      case INDEXED:
        int p = raw[0] * 3;

        int a = _info.transparency != null &&
            raw[0] < _info.transparency.length ? _info.transparency[raw[0]] : 255;

        if (p >= _info.palette.length) {
          return getColor(255, 255, 255, a);
        }

        int r = _info.palette[p];
        int g = _info.palette[p + 1];
        int b = _info.palette[p + 2];

        return getColor(r, g, b, a);
      case GRAYSCALE_ALPHA:
        int g, a;
        switch (_info.bits) {
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

        g = _info.colorLut[g];

        return getColor(g, g, g, a);
      case RGBA:
        int r, g, b, a;
        switch (_info.bits) {
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

        r = _info.colorLut[r];
        g = _info.colorLut[g];
        b = _info.colorLut[b];

        return getColor(r, g, b, a);
    }

    throw new ImageException('Invalid color type: ${_info.colorType}.');
  }

  InputBuffer _input;
  int _progressY;
  int _frame = 0;
  int _numFrames = 1;

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
