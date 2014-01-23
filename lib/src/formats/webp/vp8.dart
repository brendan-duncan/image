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
    if (!decodeHeader()) {
      return null;
    }

    _picHeader.width = webp.width;
    _picHeader.height = webp.height;
    _picHeader.xscale = (webp.width >> 8) >> 6;
    _picHeader.yscale = (webp.height >> 8) >> 6;

    _mbWidth = (webp.width + 15) >> 4;
    _mbHeight = (webp.height + 15) >> 4;

    _probabilities = new VP8Proba();

    _segmentHeader.useSegment = false;
    _segmentHeader.updateMap = false;
    _segmentHeader.absoluteDelta = true;
    _segmentHeader.quantizer.fillRange(0, _segmentHeader.quantizer.length, 0);
    _segmentHeader.filterStrength.fillRange(0,
        _segmentHeader.filterStrength.length, 0);
    _segment = 0;

    br = new VP8BitReader(input.subset(null, _frameHeader.partitionLength));
    input.skip(_frameHeader.partitionLength);

    _picHeader.colorspace = br.getBit();
    _picHeader.clampType = br.getBit();

    /*if (!_parseSegmentHeader(_segmentHeader, _probabilities)) {
      return null;
    }

    // Filter specs
    if (!_parseFilterHeader()) {
      return null;
    }

    if (!_parsePartitions(input)) {
      return null;
    }

    // quantizer change
    _parseQuant();

    // Frame buffer marking
    br.getBit();   // ignore the value of update_proba_

    _parseProba();*/

    // Finish setting up the decoding parameter.
    /*if (!_enterCritical()) {
      return null;
    }

    // Will allocate memory and prepare everything.
    if (!_initFrame()) {
      return null;
    }

    // Main decoding loop
    if (!_parseFrame()) {
      return null;
    }*/

    Image image = new Image(webp.width, webp.height);

    return image;
  }

  /**
   * Finish setting up the decoding parameter once user's setup() is called.
   */
  bool _enterCritical() {
    // Define the area where we can skip in-loop filtering, in case of cropping.
    //
    // 'Simple' filter reads two luma samples outside of the macroblock
    // and filters one. It doesn't filter the chroma samples. Hence, we can
    // avoid doing the in-loop filtering before crop_top/crop_left position.
    // For the 'Complex' filter, 3 samples are read and up to 3 are filtered.
    // Means: there's a dependency chain that goes all the way up to the
    // top-left corner of the picture (MB #0). We must filter all the previous
    // macroblocks.
    /*{
      final int extra_pixels = kFilterExtraRows[dec->filter_type_];
      if (dec->filter_type_ == 2) {
        // For complex filter, we need to preserve the dependency chain.
        dec->tl_mb_x_ = 0;
        dec->tl_mb_y_ = 0;
      } else {
        // For simple filter, we can filter only the cropped region.
        // We include 'extra_pixels' on the other side of the boundary, since
        // vertical or horizontal filtering of the previous macroblock can
        // modify some abutting pixels.
        dec->tl_mb_x_ = (io->crop_left - extra_pixels) >> 4;
        dec->tl_mb_y_ = (io->crop_top - extra_pixels) >> 4;
        if (dec->tl_mb_x_ < 0) dec->tl_mb_x_ = 0;
        if (dec->tl_mb_y_ < 0) dec->tl_mb_y_ = 0;
      }
      // We need some 'extra' pixels on the right/bottom.
      dec->br_mb_y_ = (io->crop_bottom + 15 + extra_pixels) >> 4;
      dec->br_mb_x_ = (io->crop_right + 15 + extra_pixels) >> 4;
      if (dec->br_mb_x_ > dec->mb_w_) {
        dec->br_mb_x_ = dec->mb_w_;
      }
      if (dec->br_mb_y_ > dec->mb_h_) {
        dec->br_mb_y_ = dec->mb_h_;
      }
    }
    _precomputeFilterStrengths();*/
    return true;
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

  // headers
  VP8FrameHeader _frameHeader = new VP8FrameHeader();
  VP8PictureHeader _picHeader = new VP8PictureHeader();
  VP8FilterHeader  _filterHeader = new VP8FilterHeader();
  VP8SegmentHeader _segmentHeader = new VP8SegmentHeader();

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
  List<VP8QuantMatrix> dqm = new List<VP8QuantMatrix>(NUM_MB_SEGMENTS);

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
  int _mbX, _mbY;
  /// parsed reconstruction data
  VP8MBData _mbData;

  // Filtering side-info
  /// 0=off, 1=simple, 2=complex
  int _filterType;
  /// precalculated per-segment/type
  List<VP8FInfo> _fStrengths = new List<VP8FInfo>(NUM_MB_SEGMENTS * 2);

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

class VP8FrameHeader {
  bool keyFrame;
  int profile; // uint8
  int show; // uint8
  int partitionLength; // uint32
}

class VP8PictureHeader {
  int width; // uint16
  int height; // uint16
  int xscale; // uint8
  int yscale; // uint8
  int colorspace; // uint8, 0 = YCbCr
  int clampType; // uint8
}

/**
 * Segment features
 */
class VP8SegmentHeader {
  bool useSegment;
  bool updateMap; // whether to update the segment map or not
  bool absoluteDelta; // absolute or delta values for quantizer and filter
  /// quantization changes
  Data.Int8List quantizer = new Data.Int8List(VP8.NUM_MB_SEGMENTS);
  /// filter strength for segments
  Data.Int8List filterStrength = new Data.Int8List(VP8.NUM_MB_SEGMENTS);
}

/**
 * All the probas associated to one band
 */
class VP8BandProbas {
  Data.Uint8List probas = new Data.Uint8List(VP8.NUM_PROBAS * VP8.NUM_CTX);
}

/**
 * Struct collecting all frame-persistent probabilities.
 */
class VP8Proba {
  Data.Uint8List segments = new Data.Uint8List(VP8.MB_FEATURE_TREE_PROBS);
  /// Type: 0:Intra16-AC  1:Intra16-DC   2:Chroma   3:Intra4
  List<List<VP8BandProbas>> bands = new List(VP8.NUM_TYPES);

  VP8Proba() {
    for (int i = 0; i < VP8.NUM_TYPES; ++i) {
      bands[i] = new List<VP8BandProbas>(VP8.NUM_BANDS);
      for (int j = 0; j < VP8.NUM_BANDS; ++j) {
        bands[i][j] = new VP8BandProbas();
      }
    }

    segments.fillRange(0, segments.length, 255);
  }
}

/**
 * Filter parameters
 */
class VP8FilterHeader {
  bool simple; // 0=complex, 1=simple
  int level; // [0..63]
  int sharpness; // [0..7]
  int useLfDelta;
  Data.Int32List refLfDelta = new Data.Int32List(VP8.NUM_REF_LF_DELTAS);
  Data.Int32List modeLfDelta = new Data.Int32List(VP8.NUM_MODE_LF_DELTAS);
}

//------------------------------------------------------------------------------
// Informations about the macroblocks.

/**
 * filter specs
 */
class VP8FInfo {
  int fLimit; // uint8_t, filter limit in [3..189], or 0 if no filtering
  int fInnerlevel; // uint8_t, inner limit in [1..63]
  int fInner; // uint8_t, do inner filtering?
  int hevThresh; // uint8_t, high edge variance threshold in [0..2]
}

/**
 * Top/Left Contexts used for syntax-parsing
 */
class VP8MB{
  int nz; // uint8_t, non-zero AC/DC coeffs (4bit for luma + 4bit for chroma)
  int nzDc; // uint8_t, non-zero DC coeff (1bit)
}

/**
 * Dequantization matrices
 */
class VP8QuantMatrix {
  Data.Int32List y1Mat = new Data.Int32List(2);
  Data.Int32List y2Mat = new Data.Int32List(2);
  Data.Int32List uvMat = new Data.Int32List(2);

  int uvQuant; // U/V quantizer value
  int dither; // dithering amplitude (0 = off, max=255)
}

/**
 * Data needed to reconstruct a macroblock
 */
class VP8MBData {
  /// 384 coeffs = (16+4+4) * 4*4
  Data.Int16List coeffs = new Data.Int16List(384);
  bool isIntra4x4; // true if intra4x4
  /// one 16x16 mode (#0) or sixteen 4x4 modes
  Data.Uint8List imodes = new Data.Uint8List(16);
  /// chroma prediction mode
  int uvmode;
  // bit-wise info about the content of each sub-4x4 blocks (in decoding order).
  // Each of the 4x4 blocks for y/u/v is associated with a 2b code according to:
  //   code=0 -> no coefficient
  //   code=1 -> only DC
  //   code=2 -> first three coefficients are non-zero
  //   code=3 -> more than three coefficients are non-zero
  // This allows to call specialized transform functions.
  int nonZeroY;
  int nonZeroUV;
  /// uint8_t, local dithering strength (deduced from non_zero_*)
  int dither;
}

/**
 * Saved top samples, per macroblock. Fits into a cache-line.
 */
class VP8TopSamples {
  Data.Uint8List y = new Data.Uint8List(16);
  Data.Uint8List u = new Data.Uint8List(8);
  Data.Uint8List v = new Data.Uint8List(8);
}

class VP8Random {
  int _index1;
  int _index2;
  Data.Uint32List _table = new Data.Uint32List(RANDOM_TABLE_SIZE);
  int _amplitude;

  /**
   * Initializes random generator with an amplitude 'dithering' in range [0..1].
   */
  VP8Random(double dithering) {
    _table.setRange(0, RANDOM_TABLE_SIZE, _RANDOM_TABLE);
    _index1 = 0;
    _index2 = 31;
    _amplitude = (dithering < 0.0) ? 0 :
                 (dithering > 1.0) ? (1 << RANDOM_DITHER_FIX) :
                 ((1 << RANDOM_DITHER_FIX) * dithering).toInt();
  }

  /**
   * Returns a centered pseudo-random number with 'num_bits' amplitude.
   * (uses D.Knuth's Difference-based random generator).
   * 'amp' is in RANDOM_DITHER_FIX fixed-point precision.
   */
  int randomBits2(int numBits, int amp) {
    int diff = _table[_index1] - _table[_index2];
    if (diff < 0) {
      diff += (1 << 31);
    }

    _table[_index1] = diff;

    if (++_index1 == RANDOM_TABLE_SIZE) {
      _index1 = 0;
    }
    if (++_index2 == RANDOM_TABLE_SIZE) {
      _index2 = 0;
    }

    // sign-extend, 0-center
    diff = (diff << 1) >> (32 - numBits);
    // restrict range
    diff = (diff * amp) >> RANDOM_DITHER_FIX;
    // shift back to 0.5-center
    diff += 1 << (numBits - 1);

    return diff;
  }

  int randomBits(int numBits) {
    return randomBits2(numBits, _amplitude);
  }

  /// fixed-point precision for dithering
  static const int RANDOM_DITHER_FIX = 8;
  static const int RANDOM_TABLE_SIZE = 55;

  // 31b-range values
  static const List<int> _RANDOM_TABLE = const [
    0x0de15230, 0x03b31886, 0x775faccb, 0x1c88626a, 0x68385c55, 0x14b3b828,
    0x4a85fef8, 0x49ddb84b, 0x64fcf397, 0x5c550289, 0x4a290000, 0x0d7ec1da,
    0x5940b7ab, 0x5492577d, 0x4e19ca72, 0x38d38c69, 0x0c01ee65, 0x32a1755f,
    0x5437f652, 0x5abb2c32, 0x0faa57b1, 0x73f533e7, 0x685feeda, 0x7563cce2,
    0x6e990e83, 0x4730a7ed, 0x4fc0d9c6, 0x496b153c, 0x4f1403fa, 0x541afb0c,
    0x73990b32, 0x26d7cb1c, 0x6fcc3706, 0x2cbb77d8, 0x75762f2a, 0x6425ccdd,
    0x24b35461, 0x0a7d8715, 0x220414a8, 0x141ebf67, 0x56b41583, 0x73e502e3,
    0x44cab16f, 0x28264d42, 0x73baaefb, 0x0a50ebed, 0x1d6ab6fb, 0x0d3ad40b,
    0x35db3b68, 0x2b081e83, 0x77ce6b95, 0x5181e5f0, 0x78853bbc, 0x009f9494,
    0x27e5ed3c];
}
