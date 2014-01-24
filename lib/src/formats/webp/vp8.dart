part of image;

/**
 * WebP lossy format.
 */
class VP8 {
  Arc.InputStream input;
  WebPData webp;

  VP8(Arc.InputStream input, this.webp) :
    this.input = input {
  }

  bool decodeHeader() {
    int bits = input.readUint24();

    final bool keyFrame = (bits & 1) == 0;
    if (!keyFrame) {
      return false;
    }

    if (((bits >> 1) & 7) > 3) {
      return false; // unknown profile
    }

    if (((bits >> 4) & 1) == 0) {
      return false; // first frame is invisible!
    }

    _frameHeader.keyFrame = (bits & 1) == 0;
    _frameHeader.profile = (bits >> 1) & 7;
    _frameHeader.show = (bits >> 4) & 1;
    _frameHeader.partitionLength = (bits >> 5);

    int signature = input.readUint24();
    if (signature != VP8_SIGNATURE) {
      return false;
    }

    webp.width = input.readUint16();
    webp.height = input.readUint16();

    return true;
  }

  Image decode() {
    if (!_getHeaders()) {
      return null;
    }

    output = new Image(webp.width, webp.height);

    // Finish setting up the decoding parameter.
    if (!_enterCritical()) {
      return null;
    }

    // Will allocate memory and prepare everything.
    /*if (!_initFrame()) {
      return null;
    }

    // Main decoding loop
    if (!_parseFrame()) {
      return null;
    }*/

    return output;
  }

  bool _getHeaders() {
    if (!decodeHeader()) {
      return false;
    }

    _probabilities = new VP8Proba();
    for (int i = 0; i < NUM_MB_SEGMENTS; ++i) {
      _dqm[i] = new VP8QuantMatrix();
    }

    _picHeader.width = webp.width;
    _picHeader.height = webp.height;
    _picHeader.xscale = (webp.width >> 8) >> 6;
    _picHeader.yscale = (webp.height >> 8) >> 6;

    _cropTop = 0;
    _cropLeft = 0;
    _cropRight = webp.width;
    _cropBottom = webp.height;

    _mbWidth = (webp.width + 15) >> 4;
    _mbHeight = (webp.height + 15) >> 4;

    _segment = 0;

    br = new VP8BitReader(input.subset(null, _frameHeader.partitionLength));
    input.skip(_frameHeader.partitionLength);

    _picHeader.colorspace = br.getBit();
    _picHeader.clampType = br.getBit();

    if (!_parseSegmentHeader(_segmentHeader, _probabilities)) {
      return false;
    }

    // Filter specs
    if (!_parseFilterHeader()) {
      return false;
    }

    if (!_parsePartitions(input)) {
      return false;
    }

    // quantizer change
    _parseQuant();

    // Frame buffer marking
    br.getBit();   // ignore the value of update_proba_

    _parseProba();

    return true;
  }

  bool _parseSegmentHeader(VP8SegmentHeader hdr, VP8Proba proba) {
    hdr.useSegment = br.getBit() != 0;
    if (hdr.useSegment) {
      hdr.updateMap = br.getBit() != 0;
      if (br.getBit() != 0) {   // update data
        hdr.absoluteDelta = br.getBit() != 0;
        for (int s = 0; s < NUM_MB_SEGMENTS; ++s) {
          hdr.quantizer[s] = br.getBit() != 0 ? br.getSignedValue(7) : 0;
        }
        for (int s = 0; s < NUM_MB_SEGMENTS; ++s) {
          hdr.filterStrength[s] = br.getBit() != 0 ? br.getSignedValue(6) : 0;
        }
      }
      if (hdr.updateMap) {
        for (int s = 0; s < MB_FEATURE_TREE_PROBS; ++s) {
          proba.segments[s] = br.getBit() != 0 ? br.getValue(8) : 255;
        }
      }
    } else {
      hdr.updateMap = false;
    }

    return true;
  }

