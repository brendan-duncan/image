part of image;


// This JPEG decoder was ported from Rich Geldreich's public domain JPGD decoder
// (https://code.google.com/archive/p/jpeg-compressor).
class JpegDecoder extends Decoder {
  JpegInfo info;
  JpegJfif jfif;
  JpegAdobe adobe;

  /**
   * Is the given file a valid JPEG image?
   */
  bool isValidFile(List<int> data) {
    _stream = new InputBuffer(data, bigEndian: true);

    int marker = _next_marker();
    if (marker != M_SOI) {
      _stream = null;
      return false;
    }

    bool hasSOF = false;
    bool hasSOS = false;

    marker = _next_marker();

    while (marker != M_EOI && !_stream.isEOS) { // EOI (End of image)
      _skip_variable_marker();
      switch (marker) {
        case M_SOF0: // SOF0 (Start of Frame, Baseline DCT)
        case M_SOF1: // SOF1 (Start of Frame, Extended DCT)
        case M_SOF2: // SOF2 (Start of Frame, Progressive DCT)
          hasSOF = true;
          break;
        case M_SOS: // SOS (Start of Scan)
          hasSOS = true;
          break;
        default:
      }
      if (hasSOF && hasSOS) {
        break;
      }
      marker = _next_marker();
    }

    _stream = null;
    return hasSOF && hasSOS;
  }

  DecodeInfo startDecode(List<int> data) {
    _decode_init(new InputBuffer(data, bigEndian: true));
    return info;
  }

  int numFrames() => info == null ? 0 : info.numFrames;

  Image decodeFrame(int frame) {
    if (_stream == null) {
      return null;
    }
    return _decodeImage();
  }

  Image decodeImage(List<int> data, {int frame: 0}) {
    startDecode(data);
    return _decodeImage();
  }

  Animation decodeAnimation(List<int> data) {
    Image image = decodeImage(data);
    if (image == null) {
      return null;
    }

    Animation anim = new Animation();
    anim.width = image.width;
    anim.height = image.height;
    anim.addFrame(image);

    return anim;
  }

  Image _decodeImage() {
    begin();
    Image image = new Image(_image_x_size, _image_y_size);
    int y = 0;
    while (true) {
      if (decode() != 0) {
        break;
      }
      int pi = 0;
      if (num_components == 3) {
        for (int x = 0; x < _image_x_size; ++x, pi += 4) {
          image.setPixel(x, y, Color.fromRgb(scanline[pi],
              scanline[pi + 1], scanline[pi + 2]));
        }
        y++;
      } else if (num_components == 1) {
        for (int x = 0; x < _image_x_size; ++x, pi++) {
          int g = scanline[pi];
          image.setPixel(x, y, Color.fromRgb(g, g, g));
        }
        y++;
      }
    }
    return image;
  }

  static const int FAILED = -1;
  static const int DONE = 1;
  static const int OKAY = 0;

  // JPEG specific error codes
  static const int BAD_DHT_COUNTS = -200;
  static const int BAD_DHT_INDEX  = -201;
  static const int BAD_DHT_MARKER = -202;
  static const int BAD_DQT_MARKER = -203;
  static const int BAD_DQT_TABLE = -204;
  static const int BAD_PRECISION = -205;
  static const int BAD_HEIGHT = -206;
  static const int BAD_WIDTH  = -207;
  static const int TOO_MANY_COMPONENTS = -208;
  static const int BAD_SOF_LENGTH = -209;
  static const int BAD_VARIABLE_MARKER = -210;
  static const int BAD_DRI_LENGTH = -211;
  static const int BAD_SOS_LENGTH = -212;
  static const int BAD_SOS_COMP_ID = -213;
  static const int W_EXTRA_BYTES_BEFORE_MARKER = -214;
  static const int NO_ARITHMITIC_SUPPORT = -215;
  static const int UNEXPECTED_MARKER = -216;
  static const int NOT_JPEG = -217;
  static const int UNSUPPORTED_MARKER = -218;
  static const int BAD_DQT_LENGTH = -219;
  static const int TOO_MANY_BLOCKS = -221;
  static const int UNDEFINED_QUANT_TABLE = -222;
  static const int UNDEFINED_HUFF_TABLE = -223;
  static const int NOT_SINGLE_SCAN = -224;
  static const int UNSUPPORTED_COLORSPACE = -225;
  static const int UNSUPPORTED_SAMP_FACTORS = -226;
  static const int DECODE_ERROR = -227;
  static const int BAD_RESTART_MARKER = -228;
  static const int ASSERTION_ERROR = -229;
  static const int BAD_SOS_SPECTRAL = -230;
  static const int BAD_SOS_SUCCESSIVE = -231;
  static const int STREAM_READ = -232;
  static const int NOTENOUGHMEM = -233;

  int get width => _image_x_size;

  int get height => _image_y_size;

  int get num_components => _comps_in_frame;

  int get bytes_per_pixel => _dest_bytes_per_pixel;

  int get bytes_per_scanline => _dest_bytes_per_pixel * _image_x_size;

  int get error_code => _error_code;

  Uint8List scanline;

  int scanline_length = 0;

  int begin() {
    if (_ready_flag) {
      return OKAY;
    }
    if (_error_code != 0) {
      return FAILED;
    }

    _decode_start();
    _ready_flag = true;
    scanline = null;
    scanline_length = 0;

    return OKAY;
  }

  int decode() {
    if ((_error_code != 0) || (_ready_flag == 0)) {
      return FAILED;
    }

    if (_total_lines_left == 0) {
      return DONE;
    }

    if (_mcu_lines_left == 0) {
      if (_progressive_flag != 0) {
        _load_next_row();
      } else {
        _decode_next_row();
      }

      // Find the EOI marker if that was the last row.
      if (_total_lines_left <= _max_mcu_y_size) {
        //find_eoi();
      }

      _mcu_lines_left = _max_mcu_y_size;
    }

    if (_freq_domain_chroma_upsample) {
      _expanded_convert();
      scanline = _scan_line_0;
    } else {
      switch (_scan_type) {
        case _YH2V2:
          if ((_mcu_lines_left & 1) == 0) {
            _H2V2Convert();
            scanline = _scan_line_0;
          } else {
            scanline = _scan_line_1;
          }
          break;
        case _YH2V1:
          _H2V1Convert();
          scanline = _scan_line_0;
          break;
        case _YH1V2:
          if ((_mcu_lines_left & 1) == 0) {
            _H1V2Convert();
            scanline = _scan_line_0;
          } else {
            scanline = _scan_line_1;
          }
          break;
        case _YH1V1:
          _H1V1Convert();
          scanline = _scan_line_0;
          break;
        case _GRAYSCALE:
          _gray_convert();
          scanline = _scan_line_0;
          break;
      }
    }

    scanline_length = _real_dest_bytes_per_scan_line;
    _mcu_lines_left--;
    _total_lines_left--;

    return OKAY;
  }

  void _decode_init(InputBuffer stream) {
    _init(stream);
    _locate_sof_marker();
  }

  // Y (1 block per MCU) to 8-bit grayscale
  void _gray_convert() {
    int row = _max_mcu_y_size - _mcu_lines_left;
    Uint8List d = _scan_line_0;
    int di = 0;
    Uint8List s = _sample_buf;
    int si = row * 8;

    for (int i = _max_mcus_per_row; i > 0; i--) {
      d[di] = s[si];
      d[di + 1] = s[si + 1];
      d[di + 2] = s[si + 2];
      d[di + 3] = s[si + 3];
      d[di + 4] = s[si + 4];
      d[di + 5] = s[si + 5];
      d[di + 6] = s[si + 6];
      d[di + 7] = s[si + 7];
      si += 64;
      di += 8;
    }
  }

  // YCbCr H1V1 (1x1:1:1, 3 m_blocks per MCU) to 24-bit RGB
  void _H1V1Convert() {
    int row = _max_mcu_y_size - _mcu_lines_left;
    Uint8List d = _scan_line_0;
    int di = 0;
    Uint8List s = _sample_buf;
    int si = row * 8;

    for (int i = _max_mcus_per_row; i > 0; i--) {
      for (int j = 0; j < 8; j++) {
        int y = s[si + j];
        int cb = s[si + 64 + j];
        int cr = s[si + 128 + j];

        d[di + 0] = _clamp(y + _crr[cr]);
        d[di + 1] = _clamp(y + ((_crg[cr] + _cbg[cb]) >> 16));
        d[di + 2] = _clamp(y + _cbb[cb]);
        d[di + 3] = 255;

        di += 4;
      }

      si += 64 * 3;
    }
  }

  // YCbCr H2V1 (1x2:1:1, 4 m_blocks per MCU) to 24-bit RGB
  void _H1V2Convert() {
    int row = _max_mcu_y_size - _mcu_lines_left;
    Uint8List d0 = _scan_line_0;
    int d0i = 0;
    Uint8List d1 = _scan_line_1;
    int d1i = 0;
    Uint8List y = _sample_buf;
    int yi = 0;
    Uint8List c = _sample_buf;
    int ci = 0;

    if (row < 8) {
      yi = row * 8;
    } else {
      yi = 64 * 1 + (row & 7) * 8;
    }

    ci = 64 * 2 + (row >> 1) * 8;

    for (int i = _max_mcus_per_row; i > 0; i--) {
      for (int j = 0; j < 8; j++) {
        int cb = c[ci + 0 + j];
        int cr = c[ci + 64 + j];

        int rc = _crr[cr];
        int gc = ((_crg[cr] + _cbg[cb]) >> 16);
        int bc = _cbb[cb];

        int yy = y[yi + j];
        d0[d0i + 0] = _clamp(yy + rc);
        d0[d0i + 1] = _clamp(yy + gc);
        d0[d0i + 2] = _clamp(yy + bc);
        d0[d0i + 3] = 255;

        yy = y[yi + 8 + j];
        d1[d1i + 0] = _clamp(yy + rc);
        d1[d1i + 1] = _clamp(yy + gc);
        d1[d1i + 2] = _clamp(yy + bc);
        d1[d1i + 3] = 255;

        d0i += 4;
        d1i += 4;
      }

      yi += 64 * 4;
      ci += 64 * 4;
    }
  }

  // YCbCr H2V1 (2x1:1:1, 4 m_blocks per MCU) to 24-bit RGB
  void _H2V1Convert() {
    int row = _max_mcu_y_size - _mcu_lines_left;
    Uint8List d0 = _scan_line_0;
    int d0i = 0;
    Uint8List y = _sample_buf;
    int yi = row * 8;
    Uint8List c = _sample_buf;
    int ci = 2 * 64 + row * 8;

    for (int i = _max_mcus_per_row; i > 0; i--) {
      for (int l = 0; l < 2; l++) {
        for (int j = 0; j < 4; j++) {
          int cb = c[ci + 0];
          int cr = c[ci + 64];

          int rc = _crr[cr];
          int gc = ((_crg[cr] + _cbg[cb]) >> 16);
          int bc = _cbb[cb];

          int yy = y[yi + j << 1];
          d0[d0i + 0] = _clamp(yy + rc);
          d0[d0i + 1] = _clamp(yy + gc);
          d0[d0i + 2] = _clamp(yy + bc);
          d0[d0i + 3] = 255;

          yy = y[yi + (j << 1) + 1];
          d0[d0i + 4] = _clamp(yy + rc);
          d0[d0i + 5] = _clamp(yy + gc);
          d0[d0i + 6] = _clamp(yy + bc);
          d0[d0i + 7] = 255;

          d0i += 8;

          ci++;
        }
        yi += 64;
      }

      yi += 64 * 4 - 64 * 2;
      ci += 64 * 4 - 8;
    }
  }

  // YCbCr H2V2 (2x2:1:1, 6 m_blocks per MCU) to 24-bit RGB
  void _H2V2Convert() {
    int row = _max_mcu_y_size - _mcu_lines_left;
    Uint8List d0 = _scan_line_0;
    int d0i = 0;
    Uint8List d1 = _scan_line_1;
    int d1i = 0;
    Uint8List y = _sample_buf;
    int yi = 0;
    Uint8List c = _sample_buf;
    int ci = 0;

    if (row < 8) {
      yi = row * 8;
    } else {
      yi = 64 * 2 + (row & 7) * 8;
    }

    ci = 64 * 4 + (row >> 1) * 8;

    for (int i = _max_mcus_per_row; i > 0; i--) {
      for (int l = 0; l < 2; l++) {
        for (int j = 0; j < 8; j += 2) {
          int cb = c[ci + 0];
          int cr = c[ci + 64];

          int rc = _crr[cr];
          int gc = ((_crg[cr] + _cbg[cb]) >> 16);
          int bc = _cbb[cb];

          int yy = y[yi + j];
          d0[d0i + 0] = _clamp(yy + rc);
          d0[d0i + 1] = _clamp(yy + gc);
          d0[d0i + 2] = _clamp(yy + bc);
          d0[d0i + 3] = 255;

          yy = y[yi + j + 1];
          d0[d0i + 4] = _clamp(yy + rc);
          d0[d0i + 5] = _clamp(yy + gc);
          d0[d0i + 6] = _clamp(yy + bc);
          d0[d0i + 7] = 255;

          yy = y[yi + j + 8];
          d1[d1i + 0] = _clamp(yy + rc);
          d1[d1i + 1] = _clamp(yy + gc);
          d1[d1i + 2] = _clamp(yy + bc);
          d1[d1i + 3] = 255;

          yy = y[yi + j + 8 + 1];
          d1[d1i + 4] = _clamp(yy + rc);
          d1[d1i + 5] = _clamp(yy + gc);
          d1[d1i + 6] = _clamp(yy + bc);
          d1[d1i + 7] = 255;

          d0i += 8;
          d1i += 8;

          ci++;
        }
        yi += 64;
      }

      yi += 64 * 6 - 64 * 2;
      ci += 64 * 6 - 8;
    }
  }

  void _expanded_convert() {
    int row = _max_mcu_y_size - _mcu_lines_left;
    Uint8List Py = _sample_buf;
    int pi = (row ~/ 8) * 64 * _comp_h_samp[0] + (row & 7) * 8;
    Uint8List d = _scan_line_0;
    int di = 0;

    for (int i = _max_mcus_per_row; i > 0; i--) {
      for (int k = 0; k < _max_mcu_x_size; k += 8) {
        int Y_ofs = k * 8;
        int Cb_ofs = Y_ofs + 64 * _expanded_blocks_per_component;
        int Cr_ofs = Y_ofs + 64 * _expanded_blocks_per_component * 2;
        for (int j = 0; j < 8; j++) {
          int y = Py[pi + Y_ofs + j];
          int cb = Py[pi + Cb_ofs + j];
          int cr = Py[pi + Cr_ofs + j];

          d[di + 0] = _clamp(y + _crr[cr]);
          d[di + 1] = _clamp(y + ((_crg[cr] + _cbg[cb]) >> 16));
          d[di + 2] = _clamp(y + _cbb[cb]);
          d[di + 3] = 255;

          di += 4;
        }
      }

      pi += 64 * _expanded_blocks_per_mcu;
    }
  }

