part of image;

/**
 * WebP lossless format.
 */
class Vp8l {
  Arc.InputStream input;
  WebPData webp;
  Image image;

  Vp8l(this.input, WebPData data) :
    this.webp = data,
    _cache = new Data.Uint32List(data.width * _NUM_ARGB_CACHE_ROWS) {
  }

  Image decode() {
    image = new Image(webp.width, webp.height);
    _lastPixel = 0;
    return image;
  }

  bool _readTransform(List<int> transformSize) {
    bool ok = true;

    int type = input.readBits(2);

    // Each transform type can only be present once in the stream.
    if ((_transformsSeen & (1 << type)) != 0) {
      return false;
    }
    _transformsSeen |= (1 << type);

    VP8LTransform transform = new VP8LTransform();
    _transforms.add(transform);

    transform.type = type;
    transform.xsize = transformSize[0];
    transform.ysize = transformSize[1];

    switch (type) {
      case WebP.PREDICTOR_TRANSFORM:
      case WebP.CROSS_COLOR_TRANSFORM:
        transform.bits = input.readBits(3) + 2;
        try {
          transform.data = _decodeImageStream(
                  _subSampleSize(transform.xsize, transform.bits),
                  _subSampleSize(transform.ysize, transform.bits), false);
        } catch (e) {
          return false;
        }
        break;
      case WebP.COLOR_INDEXING_TRANSFORM:
        final int numColors = input.readBits(8) + 1;
        final int bits = (numColors > 16) ? 0 :
                         (numColors > 4) ? 1 :
                         (numColors > 2) ? 2 : 3;
        transformSize[0] = _subSampleSize(transform.xsize, bits);
        transform.bits = bits;
        try {
          transform.data = _decodeImageStream(numColors, 1, false);
        } catch (e) {
          return false;
        }
        ok = _expandColorMap(numColors, transform);
        break;
      case WebP.SUBTRACT_GREEN:
        break;
      default:
        throw new ImageException('Invalid WebP tranform type: $type');
    }

    return ok;
  }

  Data.Uint32List _decodeImageStream(int xsize, int ysize, bool isLevel0) {
    bool ok = true;
    int transformXsize = xsize;
    int transformYsize = ysize;
    int colorCacheBits = 0;

    // Read the transforms (may recurse).
    if (isLevel0) {
      List<int> sizes = [transformXsize, transformYsize];
      while (ok && input.readBits(1)) {
        ok = _readTransform(sizes);
      }
      transformXsize = sizes[0];
      transformYsize = sizes[1];
    }

    // Color cache
    if (ok && input.readBits(1) != 0) {
      colorCacheBits = input.readBits(4);
      ok = (colorCacheBits >= 1 && colorCacheBits <= WebP.MAX_CACHE_BITS);
      if (!ok) {
        throw new ImageException('Invalid Color Cache');
      }
    }

    // Read the Huffman codes (may recurse).
    ok = ok && _readHuffmanCodes(transformXsize, transformYsize,
                                 colorCacheBits, isLevel0);
    if (!ok) {
      throw new ImageException('Invalid Huffman Codes');
    }

    // Finish setting up the color-cache
    if (colorCacheBits > 0) {
      _colorCacheSize = 1 << colorCacheBits;
      _colorCache = new VP8LColorCache(colorCacheBits);
    } else {
      _colorCacheSize = 0;
    }

    final int numBits = _huffmanSubsampleBits;
    _huffmanXsize = _subSampleSize(transformXsize, numBits);
    _huffmanMask = (numBits == 0) ? 0xffffffff : (1 << numBits) - 1;

    if (isLevel0) {
      // Reset for future DECODE_DATA_FUNC() calls.
      _lastPixel = 0;
      return null;
    }

    final int totalSize = transformXsize * transformYsize;
    Data.Uint32List data = new Data.Uint32List(totalSize);

    // Use the Huffman trees to decode the LZ77 encoded data.
    ok = _decodeImageData(data, transformXsize, transformYsize,
                          transformYsize, null);

    if (!ok) {
      throw new ImageException('Failed to decode image data.');
    }

    // Reset for future DECODE_DATA_FUNC() calls.
    _lastPixel = 0;

    return data;
  }