  bool _parseFilterHeader() {
    VP8FilterHeader hdr = _filterHeader;
    hdr.simple = br.getBit() != 0;
    hdr.level = br.getValue(6);
    hdr.sharpness = br.getValue(3);
    hdr.useLfDelta = br.getBit() != 0;
    if (hdr.useLfDelta) {
      if (br.getBit() != 0) {   // update lf-delta?
        for (int i = 0; i < NUM_REF_LF_DELTAS; ++i) {
          if (br.getBit() != 0) {
            hdr.refLfDelta[i] = br.getSignedValue(6);
          }
        }

        for (int i = 0; i < NUM_MODE_LF_DELTAS; ++i) {
          if (br.getBit() != 0) {
            hdr.modeLfDelta[i] = br.getSignedValue(6);
          }
        }
      }
    }

    _filterType = (hdr.level == 0) ? 0 : hdr.simple ? 1 : 2;

    return true;
  }

  /**
   * This function returns VP8_STATUS_SUSPENDED if we don't have all the
   * necessary data in 'buf'.
   * This case is not necessarily an error (for incremental decoding).
   * Still, no bitreader is ever initialized to make it possible to read
   * unavailable memory.
   * If we don't even have the partitions' sizes, than VP8_STATUS_NOT_ENOUGH_DATA
   * is returned, and this is an unrecoverable error.
   * If the partitions were positioned ok, VP8_STATUS_OK is returned.
   */
  bool _parsePartitions(Arc.InputStream input) {
    int sz = 0;
    int bufEnd = input.remainder;

    _numPartitions = 1 << br.getValue(2);
    int lastPart = _numPartitions - 1;
    int partStart = lastPart * 3;
    if (bufEnd < partStart) {
      // we can't even read the sizes with sz[]! That's a failure.
      return false;
    }

    for (int p = 0; p < lastPart; ++p) {
      List<int> szb = input.peekBytes(3, sz);
      final int psize = szb[0] | (szb[1] << 8) | (szb[2] << 16);
      int partEnd = partStart + psize;
      if (partEnd > bufEnd) {
        partEnd = bufEnd;
      }

      Arc.InputStream pin = input.subset(partStart, partEnd - partStart);
      _partitions[p] = new VP8BitReader(pin);
      partStart = partEnd;
      sz += 3;
    }

    Arc.InputStream pin = input.subset(partStart, bufEnd - partStart);
    _partitions[lastPart] = new VP8BitReader(pin);

    // Init is ok, but there's not enough data
    return (partStart < bufEnd) ? true : false;
  }

  void _parseQuant() {
    final int base_q0 = br.getValue(7);
    final int dqy1_dc = br.getBit() != 0 ? br.getSignedValue(4) : 0;
    final int dqy2_dc = br.getBit() != 0 ? br.getSignedValue(4) : 0;
    final int dqy2_ac = br.getBit() != 0 ? br.getSignedValue(4) : 0;
    final int dquv_dc = br.getBit() != 0 ? br.getSignedValue(4) : 0;
    final int dquv_ac = br.getBit() != 0 ? br.getSignedValue(4) : 0;

    VP8SegmentHeader hdr = _segmentHeader;

    for (int i = 0; i < NUM_MB_SEGMENTS; ++i) {
      int q;
      if (hdr.useSegment) {
        q = hdr.quantizer[i];
        if (!hdr.absoluteDelta) {
          q += base_q0;
        }
      } else {
        if (i > 0) {
          _dqm[i] = _dqm[0];
          continue;
        } else {
          q = base_q0;
        }
      }

      VP8QuantMatrix m = _dqm[i];
      m.y1Mat[0] = DC_TABLE[_clip(q + dqy1_dc, 127)];
      m.y1Mat[1] = AC_TABLE[_clip(q + 0,       127)];

      m.y2Mat[0] = DC_TABLE[_clip(q + dqy2_dc, 127)] * 2;
      // For all x in [0..284], x*155/100 is bitwise equal to (x*101581) >> 16.
      // The smallest precision for that is '(x*6349) >> 12' but 16 is a good
      // word size.
      m.y2Mat[1] = (AC_TABLE[_clip(q + dqy2_ac, 127)] * 101581) >> 16;
      if (m.y2Mat[1] < 8) {
        m.y2Mat[1] = 8;
      }

      m.uvMat[0] = DC_TABLE[_clip(q + dquv_dc, 117)];
      m.uvMat[1] = AC_TABLE[_clip(q + dquv_ac, 127)];

      m.uvQuant = q + dquv_ac;   // for dithering strength evaluation
    }
  }

