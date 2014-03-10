part of image;


class ImfInputFile {
  InputStream input;
  int version;
  int flags;

  ImfInputFile(List<int> bytes) {
    input = new InputStream(bytes);

    _readMagicNumberAndVersionField(input);

    /*if (_isMultiPart(version)) {
      _compatibilityInitialize(input);
    } else {
      header.readFrom(input, flags);

      // fix type attribute in single part regular image types
      // (may be wrong if an old version of OpenEXR converts
      // a tiled image to scanline or vice versa)
      if (!isNonImage(flags)  &&
          !isMultiPart(flags) &&
          header.hasType()) {
        header.setType(isTiled(flags) ? TILEDIMAGE : SCANLINEIMAGE);
      }

      header.sanityCheck(isTiled(flags));

      initialize();
    }*/
  }


  void _readMagicNumberAndVersionField(InputStream input) {
    int magic = input.readUint32();
    int versionFlags = input.readUint32();

    if (magic != MAGIC) {
      throw new ImageException("File is not an OpenEXR image file.");
    }

    version = _getVersion(versionFlags);
    if (_getVersion(version) != EXR_VERSION) {
      throw new ImageException("Cannot read version $version image files.");
    }

    flags = _getFlags(versionFlags);
    if (!_supportsFlags(flags)) {
      throw new ImageException("The file format version number's flag field "
                               "contains unrecognized flags.");
    }
  }



  int _getVersion(int version) { return version & VERSION_NUMBER_FIELD; }
  int _getFlags(int version) { return version & VERSION_FLAGS_FIELD; }
  bool _supportsFlags(int flags) { return (flags & ~ALL_FLAGS) == 0; }

  //
  // The MAGIC number is stored in the first four bytes of every
  // OpenEXR image file.  This can be used to quickly test whether
  // a given file is an OpenEXR image file (see isImfMagic(), below).
  static const int MAGIC = 20000630;

  // The second item in each OpenEXR image file, right after the
  // magic number, is a four-byte file version identifier.  Depending
  // on a file's version identifier, a file reader can enable various
  // backwards-compatibility switches, or it can quickly reject files
  // that it cannot read.
  //
  // The version identifier is split into an 8-bit version number,
  // and a 24-bit flags field.
  static const int VERSION_NUMBER_FIELD  = 0x000000ff;
  static const int VERSION_FLAGS_FIELD = 0xffffff00;


  // Value that goes into VERSION_NUMBER_FIELD.
  static const int EXR_VERSION   = 2;

  // Flags that can go into VERSION_FLAGS_FIELD.
  // Flags can only occupy the 1 bits in VERSION_FLAGS_FIELD.
  static const int TILED_FLAG = 0x00000200;   // File is tiled

  static const int LONG_NAMES_FLAG = 0x00000400;   // File contains long
                                                  // attribute or channel
                                                  // names

  // Bitwise OR of all known flags.
  static const int ALL_FLAGS = TILED_FLAG | LONG_NAMES_FLAG;
}