  bool _decodeImageData(Data.Uint32List data, int width, int height,
                        int last_row, process_func) {
    int row = _lastPixel ~/ width;
    int col = _lastPixel % width;

    _HTreeGroup htreeGroup = _getHtreeGroupForPos(col, row);

    int src = _lastPixel;
    int lastCached = src;
    int srcEnd = width * height; // End of data
    int srcLast = width * last_row; // Last pixel to decode

    const int lenCodeLimit = WebP.NUM_LITERAL_CODES + WebP.NUM_LENGTH_CODES;
    final int colorCacheLimit = lenCodeLimit + _colorCacheSize;

    VP8LColorCache colorCache = (_colorCacheSize > 0) ? _colorCache : null;
    final int mask = _huffmanMask;

    /*while (!input.isEOF && src < srcLast) {
      int code;
      // Only update when changing tile. Note we could use this test:
      // if "((((prev_col ^ col) | prev_row ^ row)) > mask)" -> tile changed
      // but that's actually slower and needs storing the previous col/row.
      if ((col & mask) == 0) {
        htreeGroup = _getHtreeGroupForPos(col, row);
      }

      input.fillBitWindow();//VP8LFillBitWindow(br);

      code = _readSymbol(htreeGroup.htrees[GREEN]);

      if (code < NUM_LITERAL_CODES) {  // Literal
        int red, green, blue, alpha;
        red = ReadSymbol(&htree_group->htrees_[RED], br);
        green = code;
        VP8LFillBitWindow(br);
        blue = ReadSymbol(&htree_group->htrees_[BLUE], br);
        alpha = ReadSymbol(&htree_group->htrees_[ALPHA], br);
        *src = (alpha << 24) | (red << 16) | (green << 8) | blue;
        AdvanceByOne:
          ++src;
        ++col;
        if (col >= width) {
          col = 0;
          ++row;
          if ((row % NUM_ARGB_CACHE_ROWS == 0) && (process_func != NULL)) {
            process_func(dec, row);
          }
          if (color_cache != NULL) {
            while (last_cached < src) {
              VP8LColorCacheInsert(color_cache, *last_cached++);
            }
          }
        }
      } else if (code < len_code_limit) {  // Backward reference
        int dist_code, dist;
        const int length_sym = code - NUM_LITERAL_CODES;
        const int length = GetCopyLength(length_sym, br);
        const int dist_symbol = ReadSymbol(&htree_group->htrees_[DIST], br);
        VP8LFillBitWindow(br);
        dist_code = GetCopyDistance(dist_symbol, br);
        dist = PlaneCodeToDistance(width, dist_code);
        if (src - data < (ptrdiff_t)dist || src_end - src < (ptrdiff_t)length) {
          ok = 0;
          goto End;
        } else {
          int i;
          for (i = 0; i < length; ++i) src[i] = src[i - dist];
          src += length;
        }
        col += length;
        while (col >= width) {
          col -= width;
          ++row;
          if ((row % NUM_ARGB_CACHE_ROWS == 0) && (process_func != NULL)) {
            process_func(dec, row);
          }
        }
        if (src < src_last) {
          if (col & mask) htree_group = GetHtreeGroupForPos(hdr, col, row);
          if (color_cache != NULL) {
            while (last_cached < src) {
              VP8LColorCacheInsert(color_cache, *last_cached++);
            }
          }
        }
      } else if (code < color_cache_limit) {  // Color cache
        const int key = code - len_code_limit;
        assert(color_cache != NULL);
        while (last_cached < src) {
          VP8LColorCacheInsert(color_cache, *last_cached++);
        }
        *src = VP8LColorCacheLookup(color_cache, key);
        goto AdvanceByOne;
      } else {  // Not reached
        ok = 0;
        goto End;
      }
      ok = !br->error_;
      if (!ok) goto End;
    }
    // Process the remaining rows corresponding to last row-block.
    if (process_func != NULL) process_func(dec, row);

    End:
      if (br->error_ || !ok || (br->eos_ && src < src_end)) {
        ok = 0;
        dec->status_ = br->eos_ ? VP8_STATUS_SUSPENDED
            : VP8_STATUS_BITSTREAM_ERROR;
      } else {
        dec->last_pixel_ = (int)(src - data);
        if (src == src_end) dec->state_ = READ_DATA;
      }
    return ok;*/
  }