  // Find end of image (EOI) marker, so we can return to the user the
  // exact size of the input stream.
  void _find_eoi() {
    if (_progressive_flag == 0) {
      // Prime the bit buffer
      _bits_left = 16;
      _get_bits_1(16);
      _get_bits_1(16);

      // The next marker _should_ be EOI
      _process_markers();
    }
  }

  // Decodes and dequantizes the next row of coefficients.
  void _decode_next_row() {
    int row_block = 0;

    _min(a, b) => (a < b) ? a : b;

    for (int mcu_row = 0; mcu_row < _mcus_per_row; mcu_row++) {
      if ((_restart_interval != 0) && (_restarts_left == 0)) {
        _process_restart();
      }

      Int16List p = _mcu_coefficients;
      int pi = 0;
      for (int mcu_block = 0; mcu_block < _blocks_per_mcu; mcu_block++, pi += 64) {
        int component_id = _mcu_org[mcu_block];
        Int16List q = _quant[_comp_quant[component_id]];
        List<int> r = [0];
        int s = _huff_decode(_huff_tabs[_comp_dc_tab[component_id]], r);
        s = _HUFF_EXTEND(r[0], s);

        _last_dc_val[component_id] = (s += _last_dc_val[component_id]);

        p[pi] = s * q[0];

        int prev_num_set = _mcu_block_max_zag[mcu_block];
        _JPEG_HuffTables Ph = _huff_tabs[_comp_ac_tab[component_id]];

        int k = 0;
        for (k = 1; k < 64; k++) {
          List<int> extra_bits = [0];
          s = _huff_decode(Ph, extra_bits);

          int r2 = s >> 4;
          s &= 15;

          if (s != 0) {
            if (r2 != 0) {
              if ((k + r2) > 63) {
                _terminate(DECODE_ERROR);
              }

              if (k < prev_num_set) {
                int n = _min(r2, prev_num_set - k);
                int kt = k;
                while (n-- != 0) {
                  p[pi + _ZAG[kt++]] = 0;
                }
              }

              k += r2;
            }

            s = _HUFF_EXTEND(extra_bits[0], s);
            //assert(k < 64);

            p[pi + _ZAG[k]] = _dequantize_ac(s, q[k]);
          } else {
            if (r2 == 15) {
              if ((k + 16) > 64) {
                _terminate(DECODE_ERROR);
              }

              if (k < prev_num_set) {
                int n = _min(16, prev_num_set - k);    // Dec. 19, 2001 - bugfix! was 15
                int kt = k;
                while (n-- != 0) {
                  //assert(kt <= 63);
                  p[pi + _ZAG[kt++]] = 0;
                }
              }

              k += 16 - 1; // - 1 because the loop counter is k!
              //assert(p[g_ZAG[k]] == 0);
            } else {
              break;
            }
          }
        }

        if (k < prev_num_set) {
          int kt = k;
          while (kt < prev_num_set) {
            p[pi + _ZAG[kt++]] = 0;
          }
        }

        _mcu_block_max_zag[mcu_block] = k;
        row_block++;
      }

      if (_freq_domain_chroma_upsample) {
        _transform_mcu_expand(mcu_row);
      } else {
        _transform_mcu(mcu_row);
      }

      _restarts_left--;
    }
  }

  int _dequantize_ac(int c, int q) {
    c *= q;
    if (c < 0) {
      c += (q * q + 64) >> 7;
      if (c > 0) {
        c = 0;
      }
    } else {
      c -= (q * q + 64) >> 7;
      if (c < 0) {
        c = 0;
      }
    }

    return c;
  }

  void _decode_start() {
    _init_frame();
    if (_progressive_flag != 0) {
      _init_progressive();
    } else {
      _init_sequential();
    }
  }

  // Decode a progressively encoded image.
  void _init_progressive() {
    if (_comps_in_frame == 4) {
      _terminate(UNSUPPORTED_COLORSPACE);
    }

    // Allocate the coefficient buffers.
    for (int i = 0; i < _comps_in_frame; i++) {
      _dc_coeffs[i] = _coeff_buf_open(_max_mcus_per_row * _comp_h_samp[i],
          _max_mcus_per_col * _comp_v_samp[i], 1, 1);
      _ac_coeffs[i] = _coeff_buf_open(_max_mcus_per_row * _comp_h_samp[i],
          _max_mcus_per_col * _comp_v_samp[i], 8, 8);
    }

    while (!_stream.isEOS) {
      if (_init_scan() == 0) {
        break;
      }

      bool dc_only_scan = (_spectral_start == 0);
      bool refinement_scan = (_successive_high != 0);

      if ((_spectral_start > _spectral_end) || (_spectral_end > 63)) {
        _terminate(BAD_SOS_SPECTRAL);
      }

      if (dc_only_scan) {
        if (_spectral_end != 0) {
          _terminate(BAD_SOS_SPECTRAL);
        }
      } else if (_comps_in_scan != 1) {
        // AC scans can only contain one component
        _terminate(BAD_SOS_SPECTRAL);
      }

      if ((refinement_scan) && (_successive_low != _successive_high - 1)) {
        _terminate(BAD_SOS_SUCCESSIVE);
      }

      dynamic decode_block_func;

      if (dc_only_scan) {
        if (refinement_scan) {
          decode_block_func = _progressive_decode_block_dc_refine;
        } else {
          decode_block_func = _progressive_decode_block_dc_first;
        }
      } else {
        if (refinement_scan) {
          decode_block_func = _progressive_decode_block_ac_refine;
        } else {
          decode_block_func = _progressive_decode_block_ac_first;
        }
      }

      _decode_scan(decode_block_func);

      _bits_left = 16;
      _get_bits_1(16);
      _get_bits_1(16);
    }

    _comps_in_scan = _comps_in_frame;

    for (int i = 0; i < _comps_in_frame; i++) {
      _comp_list[i] = i;
    }

    _calc_mcu_block_order();
  }

  // The following methods decode the various types of m_blocks encountered
  // in progressively encoded images.
  void _progressive_decode_block_dc_first(int component_id, int block_x,
      int block_y) {
    Int16List p = _dc_coeffs[component_id].Pdata;
    int pi = _coeff_buf_getp(_dc_coeffs[component_id], block_x, block_y);

    int hi = _comp_dc_tab[component_id];
    _JPEG_HuffTables h = _huff_tabs[hi];
    int s = _huff_decode(h);
    if (s != 0) {
      int r = _get_bits_2(s);
      s = _HUFF_EXTEND_P(r, s);
    }

    s += _last_dc_val[component_id];
    s = _uint32ToInt32(s);
    _last_dc_val[component_id] = s;

    p[pi] = s << _successive_low;
  }

  void _progressive_decode_block_dc_refine(int component_id, int block_x,
      int block_y) {
    if (_get_bits_2(1) != 0) {
      Int16List p = _dc_coeffs[component_id].Pdata;
      int pi = _coeff_buf_getp(_dc_coeffs[component_id], block_x, block_y);
      p[pi] |= (1 << _successive_low);
    }
  }

  void _progressive_decode_block_ac_first(int component_id, int block_x,
      int block_y) {
    if (_eob_run != 0) {
      _eob_run--;
      return;
    }

    Int16List p = _ac_coeffs[component_id].Pdata;
    int pi = _coeff_buf_getp(_ac_coeffs[component_id], block_x, block_y);

    for (int k = _spectral_start; k <= _spectral_end; k++) {
      int s = _huff_decode(_huff_tabs[_comp_ac_tab[component_id]]);

      int r = (s >> 4) & 0xFFFFFFFF;
      s &= 15;

      if (s != 0) {
        k += r;
        if (k > 63) {
          _terminate(DECODE_ERROR);
        }

        r = _get_bits_2(s);
        s = _HUFF_EXTEND_P(r, s);

        p[pi + _ZAG[k]] = s << _successive_low;
      } else {
        if (r == 15) {
          if ((k += 15) > 63) {
            _terminate(DECODE_ERROR);
          }
        } else {
          _eob_run = 1 << r;
          if (r != 0) {
            _eob_run += _get_bits_2(r);
          }
          _eob_run--;
          break;
        }
      }
    }
  }

  void _progressive_decode_block_ac_refine(int component_id, int block_x,
      int block_y) {
    int p1 = 1 << _successive_low;
    int m1 = (-1) << _successive_low;
    Int16List p = _ac_coeffs[component_id].Pdata;
    int pi = _coeff_buf_getp(_ac_coeffs[component_id], block_x, block_y);
    int k = _spectral_start;

    if (_eob_run == 0) {
      for ( ; k <= _spectral_end; k++) {
        int s = _huff_decode(_huff_tabs[_comp_ac_tab[component_id]]);
        int r = s >> 4;
        s &= 15;

        if (s != 0) {
          if (s != 1) {
            _terminate(DECODE_ERROR);
          }

          if (_get_bits_2(1) != 0) {
            s = p1;
          } else {
            s = m1;
          }
        } else {
          if (r != 15) {
            _eob_run = 1 << r;

            if (r != 0) {
              _eob_run += _get_bits_2(r);
            }

            break;
          }
        }

        do {
          int pi2 = pi + _ZAG[k];
          if (p[pi2] != 0) {
            if (_get_bits_2(1) != 0) {
              if ((p[pi2] & p1) == 0) {
                if (p[pi2] >= 0) {
                  p[pi2] = p[pi2] + p1;
                } else {
                  p[pi2] = p[pi2] + m1;
                }
              }
            }
          } else {
            if (--r < 0) {
              break;
            }
          }

          k++;
        } while (k <= _spectral_end);

        if ((s != 0) && (k < 64)) {
          p[pi + _ZAG[k]] = s;
        }
      }
    }

    if (_eob_run > 0) {
      for ( ; k <= _spectral_end; k++) {
        int pi2 = pi + _ZAG[k];
        if (p[pi2] != 0) {
          if (_get_bits_2(1) != 0) {
            if ((p[pi2] & p1) == 0) {
              if (p[pi2] >= 0) {
                p[pi2] = p[pi2] + p1;
              } else {
                p[pi2] = p[pi2] + m1;
              }
            }
          }
        }
      }

      _eob_run--;
    }
  }

  // Decode a scan in a progressively encoded image.
  void _decode_scan(dynamic decode_block_func) {
    Int32List block_x_mcu = new Int32List(_MAX_COMPONENTS);
    Int32List m_block_y_mcu = new Int32List(_MAX_COMPONENTS);

    for (int mcu_col = 0; mcu_col < _mcus_per_col; mcu_col++) {
      block_x_mcu.fillRange(0, block_x_mcu.length, 0);

      for (int mcu_row = 0; mcu_row < _mcus_per_row; mcu_row++) {
        int block_x_mcu_ofs = 0;
        int block_y_mcu_ofs = 0;

        if ((_restart_interval != 0) && (_restarts_left == 0)) {
          _process_restart();
        }

        for (int mcu_block = 0; mcu_block < _blocks_per_mcu; mcu_block++) {
          int component_id = _mcu_org[mcu_block];

          decode_block_func(component_id,
              block_x_mcu[component_id] + block_x_mcu_ofs,
              m_block_y_mcu[component_id] + block_y_mcu_ofs);

          if (_comps_in_scan == 1) {
            block_x_mcu[component_id]++;
          } else {
            if (++block_x_mcu_ofs == _comp_h_samp[component_id]) {
              block_x_mcu_ofs = 0;
              if (++block_y_mcu_ofs == _comp_v_samp[component_id]) {
                block_y_mcu_ofs = 0;
                block_x_mcu[component_id] += _comp_h_samp[component_id];
              }
            }
          }
        }
        _restarts_left--;
      }

      if (_comps_in_scan == 1) {
        m_block_y_mcu[_comp_list[0]]++;
      } else {
        for (int component_num = 0; component_num < _comps_in_scan;
             component_num++) {
          int component_id = _comp_list[component_num];
          m_block_y_mcu[component_id] += _comp_v_samp[component_id];
        }
      }
    }
  }

  void _process_restart() {
    // Let's scan a little bit to find the marker, but not _too_ far.
    // 1536 is a "fudge factor" that determines how much to scan.
    int i = 0;
    for (i = 1536; i > 0; i--) {
      if (_get_char() == 0xFF) {
        break;
      }
    }

    if (i == 0) {
      _terminate(BAD_RESTART_MARKER);
    }

    int c = 0;
    for ( ; i > 0; i--) {
      c = _get_char();
      if (c != 0xFF) {
        break;
      }
    }

    if (i == 0) {
      _terminate(BAD_RESTART_MARKER);
    }

    // Is it the expected marker? If not, something bad happened.
    if (c != (_next_restart_num + M_RST0)) {
      _terminate(BAD_RESTART_MARKER);
    }

    // Reset each component's DC prediction values.
    _last_dc_val.fillRange(0, _comps_in_frame, 0);
    _eob_run = 0;
    _restarts_left = _restart_interval;
    _next_restart_num = (_next_restart_num + 1) & 7;

    // Get the bit buffer going again...
    _bits_left = 16;
    _get_bits_2(16);
    _get_bits_2(16);
  }

  void _init_sequential() {
    if (_init_scan() == 0) {
      _terminate(UNEXPECTED_MARKER);
    }
  }

  void _read_dht_marker() {
    int left = _get_bits_1(16);
    if (left < 2) {
      _terminate(BAD_DHT_MARKER);
    }
    left -= 2;

    while (left > 0) {
      Uint8List huff_num = new Uint8List(17);
      Uint8List huff_val = new Uint8List(256);

      int index = _get_bits_1(8);
      huff_num[0] = 0;
      int count = 0;

      for (int i = 1; i <= 16; i++) {
        huff_num[i] = _get_bits_1(8);
        count += huff_num[i];
      }

      if (count > 255) {
        _terminate(BAD_DHT_COUNTS);
      }

      for (int i = 0; i < count; i++) {
        huff_val[i] = _get_bits_1(8);
      }

      int i = 1 + 16 + count;

      if (left < i) {
        _terminate(BAD_DHT_MARKER);
      }

      left -= i;

      if ((index & 0x10) > 0x10) {
        _terminate(BAD_DHT_INDEX);
      }

      index = (index & 0x0F) + ((index & 0x10) >> 4) *
          (_MAX_HUFF_TABLES >> 1);

      if (index >= _MAX_HUFF_TABLES) {
        _terminate(BAD_DHT_INDEX);
      }

      _huff_ac[index] = (index & 0x10) != 0 ? 1 : 0;
      _huff_num[index] = huff_num;
      _huff_val[index] = huff_val;
    }
  }

