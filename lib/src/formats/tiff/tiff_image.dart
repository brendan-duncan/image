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
  int predictor = 1;
  int chromaSubH;
  int chromaSubV;
  bool tiled = false;
  int tileWidth;
  int tileHeight;
  List<int> tileOffsets;
  List<int> tileByteCounts;
  int tilesX;
  int tilesY;
  int tileSize;
  int fillOrder;
  int t4Options;
  int t6Options;
  int extraSamples;
  Image image;

  TiffImage(Buffer p) {
    Buffer p3 = new Buffer.from(p);

    int numDirEntries = p.readUint16();
    for (int i = 0; i < numDirEntries; ++i) {
      TiffEntry entry = new TiffEntry();

      entry.tag = p.readUint16();
      entry.type = p.readUint16();
      entry.numValues = p.readUint32();

      // The value for the tag is either stored in another location,
      // or within the tag itself (if the size fits in 4 bytes).
      // We're not reading the data here, just storing offsets.
      if (entry.numValues * entry.typeSize > 4) {
        entry.valueOffset = p.readUint32();
      } else {
        entry.valueOffset = p.offset;
        p.offset += 4;
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

    if (width == null || height == null || samplesPerPixel == null ||
        bitsPerSample == null || compression == null) {
      return;
    }

    if (photometricType == 0) {
      isWhiteZero = true;
    }

    if (hasTag(TAG_TILE_OFFSETS)) {
      tiled = true;
      // Image is in tiled format
      tileWidth = _readTag(p3, TAG_TILE_WIDTH);
      tileHeight = _readTag(p3, TAG_TILE_LENGTH);
      tileOffsets = _readTagList(p3, TAG_TILE_OFFSETS);
      tileByteCounts = _readTagList(p3, TAG_TILE_BYTE_COUNTS);
    } else {
      tiled = false;

      tileWidth = _readTag(p3, TAG_TILE_WIDTH, width);
      if (!hasTag(TAG_ROWS_PER_STRIP)) {
        tileHeight = _readTag(p3, TAG_TILE_LENGTH, height);
      } else {
        int l = _readTag(p3, TAG_ROWS_PER_STRIP);
        int infinity = 1;
        infinity = (infinity << 32) - 1;
        if (l == infinity) {
          // 2^32 - 1 (effectively infinity, entire image is 1 strip)
          tileHeight = height;
        } else {
          tileHeight = l;
        }
      }

      tileOffsets = _readTagList(p3, TAG_STRIP_OFFSETS);
      tileByteCounts = _readTagList(p3, TAG_STRIP_BYTE_COUNTS);
    }

    // Calculate number of tiles and the tileSize in bytes
    tilesX = (width + tileWidth - 1) ~/ tileWidth;
    tilesY = (height + tileHeight - 1) ~/ tileHeight;
    tileSize = tileWidth * tileHeight * samplesPerPixel;

    fillOrder = _readTag(p3, TAG_FILL_ORDER, 1);
    t4Options = _readTag(p3, TAG_T4_OPTIONS, 0);
    t6Options = _readTag(p3, TAG_T6_OPTIONS, 0);
    extraSamples = _readTag(p3, TAG_EXTRA_SAMPLES, 0);


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

  bool get isValid => width != null && height != null &&
                      samplesPerPixel != null &&
                      bitsPerSample != null &&
                      compression != null;

  Image decode(Buffer p) {
    image = new Image(width, height);
    for (int tileY = 0, ti = 0; tileY < tilesY; ++tileY) {
      for (int tileX = 0; tileX < tilesX; ++tileX, ++ti) {
        _decodeTile(p, tileX, tileY);
      }
    }
    return image;
  }

  bool hasTag(int tag) => tags.containsKey(tag);

  void _decodeTile(Buffer p, int tileX, int tileY) {
    // Read the data, uncompressing as needed. There are four cases:
    // bilevel, palette-RGB, 4-bit grayscale, and everything else.
    if (imageType == TYPE_BILEVEL) {
      _decodeBilevelTile(p, tileX, tileY);
      return;
    }

    int tileIndex = tileY * tilesX + tileX;
    p.offset = tileOffsets[tileIndex];

    int outX = tileX * tileWidth;
    int outY = tileY * tileHeight;

    int byteCount = tileByteCounts[tileIndex];
    int bytesInThisTile = tileWidth * tileHeight * samplesPerPixel;

    Buffer bdata;
    if (bitsPerSample == 8) {
      if (compression == COMP_NONE) {
        bdata = p;

      } else if (compression == COMP_LZW) {
        bdata = new Buffer(new Uint8List(bytesInThisTile));
        LzwDecoder decoder = new LzwDecoder();
        decoder.decode(new Buffer.from(p, 0, byteCount), bdata.data);

        // Horizontal Differencing Predictor
        if (predictor == 2) {
          int count;
          for (int j = 0; j < tileHeight; j++) {
            count = samplesPerPixel * (j * tileWidth + 1);
            for (int i = samplesPerPixel, len = tileWidth * samplesPerPixel;
                 i < len; i++) {
              bdata[count] += bdata[count - samplesPerPixel];
              count++;
            }
          }
        }

      } else if (compression == COMP_PACKBITS) {
        bdata = new Buffer(new Uint8List(bytesInThisTile));
        _decodePackbits(p, bytesInThisTile, bdata.data);

      } else if (compression == COMP_DEFLATE) {
        List<int> data = p.toList(0, byteCount);
        List<int> outData = new Inflate(data).getBytes();
        bdata = new Buffer(outData);

      } else if (compression == COMP_ZIP) {
        List<int> data = p.toList(0, byteCount);
        List<int> outData = new ZLibDecoder().decodeBytes(data);
        bdata = new Buffer(outData);
      } else if (compression == COMP_JPEG_OLD) {
        List<int> data = p.toList(0, byteCount);
        JpegData jpeg = new JpegData();
        jpeg.read(data);
        print('!!!!');
      } else {
        throw new ImageException('Unsupported Compression Type: $compression');
      }

      if (bdata == null) {
        return;
      }

      for (int y = 0, py = outY, pi = 0; y < tileHeight; ++y, ++py) {
        for (int x = 0, px = outX; x < tileWidth; ++x, ++px) {
          if (samplesPerPixel == 3) {
            int c = getColor(bdata[pi++], bdata[pi++], bdata[pi++], 255);
            image.setPixel(px, py, c);
          } else {
            int c = getColor(bdata[pi++], bdata[pi++], bdata[pi++], bdata[pi++]);
            image.setPixel(px, py, c);
          }
        }
      }
    } else {
      throw new ImageException('Unsupported bitsPerSample: $bitsPerSample');
    }
  }


  void _decodeBilevelTile(Buffer p, int tileX, int tileY) {
    int tileIndex = tileY * tilesX + tileX;
    p.offset = tileOffsets[tileIndex];

    int outX = tileX * tileWidth;
    int outY = tileY * tileHeight;

    int byteCount = tileByteCounts[tileIndex];

    Buffer bdata;
    if (compression == COMP_PACKBITS) {
      // Since the decompressed data will still be packed
      // 8 pixels into 1 byte, calculate bytesInThisTile
      int bytesInThisTile;
      if ((tileWidth % 8) == 0) {
        bytesInThisTile = (tileWidth ~/ 8) * tileHeight;
      } else {
        bytesInThisTile = (tileWidth ~/ 8 + 1) * tileHeight;
      }
      bdata = new Buffer(new Uint8List(tileWidth * tileHeight));
      _decodePackbits(p, bytesInThisTile, bdata.data);
    } else if (compression == COMP_LZW) {
      bdata = new Buffer(new Uint8List(tileWidth * tileHeight));

      LzwDecoder decoder = new LzwDecoder();
      decoder.decode(new Buffer.from(p, 0, byteCount), bdata.data);

      // Horizontal Differencing Predictor
      if (predictor == 2) {
        int count;
        for (int j = 0; j < height; j++) {
          count = samplesPerPixel * (j * width + 1);
          for (int i = samplesPerPixel; i < width * samplesPerPixel; i++) {
            bdata[count] += bdata[count - samplesPerPixel];
            count++;
          }
        }
      }
    } else if (compression == COMP_FAX_G3_1D) {
      bdata = new Buffer(new Uint8List(tileWidth * tileHeight));
      try {
        new TiffFaxDecoder(fillOrder, tileWidth, tileHeight).
            decode1D(bdata, p, 0, tileHeight);
      } catch (_) {
      }
    } else if (compression == COMP_FAX_G3_2D) {
      bdata = new Buffer(new Uint8List(tileWidth * tileHeight));
      try {
        new TiffFaxDecoder(fillOrder, tileWidth, tileHeight).
            decode2D(bdata, p, 0, tileHeight, t4Options);
      } catch (_) {
      }
    } else if (compression == COMP_FAX_G4_2D) {
      bdata = new Buffer(new Uint8List(tileWidth * tileHeight));
      try {
        new TiffFaxDecoder(fillOrder, tileWidth, tileHeight).
            decodeT6(bdata, p, 0, tileHeight, t6Options);
      } catch (_) {
      }
    } else if (compression == COMP_ZIP) {
      List<int> data = p.toList(0, byteCount);
      List<int> outData = new ZLibDecoder().decodeBytes(data);
      bdata = new Buffer(outData);
    } else if (compression == COMP_DEFLATE) {
      List<int> data = p.toList(0, byteCount);
      List<int> outData = new Inflate(data).getBytes();
      bdata = new Buffer(outData);
    } else if (compression == COMP_NONE) {
      bdata = p;
    } else {
      throw new ImageException('Unsupported Compression Type: $compression');
    }

    if (bdata == null) {
      return;
    }

    TiffBitReader br = new TiffBitReader(bdata);
    final int white = isWhiteZero ? 0xff000000 : 0xffffffff;
    final int black = isWhiteZero ? 0xffffffff : 0xff000000;

    for (int y = 0, py = outY; y < tileHeight; ++y, ++py) {
      for (int x = 0, px = outX; x < tileWidth; ++x, ++px) {
        if (br.readBits(1) == 0) {
          image.setPixel(px, py, black);
        } else {
          image.setPixel(px, py, white);
        }
      }
      br.flushByte();
    }
  }

  /**
   * Uncompress packbits compressed image data.
   */
  void _decodePackbits(Buffer data, int arraySize, List<int> dst) {
    int srcCount = 0;
    int dstCount = 0;

    while (dstCount < arraySize) {
      int b = data[srcCount++];
      if (b >= 0 && b <= 127) {
        // literal run packet
        for (int i = 0; i < (b + 1); ++i) {
          dst[dstCount++] = data[srcCount++];
        }
      } else if (b <= -1 && b >= -127) {
        // 2 byte encoded run packet
        int repeat = data[srcCount++];
        for (int i = 0; i < (-b + 1); ++i) {
          dst[dstCount++] = repeat;
        }
      } else {
        // no-op packet. Do nothing
        srcCount++;
      }
    }
  }

  int _readTag(Buffer p, int type, [int defaultValue = 0]) {
    if (!hasTag(type)) {
      return defaultValue;
    }
    return tags[type].readValue(p);
  }

  List<int> _readTagList(Buffer p, int type) {
    if (!hasTag(type)) {
      return null;
    }
    return tags[type].readValues(p);
  }

  // Compression types
  static const int COMP_NONE = 1;
  static const int COMP_FAX_G3_1D = 2; // CCITT modified Huffman RLE
  static const int COMP_FAX_G3_2D = 3; // CCITT Group 3 fax encoding
  static const int COMP_FAX_G4_2D = 4; // CCITT Group 4 fax encoding
  static const int COMP_LZW = 5;
  static const int COMP_JPEG_OLD  = 6;
  static const int COMP_JPEG_TTN2 = 7;
  static const int COMP_ZIP = 8;
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
  static const int TAG_T4_OPTIONS = 292;
  static const int TAG_T6_OPTIONS = 293;
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