  /**
   * Processes (transforms, scales & color-converts) the rows decoded after the
   * last call.
   */
  void _processRows(int row) {
    /*const uint32_t* const rows = dec->pixels_ + dec->width_ * dec->last_row_;
    const int num_rows = row - dec->last_row_;

    if (num_rows <= 0) return;  // Nothing to be done.
    ApplyInverseTransforms(dec, num_rows, rows);

    // Emit output.
    {
      VP8Io* const io = dec->io_;
      uint8_t* rows_data = (uint8_t*)dec->argb_cache_;
      const int in_stride = io->width * sizeof(uint32_t);  // in unit of RGBA
      if (!SetCropWindow(io, dec->last_row_, row, &rows_data, in_stride)) {
        // Nothing to output (this time).
      } else {
        const WebPDecBuffer* const output = dec->output_;
        if (output->colorspace < MODE_YUV) {  // convert to RGBA
          const WebPRGBABuffer* const buf = &output->u.RGBA;
          uint8_t* const rgba = buf->rgba + dec->last_out_row_ * buf->stride;
          const int num_rows_out = io->use_scaling ?
              EmitRescaledRowsRGBA(dec, rows_data, in_stride, io->mb_h,
                                   rgba, buf->stride) :
              EmitRows(output->colorspace, rows_data, in_stride,
                       io->mb_w, io->mb_h, rgba, buf->stride);
          // Update 'last_out_row_'.
          dec->last_out_row_ += num_rows_out;
        } else {                              // convert to YUVA
          dec->last_out_row_ = io->use_scaling ?
              EmitRescaledRowsYUVA(dec, rows_data, in_stride, io->mb_h) :
              EmitRowsYUVA(dec, rows_data, in_stride, io->mb_w, io->mb_h);
        }
        assert(dec->last_out_row_ <= output->height);
      }
    }

    // Update 'last_row_'.
    dec->last_row_ = row;
    assert(dec->last_row_ <= dec->height_);*/
  }

  bool _readHuffmanCodes(int xsize, int ysize, int colorCacheBits,
                         bool allowRecursion) {
    Data.Uint32List huffmanImage = null;
    int numHtreeGroups = 1;

    if (allowRecursion && input.readBits(1) != 0) {
      // use meta Huffman codes.
      final int huffmanPrecision = input.readBits(3) + 2;
      final int huffmanXsize = _subSampleSize(xsize, huffmanPrecision);
      final int huffmanYsize = _subSampleSize(ysize, huffmanPrecision);
      final int huffmanPixs = huffmanXsize * huffmanYsize;

      try {
        huffmanImage = _decodeImageStream(huffmanXsize, huffmanYsize, false);
      } catch (e) {
        return false;
      }

      _huffmanSubsampleBits = huffmanPrecision;
      for (int i = 0; i < huffmanPixs; ++i) {
        // The huffman data is stored in red and green bytes.
        final int group = (huffmanImage[i] >> 8) & 0xffff;
        huffmanImage[i] = group;
        if (group >= numHtreeGroups) {
          numHtreeGroups = group + 1;
        }
      }
    }

    //assert(numHtreeGroups <= 0x10000);

    List<_HTreeGroup> htreeGroups = new List<_HTreeGroup>(numHtreeGroups);
    for (int i = 0; i < numHtreeGroups; ++i) {
      htreeGroups[i] = new _HTreeGroup();

      for (int j = 0; j < WebP.HUFFMAN_CODES_PER_META_CODE; ++j) {
        int alphabetSize = ALPHABET_SIZE[j];
        if (j == 0 && colorCacheBits > 0) {
          alphabetSize += 1 << colorCacheBits;
        }

        if (!_readHuffmanCode(alphabetSize, htreeGroups[i].htrees[j])) {
          return false;
        }
      }
    }

    // All OK. Finalize pointers and return.
    _huffmanImage = huffmanImage;
    _numHtreeGroups = numHtreeGroups;
    _htreeGroups = htreeGroups;

    return true;
  }

