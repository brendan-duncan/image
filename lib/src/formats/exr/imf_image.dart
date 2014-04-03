part of image;


class ImfImage {
  int version;
  int flags;
  List<ImfPart> headers = [];

  ImfImage(List<int> bytes) {
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
      ImfPart header = new ImfPart(isTiled(), input);
      if (header.isValid) {
        headers.add(header);
      }
    } else {
      while (true) {
        ImfPart header = new ImfPart(isTiled(), input);
        if (!header.isValid) {
          break;
        }
        headers.add(header);
      }
    }

    if (headers.isEmpty) {
      throw new ImageException('Error reading image header');
    }

    for (ImfPart header in headers) {
      header.readOffsets(input);
    }

    _readImage(input);
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

  bool _supportsFlags(int flags) {
    return (flags & ~ALL_FLAGS) == 0;
  }


  void _readImage(InputBuffer input) {
    final bool multiPart = isMultiPart();
    /*for (int offset in offsets) {
      input.offset = offset;

      int partNum = 0;
      if (multiPart) {
        partNum = input.readUint32();
      }

      ImfHeader header = headers[partNum];
    }*/
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
