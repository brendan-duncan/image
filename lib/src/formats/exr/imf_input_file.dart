part of image;


class ImfInputFile {
  InputBuffer input;
  int version;
  int flags;
  Map<String, ImfAttribute> attributes = {};
  List<int> displayWindow;
  List<int> dataWindow;

  ImfInputFile(List<int> bytes) {
    input = new InputBuffer(bytes);

    int magic = input.readUint32();
    if (magic != MAGIC) {
      throw new ImageException('File is not an OpenEXR image file.');
    }

    int versionFlags = input.readUint32();

    version = _getVersion(versionFlags);
    if (_getVersion(version) != EXR_VERSION) {
      throw new ImageException('Cannot read version $version image files.');
    }

    flags = _getFlags(versionFlags);
    if (!_supportsFlags(flags)) {
      throw new ImageException('The file format version number\'s flag field '
                               'contains unrecognized flags.');
    }

    if (!isMultiPart()) {
      _readHeader();
    } else {
      throw new ImageException('Multi-part images not yet supported.');
    }

    if (isTiled()) {
      _readTiledOffsets();
    } else {
      _readScanlineOffsets();
    }
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

  int _getVersion(int version) {
    return version & VERSION_NUMBER_FIELD;
  }

  int _getFlags(int version) {
    return version & VERSION_FLAGS_FIELD;
  }

  bool _supportsFlags(int flags) {
    return (flags & ~ALL_FLAGS) == 0;
  }

  void _readTiledOffsets() {

  }

  void _readScanlineOffsets() {

  }

  void _readHeader() {
    while (true) {
      String name = input.readString();
      if (name == null || name.isEmpty) {
        break;
      }

      String type = input.readString();
      int size = input.readUint32();
      InputBuffer value = input.readBytes(size);

      switch (name) {
        case 'dataWindow':
          dataWindow = [value.readInt32(), value.readInt32(),
                        value.readInt32(), value.readInt32()];
          break;
        case 'displayWindow':
          displayWindow = [value.readInt32(), value.readInt32(),
                           value.readInt32(), value.readInt32()];
          break;
      }

      attributes[name] = new ImfAttribute(name, type, size, value);
    }
  }


  /// The MAGIC number is stored in the first four bytes of every
  /// OpenEXR image file.  This can be used to quickly test whether
  /// a given file is an OpenEXR image file (see isImfMagic(), below).
  static const int MAGIC = 20000630;

  /// The second item in each OpenEXR image file, right after the
  /// magic number, is a four-byte file version identifier.  Depending
  /// on a file's version identifier, a file reader can enable various
  /// backwards-compatibility switches, or it can quickly reject files
  /// that it cannot read.
  ///
  /// The version identifier is split into an 8-bit version number,
  /// and a 24-bit flags field.
  static const int VERSION_NUMBER_FIELD = 0x000000ff;
  static const int VERSION_FLAGS_FIELD = 0xffffff00;

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

class ImfAttribute {
  String name;
  String type;
  int size;
  InputBuffer value;

  ImfAttribute(this.name, this.type, this.size, this.value);
}
