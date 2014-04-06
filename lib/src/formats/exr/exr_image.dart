part of image;


class ExrImage extends DecodeInfo {
  /// An EXR image has one or more parts, each of which contains a framebuffer.
  List<ExrPart> parts = [];

  ExrImage(List<int> bytes) {
    InputBuffer input = new InputBuffer(bytes);
    int magic = input.readUint32();
    if (magic != MAGIC) {
      throw new ImageException('File is not an OpenEXR image file.');
    }

    version = input.readByte();
    if (version != EXR_VERSION) {
      throw new ImageException('Cannot read version $version image files.');
    }

    flags = input.readUint24();
    if (!_supportsFlags(flags)) {
      throw new ImageException('The file format version number\'s flag field '
                               'contains unrecognized flags.');
    }

    if (!_isMultiPart()) {
      ExrPart part = new ExrPart(_isTiled(), input);
      if (part.isValid) {
        parts.add(part);
      }
    } else {
      while (true) {
        ExrPart part = new ExrPart(_isTiled(), input);
        if (!part.isValid) {
          break;
        }
        parts.add(part);
      }
    }

    if (parts.isEmpty) {
      throw new ImageException('Error reading image header');
    }

    for (ExrPart part in parts) {
      part._readOffsets(input);
    }

    _readImage(input);
  }

  int get numFrames => 1;

  /**
   * Parse just enough of the file to identify that it's an EXR image.
   */
  static bool isValidFile(List<int> bytes) {
    InputBuffer input = new InputBuffer(bytes);

    int magic = input.readUint32();
    if (magic != MAGIC) {
      return false;
    }

    int version = input.readByte();
    if (version != EXR_VERSION) {
      return false;
    }

    int flags = input.readUint24();
    if (!_supportsFlags(flags)) {
      return false;
    }

    return true;
  }

  int numParts() => parts.length;

  ExrPart getPart(int i) => parts[i];

  bool _isTiled()  {
    return (flags & TILED_FLAG) != 0;
  }

  bool _isMultiPart() {
    return flags & MULTI_PART_FILE_FLAG != 0;
  }

  bool _isNonImage() {
    return flags & NON_IMAGE_FLAG != 0;
  }

  static bool _supportsFlags(int flags) {
    return (flags & ~ALL_FLAGS) == 0;
  }

  void _readImage(InputBuffer input) {
    final bool multiPart = _isMultiPart();

    for (int hi = 0; hi < parts.length; ++hi) {
      ExrPart part = parts[hi];
      ExrCompressor compressor = part._compressor;
      List<int> offsets = part._offsets;
      ExrFrameBuffer framebuffer = part.framebuffer;

      for (int ci = 0; ci < part.channels.length; ++ci) {
        ExrChannel ch = part.channels[ci];
        if (!framebuffer.contains(ch.name)) {
          width = part.width;
          height = part.height;
          framebuffer[ch.name] = new ExrSlice(ch, part.width, part.height);
        }
      }

      int scanLineMin = part.top;
      int scanLineMax = part.bottom;
      int linesInBuffer = part._linesInBuffer;

      int minY = part.top;
      int maxY = minY + part._linesInBuffer - 1;

      Uint32List fbi = new Uint32List(part.channels.length);
      int total = 0;

      int xx = 0;
      int yy = 0;

      InputBuffer imgData = new InputBuffer.from(input);
      for (int offset in offsets) {
        imgData.offset = offset;

        if (multiPart) {
          int p = imgData.readUint32();
          if (p != hi) {
            throw new ImageException('Invalid Image Data');
          }
        }

        int y = imgData.readInt32();
        int dataSize = imgData.readInt32();
        InputBuffer data = imgData.readBytes(dataSize);

        Uint8List uncompressedData;
        if (compressor != null) {
          uncompressedData = compressor.uncompress(data, yy);
        } else {
          uncompressedData = data.toUint8List();
        }

        int si = 0;
        int len = uncompressedData.length;
        int numChannels = part.channels.length;
        int lineCount = 0;
        for (int yi = 0; yi < linesInBuffer && yy < height; ++yi, ++yy) {
          si = part._offsetInLineBuffer[yy];
          if (si >= len) {
            break;
          }

          for (int ci = 0; ci < numChannels; ++ci) {
            ExrChannel ch = part.channels[ci];
            Uint8List slice = framebuffer[ch.name].bytes;
            if (si >= len) {
              break;
            }
            for (int xx = 0; xx < part.width; ++xx) {
              for (int bi = 0; bi < ch.size; ++bi) {
                slice[fbi[ci]++] = uncompressedData[si++];
              }
            }
          }
        }
      }
    }
  }

  int version;
  int flags;

  /// The MAGIC number is stored in the first four bytes of every
  /// OpenEXR image file.  This can be used to quickly test whether
  /// a given file is an OpenEXR image file (see isImfMagic(), below).
  static const int MAGIC = 20000630;

  /// Value that goes into VERSION_NUMBER_FIELD.
  static const int EXR_VERSION = 2;

  /// File is tiled
  static const int TILED_FLAG = 0x00000200;

  /// File contains long attribute or channel names
  static const int LONG_NAMES_FLAG = 0x00000400;

  /// File has at least one part which is not a regular scanline image or
  /// regular tiled image (that is, it is a deep format).
  static const int NON_IMAGE_FLAG = 0x00000800;

  /// File has multiple parts.
  static const int MULTI_PART_FILE_FLAG  = 0x00001000;

  /// Bitwise OR of all supported flags.
  static const int ALL_FLAGS = TILED_FLAG | LONG_NAMES_FLAG;
}