  bool _readHuffmanCode(int alphabetSize, _HuffmanTree tree) {
    bool ok = false;
    final int simpleCode = input.readBits(1);

    // Read symbols, codes & code lengths directly.
    if (simpleCode != 0) {
      List<int> symbols = [0, 0];
      List<int> codes = [0, 0];
      List<int> codeLengths = [0, 0];

      final int numSymbols = input.readBits(1) + 1;
      final int firstSymbolLenCode = input.readBits(1);

      // The first code is either 1 bit or 8 bit code.
      symbols[0] = input.readBits((firstSymbolLenCode == 0) ? 1 : 8);
      codes[0] = 0;
      codeLengths[0] = numSymbols - 1;

      // The second code (if present), is always 8 bit long.
      if (numSymbols == 2) {
        symbols[1] = input.readBits(8);
        codes[1] = 1;
        codeLengths[1] = numSymbols - 1;
      }

      ok = tree.buildExplicit(codeLengths, codes, symbols,
                              alphabetSize, numSymbols);
    } else {
      // Decode Huffman-coded code lengths.
      List<int> codeLengthCodeLengths = new List<int>(_NUM_CODE_LENGTH_CODES);
      final int numCodes = input.readBits(4) + 4;
      if (numCodes > _NUM_CODE_LENGTH_CODES) {
        return false;
      }

      List<int> codeLengths = new List<int>(alphabetSize);

      for (int i = 0; i < numCodes; ++i) {
        codeLengthCodeLengths[_CODE_LENGTH_CODE_ORDER[i]] = input.readBits(3);
      }

      ok = _readHuffmanCodeLengths(codeLengthCodeLengths, alphabetSize,
                                   codeLengths);

      if (ok) {
        ok = tree.buildImplicit(codeLengths, alphabetSize);
      }
    }

    return true;
  }

  bool _readHuffmanCodeLengths(List<int> codeLengthCodeLengths,
                               int numSymbols, List<int> codeLengths) {
    bool ok = false;
    int symbol;
    int max_symbol;
    int prev_code_len = WebP.DEFAULT_CODE_LENGTH;
    _HuffmanTree tree = new _HuffmanTree();

    if (!tree.buildImplicit(codeLengthCodeLengths, _NUM_CODE_LENGTH_CODES)) {
      return false;
    }

    if (input.readBits(1) != 0) {    // use length
      final int length_nbits = 2 + 2 * input.readBits(3);
      max_symbol = 2 + input.readBits(length_nbits);
      if (max_symbol > numSymbols) {
        return false;
      }
    } else {
      max_symbol = numSymbols;
    }

    symbol = 0;
    while (symbol < numSymbols) {
      int code_len;
      if (max_symbol-- == 0) {
        break;
      }

      code_len = tree.readSymbol(input);

      if (code_len < _CODE_LENGTH_LITERALS) {
        codeLengths[symbol++] = code_len;
        if (code_len != 0) {
          prev_code_len = code_len;
        }
      } else {
        final bool usePrev = (code_len == _CODE_LENGTH_REPEAT_CODE);
        final int slot = code_len - _CODE_LENGTH_LITERALS;
        final int extra_bits = _CODE_LENGTH_EXTRA_BITS[slot];
        final int repeat_offset = _CODE_LENGTH_REPEAT_OFFSETS[slot];
        int repeat = input.readBits(extra_bits) + repeat_offset;

        if (symbol + repeat > numSymbols) {
          return false;
        } else {
          final int length = usePrev ? prev_code_len : 0;
          while (repeat-- > 0) {
            codeLengths[symbol++] = length;
          }
        }
      }
    }

    return true;
  }



