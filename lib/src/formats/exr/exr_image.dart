part of image;


class ExrImage extends DecodeInfo {
  int version;
  int flags;
  List<ExrHeader> parts = [];

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

    if (!isMultiPart()) {
      ExrHeader header = new ExrHeader(isTiled(), input);
      if (header.isValid) {
        parts.add(header);
      }
    } else {
      while (true) {
        ExrHeader header = new ExrHeader(isTiled(), input);
        if (!header.isValid) {
          break;
        }
        parts.add(header);
      }
    }

    if (parts.isEmpty) {
      throw new ImageException('Error reading image header');
    }

    for (ExrHeader header in parts) {
      header.readOffsets(input);
    }

    _readImage(input);
  }

  int get numFrames => 1;

  static bool isValid(List<int> bytes) {
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

  bool isTiled()  {
    return (flags & TILED_FLAG) != 0;
  }

  bool isMultiPart() {
    return flags & MULTI_PART_FILE_FLAG != 0;
  }

  bool isNonImage() {
    return flags & NON_IMAGE_FLAG != 0;
  }

  static bool _supportsFlags(int flags) {
    return (flags & ~ALL_FLAGS) == 0;
  }

  int numParts() => parts.length;

  ExrHeader part(int i) => parts[i];

  void _readImage(InputBuffer input) {
    final bool multiPart = isMultiPart();

    for (int hi = 0; hi < parts.length; ++hi) {
      ExrHeader header = parts[hi];
      ExrLineBuffer lineBuffer = header.lineBuffer;
      ExrCompressor compressor = lineBuffer.compressor;
      List<int> offsets = header.offsets;
      ExrFrameBuffer framebuffer = header.framebuffer;

      for (int ci = 0; ci < header.channels.length; ++ci) {
        ExrChannel ch = header.channels[ci];
        if (!framebuffer.contains(ch.name)) {
          width = header.width;
          height = header.height;
          framebuffer[ch.name] = new ExrSlice(ch, header.width, header.height);
        }
      }

      int scanLineMin = header.top;
      int scanLineMax = header.bottom;
      int linesInBuffer = header.linesInBuffer;

      lineBuffer.minY = header.top;
      lineBuffer.maxY = lineBuffer.minY + header.linesInBuffer - 1;

      Uint32List fbi = new Uint32List(header.channels.length);
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
          lineBuffer.format = compressor.format();
          uncompressedData = compressor.uncompress(data, lineBuffer.minY);
        } else {
          uncompressedData = data.toUint8List();
        }

        int si = 0;
        int len = uncompressedData.length;
        int numChannels = header.channels.length;
        int lineCount = 0;
        for (int yi = 0; yi < linesInBuffer && yy < height; ++yi, ++yy) {
          si = header.offsetInLineBuffer[yy];

          for (int ci = 0; ci < numChannels; ++ci) {
            ExrChannel ch = header.channels[ci];
            Uint8List slice = framebuffer[ch.name].bytes;
            for (int xx = 0; xx < header.width; ++xx) {
              for (int bi = 0; bi < ch.size; ++bi) {
                slice[fbi[ci]++] = uncompressedData[si++];
              }
            }
          }
        }
      }
    }
  }


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
