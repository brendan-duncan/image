part of image;

/**
 * WebP lossy format.
 */
class Vp8 {
  Arc.InputStream input;
  WebPData webp;

  Vp8(Arc.InputStream input, this.webp) :
    this.input = input;

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

    // Finish setting up the decoding parameter.
    if (!_enterCritical()) {
      return null;
    }

    // Will allocate memory and prepare everything.
    if (!_initFrame()) {
      return null;
    }

    // Main decoding loop
    if (!_parseFrame()) {
      return null;
    }

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
    //_dspInit();  // Init critical function pointers and look-up tables.
    return true;
  }

  bool _parseFrame() {
    /*for (_mbY = 0; _mbY < _brMbY; ++_mbY) {
      // Parse bitstream for this row.
      VP8BitReader tokenBr = _parts[_mbY & (_numParts_ - 1)];
      for (; _mbX < _mbW; ++_mbX) {
        if (!_decodeMB(tokenBr)) {
          return false;
        }
      }

      _initScanline(); // Prepare for next scanline

      // Reconstruct, filter and emit the row.
      if (!_processRow()) {
        return false;
      }
    }

    // Finish
    // WEBP_EXPERIMENTAL_FEATURES
    if (_layerDataSize > 0) {
      if (!_decodeLayer()) {
        return false;
      }
    }*/

    return true;
  }

  // Main data source
  /*VP8BitReader br;

  // headers
  VP8FrameHeader _frameHeader;
  VP8PictureHeader _pictureHeader;
  VP8FilterHeader  _filterHeader;
  VP8SegmentHeader _segmentHeader;

  // dimension, in macroblock units.
  int _macroblockWidth;
  int _macroblockHeight;

  // Macroblock to process/filter, depending on cropping and filter_type.
  int _tlMacroblockX; // top-left MB that must be in-loop filtered
  int _tlMacroblockY;
  int _brMacroblockX; // last bottom-right MB that must be decoded
  int _brMacroblockY;

  // number of partitions.
  int _numPartitions;
  // per-partition boolean decoders.
  List<VP8BitReader> _partitions = new List<VP8BitReader>(MAX_NUM_PARTITIONS);

  // Dithering strength, deduced from decoding options
  bool _dither; // whether to use dithering or not
  VP8Random _ditheringRand; // random generator for dithering

  // dequantization (one set of DC/AC dequant factor per segment)
  List<VP8QuantMatrix> _dqm = new List<NUM_MB_SEGMENTS>;

  // probabilities
  VP8Probabilities _probabilities;
  bool _useSkipProbabilities;
  int _skipProb;

  // Boundary data cache and persistent buffers.
  uint8_t* intra_t_;      // top intra modes values: 4 * mb_w_
  uint8_t  intra_l_[4];   // left intra modes values

  uint8_t segment_;       // segment of the currently parsed block
  VP8TopSamples* yuv_t_;  // top y/u/v samples

  VP8MB* mb_info_;        // contextual macroblock info (mb_w_ + 1)
  VP8FInfo* f_info_;      // filter strength info
  uint8_t* yuv_b_;        // main block for Y/U/V (size = YUV_SIZE)

  uint8_t* cache_y_;      // macroblock row for storing unfiltered samples
  uint8_t* cache_u_;
  uint8_t* cache_v_;
  int cache_y_stride_;
  int cache_uv_stride_;

  // main memory chunk for the above data. Persistent.
  void* mem_;
  size_t mem_size_;

  // Per macroblock non-persistent infos.
  int _mbX, _mbY;       // current position, in macroblock units
  VP8MBData _mbData;    // parsed reconstruction data

  // Filtering side-info
  int _filterType; // 0=off, 1=simple, 2=complex
  List<VP8FInfo> _fstrengths = new List<VP8FInfo>(NUM_MB_SEGMENTS * 2);  // precalculated per-segment/type

  // Alpha
  WebPAlpha _alpha;  // alpha-plane decoder object
  Data.Uint8List _alphaData;     // compressed alpha data (if present)
  int _isAlphaDecoded;  // true if alpha_data_ is decoded in alpha_plane_
  Data.Uint8List _alphaPlane; // output. Persistent, contains the whole data.

  // extensions
  int _layerColorspace;
  Data.Uint8List _layerData;   // compressed layer data (if present)
  */
  static const int VP8_SIGNATURE = 0x2a019d;
}