  void _parseProba() {
    VP8Proba proba = _probabilities;

    for (int t = 0; t < NUM_TYPES; ++t) {
      for (int b = 0; b < NUM_BANDS; ++b) {
        for (int c = 0; c < NUM_CTX; ++c) {
          for (int p = 0; p < NUM_PROBAS; ++p) {
            final int v = br.getBits(COEFFS_UPDATE_PROBA[t][b][c][p]) != 0 ?
                br.getValue(8) : COEFFS_PROBA_0[t][b][c][p];
                proba.bands[t][b].probas[c][p] = v;
          }
        }
      }
    }

    _useSkipProbabilities = br.getBit() != 0;
    if (_useSkipProbabilities) {
      _skipProb = br.getValue(8);
    }
  }

  /**
   * Finish setting up the decoding parameter once user's setup() is called.
   */
  bool _enterCritical() {
    _fStrengths = new List<List<VP8FInfo>>(NUM_MB_SEGMENTS);
    for (int i = 0; i < NUM_MB_SEGMENTS; ++i) {
      _fStrengths[i] = [new VP8FInfo(), new VP8FInfo()];
    }

    // Define the area where we can skip in-loop filtering, in case of cropping.
    //
    // 'Simple' filter reads two luma samples outside of the macroblock
    // and filters one. It doesn't filter the chroma samples. Hence, we can
    // avoid doing the in-loop filtering before crop_top/crop_left position.
    // For the 'Complex' filter, 3 samples are read and up to 3 are filtered.
    // Means: there's a dependency chain that goes all the way up to the
    // top-left corner of the picture (MB #0). We must filter all the previous
    // macroblocks.
    {
      final int extraPixels = FILTER_EXTRA_ROWS[_filterType];
      if (_filterType == 2) {
        // For complex filter, we need to preserve the dependency chain.
        _tlMbX = 0;
        _tlMbY = 0;
      } else {
        // For simple filter, we can filter only the cropped region.
        // We include 'extra_pixels' on the other side of the boundary, since
        // vertical or horizontal filtering of the previous macroblock can
        // modify some abutting pixels.
        _tlMbX = (_cropLeft - extraPixels) >> 4;
        _tlMbY = (_cropTop - extraPixels) >> 4;
        if (_tlMbX < 0) {
          _tlMbX = 0;
        }
        if (_tlMbY < 0) {
          _tlMbY = 0;
        }
      }
      // We need some 'extra' pixels on the right/bottom.
      _brMbY = (_cropBottom + 15 + extraPixels) >> 4;
      _brMbX = (_cropRight + 15 + extraPixels) >> 4;
      if (_brMbX > _mbWidth) {
        _brMbX = _mbWidth;
      }
      if (_brMbY > _mbHeight) {
        _brMbY = _mbHeight;
      }
    }

    _precomputeFilterStrengths();
    return true;
  }

