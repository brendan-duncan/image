part of image;


class TiffDecoder extends Decoder {
  /**
   * Is the given file a valid TIFF image?
   */
  bool isValidFile(List<int> data) {
    return _readHeader(new MemPtr(data)) != null;
  }

  Image decodeImage(List<int> data, {int frame: 0}) {
    MemPtr ptr = new MemPtr(data);

    TiffInfo info = _readHeader(ptr);
    if (info == null) {
      return null;
    }

    for (TiffDirectory d in info.directories) {
      print('------------');
      for (TiffEntity t in d.entities) {
        switch (t.tag) {
          case TAG_PHOTOMETRIC_INTERPRETATION:
            print('PHOTOMETRIC_INTERPRETATION ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_COMPRESSION:
            print('COMPRESSION ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_LENGTH:
            print('HEIGHT ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_WIDTH:
            print('WIDTH ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_RESOLUTION_UNIT:
            print('RESOLUTION UNIT ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_X_RESOLUTION:
            print('X RESOLUTION ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_Y_RESOLUTION:
            print('Y RESOLUTION ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_ROWS_PER_STRIP:
            print('ROWS PER STRIP: ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_STRIP_OFFSETS:
            print('STRIP OFFSETS ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_STRIP_BYTE_COUNTS:
            print('STRIP BYTE COUNTS ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_ARTIST:
            print('ARTIST ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_BITS_PER_SAMPLE:
            print('BITS_PER_SAMPLE ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_CELL_LENGTH:
            print('CELL_LENGTH ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_CELL_WIDTH:
            print('CELL_WIDTH ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_COLOR_MAP:
            print('COLOR_MAP ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_DATE_TIME:
            print('DATE_TIME ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_EXTRA_SAMPLES:
            print('EXTRA_SAMPLES ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_FILL_ORDER:
            print('FILL_ORDER ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_FREE_BYTE_COUNTS:
            print('FREE_BYTE_COUNTS ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_FREE_OFFSETS:
            print('FREE OFFSETS ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_GRAY_RESPONSE_CURVE:
            print('GRAY RESPONSE CURVE ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_GRAY_RESPONSE_UNIT:
            print('GRAY RESPONSE UNIT ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_HOST_COMPUTER:
            print('HOST COMPUTER ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_IMAGE_DESCRIPTION:
            print('IMAGE DESCRIPTION ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_MAKE:
            print('MAKE ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_MAX_SAMPLE_VALUE:
            print('MAX SAMPLE VALUE ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_MIN_SAMPLE_VALUE:
            print('MIN SAMPLE VALUE ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_MODEL:
            print('MODEL ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_NEW_SUBFILE_TYPE:
            print('NEW SUBFILE TYPE ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_ORIENTATION:
            print('ORIENTATION ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_PLANAR_CONFIGURATION:
            print('PLANAR CONFIGURATION ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_PREDICTOR:
            print('PREDICTOR ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_SAMPLES_PER_PIXEL:
            print('SAMPLES PER PIXEL ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_SOFTWARE:
            print('SOFTWARE ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_SUBFILE_TYPE:
            print('SUBFILE TYPE ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_THRESHOLDING:
            print('THRESHOLDING ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_XMP:
            print('XMP ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_EXIF_IFD:
            print('EXIF IFD ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_PHOTOSHOP:
            print('PHOTOSHOP ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          case TAG_IPTC:
            print('IPTC ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
            break;
          default:
            print('UNKNOWN ${t.tag} ${t.numValues} ${SIZE_OF_TYPE[t.type]}');
        }
      }
    }

    return null;
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
   * Read the TIFF header and IFD blocks.
   */
  TiffInfo _readHeader(MemPtr p) {
    TiffInfo info = new TiffInfo();
    info.byteOrder = p.readUint16();
    if (info.byteOrder != TIFF_LITTLE_ENDIAN &&
        info.byteOrder != TIFF_BIG_ENDIAN) {
      return null;
    }

    if (info.byteOrder == TIFF_BIG_ENDIAN) {
      p.byteOrder = BIG_ENDIAN;
    } else {
      p.byteOrder = LITTLE_ENDIAN;
    }

    info.signature = p.readUint16();
    if (info.signature != TIFF_SIGNATURE) {
      return null;
    }

    int offset = p.readUint32();
    info.ifdOffset = offset;

    MemPtr p2 = new MemPtr.from(p);
    p2.offset = offset;

    while (offset != 0) {
      TiffDirectory dir = new TiffDirectory();
      info.directories.add(dir);

      int numDirEntries = p2.readUint16();
      for (int i = 0; i < numDirEntries; ++i) {
        TiffEntity entity = new TiffEntity();
        dir.entities.add(entity);

        entity.tag = p2.readUint16();
        entity.type = p2.readUint16();
        entity.numValues = p2.readUint32();
        // The value for the tag is either stored in another location,
        // or within the tag itself (if the size fits in 4 bytes).
        // We're not reading the data here, just storing offsets.
        if (entity.numValues * SIZE_OF_TYPE[entity.type] > 4) {
          entity.valueOffset = p2.readUint32();
        } else {
          entity.valueOffset = p2.offset;
          p2.offset += 4;
        }
      }

      offset = p2.readUint32();;
      if (offset != 0) {
        p2.offset = offset;
      }
    }

    return info;
  }

  static const int TIFF_SIGNATURE = 42;
  static const int TIFF_LITTLE_ENDIAN = 0x4949;
  static const int TIFF_BIG_ENDIAN = 0x4d4d;

  static const int TYPE_BYTE = 1;
  static const int TYPE_ASCII = 2;
  static const int TYPE_SHORT = 3;
  static const int TYPE_LONG = 4;
  static const int TYPE_RATIONAL = 5;
  static const int TYPE_SBYTE = 6;
  static const int TYPE_UNDEFINED = 7;
  static const int TYPE_SSHORT = 8;
  static const int TYPE_SLONG = 9;
  static const int TYPE_SRATIONAL = 10;
  static const int TYPE_FLOAT = 11;
  static const int TYPE_DOUBLE = 12;

  static const int TAG_ARTIST = 315;
  static const int TAG_BITS_PER_SAMPLE = 258;
  static const int TAG_CELL_LENGTH = 265;
  static const int TAG_CELL_WIDTH = 264;
  static const int TAG_COLOR_MAP = 320;
  static const int TAG_COMPRESSION = 259;
  static const int TAG_DATE_TIME = 306;
  static const int TAG_EXIF_IFD = 34665;
  static const int TAG_EXTRA_SAMPLES = 338;
  static const int TAG_FILL_ORDER = 266;
  static const int TAG_FREE_BYTE_COUNTS = 289;
  static const int TAG_FREE_OFFSETS = 288;
  static const int TAG_GRAY_RESPONSE_CURVE = 291;
  static const int TAG_GRAY_RESPONSE_UNIT = 290;
  static const int TAG_HOST_COMPUTER = 316;
  static const int TAG_IMAGE_DESCRIPTION = 270;
  static const int TAG_IPTC = 33723;
  static const int TAG_LENGTH = 257;
  static const int TAG_MAKE = 271;
  static const int TAG_MAX_SAMPLE_VALUE = 281;
  static const int TAG_MIN_SAMPLE_VALUE = 280;
  static const int TAG_MODEL = 272;
  static const int TAG_NEW_SUBFILE_TYPE = 254;
  static const int TAG_ORIENTATION = 274;
  static const int TAG_PHOTOMETRIC_INTERPRETATION = 262;
  static const int TAG_PHOTOSHOP = 34377;
  static const int TAG_PLANAR_CONFIGURATION = 284;
  static const int TAG_PREDICTOR = 317;
  static const int TAG_RESOLUTION_UNIT = 296;
  static const int TAG_ROWS_PER_STRIP = 278;
  static const int TAG_SAMPLES_PER_PIXEL = 277;
  static const int TAG_SOFTWARE = 305;
  static const int TAG_STRIP_BYTE_COUNTS = 279;
  static const int TAG_STRIP_OFFSETS = 273;
  static const int TAG_SUBFILE_TYPE = 255;
  static const int TAG_THRESHOLDING = 263;
  static const int TAG_WIDTH = 256;
  static const int TAG_XMP = 700;
  static const int TAG_X_RESOLUTION = 282;
  static const int TAG_Y_RESOLUTION = 283;

  static const List<int> SIZE_OF_TYPE = const [
      0, //  0 = n/a
      1, //  1 = byte
      1, //  2 = ascii
      2, //  3 = short
      4, //  4 = long
      8, //  5 = rational
      1, //  6 = sbyte
      1, //  7 = undefined
      2, //  8 = sshort
      4, //  9 = slong
      8, // 10 = srational
      4, // 11 = float
      8];  // 12 = double
}