  void _read_dqt_marker() {
    int left = _get_bits_1(16);

    if (left < 2) {
      _terminate(BAD_DQT_MARKER);
    }

    left -= 2;

    while (left != 0) {
      int n = _get_bits_1(8);
      int prec = n >> 4;
      n &= 0x0F;

      if (n >= _MAX_QUANT_TABLES) {
        _terminate(BAD_DQT_TABLE);
      }

      if (_quant[n] == null) {
        _quant[n] = new Int16List(64);
      }

      // read quantization entries, in zag order
      for (int i = 0; i < 64; i++) {
        int temp = _get_bits_1(8);

        if (prec != 0) {
          temp = (temp << 8) + _get_bits_1(8);
        }

        _quant[n][i] = temp & 0xFFFF;
      }

      int i = 64 + 1;

      if (prec != 0) {
        i += 64;
      }

      if (left < i) {
        _terminate(BAD_DQT_LENGTH);
      }

      left -= i;
    }
  }

  void _read_sof_marker() {
    int left = _get_bits_1(16);

    if (_get_bits_1(8) != 8) {
      /* precision: sorry, only 8-bit precision is supported right now */
      _terminate(BAD_PRECISION);
    }

    _image_y_size = _get_bits_1(16);

    if ((_image_y_size < 1) || (_image_y_size > _MAX_HEIGHT)) {
      _terminate(BAD_HEIGHT);
    }

    _image_x_size = _get_bits_1(16);

    if ((_image_x_size < 1) || (_image_x_size > _MAX_WIDTH)) {
      _terminate(BAD_WIDTH);
    }

    _comps_in_frame = _get_bits_1(8);

    if (_comps_in_frame > _MAX_COMPONENTS) {
      _terminate(TOO_MANY_COMPONENTS);
    }

    if (left != (_comps_in_frame * 3 + 8)) {
      _terminate(BAD_SOF_LENGTH);
    }

    for (int i = 0; i < _comps_in_frame; i++) {
      _comp_ident[i]  = _get_bits_1(8);
      _comp_h_samp[i] = _get_bits_1(4);
      _comp_v_samp[i] = _get_bits_1(4);
      _comp_quant[i]  = _get_bits_1(8);
    }
  }

  void _skip_variable_marker() {
    int left = _get_bits_1(16);
    if (left < 2) {
      _terminate(BAD_VARIABLE_MARKER);
    }
    left -= 2;
    while (left != 0) {
      _get_bits_1(8);
      left--;
    }
  }

  void _read_dri_marker() {
    if (_get_bits_1(16) != 4) {
      _terminate(BAD_DRI_LENGTH);
    }

    _restart_interval = _get_bits_1(16);
  }

  void _read_sos_marker() {
    int left = _get_bits_1(16);

    int n = _get_bits_1(8);

    _comps_in_scan = n;

    left -= 3;

    if ((left != (n * 2 + 3)) || (n < 1) || (n > _MAX_COMPS_IN_SCAN)) {
      _terminate(BAD_SOS_LENGTH);
    }

    for (int i = 0; i < n; i++) {
      int cc = _get_bits_1(8);
      int c = _get_bits_1(8);
      left -= 2;

      int ci;
      for (ci = 0; ci < _comps_in_frame; ci++) {
        if (cc == _comp_ident[ci]) {
          break;
        }
      }

      if (ci >= _comps_in_frame) {
        _terminate(BAD_SOS_COMP_ID);
      }

      _comp_list[i] = ci;
      _comp_dc_tab[ci] = (c >> 4) & 15;
      _comp_ac_tab[ci] = (c & 15) + (_MAX_HUFF_TABLES >> 1);
    }

    _spectral_start = _get_bits_1(8);
    _spectral_end  = _get_bits_1(8);
    _successive_high = _get_bits_1(4);
    _successive_low = _get_bits_1(4);

    if (_progressive_flag == 0) {
      _spectral_start = 0;
      _spectral_end = 63;
    }

    left -= 3;

    while (left != 0) {
      // read past whatever is left
      _get_bits_1(8);
      left--;
    }
  }

  int _next_marker() {
    int bytes = 0;
    int c = 0;
    do {
      do {
        bytes++;
        c = _get_bits_1(8);
      } while (c != 0xFF);

      do {
        c = _get_bits_1(8);
      } while (c == 0xFF);
    } while (c == 0);

    // If bytes > 0 here, there where extra bytes before the marker (not good).
    return c;
  }

  int _process_markers() {
    int c = 0;
    while (!_stream.isEOS) {
      c = _next_marker();
      switch (c) {
        case M_SOF0:
        case M_SOF1:
        case M_SOF2:
        case M_SOF3:
        case M_SOF5:
        case M_SOF6:
        case M_SOF7:
        case M_SOF9:
        case M_SOF10:
        case M_SOF11:
        case M_SOF13:
        case M_SOF14:
        case M_SOF15:
        case M_SOI:
        case M_EOI:
        case M_SOS:
          return c;
        case M_DHT:
          _read_dht_marker();
          break;
        // Sorry, no arithmitic support at this time. Dumb patents!
        case M_DAC:
          _terminate(NO_ARITHMITIC_SUPPORT);
          break;
        case M_DQT:
          _read_dqt_marker();
          break;
        case M_DRI:
          _read_dri_marker();
          break;
        case M_APP0:
        case M_APP1:
        case M_APP2:
        case M_APP3:
        case M_APP4:
        case M_APP5:
        case M_APP6:
        case M_APP7:
        case M_APP8:
        case M_APP9:
        case M_APP10:
        case M_APP11:
        case M_APP12:
        case M_APP13:
        case M_APP14:
        case M_APP15:
        case M_COM:
          _read_app_data(c);
          break;
        case M_JPG:
        case M_RST0:    /* no parameters */
        case M_RST1:
        case M_RST2:
        case M_RST3:
        case M_RST4:
        case M_RST5:
        case M_RST6:
        case M_RST7:
        case M_TEM:
          _terminate(UNEXPECTED_MARKER);
          break;
        default:    /* must be DNL, DHP, EXP, APPn, JPGn, COM, or RESn or APP0 */
          _skip_variable_marker();
          break;
      }
    }
    _terminate(STREAM_READ);
    return 0;
  }

  void _read_app_data(int marker) {
    int left = _get_bits_1(16);
    if (left < 2) {
      _terminate(BAD_DHT_MARKER);
    }
    left -= 2;

    if (marker == M_APP0) {
      // 'JFIF\0'
      int h1 = _get_bits_1(8);
      int h2 = _get_bits_1(8);
      int h3 = _get_bits_1(8);
      int h4 = _get_bits_1(8);
      int h5 = _get_bits_1(8);
      left -= 5;
      if (h1 == 0x4A && h2 == 0x46 &&
          h3 == 0x49 && h4 == 0x46 && h5 == 0) {
        jfif = new JpegJfif();
        jfif.majorVersion = _get_bits_1(8);
        jfif.minorVersion = _get_bits_1(8);
        jfif.densityUnits = _get_bits_1(8);
        jfif.xDensity = _get_bits_1(16);
        jfif.yDensity = _get_bits_1(16);
        jfif.thumbWidth = _get_bits_1(8);
        jfif.thumbHeight = _get_bits_1(8);
        int thumbSize = 3 * jfif.thumbWidth * jfif.thumbHeight;
        jfif.thumbData = new Uint8List(thumbSize);
        for (int i = 0; i < thumbSize; ++i) {
          jfif.thumbData[i] = _get_bits_1(8);
        }
        left -= 9 - thumbSize;
      }
    }

    if (marker == M_APP14) {
      // 'Adobe\0'
      int h1 = _get_bits_1(8);
      int h2 = _get_bits_1(8);
      int h3 = _get_bits_1(8);
      int h4 = _get_bits_1(8);
      int h5 = _get_bits_1(8);
      int h6 = _get_bits_1(8);
      left -= 6;
      if (h1 == 0x41 && h2 == 0x64 &&
          h3 == 0x6F && h4 == 0x62 &&
          h5 == 0x65 && h6 == 0) {
        adobe = new JpegAdobe();
        adobe.version = _get_bits_1(8);
        adobe.flags0 = _get_bits_1(16);
        adobe.flags1 = _get_bits_1(16);
        adobe.transformCode = _get_bits_1(8);
        left -= 6;
      }
    }

    while (left != 0) {
      _get_bits_1(8);
      left--;
    }
  }

  void _locate_soi_marker() {
    int lastchar = _get_bits_1(8);
    int thischar = _get_bits_1(8);

    // ok if it's a normal JPEG file without a special header
    if ((lastchar == 0xFF) && (thischar == M_SOI)) {
      return;
    }

    int bytesleft = 4096;

    for ( ; ; ) {
      if (--bytesleft == 0) {
        _terminate(NOT_JPEG);
      }

      lastchar = thischar;
      thischar = _get_bits_1(8);

      if (lastchar == 0xFF) {
        if (thischar == M_SOI) {
          break;
        } else if (thischar == M_EOI) {
          _terminate(NOT_JPEG);
        }
      }
    }

    /* Check the next character after marker: if it's not 0xFF, it can't
       be the start of the next marker, so the file is bad */
    thischar = (_bit_buf >> 24) & 0xFF;

    if (thischar != 0xFF) {
      _terminate(NOT_JPEG);
    }
  }

  void _locate_sof_marker() {
    _locate_soi_marker();

    int c = _process_markers();
    switch (c) {
      case M_SOF2:
        _progressive_flag = TRUE;
        _read_sof_marker();
        break;
      case M_SOF0:  /* baseline DCT */
      case M_SOF1:  /* extended sequential DCT */
        _read_sof_marker();
        break;
      case M_SOF9:  /* Arithmitic coding */
        _terminate(NO_ARITHMITIC_SUPPORT);
        break;
      default:
        _terminate(UNSUPPORTED_MARKER);
        break;
    }
  }

  int _locate_sos_marker() {
    int c = _process_markers();
    if (c == M_EOI) {
      return FALSE;
    } else if (c != M_SOS) {
      _terminate(UNEXPECTED_MARKER);
    }
    _read_sos_marker();
    return TRUE;
  }

  void _init(InputBuffer stream) {
    info = new JpegInfo();
    _error_code = 0;
    _ready_flag = false;
    _image_x_size = _image_y_size = 0;
    _stream = stream;
    _progressive_flag = 0;
    _huff_ac.fillRange(0, _huff_ac.length, 0);
    _huff_num.fillRange(0, _huff_num.length, null);
    _huff_val.fillRange(0, _huff_val.length, null);
    _quant.fillRange(0, _quant.length, null);

    _scan_type = 0;

    _comps_in_frame = 0;

    _comp_h_samp.fillRange(0, _comp_h_samp.length, 0);
    _comp_v_samp.fillRange(0, _comp_v_samp.length, 0);
    _comp_quant.fillRange(0, _comp_quant.length, 0);
    _comp_ident.fillRange(0, _comp_ident.length, 0);
    _comp_h_blocks.fillRange(0, _comp_h_blocks.length, 0);
    _comp_v_blocks.fillRange(0, _comp_v_blocks.length, 0);

    _comps_in_scan = 0;
    _comp_list.fillRange(0, _comp_list.length, 0);
    _comp_dc_tab.fillRange(0, _comp_dc_tab.length, 0);
    _comp_ac_tab.fillRange(0, _comp_ac_tab.length, 0);

    _spectral_start = 0;
    _spectral_end = 0;
    _successive_low = 0;
    _successive_high = 0;

    _max_mcu_x_size = 0;
    _max_mcu_y_size = 0;

    _blocks_per_mcu = 0;
    _max_blocks_per_row = 0;
    _mcus_per_row = 0;
    _mcus_per_col = 0;

    _expanded_blocks_per_component = 0;
    _expanded_blocks_per_mcu = 0;
    _expanded_blocks_per_row = 0;
    _freq_domain_chroma_upsample = false;

    _mcu_org.fillRange(0, _mcu_org.length, 0);

    _total_lines_left = 0;
    _mcu_lines_left = 0;

    _real_dest_bytes_per_scan_line = 0;
    _dest_bytes_per_scan_line = 0;
    _dest_bytes_per_pixel = 0;

    _huff_tabs.fillRange(0, _huff_tabs.length, null);
    _dc_coeffs.fillRange(0, _dc_coeffs.length, null);
    _ac_coeffs.fillRange(0, _ac_coeffs.length, null);
    _block_y_mcu.fillRange(0, _block_y_mcu.length, 0);

    _eob_run = 0;

    _restart_interval = 0;
    _restarts_left    = 0;
    _next_restart_num = 0;

    _max_mcus_per_row = 0;
    _max_blocks_per_mcu = 0;
    _max_mcus_per_col = 0;

    _last_dc_val.fillRange(0, _last_dc_val.length, 0);
    _mcu_coefficients = null;
    _sample_buf = null;

    // Prime the bit buffer.
    _bits_left = 16;
    _bit_buf = 0;

    int p1 = _get_bits_1(16);
    int p2 = _get_bits_1(16);

    for (int i = 0; i < _MAX_BLOCKS_PER_MCU; i++) {
      _mcu_block_max_zag[i] = 64;
    }
  }

  void _create_look_ups() {
    const int SCALEBITS = 16;
    const int ONE_HALF = (1 << (SCALEBITS - 1));
    int FIX(x) => (x * (1 << SCALEBITS) + 0.5).toInt();
    for (int i = 0; i <= 255; i++) {
      int k = i - 128;
      _crr[i] = ((FIX(1.40200) * k + ONE_HALF) >> SCALEBITS);
      _cbb[i] = ((FIX(1.77200) * k + ONE_HALF) >> SCALEBITS);
      _crg[i] = ((-FIX(0.71414)) * k);
      _cbg[i] = ((-FIX(0.34414)) * k + ONE_HALF);
    }
  }