  /**
   * Precompute the filtering strength for each segment and each i4x4/i16x16
   * mode.
   */
  void _precomputeFilterStrengths() {
    if (_filterType > 0) {
      VP8FilterHeader hdr = _filterHeader;
      for (int s = 0; s < NUM_MB_SEGMENTS; ++s) {
        // First, compute the initial level
        int baseLevel;
        if (_segmentHeader.useSegment) {
          baseLevel = _segmentHeader.filterStrength[s];
          if (!_segmentHeader.absoluteDelta) {
            baseLevel += hdr.level;
          }
        } else {
          baseLevel = hdr.level;
        }

        for (int i4x4 = 0; i4x4 <= 1; ++i4x4) {
          VP8FInfo info = _fStrengths[s][i4x4];
          int level = baseLevel;
          if (hdr.useLfDelta) {
            level += hdr.refLfDelta[0];
            if (i4x4 != 0) {
              level += hdr.modeLfDelta[0];
            }
          }

          level = (level < 0) ? 0 : (level > 63) ? 63 : level;
          if (level > 0) {
            int ilevel = level;
            if (hdr.sharpness > 0) {
              if (hdr.sharpness > 4) {
                ilevel >>= 2;
              } else {
                ilevel >>= 1;
              }

              if (ilevel > 9 - hdr.sharpness) {
                ilevel = 9 - hdr.sharpness;
              }
            }

            if (ilevel < 1) {
              ilevel = 1;
            }

            info.fInnerlevel = ilevel;
            info.fLimit = 2 * level + ilevel;
            info.hevThresh = (level >= 40) ? 2 : (level >= 15) ? 1 : 0;
          } else {
            info.fLimit = 0;  // no filtering
          }

          info.fInner = i4x4;
        }
      }
    }
  }

  bool _initFrame() {
    // Init critical function pointers and look-up tables.
    //_dspInit();
    return true;
  }

  bool _parseFrame() {
    for (_mbY = 0; _mbY < _brMbY; ++_mbY) {
      // Parse bitstream for this row.
      VP8BitReader tokenBr = _partitions[_mbY & (_numPartitions - 1)];
      for (; _mbX < _mbWidth; ++_mbX) {
        if (!_decodeMB(tokenBr)) {
          return false;
        }
      }

      /*_initScanline(); // Prepare for next scanline

      // Reconstruct, filter and emit the row.
      if (!_processRow()) {
        return false;
      }*/
    }

    return true;
  }

  bool _decodeMB(VP8BitReader br) {

  }

  // Main data source
  VP8BitReader br;

  Image output;

  // headers
  VP8FrameHeader _frameHeader = new VP8FrameHeader();
  VP8PictureHeader _picHeader = new VP8PictureHeader();
  VP8FilterHeader _filterHeader = new VP8FilterHeader();
  VP8SegmentHeader _segmentHeader = new VP8SegmentHeader();

  int _cropLeft;
  int _cropRight;
  int _cropTop;
  int _cropBottom;

  /// Width in macroblock units.
  int _mbWidth;
  /// Height in macroblock units.
  int _mbHeight;

  // Macroblock to process/filter, depending on cropping and filter_type.
  int _tlMbX; // top-left MB that must be in-loop filtered
  int _tlMbY;
  int _brMbX; // last bottom-right MB that must be decoded
  int _brMbY;

  // number of partitions.
  int _numPartitions;
  // per-partition boolean decoders.
  List<VP8BitReader> _partitions = new List<VP8BitReader>(MAX_NUM_PARTITIONS);

  // Dithering strength, deduced from decoding options
  bool _dither; // whether to use dithering or not
  VP8Random _ditheringRand; // random generator for dithering

  // dequantization (one set of DC/AC dequant factor per segment)
  List<VP8QuantMatrix> _dqm = new List<VP8QuantMatrix>(NUM_MB_SEGMENTS);

  // probabilities
  VP8Proba _probabilities;
  bool _useSkipProbabilities;
  int _skipProb;

  // Boundary data cache and persistent buffers.
  /// top intra modes values: 4 * _mbWidth
  Data.Uint8List _intraT;
  /// left intra modes values
  Data.Uint8List _intraL = new Data.Uint8List(4);

  /// uint8, segment of the currently parsed block
  int _segment;
  /// top y/u/v samples
  VP8TopSamples _yuvT;

