part of image;

class TiffImage {
  Map<int, TiffEntry> tags = {};
  int width;
  int height;
  int photometricType;
  int compression;
  int bitsPerSample = 1;
  int samplesPerPixel;
  int imageType = TYPE_UNSUPPORTED;
  bool isWhiteZero = false;
  int predictor;
  int chromaSubH;
  int chromaSubV;

  TiffImage(MemPtr p2) {
    MemPtr p3 = new MemPtr.from(p2);

    int numDirEntries = p2.readUint16();
    for (int i = 0; i < numDirEntries; ++i) {
      TiffEntry entry = new TiffEntry();

      entry.tag = p2.readUint16();
      entry.type = p2.readUint16();
      entry.numValues = p2.readUint32();

      // The value for the tag is either stored in another location,
      // or within the tag itself (if the size fits in 4 bytes).
      // We're not reading the data here, just storing offsets.
      if (entry.numValues * entry.typeSize > 4) {
        entry.valueOffset = p2.readUint32();
      } else {
        entry.valueOffset = p2.offset;
        p2.offset += 4;
      }

      tags[entry.tag] = entry;

      if (entry.tag == TAG_WIDTH) {
        width = entry.readValue(p3);
      } else if (entry.tag == TAG_LENGTH) {
        height = entry.readValue(p3);
      } else if (entry.tag == TAG_PHOTOMETRIC_INTERPRETATION) {
        photometricType = entry.readValue(p3);
      } else if (entry.tag == TAG_COMPRESSION) {
        compression = entry.readValue(p3);
      } else if (entry.tag == TAG_BITS_PER_SAMPLE) {
        bitsPerSample = entry.readValue(p3);
      } else if (entry.tag == TAG_SAMPLES_PER_PIXEL) {
        samplesPerPixel = entry.readValue(p3);
      } else if (entry.tag == TAG_PREDICTOR) {
        predictor = entry.readValue(p3);
      }
    }

    if (photometricType == 0) {
      isWhiteZero = true;
    }

    // Determine which kind of image we are dealing with.
    switch (photometricType) {
      case 0: // WhiteIsZero
      case 1: // BlackIsZero
        if (bitsPerSample == 1 && samplesPerPixel == 1) {
          imageType = TYPE_BILEVEL;
        } else if (bitsPerSample == 4 && samplesPerPixel == 1) {
          imageType = TYPE_GRAY_4BIT;
        } else if (bitsPerSample % 8 == 0) {
          if (samplesPerPixel == 1) {
            imageType = TYPE_GRAY;
          } else if (samplesPerPixel == 2) {
            imageType = TYPE_GRAY_ALPHA;
          } else {
            imageType = TYPE_GENERIC;
          }
        }
        break;
      case 2: // RGB
        if (bitsPerSample % 8 == 0) {
          if (samplesPerPixel == 3) {
            imageType = TYPE_RGB;
          } else if (samplesPerPixel == 4) {
            imageType = TYPE_RGB_ALPHA;
          } else {
            imageType = TYPE_GENERIC;
          }
        }
        break;
      case 3: // RGB Palette
        if (samplesPerPixel == 1 &&
            (bitsPerSample == 4 || bitsPerSample == 8 ||
             bitsPerSample == 16)) {
          imageType = TYPE_PALETTE;
        }
        break;
      case 4: // Transparency mask
        if (bitsPerSample == 1 && samplesPerPixel == 1) {
          imageType = TYPE_BILEVEL;
        }
        break;
      case 6: // YCbCr
        if (compression == COMP_JPEG_TTN2 &&
            bitsPerSample == 8 && samplesPerPixel == 3) {
          imageType = TYPE_RGB;
        } else {
          if (hasTag(TAG_YCBCR_SUBSAMPLING)) {
            List<int> v = tags[TAG_YCBCR_SUBSAMPLING].readValues(p3);
            chromaSubH = v[0];
            chromaSubV = v[1];
          } else {
            chromaSubH = 2;
            chromaSubV = 2;
          }

          if (chromaSubH * chromaSubV == 1) {
            imageType = TYPE_GENERIC;
          } else if (bitsPerSample == 8 && samplesPerPixel == 3) {
            imageType = TYPE_YCBCR_SUB;
          }
        }
        break;
      default: // Other including CMYK, CIE L*a*b*, unknown.
        if (bitsPerSample % 8 == 0) {
          imageType = TYPE_GENERIC;
        }
        break;
    }
  }