  void _transform_mcu(int mcu_row) {
    int Psrc_ptr = 0;
    int Pdst_ptr = mcu_row * _blocks_per_mcu * 64;
    Int16List Psrc = _mcu_coefficients;
    Uint8List Pdst = _sample_buf;
    for (int mcu_block = 0; mcu_block < _blocks_per_mcu; mcu_block++) {
      _idct(Psrc, Psrc_ptr, Pdst, Pdst_ptr, _mcu_block_max_zag[mcu_block]);
      Psrc_ptr += 64;
      Pdst_ptr += 64;
    }
  }

  void _transform_mcu_expand(int mcu_row) {
    Int16List Psrc = _mcu_coefficients;
    int Psrc_ptr = 0;
    Uint8List Pdst = _sample_buf;
    int Pdst_ptr = mcu_row * _expanded_blocks_per_mcu * 64;

    // Y IDCT
    int mcu_block = 0;
    for (mcu_block = 0; mcu_block < _expanded_blocks_per_component;
         ++mcu_block) {
      _idct(Psrc, Psrc_ptr, Pdst, Pdst_ptr, _mcu_block_max_zag[mcu_block]);
      Psrc_ptr += 64;
      Pdst_ptr += 64;
    }

    // Chroma IDCT, with upsampling
    Int16List temp_block = new Int16List(64);

    for (int i = 0; i < 2; i++) {
      _DCT_Upsample_Matrix44 P = new _DCT_Upsample_Matrix44();
      _DCT_Upsample_Matrix44 Q = new _DCT_Upsample_Matrix44();
      _DCT_Upsample_Matrix44 R = new _DCT_Upsample_Matrix44();
      _DCT_Upsample_Matrix44 S = new _DCT_Upsample_Matrix44();

      switch (_MAX_RC[_mcu_block_max_zag[mcu_block++] - 1]) {
        case 1*16+1:
          _P_Q_calc(1, 1, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(1, 1, R, S, Psrc, Psrc_ptr);
          break;
        case 1*16+2:
          _P_Q_calc(1, 2, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(1, 2, R, S, Psrc, Psrc_ptr);
          break;
        case 2*16+2:
          _P_Q_calc(2, 2, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(2, 2, R, S, Psrc, Psrc_ptr);
          break;
        case 3*16+2:
          _P_Q_calc(3, 2, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(3, 2, R, S, Psrc, Psrc_ptr);
          break;
        case 3*16+3:
          _P_Q_calc(3, 3, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(3, 3, R, S, Psrc, Psrc_ptr);
          break;
        case 3*16+4:
          _P_Q_calc(3, 4, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(3, 4, R, S, Psrc, Psrc_ptr);
          break;
        case 4*16+4:
          _P_Q_calc(4, 4, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(4, 4, R, S, Psrc, Psrc_ptr);
          break;
        case 5*16+4:
          _P_Q_calc(5, 4, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(5, 4, R, S, Psrc, Psrc_ptr);
          break;
        case 5*16+5:
          _P_Q_calc(5, 5, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(5, 5, R, S, Psrc, Psrc_ptr);
          break;
        case 5*16+6:
          _P_Q_calc(5, 6, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(5, 6, R, S, Psrc, Psrc_ptr);
          break;
        case 6*16+6:
          _P_Q_calc(6, 6, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(6, 6, R, S, Psrc, Psrc_ptr);
          break;
        case 7*16+6:
          _P_Q_calc(7, 6, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(7, 6, R, S, Psrc, Psrc_ptr);
          break;
        case 7*16+7:
          _P_Q_calc(7, 7, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(7, 7, R, S, Psrc, Psrc_ptr);
          break;
        case 7*16+8:
          _P_Q_calc(7, 8, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(7, 8, R, S, Psrc, Psrc_ptr);
          break;
        case 8*16+8:
          _P_Q_calc(8, 8, P, Q, Psrc, Psrc_ptr);
          _R_S_calc(8, 8, R, S, Psrc, Psrc_ptr);
          break;
        default:
          assert(false);
      }

      _DCT_Upsample_Matrix44 a = P + Q;
      P -= Q;
      _DCT_Upsample_Matrix44 b = P;
      _DCT_Upsample_Matrix44 c = R + S;
      R -= S;
      _DCT_Upsample_Matrix44 d = R;

      _DCT_Upsample_Matrix44.add_and_store(temp_block, a, c);
      _idct_4x4(temp_block, Pdst, Pdst_ptr);
      Pdst_ptr += 64;

      _DCT_Upsample_Matrix44.sub_and_store(temp_block, a, c);
      _idct_4x4(temp_block, Pdst, Pdst_ptr);
      Pdst_ptr += 64;

      _DCT_Upsample_Matrix44.add_and_store(temp_block, b, d);
      _idct_4x4(temp_block, Pdst, Pdst_ptr);
      Pdst_ptr += 64;

      _DCT_Upsample_Matrix44.sub_and_store(temp_block, b, d);
      _idct_4x4(temp_block, Pdst, Pdst_ptr);
      Pdst_ptr += 64;

      Psrc_ptr += 64;
    }
  }

  // Loads and dequantizes the next row of (already decoded) coefficients.
  // Progressive images only.
  void _load_next_row() {
    Int16List p = _mcu_coefficients;
    int component_num = 0;
    int component_id = 0;
    int row_block = 0;
    Int32List block_x_mcu = new Int32List(_MAX_COMPONENTS);

    for (int mcu_row = 0; mcu_row < _mcus_per_row; mcu_row++) {
      int block_x_mcu_ofs = 0;
      int block_y_mcu_ofs = 0;

      for (int mcu_block = 0; mcu_block < _blocks_per_mcu; mcu_block++) {
        component_id = _mcu_org[mcu_block];
        Int16List q = _quant[_comp_quant[component_id]];

        int p_i = 64 * mcu_block;

        Int16List pAC_p = _ac_coeffs[component_id].Pdata;
        int pAC = _coeff_buf_getp(_ac_coeffs[component_id],
            block_x_mcu[component_id] + block_x_mcu_ofs,
            _block_y_mcu[component_id] + block_y_mcu_ofs);

        Int16List pDC_p = _dc_coeffs[component_id].Pdata;
        int pDC = _coeff_buf_getp(_dc_coeffs[component_id],
            block_x_mcu[component_id] + block_x_mcu_ofs,
            _block_y_mcu[component_id] + block_y_mcu_ofs);

        p[p_i + 0] = pDC_p[pDC + 0];
        for (int i = 0; i < 63; ++i) {
          p[p_i + 1 + i] = pAC_p[pAC + 1 + i];
        }

        int i = 0;
        for (i = 63; i > 0; i--) {
          if (p[p_i + _ZAG[i]] != 0) {
            break;
          }
        }

        _mcu_block_max_zag[mcu_block] = i + 1;

        for ( ; i >= 0; i--) {
          if (p[p_i + _ZAG[i]] != 0) {
            p[p_i + _ZAG[i]] = p[p_i + _ZAG[i]] * q[i];
          }
        }

        row_block++;

        if (_comps_in_scan == 1) {
          block_x_mcu[component_id]++;
        } else {
          if (++block_x_mcu_ofs == _comp_h_samp[component_id]) {
            block_x_mcu_ofs = 0;

            if (++block_y_mcu_ofs == _comp_v_samp[component_id]) {
              block_y_mcu_ofs = 0;
              block_x_mcu[component_id] += _comp_h_samp[component_id];
            }
          }
        }
      }

      if (_freq_domain_chroma_upsample) {
        _transform_mcu_expand(mcu_row);
      } else {
        _transform_mcu(mcu_row);
      }
    }

    if (_comps_in_scan == 1) {
      _block_y_mcu[_comp_list[0]]++;
    } else {
      for (component_num = 0; component_num < _comps_in_scan; component_num++) {
        component_id = _comp_list[component_num];
        _block_y_mcu[component_id] += _comp_v_samp[component_id];
      }
    }
  }

  int _init_scan() {
    if (_locate_sos_marker() == 0) {
      return FALSE;
    }

    _calc_mcu_block_order();
    _check_huff_tables();
    _check_quant_tables();

    _last_dc_val.fillRange(0, _comps_in_frame, 0);

    _eob_run = 0;

    if (_restart_interval != 0) {
      _restarts_left = _restart_interval;
      _next_restart_num = 0;
    }

    _fix_in_buffer();

    return TRUE;
  }

  // This method throws back into the stream any bytes that where read
  // into the bit buffer during initial marker scanning.
  void _fix_in_buffer() {
    // In case any 0xFF's where pulled into the buffer during marker scanning
    //assert((m_bits_left & 7) == 0);

    if (_bits_left == 16) {
      _stream.skip(-1);
      //stuff_char(m_bit_buf & 0xFF);
    }

    if (_bits_left >= 8) {
      _stream.skip(-1);
      //stuff_char(m_bit_buf >> 8) & 0xFF);
    }

    _stream.skip(-2);
    //stuff_char((m_bit_buf >> 16) & 0xFF);
    //stuff_char((m_bit_buf >> 24) & 0xFF);

    _bits_left = 16;
    _get_bits_2(16);
    _get_bits_2(16);
  }

  // Verifies the quantization tables needed for this scan are available.
  void _check_quant_tables() {
    for (int i = 0; i < _comps_in_scan; i++) {
      if (_quant[_comp_quant[_comp_list[i]]] == null) {
        _terminate(UNDEFINED_QUANT_TABLE);
      }
    }
  }

  // Verifies that all the Huffman tables needed for this scan are available.
  void _check_huff_tables() {
    for (int i = 0; i < _comps_in_scan; i++) {
      if ((_spectral_start == 0) &&
          (_huff_num[_comp_dc_tab[_comp_list[i]]] == null)) {
        _terminate(UNDEFINED_HUFF_TABLE);
      }

      if ((_spectral_end > 0) &&
          (_huff_num[_comp_ac_tab[_comp_list[i]]] == null)) {
        _terminate(UNDEFINED_HUFF_TABLE);
      }
    }

    for (int i = 0; i < _MAX_HUFF_TABLES; i++) {
      if (_huff_num[i] != null) {
        if (_huff_tabs[i] == null) {
          _huff_tabs[i] = new _JPEG_HuffTables();
        }
        _make_huff_table(i, _huff_tabs[i]);
      }
    }
  }

  // Creates the tables needed for efficient Huffman decoding.
  void _make_huff_table(int index, _JPEG_HuffTables hs) {
    Uint8List huffsize = new Uint8List(257);
    Uint32List huffcode = new Uint32List(257);

    hs.ac_table = _huff_ac[index] != 0;

    int p = 0;

    for (int l = 1; l <= 16; l++) {
      for (int i = 1; i <= _huff_num[index][l]; i++) {
        huffsize[p++] = l;
      }
    }

    huffsize[p] = 0;

    int lastp = p;
    int code = 0;
    int si = huffsize[0];

    p = 0;

    while (huffsize[p] != 0) {
      while (huffsize[p] == si) {
        huffcode[p++] = code;
        code++;
      }

      code <<= 1;
      si++;
    }

    hs.look_up.fillRange(0, hs.look_up.length, 0);
    hs.look_up2.fillRange(0, hs.look_up2.length, 0);
    hs.tree.fillRange(0, hs.tree.length, 0);
    hs.code_size.fillRange(0, hs.code_size.length, 0);

    int nextfreeentry = -1;

    p = 0;
    while (p < lastp) {
      int i = _huff_val[index][p];
      code = huffcode[p];
      int code_size = huffsize[p];

      hs.code_size[i] = code_size;

      if (code_size <= 8) {
        code <<= (8 - code_size);

        for (int l = 1 << (8 - code_size); l > 0; l--) {
          //assert(i < 256);
          hs.look_up[code] = i;

          bool has_extrabits = false;
          int extra_bits = 0;
          int num_extra_bits = i & 15;

          int bits_to_fetch = code_size;
          if (num_extra_bits != 0) {
            int total_codesize = code_size + num_extra_bits;
            if (total_codesize <= 8) {
              has_extrabits = true;
              extra_bits = ((1 << num_extra_bits) - 1) &
                  (code >> (8 - total_codesize));
              assert(extra_bits <= 0x7FFF);
              bits_to_fetch += num_extra_bits;
            }
          }

          if (!has_extrabits) {
            hs.look_up2[code] = i | (bits_to_fetch << 8);
          } else {
            hs.look_up2[code] = i | 0x8000 | (extra_bits << 16) |
                (bits_to_fetch << 8);
          }

          code++;
        }
      } else {
        int subtree = (code >> (code_size - 8)) & 0xFF;

        int currententry = _uint32ToInt32(hs.look_up[subtree]);
        if (currententry == 0) {
          currententry = nextfreeentry;
          hs.look_up[subtree] = currententry;
          hs.look_up2[subtree] = currententry;
          nextfreeentry -= 2;
        }

        code <<= (16 - (code_size - 8));

        for (int l = code_size; l > 9; l--) {
          if ((code & 0x8000) == 0) {
            currententry--;
          }

          if (hs.tree[-currententry - 1] == 0) {
            hs.tree[-currententry - 1] = nextfreeentry;
            currententry = nextfreeentry;
            nextfreeentry -= 2;
          } else {
            currententry = _uint32ToInt32(hs.tree[-currententry - 1]);
          }

          code <<= 1;
        }

        if ((code & 0x8000) == 0) {
          currententry--;
        }

        hs.tree[-currententry - 1] = i;
      }

      p++;
    }
  }

  // Determines the component order inside each MCU.
  // Also calcs how many MCU's are on each row, etc.
  void _calc_mcu_block_order() {
    int component_num = 0;
    int component_id = 0;
    int max_h_samp = 0;
    int max_v_samp = 0;

    for (component_id = 0; component_id < _comps_in_frame; component_id++) {
      if (_comp_h_samp[component_id] > max_h_samp) {
        max_h_samp = _comp_h_samp[component_id];
      }

      if (_comp_v_samp[component_id] > max_v_samp) {
        max_v_samp = _comp_v_samp[component_id];
      }
    }

    for (component_id = 0; component_id < _comps_in_frame; component_id++) {
      _comp_h_blocks[component_id] = ((((_image_x_size *
          _comp_h_samp[component_id]) + (max_h_samp - 1)) ~/
          max_h_samp) + 7) ~/ 8;
      _comp_v_blocks[component_id] = ((((_image_y_size *
          _comp_v_samp[component_id]) + (max_v_samp - 1)) ~/
          max_v_samp) + 7) ~/ 8;
    }

    if (_comps_in_scan == 1) {
      _mcus_per_row = _comp_h_blocks[_comp_list[0]];
      _mcus_per_col = _comp_v_blocks[_comp_list[0]];
    } else {
      _mcus_per_row = (((_image_x_size + 7) ~/ 8) + (max_h_samp - 1)) ~/
          max_h_samp;
      _mcus_per_col = (((_image_y_size + 7) ~/ 8) + (max_v_samp - 1)) ~/
          max_v_samp;
    }

    if (_comps_in_scan == 1) {
      _mcu_org[0] = _comp_list[0];
      _blocks_per_mcu = 1;
    } else {
      _blocks_per_mcu = 0;
      for (component_num = 0; component_num < _comps_in_scan; component_num++) {
        component_id = _comp_list[component_num];
        int num_blocks = _comp_h_samp[component_id] * _comp_v_samp[component_id];
        while (num_blocks-- > 0) {
          _mcu_org[_blocks_per_mcu++] = component_id;
        }
      }
    }
  }

  void _init_frame() {
    if (_comps_in_frame == 1) {
      if ((_comp_h_samp[0] != 1) || (_comp_v_samp[0] != 1)) {
        _terminate(UNSUPPORTED_SAMP_FACTORS);
      }

      _scan_type = _GRAYSCALE;
      _max_blocks_per_mcu = 1;
      _max_mcu_x_size = 8;
      _max_mcu_y_size = 8;
    } else if (_comps_in_frame == 3) {
      if (((_comp_h_samp[1] != 1) || (_comp_v_samp[1] != 1)) ||
          ((_comp_h_samp[2] != 1) || (_comp_v_samp[2] != 1))) {
        _terminate(UNSUPPORTED_SAMP_FACTORS);
      }

      if ((_comp_h_samp[0] == 1) && (_comp_v_samp[0] == 1)) {
        _scan_type = _YH1V1;
        _max_blocks_per_mcu = 3;
        _max_mcu_x_size = 8;
        _max_mcu_y_size = 8;
      } else if ((_comp_h_samp[0] == 2) && (_comp_v_samp[0] == 1)) {
        _scan_type = _YH2V1;
        _max_blocks_per_mcu = 4;
        _max_mcu_x_size = 16;
        _max_mcu_y_size = 8;
      } else if ((_comp_h_samp[0] == 1) && (_comp_v_samp[0] == 2)) {
        _scan_type = _YH1V2;
        _max_blocks_per_mcu = 4;
        _max_mcu_x_size = 8;
        _max_mcu_y_size = 16;
      } else if ((_comp_h_samp[0] == 2) && (_comp_v_samp[0] == 2)) {
        _scan_type = _YH2V2;
        _max_blocks_per_mcu = 6;
        _max_mcu_x_size = 16;
        _max_mcu_y_size = 16;
      } else {
        _terminate(UNSUPPORTED_SAMP_FACTORS);
      }
    } else {
      _terminate(UNSUPPORTED_COLORSPACE);
    }

    _max_mcus_per_row = (_image_x_size + (_max_mcu_x_size - 1)) ~/
        _max_mcu_x_size;
    _max_mcus_per_col = (_image_y_size + (_max_mcu_y_size - 1)) ~/
        _max_mcu_y_size;

    // these values are for the *destination* pixels: after conversion
    if (_scan_type == _GRAYSCALE) {
      _dest_bytes_per_pixel = 1;
    } else {
      _dest_bytes_per_pixel = 4;
    }

    _dest_bytes_per_scan_line = ((_image_x_size + 15) & 0xFFF0) *
        _dest_bytes_per_pixel;
    _real_dest_bytes_per_scan_line = (_image_x_size * _dest_bytes_per_pixel);

    // Initialize two scan line buffers.
    _scan_line_0 = new Uint8List(_dest_bytes_per_scan_line + 8);
    _scan_line_1 = new Uint8List(_dest_bytes_per_scan_line + 8);

    _max_blocks_per_row = _max_mcus_per_row * _max_blocks_per_mcu;

    // Should never happen
    if (_max_blocks_per_row > _MAX_BLOCKS_PER_ROW) {
      _terminate(ASSERTION_ERROR);
    }

    // Allocate the coefficient buffer, enough for one MCU
    Int16List q = new Int16List(_max_blocks_per_mcu * 64 + 4);
    _mcu_coefficients = q;

    for (int i = 0; i < _max_blocks_per_mcu; ++i) {
      _mcu_block_max_zag[i] = 64;
    }

    _expanded_blocks_per_component = _comp_h_samp[0] * _comp_v_samp[0];
    _expanded_blocks_per_mcu = _expanded_blocks_per_component *
        _comps_in_frame;
    _expanded_blocks_per_row = _max_mcus_per_row * _expanded_blocks_per_mcu;
    // Freq. domain chroma upsampling only supported for H2V2 subsampling factor.
    _freq_domain_chroma_upsample =
        (_SUPPORT_FREQ_DOMAIN_UPSAMPLING != 0) &&
        (_expanded_blocks_per_mcu == 4 * 3);

    if (_freq_domain_chroma_upsample) {
      _sample_buf = new Uint8List(_expanded_blocks_per_row * 64 + 8);
    } else {
      _sample_buf = new Uint8List(_max_blocks_per_row * 64 + 8);
    }

    _total_lines_left = _image_y_size;
    _mcu_lines_left = 0;

    _create_look_ups();
    _init_quant_tables();
  }

  void _init_quant_tables() {
  }

  _JPEG_CoeffBuf _coeff_buf_open(int block_num_x, int block_num_y,
      int block_len_x, int block_len_y) {
    _JPEG_CoeffBuf cb = new _JPEG_CoeffBuf();
    cb.block_num_x = block_num_x;
    cb.block_num_y = block_num_y;
    cb.block_len_x = block_len_x;
    cb.block_len_y = block_len_y;
    cb.block_size = block_len_x * block_len_y;
    cb.Pdata = new Int16List(cb.block_size * block_num_x * block_num_y);
    return cb;
  }

  int _coeff_buf_getp(_JPEG_CoeffBuf cb, int block_x, int block_y) {
    if (block_x >= cb.block_num_x) {
      _terminate(ASSERTION_ERROR);
    }

    if (block_y >= cb.block_num_y) {
      _terminate(ASSERTION_ERROR);
    }

    return block_x * cb.block_size + block_y * (cb.block_size * cb.block_num_x);
  }

  static void _R_S_calc(int NUM_ROWS, int NUM_COLS, _DCT_Upsample_Matrix44 R,
      _DCT_Upsample_Matrix44 S, Int16List Psrc, int Pi) {
    const int FRACT_BITS = 10;
    const int SCALE = 1 << FRACT_BITS;
    D(i) => (i + (SCALE >> 1)) >> FRACT_BITS;
    F(i) => (i * SCALE + .5).toInt();
    AT(c, r) =>
        (((c >= NUM_COLS) || (r >= NUM_ROWS)) ? 0 : Psrc[Pi + c + r * 8]);

    // 4x8 = 4x8 times 8x8, matrix 0 is constant
    int X100 = D(F(0.906127) * AT(1, 0) + F(-0.318190) * AT(3, 0) +
        F(0.212608) * AT(5, 0) + F(-0.180240) * AT(7, 0));
    int X101 = D(F(0.906127) * AT(1, 1) + F(-0.318190) * AT(3, 1) +
        F(0.212608) * AT(5, 1) + F(-0.180240) * AT(7, 1));
    int X102 = D(F(0.906127) * AT(1, 2) + F(-0.318190) * AT(3, 2) +
        F(0.212608) * AT(5, 2) + F(-0.180240) * AT(7, 2));
    int X103 = D(F(0.906127) * AT(1, 3) + F(-0.318190) * AT(3, 3) +
        F(0.212608) * AT(5, 3) + F(-0.180240) * AT(7, 3));
    int X104 = D(F(0.906127) * AT(1, 4) + F(-0.318190) * AT(3, 4) +
        F(0.212608) * AT(5, 4) + F(-0.180240) * AT(7, 4));
    int X105 = D(F(0.906127) * AT(1, 5) + F(-0.318190) * AT(3, 5) +
        F(0.212608) * AT(5, 5) + F(-0.180240) * AT(7, 5));
    int X106 = D(F(0.906127) * AT(1, 6) + F(-0.318190) * AT(3, 6) +
        F(0.212608) * AT(5, 6) + F(-0.180240) * AT(7, 6));
    int X107 = D(F(0.906127) * AT(1, 7) + F(-0.318190) * AT(3, 7) +
        F(0.212608) * AT(5, 7) + F(-0.180240) * AT(7, 7));
    int X110 = AT(2, 0);
    int X111 = AT(2, 1);
    int X112 = AT(2, 2);
    int X113 = AT(2, 3);
    int X114 = AT(2, 4);
    int X115 = AT(2, 5);
    int X116 = AT(2, 6);
    int X117 = AT(2, 7);
    int X120 = D(F(-0.074658) * AT(1, 0) + F(0.513280) * AT(3, 0) +
        F(0.768178) * AT(5, 0) + F(-0.375330) * AT(7, 0));
    int X121 = D(F(-0.074658) * AT(1, 1) + F(0.513280) * AT(3, 1) +
        F(0.768178) * AT(5, 1) + F(-0.375330) * AT(7, 1));
    int X122 = D(F(-0.074658) * AT(1, 2) + F(0.513280) * AT(3, 2) +
        F(0.768178) * AT(5, 2) + F(-0.375330) * AT(7, 2));
    int X123 = D(F(-0.074658) * AT(1, 3) + F(0.513280) * AT(3, 3) +
        F(0.768178) * AT(5, 3) + F(-0.375330) * AT(7, 3));
    int X124 = D(F(-0.074658) * AT(1, 4) + F(0.513280) * AT(3, 4) +
        F(0.768178) * AT(5, 4) + F(-0.375330) * AT(7, 4));
    int X125 = D(F(-0.074658) * AT(1, 5) + F(0.513280) * AT(3, 5) +
        F(0.768178) * AT(5, 5) + F(-0.375330) * AT(7, 5));
    int X126 = D(F(-0.074658) * AT(1, 6) + F(0.513280) * AT(3, 6) +
        F(0.768178) * AT(5, 6) + F(-0.375330) * AT(7, 6));
    int X127 = D(F(-0.074658) * AT(1, 7) + F(0.513280) * AT(3, 7) +
        F(0.768178) * AT(5, 7) + F(-0.375330) * AT(7, 7));
    int X130 = AT(6, 0);
    int X131 = AT(6, 1);
    int X132 = AT(6, 2);
    int X133 = AT(6, 3);
    int X134 = AT(6, 4);
    int X135 = AT(6, 5);
    int X136 = AT(6, 6);
    int X137 = AT(6, 7);

    // 4x4 = 4x8 times 8x4, matrix 1 is constant
    R.v[0] = X100;
    R.v[1] = D(X101 * F(0.415735) + X103 * F(0.791065) +
        X105 * F(-0.352443) + X107 * F(0.277785));
    R.v[2] = X104;
    R.v[3] = D(X101 * F(0.022887) + X103 * F(-0.097545) +
        X105 * F(0.490393) + X107 * F(0.865723));
    R.v[4] = X110;
    R.v[5] = D(X111 * F(0.415735) + X113 * F(0.791065) +
        X115 * F(-0.352443) + X117 * F(0.277785));
    R.v[6] = X114;
    R.v[7] = D(X111 * F(0.022887) + X113 * F(-0.097545) +
        X115 * F(0.490393) + X117 * F(0.865723));
    R.v[8] = X120;
    R.v[9] = D(X121 * F(0.415735) + X123 * F(0.791065) +
        X125 * F(-0.352443) + X127 * F(0.277785));
    R.v[10] = X124;
    R.v[11] = D(X121 * F(0.022887) + X123 * F(-0.097545) +
        X125 * F(0.490393) + X127 * F(0.865723));
    R.v[12] = X130;
    R.v[13] = D(X131 * F(0.415735) + X133 * F(0.791065) +
        X135 * F(-0.352443) + X137 * F(0.277785));
    R.v[14] = X134;
    R.v[15] = D(X131 * F(0.022887) + X133 * F(-0.097545) +
        X135 * F(0.490393) + X137 * F(0.865723));

    // 4x4 = 4x8 times 8x4, matrix 1 is constant
    S.v[0] = D(X101 * F(0.906127) + X103 * F(-0.318190) +
        X105 * F(0.212608) + X107 * F(-0.180240));
    S.v[1] = X102;
    S.v[2] = D(X101 * F(-0.074658) + X103 * F(0.513280) +
        X105 * F(0.768178) + X107 * F(-0.375330));
    S.v[3] = X106;
    S.v[4] = D(X111 * F(0.906127) + X113 * F(-0.318190) +
        X115 * F(0.212608) + X117 * F(-0.180240));
    S.v[5] = X112;
    S.v[6] = D(X111 * F(-0.074658) + X113 * F(0.513280) +
        X115 * F(0.768178) + X117 * F(-0.375330));
    S.v[7] = X116;
    S.v[8] = D(X121 * F(0.906127) + X123 * F(-0.318190) +
        X125 * F(0.212608) + X127 * F(-0.180240));
    S.v[9] = X122;
    S.v[10] = D(X121 * F(-0.074658) + X123 * F(0.513280) +
        X125 * F(0.768178) + X127 * F(-0.375330));
    S.v[11] = X126;
    S.v[12] = D(X131 * F(0.906127) + X133 * F(-0.318190) +
        X135 * F(0.212608) + X137 * F(-0.180240));
    S.v[13] = X132;
    S.v[14] = D(X131 * F(-0.074658) + X133 * F(0.513280) +
        X135 * F(0.768178) + X137 * F(-0.375330));
    S.v[15] = X136;
  }

  static void _P_Q_calc(int NUM_ROWS, int NUM_COLS, _DCT_Upsample_Matrix44 P,
      _DCT_Upsample_Matrix44 Q, Int16List Psrc, int Pi) {
    const int FRACT_BITS = 10;
    const int SCALE = 1 << FRACT_BITS;
    int D(int i) => (i + (SCALE >> 1)) >> FRACT_BITS;
    int F(i) => (i * SCALE + 0.5).toInt();
    int AT(int c, int r) =>
        (((c >= NUM_COLS) || (r >= NUM_ROWS)) ? 0 : Psrc[Pi + c + r * 8]);

    // 4x8 = 4x8 times 8x8, matrix 0 is constant
    int X000 = AT(0, 0);
    int X001 = AT(0, 1);
    int X002 = AT(0, 2);
    int X003 = AT(0, 3);
    int X004 = AT(0, 4);
    int X005 = AT(0, 5);
    int X006 = AT(0, 6);
    int X007 = AT(0, 7);
    int X010 = D(F(0.415735) * AT(1, 0) + F(0.791065) * AT(3, 0) +
        F(-0.352443) * AT(5, 0) + F(0.277785) * AT(7, 0));
    int X011 = D(F(0.415735) * AT(1, 1) + F(0.791065) * AT(3, 1) +
        F(-0.352443) * AT(5, 1) + F(0.277785) * AT(7, 1));
    int X012 = D(F(0.415735) * AT(1, 2) + F(0.791065) * AT(3, 2) +
        F(-0.352443) * AT(5, 2) + F(0.277785) * AT(7, 2));
    int X013 = D(F(0.415735) * AT(1, 3) + F(0.791065) * AT(3, 3) +
        F(-0.352443) * AT(5, 3) + F(0.277785) * AT(7, 3));
    int X014 = D(F(0.415735) * AT(1, 4) + F(0.791065) * AT(3, 4) +
        F(-0.352443) * AT(5, 4) + F(0.277785) * AT(7, 4));
    int X015 = D(F(0.415735) * AT(1, 5) + F(0.791065) * AT(3, 5) +
        F(-0.352443) * AT(5, 5) + F(0.277785) * AT(7, 5));
    int X016 = D(F(0.415735) * AT(1, 6) + F(0.791065) * AT(3, 6) +
        F(-0.352443) * AT(5, 6) + F(0.277785) * AT(7, 6));
    int X017 = D(F(0.415735) * AT(1, 7) + F(0.791065) * AT(3, 7) +
        F(-0.352443) * AT(5, 7) + F(0.277785) * AT(7, 7));
    int X020 = AT(4, 0);
    int X021 = AT(4, 1);
    int X022 = AT(4, 2);
    int X023 = AT(4, 3);
    int X024 = AT(4, 4);
    int X025 = AT(4, 5);
    int X026 = AT(4, 6);
    int X027 = AT(4, 7);
    int X030 = D(F(0.022887) * AT(1, 0) + F(-0.097545) * AT(3, 0) +
        F(0.490393) * AT(5, 0) + F(0.865723) * AT(7, 0));
    int X031 = D(F(0.022887) * AT(1, 1) + F(-0.097545) * AT(3, 1) +
        F(0.490393) * AT(5, 1) + F(0.865723) * AT(7, 1));
    int X032 = D(F(0.022887) * AT(1, 2) + F(-0.097545) * AT(3, 2) +
        F(0.490393) * AT(5, 2) + F(0.865723) * AT(7, 2));
    int X033 = D(F(0.022887) * AT(1, 3) + F(-0.097545) * AT(3, 3) +
        F(0.490393) * AT(5, 3) + F(0.865723) * AT(7, 3));
    int X034 = D(F(0.022887) * AT(1, 4) + F(-0.097545) * AT(3, 4) +
        F(0.490393) * AT(5, 4) + F(0.865723) * AT(7, 4));
    int X035 = D(F(0.022887) * AT(1, 5) + F(-0.097545) * AT(3, 5) +
        F(0.490393) * AT(5, 5) + F(0.865723) * AT(7, 5));
    int X036 = D(F(0.022887) * AT(1, 6) + F(-0.097545) * AT(3, 6) +
        F(0.490393) * AT(5, 6) + F(0.865723) * AT(7, 6));
    int X037 = D(F(0.022887) * AT(1, 7) + F(-0.097545) * AT(3, 7) +
        F(0.490393) * AT(5, 7) + F(0.865723) * AT(7, 7));

    // 4x4 = 4x8 times 8x4, matrix 1 is constant
    P.v[0] = X000;
    P.v[1] = D(X001 * F(0.415735) + X003 * F(0.791065) +
        X005 * F(-0.352443) + X007 * F(0.277785));
    P.v[2] = X004;
    P.v[3] = D(X001 * F(0.022887) + X003 * F(-0.097545) +
        X005 * F(0.490393) + X007 * F(0.865723));
    P.v[4] = X010;
    P.v[5] = D(X011 * F(0.415735) + X013 * F(0.791065) +
        X015 * F(-0.352443) + X017 * F(0.277785));
    P.v[6] = X014;
    P.v[7] = D(X011 * F(0.022887) + X013 * F(-0.097545) +
        X015 * F(0.490393) + X017 * F(0.865723));
    P.v[8] = X020;
    P.v[9] = D(X021 * F(0.415735) + X023 * F(0.791065) +
        X025 * F(-0.352443) + X027 * F(0.277785));
    P.v[10] = X024;
    P.v[11] = D(X021 * F(0.022887) + X023 * F(-0.097545) +
        X025 * F(0.490393) + X027 * F(0.865723));
    P.v[12] = X030;
    P.v[13] = D(X031 * F(0.415735) + X033 * F(0.791065) +
        X035 * F(-0.352443) + X037 * F(0.277785));
    P.v[14] = X034;
    P.v[15] = D(X031 * F(0.022887) + X033 * F(-0.097545) +
        X035 * F(0.490393) + X037 * F(0.865723));

    // 4x4 = 4x8 times 8x4, matrix 1 is constant
    Q.v[0] = D(X001 * F(0.906127) + X003 * F(-0.318190) +
        X005 * F(0.212608) + X007 * F(-0.180240));
    Q.v[1] = X002;
    Q.v[2] = D(X001 * F(-0.074658) + X003 * F(0.513280) +
        X005 * F(0.768178) + X007 * F(-0.375330));
    Q.v[3] = X006;
    Q.v[4] = D(X011 * F(0.906127) + X013 * F(-0.318190) +
        X015 * F(0.212608) + X017 * F(-0.180240));
    Q.v[5] = X012;
    Q.v[6] = D(X011 * F(-0.074658) + X013 * F(0.513280) +
        X015 * F(0.768178) + X017 * F(-0.375330));
    Q.v[7] = X016;
    Q.v[8] = D(X021 * F(0.906127) + X023 * F(-0.318190) +
        X025 * F(0.212608) + X027 * F(-0.180240));
    Q.v[9] = X022;
    Q.v[10] = D(X021 * F(-0.074658) + X023 * F(0.513280) +
        X025 * F(0.768178) + X027 * F(-0.375330));
    Q.v[11] = X026;
    Q.v[12] = D(X031 * F(0.906127) + X033 * F(-0.318190) +
        X035 * F(0.212608) + X037 * F(-0.180240));
    Q.v[13] = X032;
    Q.v[14] = D(X031 * F(-0.074658) + X033 * F(0.513280) +
        X035 * F(0.768178) + X037 * F(-0.375330));
    Q.v[15] = X036;
  }

  void _idct_4x4(Int16List data, Uint8List Pdst, int Pdst_ptr) {
    Int32List temp = new Int32List(64);

    int dataptr = 0;
    int tempptr = 0;
    for (int i = 4; i > 0; i--) {
      _idct_row(4, temp, tempptr, data, dataptr);
      dataptr += 8;
      tempptr += 8;
    }

    tempptr = 0;
    for (int i = 8; i > 0; i--) {
      _idct_col(4, Pdst, Pdst_ptr, temp, tempptr);
      tempptr++;
      Pdst_ptr++;
    }
  }

  void _idct(Int16List data, int src, Uint8List pDst, int dst,
      int block_max_zag) {
    if (block_max_zag == 1) {
      int k = ((data[src + 0] + 4) >> 3) + 128;
      k = _CLAMP(k);
      k = k | (k << 8);
      k = k | (k << 16);

      Int32List d = new Int32List.view(pDst.buffer, dst);
      int di = 0;
      for (int i = 8; i > 0; i--) {
        d[di++] = k;
        d[di++] = k;
      }
      return;
    }

    Int32List temp = new Int32List(64);
    int dataptr = src;
    int tempptr = 0;

    int Prow_tab = (block_max_zag - 1) * 8;

    for (int i = 8; i > 0; i--, Prow_tab++) {
      _idct_row(_ROW_TABLE[Prow_tab], temp, tempptr, data, dataptr);
      dataptr += 8;
      tempptr += 8;
    }

    tempptr = 0;

    int nonzero_rows = _COL_TABLE[block_max_zag - 1];
    for (int i = 8; i > 0; i--) {
      _idct_col(nonzero_rows, pDst, dst, temp, tempptr);
      tempptr++;
      dst++;
    }
  }

  void _idct_row(int NONZERO_COLS, List<int> temp, int tempptr,
      Int16List data, int dataptr) {
    if (NONZERO_COLS == 0) {
      return;
    }

    if (NONZERO_COLS == 1) {
      int dcval = (data[dataptr] << _PASS1_BITS);
      temp[tempptr] = dcval;
      temp[tempptr + 1] = dcval;
      temp[tempptr + 2] = dcval;
      temp[tempptr + 3] = dcval;
      temp[tempptr + 4] = dcval;
      temp[tempptr + 5] = dcval;
      temp[tempptr + 6] = dcval;
      temp[tempptr + 7] = dcval;
      return;
    }

    ACCESS_COL(x) => ((x < NONZERO_COLS) ? data[dataptr + x] : 0);

    int z2 = ACCESS_COL(2);
    int z3 = ACCESS_COL(6);

    int z1 = _MULTIPLY(z2 + z3, _FIX_0_541196100);
    int tmp2 = z1 + _MULTIPLY(z3, -_FIX_1_847759065);
    int tmp3 = z1 + _MULTIPLY(z2, _FIX_0_765366865);

    int tmp0 = (ACCESS_COL(0) + ACCESS_COL(4)) << _CONST_BITS;
    int tmp1 = (ACCESS_COL(0) - ACCESS_COL(4)) << _CONST_BITS;

    int tmp10 = tmp0 + tmp3;
    int tmp13 = tmp0 - tmp3;
    int tmp11 = tmp1 + tmp2;
    int tmp12 = tmp1 - tmp2;

    int atmp0 = ACCESS_COL(7);
    int atmp1 = ACCESS_COL(5);
    int atmp2 = ACCESS_COL(3);
    int atmp3 = ACCESS_COL(1);

    int bz1 = atmp0 + atmp3;
    int bz2 = atmp1 + atmp2;
    int bz3 = atmp0 + atmp2;
    int bz4 = atmp1 + atmp3;
    int bz5 = _MULTIPLY(bz3 + bz4, _FIX_1_175875602);

    int az1 = _MULTIPLY(bz1, -_FIX_0_899976223);
    int az2 = _MULTIPLY(bz2, -_FIX_2_562915447);
    int az3 = _MULTIPLY(bz3, -_FIX_1_961570560) + bz5;
    int az4 = _MULTIPLY(bz4, -_FIX_0_390180644) + bz5;

    int btmp0 = _MULTIPLY(atmp0, _FIX_0_298631336) + az1 + az3;
    int btmp1 = _MULTIPLY(atmp1, _FIX_2_053119869) + az2 + az4;
    int btmp2 = _MULTIPLY(atmp2, _FIX_3_072711026) + az2 + az3;
    int btmp3 = _MULTIPLY(atmp3, _FIX_1_501321110) + az1 + az4;

    temp[tempptr + 0] = _DESCALE(tmp10 + btmp3, _CONST_BITS - _PASS1_BITS);
    temp[tempptr + 7] = _DESCALE(tmp10 - btmp3, _CONST_BITS - _PASS1_BITS);
    temp[tempptr + 1] = _DESCALE(tmp11 + btmp2, _CONST_BITS - _PASS1_BITS);
    temp[tempptr + 6] = _DESCALE(tmp11 - btmp2, _CONST_BITS - _PASS1_BITS);
    temp[tempptr + 2] = _DESCALE(tmp12 + btmp1, _CONST_BITS - _PASS1_BITS);
    temp[tempptr + 5] = _DESCALE(tmp12 - btmp1, _CONST_BITS - _PASS1_BITS);
    temp[tempptr + 3] = _DESCALE(tmp13 + btmp0, _CONST_BITS - _PASS1_BITS);
    temp[tempptr + 4] = _DESCALE(tmp13 - btmp0, _CONST_BITS - _PASS1_BITS);
  }

  void _idct_col(int NONZERO_ROWS, Uint8List dst, int Pdst_ptr, List<int> temp,
      int tempptr) {
    if (NONZERO_ROWS == 1) {
      int dcval = _DESCALE_ZEROSHIFT(temp[tempptr], _PASS1_BITS + 3);

      dcval = _CLAMP(dcval);
      int dcvalByte = dcval & 0xFF;

      dst[Pdst_ptr + 0 * 8] = dcvalByte;
      dst[Pdst_ptr + 1 * 8] = dcvalByte;
      dst[Pdst_ptr + 2 * 8] = dcvalByte;
      dst[Pdst_ptr + 3 * 8] = dcvalByte;
      dst[Pdst_ptr + 4 * 8] = dcvalByte;
      dst[Pdst_ptr + 5 * 8] = dcvalByte;
      dst[Pdst_ptr + 6 * 8] = dcvalByte;
      dst[Pdst_ptr + 7 * 8] = dcvalByte;
      return;
    }

    // will be optimized at compile time to either an array access, or 0
    ACCESS_ROW(x) => ((x < NONZERO_ROWS) ? temp[tempptr + x * 8] : 0);

    int z2 = ACCESS_ROW(2);
    int z3 = ACCESS_ROW(6);

    int z1 = _MULTIPLY(z2 + z3, _FIX_0_541196100);
    int tmp2 = z1 + _MULTIPLY(z3, - _FIX_1_847759065);
    int tmp3 = z1 + _MULTIPLY(z2, _FIX_0_765366865);

    int tmp0 = (ACCESS_ROW(0) + ACCESS_ROW(4)) << _CONST_BITS;
    int tmp1 = (ACCESS_ROW(0) - ACCESS_ROW(4)) << _CONST_BITS;

    int tmp10 = tmp0 + tmp3;
    int tmp13 = tmp0 - tmp3;
    int tmp11 = tmp1 + tmp2;
    int tmp12 = tmp1 - tmp2;

    int atmp0 = ACCESS_ROW(7);
    int atmp1 = ACCESS_ROW(5);
    int atmp2 = ACCESS_ROW(3);
    int atmp3 = ACCESS_ROW(1);

    int bz1 = atmp0 + atmp3;
    int bz2 = atmp1 + atmp2;
    int bz3 = atmp0 + atmp2;
    int bz4 = atmp1 + atmp3;
    int bz5 = _MULTIPLY(bz3 + bz4, _FIX_1_175875602);

    int az1 = _MULTIPLY(bz1, - _FIX_0_899976223);
    int az2 = _MULTIPLY(bz2, - _FIX_2_562915447);
    int az3 = _MULTIPLY(bz3, - _FIX_1_961570560) + bz5;
    int az4 = _MULTIPLY(bz4, - _FIX_0_390180644) + bz5;

    int btmp0 = _MULTIPLY(atmp0, _FIX_0_298631336) + az1 + az3;
    int btmp1 = _MULTIPLY(atmp1, _FIX_2_053119869) + az2 + az4;
    int btmp2 = _MULTIPLY(atmp2, _FIX_3_072711026) + az2 + az3;
    int btmp3 = _MULTIPLY(atmp3, _FIX_1_501321110) + az1 + az4;

    int i = 0;

    i = _DESCALE_ZEROSHIFT(tmp10 + btmp3, _CONST_BITS + _PASS1_BITS + 3);
    i = _CLAMP(i);
    dst[Pdst_ptr + 8 * 0] = i;

    i = _DESCALE_ZEROSHIFT(tmp10 - btmp3, _CONST_BITS + _PASS1_BITS + 3);
    i = _CLAMP(i);
    dst[Pdst_ptr + 8 * 7] = i;

    i = _DESCALE_ZEROSHIFT(tmp11 + btmp2, _CONST_BITS + _PASS1_BITS + 3);
    i = _CLAMP(i);
    dst[Pdst_ptr + 8 * 1] = i;

    i = _DESCALE_ZEROSHIFT(tmp11 - btmp2, _CONST_BITS + _PASS1_BITS + 3);
    i = _CLAMP(i);
    dst[Pdst_ptr + 8 * 6] = i;

    i = _DESCALE_ZEROSHIFT(tmp12 + btmp1, _CONST_BITS + _PASS1_BITS + 3);
    i = _CLAMP(i);
    dst[Pdst_ptr + 8 * 2] = i;

    i = _DESCALE_ZEROSHIFT(tmp12 - btmp1, _CONST_BITS + _PASS1_BITS + 3);
    i = _CLAMP(i);
    dst[Pdst_ptr + 8 * 5] = i;

    i = _DESCALE_ZEROSHIFT(tmp13 + btmp0, _CONST_BITS + _PASS1_BITS + 3);
    i = _CLAMP(i);
    dst[Pdst_ptr + 8 * 3] = i;

    i = _DESCALE_ZEROSHIFT(tmp13 - btmp0, _CONST_BITS + _PASS1_BITS + 3);
    i = _CLAMP(i);
    dst[Pdst_ptr + 8 * 4] = i;
  }

  void _terminate(int code) {
    _error_code = code;
    throw new ImageException("JPEG ERROR: $code");
  }

  int _get_char() {
    if (_stream.isEOS) {
      return 0;
    }
    return _stream.readByte();
  }

  int _get_octet() {
    int c = _get_char();
    if (c == 0xFF) {
      c = _get_char();
      if (c == 0x00) {
        return 0xFF;
      }
      _stream.skip(-2);
      return 0xFF;
    }
    return c;
  }

  int _get_bits_1(int num_bits) {
    if (num_bits <= 0) {
      return 0;
    }

    int i = (_bit_buf >> (32 - num_bits)) & 0xFFFFFFFF;

    if ((_bits_left -= num_bits) <= 0) {
      num_bits += _bits_left;
      _bit_buf <<= num_bits;
      int c1 = _get_char();
      int c2 = _get_char();
      _bit_buf = (_bit_buf & 0xFFFF0000) | (c1 << 8) | c2;
      _bit_buf = (_bit_buf << -_bits_left) & 0xFFFFFFFF;

      _bits_left += 16;
    } else {
      _bit_buf = (_bit_buf << num_bits) & 0xFFFFFFFF;
    }

    return i;
  }

  int _get_bits_2(int num_bits) {
    if (num_bits <= 0) {
      return 0;
    }

    int i = (_bit_buf >> (32 - num_bits)) & 0xFFFFFFFF;

    if ((_bits_left -= num_bits) <= 0) {
      num_bits += _bits_left;
      _bit_buf = (_bit_buf << num_bits) & 0xFFFFFFFF;

      if ((_stream.length < 2) ||
          (_stream[0] == 0xFF) || (_stream[1] == 0xFF)) {
        int c1 = _get_octet();
        int c2 = _get_octet();
        _bit_buf = (_bit_buf | (c1 << 8) | c2) & 0xFFFFFFFF;
      } else {
        int c1 = _get_char();
        int c2 = _get_char();
        _bit_buf = (_bit_buf | (c1 << 8) | c2) & 0xFFFFFFFF;
      }

      _bit_buf = (_bit_buf << -_bits_left) & 0xFFFFFFFF;

      _bits_left += 16;
    } else {
      _bit_buf = (_bit_buf << num_bits) & 0xFFFFFFFF;
    }

    return i;
  }

  int _huff_decode(_JPEG_HuffTables Ph, [List<int> extra_bits]) {
    // Check first 8-bits: do we have a complete symbol?
    int li = _bit_buf >> 24;
    int symbol = extra_bits == null ?
        _uint32ToInt32(Ph.look_up[li]) :
        _uint32ToInt32(Ph.look_up2[li]);

    if (symbol < 0) {
      // Use a tree traversal to find symbol.
      int ofs = 23;
      do {
        symbol = _uint32ToInt32(Ph.tree[-(symbol + ((_bit_buf >> ofs) & 1))]);
        ofs--;
      } while (symbol < 0);

      _get_bits_2(8 + (23 - ofs));
      if (extra_bits != null) {
        extra_bits[0] = _get_bits_2(symbol & 0xF);
      }
    } else {
      if (extra_bits == null) {
        int count = Ph.code_size[symbol];
        _get_bits_2(count);
        return symbol;
      }

      if (symbol & 0x8000 != 0) {
        _get_bits_2((symbol >> 8) & 31);
        extra_bits[0] = symbol >> 16;
      } else {
        int code_size = (symbol >> 8) & 31;
        int num_extra_bits = symbol & 0xF;
        int bits = code_size + num_extra_bits;
        if (bits <= (_bits_left + 16)) {
          extra_bits[0] = _get_bits_2(bits) & ((1 << num_extra_bits) - 1);
        } else {
          _get_bits_2(code_size);
          extra_bits[0] = _get_bits_2(num_extra_bits);
        }
      }

      symbol &= 0xFF;
    }

    return symbol;
  }

  int _clamp(int i) {
    int ui = _int32ToUint32(i);
    if (ui > 255) {
      i = ~i;
      i = i >> 31;
      i = i & 0xFF;
    }
    int c = i & 0xFF;
    return c;
  }

  static const int _GRAYSCALE = 0;
  static const int _YH1V1 = 1;
  static const int _YH2V1 = 2;
  static const int _YH1V2 = 3;
  static const int _YH2V2 = 4;

  static const int _MAX_BLOCKS_PER_MCU = 10;
  static const int _MAX_HUFF_TABLES = 8;
  static const int _MAX_QUANT_TABLES = 4;
  static const int _MAX_COMPONENTS = 4;
  static const int _MAX_COMPS_IN_SCAN = 4;
  static const int _MAX_BLOCKS_PER_ROW = 8192;
  static const int _MAX_HEIGHT = 16384;
  static const int _MAX_WIDTH = 16384;

  static const int M_SOF0  = 0xC0;
  static const int M_SOF1  = 0xC1;
  static const int M_SOF2  = 0xC2;
  static const int M_SOF3  = 0xC3;
  static const int M_SOF5  = 0xC5;
  static const int M_SOF6  = 0xC6;
  static const int M_SOF7  = 0xC7;
  static const int M_JPG   = 0xC8;
  static const int M_SOF9  = 0xC9;
  static const int M_SOF10 = 0xCA;
  static const int M_SOF11 = 0xCB;
  static const int M_SOF13 = 0xCD;
  static const int M_SOF14 = 0xCE;
  static const int M_SOF15 = 0xCF;
  static const int M_DHT   = 0xC4;
  static const int M_DAC   = 0xCC;
  static const int M_RST0  = 0xD0;
  static const int M_RST1  = 0xD1;
  static const int M_RST2  = 0xD2;
  static const int M_RST3  = 0xD3;
  static const int M_RST4  = 0xD4;
  static const int M_RST5  = 0xD5;
  static const int M_RST6  = 0xD6;
  static const int M_RST7  = 0xD7;
  static const int M_SOI   = 0xD8;
  static const int M_EOI   = 0xD9;
  static const int M_SOS   = 0xDA;
  static const int M_DQT   = 0xDB;
  static const int M_DNL   = 0xDC;
  static const int M_DRI   = 0xDD;
  static const int M_DHP   = 0xDE;
  static const int M_EXP   = 0xDF;
  static const int M_APP0  = 0xe0; // JFIF
  static const int M_APP1  = 0xe1; //
  static const int M_APP2  = 0xe2;
  static const int M_APP3  = 0xe3;
  static const int M_APP4  = 0xe4;
  static const int M_APP5  = 0xe5;
  static const int M_APP6  = 0xe6;
  static const int M_APP7  = 0xe7;
  static const int M_APP8  = 0xe8;
  static const int M_APP9  = 0xe9;
  static const int M_APP10 = 0xea;
  static const int M_APP11 = 0xeb;
  static const int M_APP12 = 0xec;
  static const int M_APP13 = 0xed;
  static const int M_APP14 = 0xee; // ADOBE
  static const int M_APP15 = 0xef;
  static const int M_JPG0  = 0xF0;
  static const int M_JPG13 = 0xFD;
  static const int M_COM   = 0xFE;
  static const int M_TEM   = 0x01;
  static const int M_ERROR = 0x100;

  static const int FALSE = 0;
  static const int TRUE = 1;

  int _image_x_size = 0;
  int _image_y_size = 0;

  InputBuffer _stream;

  int _progressive_flag = 0;

  Uint8List _huff_ac = new Uint8List(_MAX_HUFF_TABLES);
  // pointer to number of Huffman codes per bit size
  List<Uint8List> _huff_num = new List<Uint8List>(_MAX_HUFF_TABLES);
  // pointer to Huffman codes per bit size
  List<Uint8List> _huff_val = new List<Uint8List>(_MAX_HUFF_TABLES);
  // pointer to quantization tables
  List<Int16List> _quant = new List<Int16List>(_MAX_QUANT_TABLES);
  // Grey, Yh1v1, Yh1v2, Yh2v1, Yh2v2, CMYK111, CMYK4114
  int _scan_type = 0;

  // # of components in frame
  int _comps_in_frame = 0;
  Int32List _comp_h_samp = new Int32List(_MAX_COMPONENTS);     /* component's horizontal sampling factor */
  Int32List _comp_v_samp = new Int32List(_MAX_COMPONENTS);     /* component's vertical sampling factor */
  Int32List _comp_quant = new Int32List(_MAX_COMPONENTS);      /* component's quantization table selector */
  Int32List _comp_ident = new Int32List(_MAX_COMPONENTS);      /* component's ID */

  Int32List _comp_h_blocks = new Int32List(_MAX_COMPONENTS);
  Int32List _comp_v_blocks = new Int32List(_MAX_COMPONENTS);

  int _comps_in_scan = 0;                  /* # of components in scan */
  Int32List _comp_list = new Int32List(_MAX_COMPS_IN_SCAN);      /* components in this scan */
  Int32List _comp_dc_tab = new Int32List(_MAX_COMPONENTS);     /* component's DC Huffman coding table selector */
  Int32List _comp_ac_tab = new Int32List(_MAX_COMPONENTS);     /* component's AC Huffman coding table selector */

  int _spectral_start = 0;                 /* spectral selection start */
  int _spectral_end = 0;                   /* spectral selection end   */
  int _successive_low = 0;                 /* successive approximation low */
  int _successive_high = 0;                /* successive approximation high */

  int _max_mcu_x_size = 0;                 /* MCU's max. X size in pixels */
  int _max_mcu_y_size = 0;                 /* MCU's max. Y size in pixels */

  int _blocks_per_mcu = 0;
  int _max_blocks_per_row = 0;
  int _mcus_per_row = 0;
  int _mcus_per_col = 0;

  Int32List _mcu_org = new Int32List(_MAX_BLOCKS_PER_MCU);

  int _total_lines_left = 0; // total # lines left in image
  int _mcu_lines_left = 0; // total # lines left in this MCU

  int _real_dest_bytes_per_scan_line = 0;
  int _dest_bytes_per_scan_line = 0; // rounded up
  int _dest_bytes_per_pixel = 0;     // currently, 4 (RGB) or 1 (Y)

  List<_JPEG_HuffTables> _huff_tabs = new List<_JPEG_HuffTables>(_MAX_HUFF_TABLES);
  List<_JPEG_CoeffBuf> _dc_coeffs = new List<_JPEG_CoeffBuf>(_MAX_COMPONENTS);
  List<_JPEG_CoeffBuf> _ac_coeffs = new List<_JPEG_CoeffBuf>(_MAX_COMPONENTS);

  int _eob_run = 0;

  Int32List _block_y_mcu = new Int32List(_MAX_COMPONENTS);

  int _bits_left = 0;
  int _bit_buf = 0;

  int _restart_interval = 0;
  int _restarts_left = 0;
  int _next_restart_num = 0;

  int _max_mcus_per_row = 0;
  int _max_blocks_per_mcu = 0;
  int _expanded_blocks_per_mcu = 0;
  int _expanded_blocks_per_row = 0;
  int _expanded_blocks_per_component = 0;
  bool _freq_domain_chroma_upsample = false;

  int _max_mcus_per_col = 0;

  Uint32List _last_dc_val = new Uint32List(_MAX_COMPONENTS);

  Int16List _mcu_coefficients;
  Int32List _mcu_block_max_zag = new Int32List(_MAX_BLOCKS_PER_MCU);

  Uint8List _sample_buf;

  Int32List _crr = new Int32List(256);
  Int32List _cbb = new Int32List(256);
  Int32List _crg = new Int32List(256);
  Int32List _cbg = new Int32List(256);

  Uint8List _scan_line_0;
  Uint8List _scan_line_1;

  int _error_code = 0;
  bool _ready_flag = false;

  //----------------------------------------------------------------------------
  // Tables and macro used to fully decode the DPCM differences.
  static const List<int> _EXTEND_TEST = const [ /* entry n is 2**(n-1) */
      0, 0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0040, 0x0080,
      0x0100, 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000 ];

  static const List<int> _EXTEND_OFFSET = const [ // entry n is (-1 << n) + 1
      0, ((-1)<<1) + 1, ((-1)<<2) + 1, ((-1)<<3) + 1, ((-1)<<4) + 1,
      ((-1)<<5) + 1, ((-1)<<6) + 1, ((-1)<<7) + 1, ((-1)<<8) + 1,
      ((-1)<<9) + 1, ((-1)<<10) + 1, ((-1)<<11) + 1, ((-1)<<12) + 1,
      ((-1)<<13) + 1, ((-1)<<14) + 1, ((-1)<<15) + 1 ];

  // used by huff_extend()
  static const List<int> _EXTEND_MASK = const [
      0,
      (1<<0), (1<<1), (1<<2), (1<<3),
      (1<<4), (1<<5), (1<<6), (1<<7),
      (1<<8), (1<<9), (1<<10), (1<<11),
      (1<<12), (1<<13), (1<<14), (1<<15),
      (1<<16) ];

  int _HUFF_EXTEND_TBL(x, s) =>
      ((x) < _EXTEND_TEST[s] ? (x) + _EXTEND_OFFSET[s] : (x));

  int _HUFF_EXTEND(x, s) => _HUFF_EXTEND_TBL(x, s);
  int _HUFF_EXTEND_P(x, s) => _HUFF_EXTEND_TBL(x, s);

  static const int _SUPPORT_FREQ_DOMAIN_UPSAMPLING = 1;
  static const List<int> _ZAG = const [
      0,  1,  8, 16,  9,  2,  3, 10,
      17, 24, 32, 25, 18, 11,  4,  5,
      12, 19, 26, 33, 40, 48, 41, 34,
      27, 20, 13,  6,  7, 14, 21, 28,
      35, 42, 49, 56, 57, 50, 43, 36,
      29, 22, 15, 23, 30, 37, 44, 51,
      58, 59, 52, 45, 38, 31, 39, 46,
      53, 60, 61, 54, 47, 55, 62, 63 ];

  static const int R1_Z = 1;
  static const int R2_Z = 2;
  static const int R3_Z = 3;
  static const int R4_Z = 4;
  static const int R5_Z = 5;
  static const int R6_Z = 6;
  static const int R7_Z = 7;
  static const int R8_Z = 8;
  static const int R1 = 1;
  static const int R2 = 2;
  static const int R3 = 3;
  static const int R4 = 4;
  static const int R5 = 5;
  static const int R6 = 6;
  static const int R7 = 7;
  static const int R8 = 8;

  static const List<int> _ROW_TABLE = const [
      R1_Z,  0,    0,    0,    0,    0,    0,    0,
      R2_Z,  0,    0,    0,    0,    0,    0,    0,
      R2,   R1_Z,  0,    0,    0,    0,    0,    0,
      R2,   R1,   R1_Z,  0,    0,    0,    0,    0,
      R2,   R2,   R1_Z,  0,    0,    0,    0,    0,
      R3,   R2,   R1_Z,  0,    0,    0,    0,    0,
      R4,   R2,   R1_Z,  0,    0,    0,    0,    0,
      R4,   R3,   R1_Z,  0,    0,    0,    0,    0,
      R4,   R3,   R2_Z,  0,    0,    0,    0,    0,
      R4,   R3,   R2,   R1_Z,  0,    0,    0,    0,
      R4,   R3,   R2,   R1,   R1_Z,  0,    0,    0,
      R4,   R3,   R2,   R2,   R1_Z,  0,    0,    0,
      R4,   R3,   R3,   R2,   R1_Z,  0,    0,    0,
      R4,   R4,   R3,   R2,   R1_Z,  0,    0,    0,
      R5,   R4,   R3,   R2,   R1_Z,  0,    0,    0,
      R6,   R4,   R3,   R2,   R1_Z,  0,    0,    0,
      R6,   R5,   R3,   R2,   R1_Z,  0,    0,    0,
      R6,   R5,   R4,   R2,   R1_Z,  0,    0,    0,
      R6,   R5,   R4,   R3,   R1_Z,  0,    0,    0,
      R6,   R5,   R4,   R3,   R2_Z,  0,    0,    0,
      R6,   R5,   R4,   R3,   R2,   R1_Z,  0,    0,
      R6,   R5,   R4,   R3,   R2,   R1,   R1_Z,  0,
      R6,   R5,   R4,   R3,   R2,   R2,   R1_Z,  0,
      R6,   R5,   R4,   R3,   R3,   R2,   R1_Z,  0,
      R6,   R5,   R4,   R4,   R3,   R2,   R1_Z,  0,
      R6,   R5,   R5,   R4,   R3,   R2,   R1_Z,  0,
      R6,   R6,   R5,   R4,   R3,   R2,   R1_Z,  0,
      R7,   R6,   R5,   R4,   R3,   R2,   R1_Z,  0,
      R8,   R6,   R5,   R4,   R3,   R2,   R1_Z,  0,
      R8,   R7,   R5,   R4,   R3,   R2,   R1_Z,  0,
      R8,   R7,   R6,   R4,   R3,   R2,   R1_Z,  0,
      R8,   R7,   R6,   R5,   R3,   R2,   R1_Z,  0,
      R8,   R7,   R6,   R5,   R4,   R2,   R1_Z,  0,
      R8,   R7,   R6,   R5,   R4,   R3,   R1_Z,  0,
      R8,   R7,   R6,   R5,   R4,   R3,   R2_Z,  0,
      R8,   R7,   R6,   R5,   R4,   R3,   R2,   R1_Z,
      R8,   R7,   R6,   R5,   R4,   R3,   R2,   R2_Z,
      R8,   R7,   R6,   R5,   R4,   R3,   R3,   R2_Z,
      R8,   R7,   R6,   R5,   R4,   R4,   R3,   R2_Z,
      R8,   R7,   R6,   R5,   R5,   R4,   R3,   R2_Z,
      R8,   R7,   R6,   R6,   R5,   R4,   R3,   R2_Z,
      R8,   R7,   R7,   R6,   R5,   R4,   R3,   R2_Z,
      R8,   R8,   R7,   R6,   R5,   R4,   R3,   R2_Z,
      R8,   R8,   R8,   R6,   R5,   R4,   R3,   R2_Z,
      R8,   R8,   R8,   R7,   R5,   R4,   R3,   R2_Z,
      R8,   R8,   R8,   R7,   R6,   R4,   R3,   R2_Z,
      R8,   R8,   R8,   R7,   R6,   R5,   R3,   R2_Z,
      R8,   R8,   R8,   R7,   R6,   R5,   R4,   R2_Z,
      R8,   R8,   R8,   R7,   R6,   R5,   R4,   R3_Z,
      R8,   R8,   R8,   R7,   R6,   R5,   R4,   R4_Z,
      R8,   R8,   R8,   R7,   R6,   R5,   R5,   R4_Z,
      R8,   R8,   R8,   R7,   R6,   R6,   R5,   R4_Z,
      R8,   R8,   R8,   R7,   R7,   R6,   R5,   R4_Z,
      R8,   R8,   R8,   R8,   R7,   R6,   R5,   R4_Z,
      R8,   R8,   R8,   R8,   R8,   R6,   R5,   R4_Z,
      R8,   R8,   R8,   R8,   R8,   R7,   R5,   R4_Z,
      R8,   R8,   R8,   R8,   R8,   R7,   R6,   R4_Z,
      R8,   R8,   R8,   R8,   R8,   R7,   R6,   R5_Z,
      R8,   R8,   R8,   R8,   R8,   R7,   R6,   R6_Z,
      R8,   R8,   R8,   R8,   R8,   R7,   R7,   R6_Z,
      R8,   R8,   R8,   R8,   R8,   R8,   R7,   R6_Z,
      R8,   R8,   R8,   R8,   R8,   R8,   R8,   R6_Z,
      R8,   R8,   R8,   R8,   R8,   R8,   R8,   R7_Z,
      R8,   R8,   R8,   R8,   R8,   R8,   R8,   R8_Z ];

  static const int _C1 = 1;
  static const int _C2 = 2;
  static const int _C3 = 3;
  static const int _C4 = 4;
  static const int _C5 = 5;
  static const int _C6 = 6;
  static const int _C7 = 7;
  static const int _C8 = 8;

  static const List<int> _COL_TABLE = const [
      _C1, _C1, _C2, _C3, _C3, _C3, _C3, _C3,
      _C3, _C4, _C5, _C5, _C5, _C5, _C5, _C5,
      _C5, _C5, _C5, _C5, _C6, _C7, _C7, _C7,
      _C7, _C7, _C7, _C7, _C7, _C7, _C7, _C7,
      _C7, _C7, _C7, _C8, _C8, _C8, _C8, _C8,
      _C8, _C8, _C8, _C8, _C8, _C8, _C8, _C8,
      _C8, _C8, _C8, _C8, _C8, _C8, _C8, _C8,
      _C8, _C8, _C8, _C8, _C8, _C8, _C8, _C8 ];

  _MULTIPLY(v, cnst) => v * cnst;

  static const int _CONST_BITS = 13;
  static const int _PASS1_BITS = 2;

  static const int _FIX_0_298631336 = 2446;        /* FIX 0.298631336 */
  static const int _FIX_0_390180644 = 3196;        /* FIX 0.390180644 */
  static const int _FIX_0_541196100 = 4433;        /* FIX 0.541196100 */
  static const int _FIX_0_765366865 = 6270;        /* FIX 0.765366865 */
  static const int _FIX_0_899976223 = 7373;        /* FIX 0.899976223 */
  static const int _FIX_1_175875602 = 9633;        /* FIX 1.175875602 */
  static const int _FIX_1_501321110 = 12299;       /* FIX 1.501321110 */
  static const int _FIX_1_847759065 = 15137;       /* FIX 1.847759065 */
  static const int _FIX_1_961570560 = 16069;       /* FIX 1.961570560 */
  static const int _FIX_2_053119869 = 16819;       /* FIX 2.053119869 */
  static const int _FIX_2_562915447 = 20995;       /* FIX 2.562915447 */
  static const int _FIX_3_072711026 = 25172;       /* FIX 3.072711026 */

  static const int _SCALEDONE = 1;
  _DESCALE(x, n) => ((x + (_SCALEDONE << (n - 1))) >> n);
  _DESCALE_ZEROSHIFT(x, n) => ((x + (128 << n) + (_SCALEDONE << (n - 1))) >> n);
  _CLAMP(i) => (_int32ToUint32(i) > 255) ? ((~i >> 31) & 0xFF) : i;

  static const List<int> _MAX_RC = const [
      17, 18, 34, 50, 50, 51, 52, 52, 52, 68, 84, 84, 84, 84, 85, 86, 86, 86,
      86, 86, 102, 118, 118, 118, 118, 118, 118, 119, 120, 120, 120, 120, 120,
      120, 120, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136,
      136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136,
      136 ];
}

class _JPEG_HuffTables {
  bool ac_table = false;
  Uint32List look_up = new Uint32List(256);
  Uint32List look_up2 = new Uint32List(256);
  Uint8List code_size = new Uint8List(256);
  Uint32List tree = new Uint32List(512);
}

class _JPEG_CoeffBuf {
  Int16List Pdata;
  int block_num_x = 0;
  int block_num_y = 0;
  int block_len_x = 0;
  int block_len_y = 0;
  int block_size = 0;
}

class _DCT_Upsample_Matrix44 {
  static const int NUM_ROWS = 4;
  static const int NUM_COLS = 4;

  Int32List v = new Int32List(NUM_ROWS * NUM_COLS);
  int rows() => NUM_ROWS;
  int cols() => NUM_COLS;

  int at(int r, int c) => v[r * 4 + c];
  void set(int r, int c, int x) { v[r * 4 + c] = x; }

  _DCT_Upsample_Matrix44 add(_DCT_Upsample_Matrix44 a) {
    for (int r = 0, i = 0; r < NUM_ROWS; r++, i += 4) {
      v[i] += a.v[i];
      v[i + 1] += a.v[i + 1];
      v[i + 2] += a.v[i + 2];
      v[i + 3] += a.v[i + 3];
    }
    return this;
  }

  _DCT_Upsample_Matrix44 sub(_DCT_Upsample_Matrix44 a) {
    for (int r = 0, i = 0; r < NUM_ROWS; r++, i += 4) {
      v[i] -= a.v[i];
      v[i + 1] -= a.v[i + 1];
      v[i + 2] -= a.v[i + 2];
      v[i + 3] -= a.v[i + 3];
    }
    return this;
  }

  _DCT_Upsample_Matrix44 operator+(_DCT_Upsample_Matrix44 b) {
    _DCT_Upsample_Matrix44 ret = new _DCT_Upsample_Matrix44();
    for (int r = 0, i = 0; r < NUM_ROWS; r++, i += 4) {
      ret.v[i] = v[i] + b.v[i];
      ret.v[i + 1] = v[i + 1] + b.v[i + 1];
      ret.v[i + 2] = v[i + 2] + b.v[i + 2];
      ret.v[i + 3] = v[i + 3] + b.v[i + 3];
    }
    return ret;
  }

  _DCT_Upsample_Matrix44 operator-(_DCT_Upsample_Matrix44 b) {
    _DCT_Upsample_Matrix44 ret = new _DCT_Upsample_Matrix44();
    for (int r = 0, i = 0; r < NUM_ROWS; r++, i += 4) {
      ret.v[i] = v[i] - b.v[i];
      ret.v[i + 1] = v[i + 1] - b.v[i + 1];
      ret.v[i + 2] = v[i + 2] - b.v[i + 2];
      ret.v[i + 3] = v[i + 3] - b.v[i + 3];
    }
    return ret;
  }

  static void add_and_store(Int16List Pdst,
      _DCT_Upsample_Matrix44 a, _DCT_Upsample_Matrix44 b) {
    for (int r = 0, i = 0; r < 4; r++, i += 4) {
      Pdst[0 * 8 + r] = a.v[i] + b.v[i];
      Pdst[1 * 8 + r] = a.v[i + 1] + b.v[i + 1];
      Pdst[2 * 8 + r] = a.v[i + 2] + b.v[i + 2];
      Pdst[3 * 8 + r] = a.v[i + 3] + b.v[i + 3];
    }
  }

  static void sub_and_store(Int16List Pdst,
      _DCT_Upsample_Matrix44 a, _DCT_Upsample_Matrix44 b) {
    for (int r = 0, i = 0; r < 4; r++, i += 4) {
      Pdst[0 * 8 + r] = a.v[i] - b.v[i];
      Pdst[1 * 8 + r] = a.v[i + 1] - b.v[i + 1];
      Pdst[2 * 8 + r] = a.v[i + 2] - b.v[i + 2];
      Pdst[3 * 8 + r] = a.v[i + 3] - b.v[i + 3];
    }
  }
}