  /// contextual macroblock info (mb_w_ + 1)
  VP8MB _mbInfo;
  /// filter strength info
  VP8FInfo _fInfo;
  /// main block for Y/U/V (size = YUV_SIZE)
  Data.Uint8List _yuvBlock;

  /// macroblock row for storing unfiltered samples
  Data.Uint8List _cacheY;
  Data.Uint8List _cacheU;
  Data.Uint8List _cacheV;
  int _cacheYStride;
  int _cacheUvStride;

  /// main memory chunk for the above data. Persistent.
  Data.Uint8List _mem;

  // Per macroblock non-persistent infos.
  /// current position, in macroblock units
  int _mbX;
  int _mbY;
  /// parsed reconstruction data
  VP8MBData _mbData;

  // Filtering side-info
  /// 0=off, 1=simple, 2=complex
  int _filterType;
  /// precalculated per-segment/type
  List<List<VP8FInfo>> _fStrengths;

  // Alpha
  /// alpha-plane decoder object
  WebPAlpha _alpha;
  /// compressed alpha data (if present)
  Data.Uint8List _alphaData;
  /// true if alpha_data_ is decoded in alpha_plane_
  int _isAlphaDecoded;
  /// output. Persistent, contains the whole data.
  Data.Uint8List _alphaPlane;

  // extensions
  int _layerColorspace;
  /// compressed layer data (if present)
  Data.Uint8List _layerData;

  static int _clip(int v, int M) {
    return v < 0 ? 0 : v > M ? M : v;
  }