  /**
   * Computes sampled size of 'size' when sampling using 'sampling bits'.
   */
  int _subSampleSize(int size, int sampling_bits) {
    return (size + (1 << sampling_bits) - 1) >> sampling_bits;
  }

  /**
   * For security reason, we need to remap the color map to span
   * the total possible bundled values, and not just the num_colors.
   */
  bool _expandColorMap(int numColors, VP8LTransform transform) {
    final int finalNumColors = 1 << (8 >> transform.bits);
    Data.Uint32List newColorMap = new Data.Uint32List(finalNumColors);


    Data.Uint8List data = new Data.Uint8List.view(transform.data.buffer);
    Data.Uint8List newData = new Data.Uint8List.view(newColorMap.buffer);

    newColorMap[0] = transform.data[0];

    int len = 4 * numColors;

    int i;
    for (i = 4; i < len; ++i) {
      // Equivalent to AddPixelEq(), on a byte-basis.
      newData[i] = (data[i] + newData[i - 4]) & 0xff;
    }

    for (; i < 4 * finalNumColors; ++i) {
      newData[i] = 0;  // black tail.
    }

    transform.data = newColorMap;

    return true;
  }

  int _getMetaIndex(Data.Uint32List image, int xsize, int bits, int x, int y) {
    if (bits == 0) {
      return 0;
    }
    return image[xsize * (y >> bits) + (x >> bits)];
  }

  _HTreeGroup _getHtreeGroupForPos(int x, int y) {
    int metaIndex = _getMetaIndex(_huffmanImage, _huffmanXsize,
                                  _huffmanSubsampleBits, x, y);
    if (_htreeGroups[metaIndex] == null) {
      _htreeGroups[metaIndex] = new _HTreeGroup();
    }
    return _htreeGroups[metaIndex];
  }

  static const int _NUM_ARGB_CACHE_ROWS = 16;
  final Data.Uint32List _cache;

  static const int _NUM_CODE_LENGTH_CODES = 19;

  static const List<int> _CODE_LENGTH_CODE_ORDER = const [
      17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

  static const int _CODE_LENGTH_LITERALS = 16;
  static const int _CODE_LENGTH_REPEAT_CODE = 16;
  static const List<int> _CODE_LENGTH_EXTRA_BITS = const [2, 3, 7];
  static const List<int> _CODE_LENGTH_REPEAT_OFFSETS = const [ 3, 3, 11 ];

  static const List<int> ALPHABET_SIZE = const [
    WebP.NUM_LITERAL_CODES + WebP.NUM_LENGTH_CODES,
    WebP.NUM_LITERAL_CODES, WebP.NUM_LITERAL_CODES,
    WebP.NUM_LITERAL_CODES, WebP.NUM_DISTANCE_CODES];

  int _lastPixel;

  int _colorCacheSize;
  VP8LColorCache  _colorCache;

  int _huffmanMask;
  int _huffmanSubsampleBits;
  int _huffmanXsize;
  Data.Uint32List _huffmanImage;
  int _numHtreeGroups;
  List<_HTreeGroup> _htreeGroups = [];
  List<VP8LTransform> _transforms = [];
  int _transformsSeen = 0;
}

class VP8LTransform {
  int type = 0;
  int xsize = 0;
  int ysize = 0;
  Data.Uint32List data;
  int bits = 0;
}