  int _readTag(MemPtr p, int type, [int defaultValue = 0]) {
    if (!hasTag(type)) {
      return defaultValue;
    }
    return tags[type].readValue(p);
  }

  List<int> _readTagList(MemPtr p, int type) {
    if (!hasTag(type)) {
      return null;
    }
    return tags[type].readValues(p);
  }

  Image decode(MemPtr p) {
    int extraSamples = _readTag(p, TAG_EXTRA_SAMPLES, 0);

    bool tiled = false;
    int tileWidth;
    int tileHeight;
    List<int> tileOffsets;
    List<int> tileByteCounts;
    if (hasTag(TAG_TILE_OFFSETS)) {
      tiled = true;
      // Image is in tiled format
      tileWidth = _readTag(p, TAG_TILE_WIDTH);
      tileHeight = _readTag(p, TAG_TILE_LENGTH);
      tileOffsets = _readTagList(p, TAG_TILE_OFFSETS);
      tileByteCounts = _readTagList(p, TAG_TILE_BYTE_COUNTS);
    } else {
      tiled = false;

      tileWidth = _readTag(p, TAG_TILE_WIDTH, width);
      if (!hasTag(TAG_ROWS_PER_STRIP)) {
        tileHeight = _readTag(p, TAG_TILE_LENGTH, height);
      } else {
        int l = _readTag(p, TAG_ROWS_PER_STRIP);
        int infinity = 1;
        infinity = (infinity << 32) - 1;
        if (l == infinity) {
          // 2^32 - 1 (effectively infinity, entire image is 1 strip)
          tileHeight = height;
        } else {
          tileHeight = l;
        }
      }

      tileOffsets = _readTagList(p, TAG_STRIP_OFFSETS);
      tileByteCounts = _readTagList(p, TAG_STRIP_BYTE_COUNTS);
    }

    // Calculate number of tiles and the tileSize in bytes
    int tilesX = (width + tileWidth - 1) ~/ tileWidth;
    int tilesY = (height + tileHeight - 1) ~/ tileHeight;
    int tileSize = tileWidth * tileHeight * samplesPerPixel;

    int fillOrder = _readTag(p, TAG_FILL_ORDER, 1);

    return null;
  }

  bool hasTag(int tag) => tags.containsKey(tag);

  // Compression types
  static final int COMP_NONE = 1;
  static const int COMP_FAX_G3_1D = 2;
  static const int COMP_FAX_G3_2D = 3;
  static const int COMP_FAX_G4_2D = 4;
  static const int COMP_LZW = 5;
  static const int COMP_JPEG_OLD  = 6;
  static const int COMP_JPEG_TTN2 = 7;
  static const int COMP_PACKBITS = 32773;
  static const int COMP_DEFLATE = 32946;

  // Image types
  static const int TYPE_UNSUPPORTED = -1;
  static const int TYPE_BILEVEL = 0;
  static const int TYPE_GRAY_4BIT = 1;
  static const int TYPE_GRAY = 2;
  static const int TYPE_GRAY_ALPHA = 3;
  static const int TYPE_PALETTE = 4;
  static const int TYPE_RGB = 5;
  static const int TYPE_RGB_ALPHA = 6;
  static const int TYPE_YCBCR_SUB = 7;
  static const int TYPE_GENERIC = 8;

  // Tag types
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
  static const int TAG_TILE_WIDTH  = 322;
  static const int TAG_TILE_LENGTH = 323;
  static const int TAG_TILE_OFFSETS = 324;
  static const int TAG_TILE_BYTE_COUNTS = 325;
  static const int TAG_WIDTH = 256;
  static const int TAG_XMP = 700;
  static const int TAG_X_RESOLUTION = 282;
  static const int TAG_Y_RESOLUTION = 283;
  static const int TAG_YCBCR_COEFFICIENTS = 529;
  static const int TAG_YCBCR_SUBSAMPLING = 530;
  static const int TAG_YCBCR_POSITIONING = 531;
}