  static const List COEFFS_PROBA_0 = const [
  const [ const [ const [ 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 ],
      const [ 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 ],
      const [ 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 ]
    ],
    const [ const [ 253, 136, 254, 255, 228, 219, 128, 128, 128, 128, 128 ],
      const [ 189, 129, 242, 255, 227, 213, 255, 219, 128, 128, 128 ],
      const [ 106, 126, 227, 252, 214, 209, 255, 255, 128, 128, 128 ]
    ],
    const [ const [ 1, 98, 248, 255, 236, 226, 255, 255, 128, 128, 128 ],
      const [ 181, 133, 238, 254, 221, 234, 255, 154, 128, 128, 128 ],
      const [ 78, 134, 202, 247, 198, 180, 255, 219, 128, 128, 128 ],
    ],
    const [ const [ 1, 185, 249, 255, 243, 255, 128, 128, 128, 128, 128 ],
      const [ 184, 150, 247, 255, 236, 224, 128, 128, 128, 128, 128 ],
      const [ 77, 110, 216, 255, 236, 230, 128, 128, 128, 128, 128 ],
    ],
    const [ const [ 1, 101, 251, 255, 241, 255, 128, 128, 128, 128, 128 ],
      const [ 170, 139, 241, 252, 236, 209, 255, 255, 128, 128, 128 ],
      const [ 37, 116, 196, 243, 228, 255, 255, 255, 128, 128, 128 ]
    ],
    const [ const [ 1, 204, 254, 255, 245, 255, 128, 128, 128, 128, 128 ],
      const [ 207, 160, 250, 255, 238, 128, 128, 128, 128, 128, 128 ],
      const [ 102, 103, 231, 255, 211, 171, 128, 128, 128, 128, 128 ]
    ],
    const [ const [ 1, 152, 252, 255, 240, 255, 128, 128, 128, 128, 128 ],
      const [ 177, 135, 243, 255, 234, 225, 128, 128, 128, 128, 128 ],
      const [ 80, 129, 211, 255, 194, 224, 128, 128, 128, 128, 128 ]
    ],
    const [ const [ 1, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 ],
      const [ 246, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 ],
      const [ 255, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 ]
    ]
  ],
  const [ const [ const [ 198, 35, 237, 223, 193, 187, 162, 160, 145, 155, 62 ],
      const [ 131, 45, 198, 221, 172, 176, 220, 157, 252, 221, 1 ],
      const [ 68, 47, 146, 208, 149, 167, 221, 162, 255, 223, 128 ]
    ],
    const [ const [ 1, 149, 241, 255, 221, 224, 255, 255, 128, 128, 128 ],
      const [ 184, 141, 234, 253, 222, 220, 255, 199, 128, 128, 128 ],
      const [ 81, 99, 181, 242, 176, 190, 249, 202, 255, 255, 128 ]
    ],
    const [ const [ 1, 129, 232, 253, 214, 197, 242, 196, 255, 255, 128 ],
      const [ 99, 121, 210, 250, 201, 198, 255, 202, 128, 128, 128 ],
      const [ 23, 91, 163, 242, 170, 187, 247, 210, 255, 255, 128 ]
    ],
    const [ const [ 1, 200, 246, 255, 234, 255, 128, 128, 128, 128, 128 ],
      const [ 109, 178, 241, 255, 231, 245, 255, 255, 128, 128, 128 ],
      const [ 44, 130, 201, 253, 205, 192, 255, 255, 128, 128, 128 ]
    ],
    const [ const [ 1, 132, 239, 251, 219, 209, 255, 165, 128, 128, 128 ],
      const [ 94, 136, 225, 251, 218, 190, 255, 255, 128, 128, 128 ],
      const [ 22, 100, 174, 245, 186, 161, 255, 199, 128, 128, 128 ]
    ],
    const [ const [ 1, 182, 249, 255, 232, 235, 128, 128, 128, 128, 128 ],
      const [ 124, 143, 241, 255, 227, 234, 128, 128, 128, 128, 128 ],
      const [ 35, 77, 181, 251, 193, 211, 255, 205, 128, 128, 128 ]
    ],
    const [ const [ 1, 157, 247, 255, 236, 231, 255, 255, 128, 128, 128 ],
      const [ 121, 141, 235, 255, 225, 227, 255, 255, 128, 128, 128 ],
      const [ 45, 99, 188, 251, 195, 217, 255, 224, 128, 128, 128 ]
    ],
    const [ const [ 1, 1, 251, 255, 213, 255, 128, 128, 128, 128, 128 ],
      const [ 203, 1, 248, 255, 255, 128, 128, 128, 128, 128, 128 ],
      const [ 137, 1, 177, 255, 224, 255, 128, 128, 128, 128, 128 ]
    ]
  ],
  const [ const [ const [ 253, 9, 248, 251, 207, 208, 255, 192, 128, 128, 128 ],
      const [ 175, 13, 224, 243, 193, 185, 249, 198, 255, 255, 128 ],
      const [ 73, 17, 171, 221, 161, 179, 236, 167, 255, 234, 128 ]
    ],
    const [ const [ 1, 95, 247, 253, 212, 183, 255, 255, 128, 128, 128 ],
      const [ 239, 90, 244, 250, 211, 209, 255, 255, 128, 128, 128 ],
      const [ 155, 77, 195, 248, 188, 195, 255, 255, 128, 128, 128 ]
    ],
    const [ const [ 1, 24, 239, 251, 218, 219, 255, 205, 128, 128, 128 ],
      const [ 201, 51, 219, 255, 196, 186, 128, 128, 128, 128, 128 ],
      const [ 69, 46, 190, 239, 201, 218, 255, 228, 128, 128, 128 ]
    ],
    const [ const [ 1, 191, 251, 255, 255, 128, 128, 128, 128, 128, 128 ],
      const [ 223, 165, 249, 255, 213, 255, 128, 128, 128, 128, 128 ],
      const [ 141, 124, 248, 255, 255, 128, 128, 128, 128, 128, 128 ]
    ],
    const [ const [ 1, 16, 248, 255, 255, 128, 128, 128, 128, 128, 128 ],
      const [ 190, 36, 230, 255, 236, 255, 128, 128, 128, 128, 128 ],
      const [ 149, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 ]
    ],
    const [ const [ 1, 226, 255, 128, 128, 128, 128, 128, 128, 128, 128 ],
      const [ 247, 192, 255, 128, 128, 128, 128, 128, 128, 128, 128 ],
      const [ 240, 128, 255, 128, 128, 128, 128, 128, 128, 128, 128 ]
    ],
    const [ const [ 1, 134, 252, 255, 255, 128, 128, 128, 128, 128, 128 ],
      const [ 213, 62, 250, 255, 255, 128, 128, 128, 128, 128, 128 ],
      const [ 55, 93, 255, 128, 128, 128, 128, 128, 128, 128, 128 ]
    ],
    const [ const [ 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 ],
      const [ 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 ],
      const [ 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 ]
    ]
  ],
  const [ const [ const [ 202, 24, 213, 235, 186, 191, 220, 160, 240, 175, 255 ],
      const [ 126, 38, 182, 232, 169, 184, 228, 174, 255, 187, 128 ],
      const [ 61, 46, 138, 219, 151, 178, 240, 170, 255, 216, 128 ]
    ],
    const [ const [ 1, 112, 230, 250, 199, 191, 247, 159, 255, 255, 128 ],
      const [ 166, 109, 228, 252, 211, 215, 255, 174, 128, 128, 128 ],
      const [ 39, 77, 162, 232, 172, 180, 245, 178, 255, 255, 128 ]
    ],
    const [ const [ 1, 52, 220, 246, 198, 199, 249, 220, 255, 255, 128 ],
      const [ 124, 74, 191, 243, 183, 193, 250, 221, 255, 255, 128 ],
      const [ 24, 71, 130, 219, 154, 170, 243, 182, 255, 255, 128 ]
    ],
    const [ const [ 1, 182, 225, 249, 219, 240, 255, 224, 128, 128, 128 ],
      const [ 149, 150, 226, 252, 216, 205, 255, 171, 128, 128, 128 ],
      const [ 28, 108, 170, 242, 183, 194, 254, 223, 255, 255, 128 ]
    ],
    const [ const [ 1, 81, 230, 252, 204, 203, 255, 192, 128, 128, 128 ],
      const [ 123, 102, 209, 247, 188, 196, 255, 233, 128, 128, 128 ],
      const [ 20, 95, 153, 243, 164, 173, 255, 203, 128, 128, 128 ]
    ],
    const [ const [ 1, 222, 248, 255, 216, 213, 128, 128, 128, 128, 128 ],
      const [ 168, 175, 246, 252, 235, 205, 255, 255, 128, 128, 128 ],
      const [ 47, 116, 215, 255, 211, 212, 255, 255, 128, 128, 128 ]
    ],
    const [ const [ 1, 121, 236, 253, 212, 214, 255, 255, 128, 128, 128 ],
      const [ 141, 84, 213, 252, 201, 202, 255, 219, 128, 128, 128 ],
      const [ 42, 80, 160, 240, 162, 185, 255, 205, 128, 128, 128 ]
    ],
    const [ const [ 1, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 ],
      const [ 244, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 ],
      const [ 238, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 ]
    ]
  ] ];


  static const List COEFFS_UPDATE_PROBA = const [
    const [ const [ const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 176, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 223, 241, 252, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 249, 253, 253, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 244, 252, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 234, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 246, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 239, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 254, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 248, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 251, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 251, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 254, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 254, 253, 255, 254, 255, 255, 255, 255, 255, 255 ],
      const [ 250, 255, 254, 255, 254, 255, 255, 255, 255, 255, 255 ],
      const [ 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ]
    ],
    const [ const [ const [ 217, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 225, 252, 241, 253, 255, 255, 254, 255, 255, 255, 255 ],
      const [ 234, 250, 241, 250, 253, 255, 253, 254, 255, 255, 255 ]
    ],
    const [ const [ 255, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 223, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 238, 253, 254, 254, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 248, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 249, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 253, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 247, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 254, 253, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ]
    ],
    const [ const [ const [ 186, 251, 250, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 234, 251, 244, 254, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 251, 251, 243, 253, 254, 255, 254, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 236, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 251, 253, 253, 254, 254, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 254, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 254, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ]
    ],
    const [ const [ const [ 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 250, 254, 252, 254, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 248, 254, 249, 253, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 253, 253, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 246, 253, 253, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 252, 254, 251, 254, 254, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 254, 252, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 248, 254, 253, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 253, 255, 254, 254, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 251, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 245, 251, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 253, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 251, 253, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 252, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 249, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 255, 253, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ],
    const [ const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ],
      const [ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ]
    ] ] ];

  // Paragraph 14.1
  static const List<int> DC_TABLE = const [ // uint8
      4,     5,   6,   7,   8,   9,  10,  10,
      11,   12,  13,  14,  15,  16,  17,  17,
      18,   19,  20,  20,  21,  21,  22,  22,
      23,   23,  24,  25,  25,  26,  27,  28,
      29,   30,  31,  32,  33,  34,  35,  36,
      37,   37,  38,  39,  40,  41,  42,  43,
      44,   45,  46,  46,  47,  48,  49,  50,
      51,   52,  53,  54,  55,  56,  57,  58,
      59,   60,  61,  62,  63,  64,  65,  66,
      67,   68,  69,  70,  71,  72,  73,  74,
      75,   76,  76,  77,  78,  79,  80,  81,
      82,   83,  84,  85,  86,  87,  88,  89,
      91,   93,  95,  96,  98, 100, 101, 102,
      104, 106, 108, 110, 112, 114, 116, 118,
      122, 124, 126, 128, 130, 132, 134, 136,
      138, 140, 143, 145, 148, 151, 154, 157];

  static const List<int> AC_TABLE = const [ // uint16
       4,     5,   6,   7,   8,   9,  10,  11,
       12,   13,  14,  15,  16,  17,  18,  19,
       20,   21,  22,  23,  24,  25,  26,  27,
       28,   29,  30,  31,  32,  33,  34,  35,
       36,   37,  38,  39,  40,  41,  42,  43,
       44,   45,  46,  47,  48,  49,  50,  51,
       52,   53,  54,  55,  56,  57,  58,  60,
       62,   64,  66,  68,  70,  72,  74,  76,
       78,   80,  82,  84,  86,  88,  90,  92,
       94,   96,  98, 100, 102, 104, 106, 108,
       110, 112, 114, 116, 119, 122, 125, 128,
       131, 134, 137, 140, 143, 146, 149, 152,
       155, 158, 161, 164, 167, 170, 173, 177,
       181, 185, 189, 193, 197, 201, 205, 209,
       213, 217, 221, 225, 229, 234, 239, 245,
       249, 254, 259, 264, 269, 274, 279, 284];

  /**
   * FILTER_EXTRA_ROWS = How many extra lines are needed on the MB boundary
   * for caching, given a filtering level.
   * Simple filter:  up to 2 luma samples are read and 1 is written.
   * Complex filter: up to 4 luma samples are read and 3 are written. Same for
   *               U/V, so it's 8 samples total (because of the 2x upsampling).
   */
  static const List<int> FILTER_EXTRA_ROWS = const [ 0, 2, 8 ];

  static const int VP8_SIGNATURE = 0x2a019d;

  static const int MB_FEATURE_TREE_PROBS = 3;
  static const int NUM_MB_SEGMENTS = 4;
  static const int NUM_REF_LF_DELTAS = 4;
  static const int NUM_MODE_LF_DELTAS = 4;    // I4x4, ZERO, *, SPLIT
  static const int MAX_NUM_PARTITIONS = 8;
  // Probabilities
  static const int NUM_TYPES = 4;
  static const int NUM_BANDS = 8;
  static const int NUM_CTX = 3;
  static const int NUM_PROBAS = 11;
}

