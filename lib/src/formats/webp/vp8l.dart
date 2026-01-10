import 'dart:typed_data';

import '../../exif/exif_data.dart';
import '../../image/image.dart';
import '../../util/_internal.dart';
import '../../util/color_util.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import 'vp8l_bit_reader.dart';
import 'vp8l_color_cache.dart';
import 'vp8l_transform.dart';
import 'webp_alpha.dart';
import 'webp_huffman.dart';
import 'webp_info.dart';

// WebP lossless format.
@internal
class VP8L {
  InputBuffer input;
  VP8LBitReader br;
  WebPInfo webp;
  Image? image;
  WebPAlpha? alphaDec;

  VP8L(this.input, this.webp) : br = VP8LBitReader(input);

  bool decodeHeader() {
    final signature = br.readBits(8);
    if (signature != vp8lMagicByte) {
      return false;
    }

    final width = br.readBits(14) + 1;
    final height = br.readBits(14) + 1;
    final hasAlpha = br.readBits(1) != 0;

    _ioWidth = width;
    _ioHeight = height;

    webp
      ..format = WebPFormat.lossless
      ..width = width
      ..height = height
      ..hasAlpha = hasAlpha;

    final version = br.readBits(3);

    if (version != vp8lVersion) {
      return false;
    }

    return true;
  }

  Image? decode() {
    _lastPixel = 0;

    if (!decodeHeader()) {
      return null;
    }

    _decodeImageStream(_ioWidth, _ioHeight, true);

    _allocateInternalBuffers32b(_ioWidth);

    image = Image(width: _ioWidth, height: _ioHeight, numChannels: 4);

    if (!_decodeImageData(
        _pixels!, webp.width, webp.height, webp.height, _processRows)) {
      return null;
    }

    if (webp.exif.isNotEmpty) {
      final input = InputBuffer(webp.exif.codeUnits);
      image!.exif = ExifData.fromInputBuffer(input);
    }

    return image;
  }

  bool _allocateInternalBuffers32b(int finalWidth) {
    final numPixels = webp.width * webp.height;
    // Scratch buffer corresponding to top-prediction row for transforming the
    // first row in the row-blocks. Not needed for paletted alpha.
    final cacheTopPixels = finalWidth;
    // Scratch buffer for temporary BGRA storage. Not needed for paletted alpha.
    final cachePixels = finalWidth * _numArgbCacheRows;
    final totalNumPixels = numPixels + cacheTopPixels + cachePixels;

    final pixels32 = Uint32List(totalNumPixels);
    _pixels = pixels32;
    _pixels8 = Uint8List.view(pixels32.buffer);
    _argbCache = numPixels + cacheTopPixels;

    return true;
  }

  bool _allocateInternalBuffers8b() {
    final totalNumPixels = webp.width * webp.height;
    _argbCache = 0;
    // pad the byteBuffer to a multiple of 4
    final n = totalNumPixels + (4 - (totalNumPixels % 4));
    _pixels8 = Uint8List(n);
    _pixels = Uint32List.view(_pixels8.buffer);
    return true;
  }

  bool _readTransform(List<int> transformSize) {
    var ok = true;

    final type = br.readBits(2);

    // Each transform type can only be present once in the stream.
    if ((_transformsSeen & (1 << type)) != 0) {
      return false;
    }
    _transformsSeen |= 1 << type;

    final transform = VP8LTransform();
    _transforms.add(transform);

    transform
      ..type = VP8LImageTransformType.values[type]
      ..xsize = transformSize[0]
      ..ysize = transformSize[1];

    switch (transform.type) {
      case VP8LImageTransformType.predictor:
      case VP8LImageTransformType.crossColor:
        transform.bits = br.readBits(3) + 2;
        transform.data = _decodeImageStream(
            _subSampleSize(transform.xsize, transform.bits),
            _subSampleSize(transform.ysize, transform.bits),
            false);
        break;
      case VP8LImageTransformType.colorIndexing:
        final numColors = br.readBits(8) + 1;
        final bits = (numColors > 16)
            ? 0
            : (numColors > 4)
                ? 1
                : (numColors > 2)
                    ? 2
                    : 3;
        transformSize[0] = _subSampleSize(transform.xsize, bits);
        transform.bits = bits;
        transform.data = _decodeImageStream(numColors, 1, false);
        ok = _expandColorMap(numColors, transform);
        break;
      case VP8LImageTransformType.subtractGreen:
        break;
    }

    return ok;
  }

  Uint32List? _decodeImageStream(int xsize, int ysize, bool isLevel0) {
    var transformXsize = xsize;
    var transformYsize = ysize;
    var colorCacheBits = 0;

    // Read the transforms (may recurse).
    if (isLevel0) {
      while (br.readBits(1) != 0) {
        final sizes = [transformXsize, transformYsize];
        if (!_readTransform(sizes)) {
          throw ImageException('Invalid Transform');
        }
        transformXsize = sizes[0];
        transformYsize = sizes[1];
      }
    }

    // Color cache
    if (br.readBits(1) != 0) {
      colorCacheBits = br.readBits(4);
      final ok = colorCacheBits >= 1 && colorCacheBits <= _maxCacheBits;
      if (!ok) {
        throw ImageException('Invalid Color Cache');
      }
    }

    // Read the Huffman codes (may recurse).
    if (!_readHuffmanCodes(
        transformXsize, transformYsize, colorCacheBits, isLevel0)) {
      throw ImageException('Invalid Huffman Codes');
    }

    // Finish setting up the color-cache
    if (colorCacheBits > 0) {
      _colorCacheSize = 1 << colorCacheBits;
      _colorCache = VP8LColorCache(colorCacheBits);
    } else {
      _colorCacheSize = 0;
    }

    webp
      ..width = transformXsize
      ..height = transformYsize;
    final numBits = _huffmanSubsampleBits;
    _huffmanXsize = _subSampleSize(transformXsize, numBits);
    _huffmanMask = (numBits == 0) ? ~0 : (1 << numBits) - 1;

    if (isLevel0) {
      // Reset for future DECODE_DATA_FUNC() calls.
      _lastPixel = 0;
      return null;
    }

    final totalSize = transformXsize * transformYsize;
    final data = Uint32List(totalSize);

    // Use the Huffman trees to decode the LZ77 encoded data.
    if (!_decodeImageData(
        data, transformXsize, transformYsize, transformYsize, null)) {
      throw ImageException('Failed to decode image data.');
    }

    // Reset for future DECODE_DATA_FUNC() calls.
    _lastPixel = 0;

    return data;
  }

  bool _decodeImageData(Uint32List data, int width, int height, int lastRow,
      void Function(int, bool)? processFunc) {
    var row = _lastPixel ~/ width;
    var col = _lastPixel % width;

    var htreeGroup = _getHtreeGroupForPos(col, row);

    var src = _lastPixel;
    var lastCached = src;
    final srcEnd = width * height; // End of data
    final srcLast = width * lastRow; // Last pixel to decode

    const lenCodeLimit = _numLiteralCodes + _numLengthCodes;
    final colorCacheLimit = lenCodeLimit + _colorCacheSize;

    final colorCache = (_colorCacheSize > 0) ? _colorCache : null;
    final mask = _huffmanMask;

    while (src < srcLast) {
      // Only update when changing tile. Note we could use this test:
      // if "((((prev_col ^ col) | prev_row ^ row)) > mask)" -> tile changed
      // but that's actually slower and needs storing the previous col/row.
      if ((col & mask) == 0) {
        htreeGroup = _getHtreeGroupForPos(col, row);
      }

      if (htreeGroup.isTrivialCode) {
        data[src] = htreeGroup.literalArb;
        // AdvanceByOne
        ++src;
        ++col;
        if (col >= width) {
          col = 0;
          ++row;
          if (processFunc != null && row <= lastRow) {
            processFunc(row, true);
          }

          if (colorCache != null) {
            while (lastCached < src) {
              colorCache.insert(data[lastCached]);
              lastCached++;
            }
          }
        }
        continue;
      }

      br.fillBitWindow();

      var code = 0;
      if (htreeGroup.usePackedTable) {
        // ReadPackedSymbols
        final val = br.prefetchBits() & (huffmanPackedTableSize - 1);
        final code32 = htreeGroup.packedTable[val];
        if (code32.bits < _bitsSpecialMarker) {
          br.bitPos += code32.bits;
          data[src] = code32.value;
          code = _packedNonLiteralCode;
        } else {
          br.bitPos += code32.bits - _bitsSpecialMarker;
          code = code32.value;
        }

        if (br.isEOS) {
          break;
        }

        if (code == VP8L._packedNonLiteralCode) {
          // AdvanceByOne
          ++src;
          ++col;
          if (col >= width) {
            col = 0;
            ++row;
            if (processFunc != null && row <= lastRow) {
              processFunc(row, true);
            }

            if (colorCache != null) {
              while (lastCached < src) {
                colorCache.insert(data[lastCached]);
                lastCached++;
              }
            }
          }
          continue;
        }
      } else {
        code = htreeGroup.readSymbol(_green, br);
      }

      if (code < _numLiteralCodes) {
        // Literal
        if (htreeGroup.isTrivialLiteral) {
          data[src] = htreeGroup.literalArb | (code << 8);
        } else {
          final red = htreeGroup.readSymbol(_red, br);
          final green = code;
          br.fillBitWindow();
          final blue = htreeGroup.readSymbol(_blue, br);
          final alpha = htreeGroup.readSymbol(_alpha, br);
          final c = rgbaToUint32(blue, green, red, alpha);
          data[src] = c;
        }

        // AdvanceByOne
        ++src;
        ++col;
        if (col >= width) {
          col = 0;
          ++row;
          if (processFunc != null && row <= lastRow) {
            processFunc(row, true);
          }
          if (colorCache != null) {
            while (lastCached < src) {
              colorCache.insert(data[lastCached]);
              lastCached++;
            }
          }
        }
      } else if (code < lenCodeLimit) {
        // Backward reference
        final lengthSym = code - _numLiteralCodes;
        final length = _getCopyLength(lengthSym);
        final distSymbol = htreeGroup.readSymbol(_dist, br);

        br.fillBitWindow();

        final distCode = _getCopyDistance(distSymbol);
        final dist = _planeCodeToDistance(width, distCode);

        if (br.isEOS) {
          break;
        }

        if (src < dist || srcEnd - src < length) {
          return false;
        } else {
          // CopyBlock32b
          final dst = src - dist;
          for (var i = 0; i < length; ++i) {
            data[src + i] = data[dst + i];
          }
        }
        src += length;
        col += length;
        while (col >= width) {
          col -= width;
          ++row;
          if (processFunc != null && row <= lastRow) {
            processFunc(row, true);
          }
        }

        if ((col & mask) != 0) {
          htreeGroup = _getHtreeGroupForPos(col, row);
        }
        if (colorCache != null) {
          while (lastCached < src) {
            colorCache.insert(data[lastCached]);
            lastCached++;
          }
        }
      } else if (code < colorCacheLimit) {
        // Color cache
        final key = code - lenCodeLimit;

        while (lastCached < src) {
          colorCache!.insert(data[lastCached]);
          lastCached++;
        }

        data[src] = colorCache!.lookup(key);

        // AdvanceByOne
        ++src;
        ++col;
        if (col >= width) {
          col = 0;
          ++row;
          if (processFunc != null && row <= lastRow) {
            processFunc(row, true);
          }
          while (lastCached < src) {
            colorCache.insert(data[lastCached]);
            lastCached++;
          }
        }
      } else {
        // Not reached
        return false;
      }
    }

    // Process the remaining rows corresponding to last row-block.
    if (processFunc != null) {
      processFunc(row > lastRow ? lastRow : row, false);
    }

    _lastPixel = src;

    return true;
  }

  // Row-processing for the special case when alpha data contains only one
  // transform (color indexing), and trivial non-green literals.
  bool _is8bOptimizable() {
    if (_colorCacheSize > 0) {
      return false;
    }
    // When the Huffman tree contains only one symbol, we can skip the
    // call to ReadSymbol() for red/blue/alpha channels.
    for (var i = 0; i < _numHtreeGroups; ++i) {
      final htrees = _htreeGroups[i].htrees;
      if (htrees[_red][0].bits > 0) {
        return false;
      }
      if (htrees[_blue][0].bits > 0) {
        return false;
      }
      if (htrees[_alpha][0].bits > 0) {
        return false;
      }
    }
    return true;
  }

  // Special row-processing that only stores the alpha data.
  void _extractAlphaRows(int lastRow, bool waitForBiggestBatch) {
    if (waitForBiggestBatch && lastRow % _numArgbCacheRows != 0) {
      return;
    }

    var currentRow = _lastRow;
    var numRows = lastRow - currentRow;
    var inPtr = _ioWidth * currentRow;

    while (numRows > 0) {
      final numRowsToProcess =
          (numRows > _numArgbCacheRows) ? _numArgbCacheRows : numRows;
      // Extract alpha (which is stored in the green plane).
      //final output = _opaque;
      final width = _ioWidth; // the final width (!= dec->width)
      final cachePixels = width * numRowsToProcess;
      final dst = width * currentRow;
      final src = _argbCache;

      _applyInverseTransforms(currentRow, numRowsToProcess, inPtr);

      //_extractGreen(src, dst, cachePixels);
      for (var i = 0; i < cachePixels; ++i) {
        _opaque![dst + i] = (_pixels![src + i] >> 8) & 0xff;
      }

      //_alphaApplyFilter(_opaque, currentRow, currentRow + numRowsToProcess,
      // dst, width);
      /*if (alphaDec?.filter != WebPFilters.filterNone) {
        final prevLine = alphaDec!.prevLine;
        final firstRow = currentRow;
        final lastRow = currentRow + numRowsToProcess;
        var out = dst;
        final stride = width;
        for (var y = currentRow; y < lastRow; ++y) {
          WebPFilters.unfilters[alphaDec!.filter]!(prevLine, _pixels, out,
              out, stride);
          out += stride;
        }
      }*/

      numRows -= numRowsToProcess;
      inPtr += numRowsToProcess * _ioWidth;
      currentRow += numRowsToProcess;
    }

    _lastRow = lastRow;
  }

  bool _decodeAlphaData(int width, int height, int lastRow) {
    var row = _lastPixel ~/ width;
    var col = _lastPixel % width;

    var htreeGroup = _getHtreeGroupForPos(col, row);
    var pos = _lastPixel; // current position
    final end = width * height; // End of data
    final last = width * lastRow; // Last pixel to decode
    const lenCodeLimit = _numLiteralCodes + _numLengthCodes;
    final mask = _huffmanMask;

    while (!br.isEOS && pos < last) {
      // Only update when changing tile.
      if ((col & mask) == 0) {
        htreeGroup = _getHtreeGroupForPos(col, row);
      }

      br.fillBitWindow();

      final code = htreeGroup.readSymbol(_green, br);
      if (code < _numLiteralCodes) {
        // Literal
        _pixels8[pos] = code;
        ++pos;
        ++col;
        if (col >= width) {
          col = 0;
          ++row;
          if (row % _numArgbCacheRows == 0) {
            _extractPalettedAlphaRows(row);
          }
        }
      } else if (code < lenCodeLimit) {
        // Backward reference
        final lengthSym = code - _numLiteralCodes;
        final length = _getCopyLength(lengthSym);
        final distSymbol = htreeGroup.readSymbol(_dist, br);

        br.fillBitWindow();

        final distCode = _getCopyDistance(distSymbol);
        final dist = _planeCodeToDistance(width, distCode);

        if (pos >= dist && end - pos >= length) {
          for (var i = 0; i < length; ++i) {
            _pixels8[pos + i] = _pixels8[pos + i - dist];
          }
        } else {
          _lastPixel = pos;
          return true;
        }

        pos += length;
        col += length;

        while (col >= width) {
          col -= width;
          ++row;
          if (row % _numArgbCacheRows == 0) {
            _extractPalettedAlphaRows(row);
          }
        }

        if (pos < last && (col & mask) != 0) {
          htreeGroup = _getHtreeGroupForPos(col, row);
        }
      } else {
        // Not reached
        return false;
      }
    }

    // Process the remaining rows corresponding to last row-block.
    _extractPalettedAlphaRows(row);

    _lastPixel = pos;

    return true;
  }

  void _extractPalettedAlphaRows(int row) {
    final numRows = row - _lastRow;
    final pIn = InputBuffer(_pixels8, offset: webp.width * _lastRow);
    if (numRows > 0) {
      _applyInverseTransformsAlpha(numRows, pIn);
    }
    _lastRow = row;
  }

  // Special method for paletted alpha data.
  void _applyInverseTransformsAlpha(int numRows, InputBuffer rows) {
    final startRow = _lastRow;
    final endRow = startRow + numRows;
    final rowsOut = InputBuffer(_opaque!, offset: _ioWidth * startRow);
    _transforms[0]
        .colorIndexInverseTransformAlpha(startRow, endRow, rows, rowsOut);
  }

  // Processes (transforms, scales & color-converts) the rows decoded after the
  // last call.
  //static int __count = 0;
  void _processRows(int row, bool waitForBiggestBatch) {
    final rows = webp.width * _lastRow; // offset into _pixels

    // In case of YUV conversion and if we do not need to get to the last row.
    if (waitForBiggestBatch) {
      // In case of YUV conversion, and if we do not use the whole cropping
      // region.
      /*if (!_isRGBMode(_colorspace) && row >= _cropTop && row < _cropBottom) {
        // Make sure the number of rows to process is even.
        if ((row - _cropTop) % 2 != 0) {
          return;
        }
        // Make sure the cache is as full as possible.
        if (row % _numArgbCacheRows != 0 &&
            (row + 1) % _numArgbCacheRows != 0) {
          return;
        }
      } else*/
      {
        if (row % _numArgbCacheRows != 0) {
          return;
        }
      }
    }

    final numRows = row - _lastRow;

    if (numRows <= 0) {
      _lastRow = row;
      return; // Nothing to be done.
    }

    _applyInverseTransforms(_lastRow, numRows, rows);

    //int count = 0;
    //int di = rows;
    for (var y = 0, pi = _argbCache, dy = _lastRow; y < numRows; ++y, ++dy) {
      for (var x = 0; x < _ioWidth; ++x, ++pi) {
        final c = _pixels![pi];

        final r = uint32ToRed(c);
        final g = uint32ToGreen(c);
        final b = uint32ToBlue(c);
        final a = uint32ToAlpha(c);
        // rearrange the ARGB webp color to RGBA image color.
        image!.setPixelRgba(x, dy, b, g, r, a);
      }
    }

    _lastRow = row;
  }

  void _applyInverseTransforms(int startRow, int numRows, int rows) {
    var n = _transforms.length;
    final cachePixels = webp.width * numRows;
    final endRow = startRow + numRows;
    final rowsOut = _argbCache;

    // Copy input data to output buffer before applying inverse transforms.
    // This is needed because some transforms (like subtractGreen) operate
    // in-place on the output buffer.
    _pixels!.setRange(rowsOut, rowsOut + cachePixels, _pixels!, rows);

    // Inverse transforms.
    while (n-- > 0) {
      _transforms[n].inverseTransform(
          startRow, endRow, _pixels!, rowsOut, _pixels!, rowsOut);
    }
  }

  bool _readHuffmanCodes(
      int xSize, int ySize, int colorCacheBits, bool allowRecursion) {
    Uint32List? huffmanImage;
    var numHtreeGroups = 1;
    var numHtreeGroupsMax = 1;
    Int32List? mapping;

    if (allowRecursion && br.readBits(1) != 0) {
      // use meta Huffman codes.
      final huffmanPrecision = _minHuffmanBits + br.readBits(_numHuffmanBits);
      final huffmanXsize = _subSampleSize(xSize, huffmanPrecision);
      final huffmanYsize = _subSampleSize(ySize, huffmanPrecision);
      final huffmanPixs = huffmanXsize * huffmanYsize;

      huffmanImage = _decodeImageStream(huffmanXsize, huffmanYsize, false);
      if (huffmanImage == null) {
        return false;
      }

      _huffmanSubsampleBits = huffmanPrecision;
      for (var i = 0; i < huffmanPixs; ++i) {
        // The huffman data is stored in red and green bytes.
        final group = (huffmanImage[i] >> 8) & 0xffff;
        huffmanImage[i] = group;
        if (group >= numHtreeGroupsMax) {
          numHtreeGroupsMax = group + 1;
        }
      }

      // Check the validity of num_htree_groups_max. If it seems too big, use a
      // smaller value for later. This will prevent big memory allocations to
      // end up with a bad bitstream anyway.
      // The value of 1000 is totally arbitrary. We know that numHtreeGroupsMax
      // is smaller than (1 << 16) and should be smaller than the number of
      // pixels (though the format allows it to be bigger).
      if (numHtreeGroupsMax > 1000 || numHtreeGroupsMax > xSize * ySize) {
        // Create a mapping from the used indices to the minimal set of used
        // values [0, num_htree_groups)
        mapping = Int32List(numHtreeGroups)..fillRange(0, numHtreeGroups, 0xff);
        numHtreeGroups = 0;
        for (var i = 0; i < huffmanPixs; ++i) {
          final mappedGroup = huffmanImage[i];
          if (mapping[mappedGroup] == -1) {
            mapping[mappedGroup] = numHtreeGroups++;
          }
          huffmanImage[i] = mapping[mappedGroup];
        }
      } else {
        numHtreeGroups = numHtreeGroupsMax;
      }
    }

    if (br.isEOS) {
      return false;
    }

    final htreeGroups = _readHuffmanCodesHelper(
        colorCacheBits, numHtreeGroups, numHtreeGroupsMax, mapping);
    if (htreeGroups == null) {
      return false;
    }

    // All OK. Finalize pointers and return.
    _huffmanImage = huffmanImage;
    _numHtreeGroups = numHtreeGroups;
    _htreeGroups = htreeGroups;

    return true;
  }

  static const _numCodeLengthCodes = 19;
  static const _codeLengthCodeOrder = <int>[
    17,
    18,
    0,
    1,
    2,
    3,
    4,
    5,
    16,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15
  ];
  static const _huffmanTableBits = 8;

  // Stores code in table[0], table[step], table[2*step], ..., table[end-step].
  // Assumes that end is an integer multiple of step.
  void _replicateValue(
      HuffmanCodeList table, int key, int step, int end, int bits, int value) {
    var currentEnd = end;
    do {
      currentEnd -= step;
      table[key + currentEnd].bits = bits;
      table[key + currentEnd].value = value;
    } while (currentEnd > 0);
  }

  // Returns the table width of the next 2nd level table. count is the histogram
  // of bit lengths for the remaining symbols, len is the code length of the
  // next processed symbol
  int _nextTableBitSize(Int32List count, int len, int rootBits) {
    var left = 1 << (len - rootBits);
    while (len < _maxAllowedCodeLength) {
      left -= count[len];
      if (left <= 0) {
        break;
      }
      ++len;
      left <<= 1;
    }
    return len - rootBits;
  }

  // Returns reverse(reverse(key, len) + 1, len), where reverse(key, len) is the
  // bit-wise reversal of the len least significant bits of key.
  int _getNextKey(int key, int len) {
    var step = 1 << (len - 1);
    while (key & step != 0) {
      step >>= 1;
    }
    return step != 0 ? (key & (step - 1)) + step : key;
  }

  int _buildHuffmanTable(HuffmanCodeList? rootTable, int rootBits,
      Int32List codeLengths, int codeLengthsSize, Uint16List? sorted) {
    var totalSize = 1 << rootBits;
    final count = Int32List(_maxAllowedCodeLength + 1);
    final offset = Int32List(_maxAllowedCodeLength + 1);
    var tableOffset = 0;

    // Build histogram of code lengths.
    for (var symbol = 0; symbol < codeLengthsSize; ++symbol) {
      if (codeLengths[symbol] > _maxAllowedCodeLength) {
        return 0;
      }
      ++count[codeLengths[symbol]];
    }

    // Error, all code lengths are zeros.
    if (count[0] == codeLengthsSize) {
      return 0;
    }

    // Generate offsets into sorted symbol table by code length.
    offset[1] = 0;
    for (var len = 1; len < _maxAllowedCodeLength; ++len) {
      if (count[len] > (1 << len)) {
        return 0;
      }
      offset[len + 1] = offset[len] + count[len];
    }

    // Sort symbols by length, by symbol order within each length.
    for (var symbol = 0; symbol < codeLengthsSize; ++symbol) {
      final symbolCodeLength = codeLengths[symbol];
      if (codeLengths[symbol] > 0) {
        if (sorted != null) {
          //assert(offset[symbolCodeLength] < codeLengthsSize);
          // The following check is not redundant with the assert. It prevents a
          // potential buffer overflow that the optimizer might not be able to
          // rule out on its own.
          if (offset[symbolCodeLength] >= codeLengthsSize) {
            return 0;
          }
          sorted[offset[symbolCodeLength]++] = symbol;
        } else {
          offset[symbolCodeLength]++;
        }
      }
    }

    // Special case code with only one value.
    if (offset[_maxAllowedCodeLength] == 1) {
      if (sorted != null) {
        _replicateValue(rootTable!, 0, 1, totalSize, 0, sorted[0]);
      }
      return totalSize;
    }

    {
      //var step = 0;  // step size to replicate values in current table
      var low = 0xffffffff; // low bits for current root entry
      final mask = totalSize - 1; // mask for low bits
      var key = 0; // reversed prefix code
      var numNodes = 1; // number of Huffman tree nodes
      var numOpen = 1; // number of open branches in current tree level
      var tableBits = rootBits; // key length of current table
      var tableSize = 1 << tableBits; // size of current table
      var symbol = 0;
      // Fill in root table.
      for (var len = 1, step = 2; len <= rootBits; ++len, step <<= 1) {
        numOpen <<= 1;
        numNodes += numOpen;
        numOpen -= count[len];
        if (numOpen < 0) {
          return 0;
        }
        if (rootTable == null) {
          continue;
        }
        for (; count[len] > 0; --count[len]) {
          final bits = len & 0xff;
          final value = sorted![symbol++];
          _replicateValue(
              rootTable, tableOffset + key, step, tableSize, bits, value);
          key = _getNextKey(key, len);
        }
      }

      // Fill in 2nd level tables and add pointers to root table.
      for (var len = rootBits + 1, step = 2;
          len <= _maxAllowedCodeLength;
          ++len, step <<= 1) {
        numOpen <<= 1;
        numNodes += numOpen;
        numOpen -= count[len];
        if (numOpen < 0) {
          return 0;
        }
        for (; count[len] > 0; --count[len]) {
          if ((key & mask) != low) {
            if (rootTable != null) {
              tableOffset += tableSize;
            }
            tableBits = _nextTableBitSize(count, len, rootBits);
            tableSize = 1 << tableBits;
            totalSize += tableSize;
            low = key & mask;
            if (rootTable != null) {
              final bits = (tableBits + rootBits) & 0xff;
              final value = tableOffset - low;
              rootTable[low].bits = bits;
              rootTable[low].value = value;
            }
          }
          if (rootTable != null) {
            final bits = (len - rootBits) & 0xff;
            final value = sorted![symbol++];
            _replicateValue(rootTable, tableOffset + (key >> rootBits), step,
                tableSize, bits, value);
          }
          key = _getNextKey(key, len);
        }
      }

      // Check if tree is full.
      if (numNodes != 2 * offset[_maxAllowedCodeLength] - 1) {
        return 0;
      }
    }

    return totalSize;
  }

  int _vp8lBuildHuffmanTable(HuffmanTables? rootTable, int rootBits,
      Int32List codeLengths, int codeLengthsSize) {
    final totalSize =
        _buildHuffmanTable(null, rootBits, codeLengths, codeLengthsSize, null);
    if (totalSize == 0 || rootTable == null) {
      return totalSize;
    }

    if (rootTable.currentSegment!.currentOffset + totalSize >=
        rootTable.currentSegment!.size) {
      // If 'root_table' does not have enough memory, allocate a new segment.
      // The available part of root_table->curr_segment is left unused because
      // we need a contiguous buffer.
      final segmentSize = rootTable.currentSegment!.size;
      final next = HuffmanTablesSegment();
      // Fill the new segment.
      // We need at least 'total_size' but if that value is small, it is better
      // to allocate a big chunk to prevent more allocations later.
      // 'segmentSize' is therefore chosen (any other arbitrary value could be
      // chosen).
      {
        final nextSize = totalSize > segmentSize ? totalSize : segmentSize;
        final nextStart = HuffmanCodeList(nextSize);
        next
          ..size = nextSize
          ..start = nextStart;
      }
      next
        ..currentTable = next.start
        ..next = null;
      // Point to the new segment.
      rootTable.currentSegment!.next = next;
      rootTable.currentSegment = next;
    }

    final sorted = Uint16List(codeLengthsSize);
    _buildHuffmanTable(rootTable.currentSegment!.currentTable, rootBits,
        codeLengths, codeLengthsSize, sorted);

    return totalSize;
  }

  static const _lengthsTableBits = 7;
  static const _lengthsTableMask = (1 << _lengthsTableBits) - 1;

  static const _codeLengthLiterals = 16;
  static const _codeLengthRepeatCode = 16;
  static const _codeLengthExtraBits = <int>[2, 3, 7];
  static const _codeLengthRepeatOffsets = <int>[3, 3, 11];

  bool _readHuffmanCodeLengths(
      Int32List codeLengthCodeLengths, int numSymbols, Int32List codeLengths) {
    var prevCodeLen = _defaultCodeLength;
    final tables = HuffmanTables(1 << _lengthsTableBits);
    if (_vp8lBuildHuffmanTable(tables, _lengthsTableBits, codeLengthCodeLengths,
            _numCodeLengthCodes) ==
        0) {
      return false;
    }

    var maxSymbol = 0;
    if (br.readBits(1) != 0) {
      final lengthNBits = 2 + 2 * br.readBits(3);
      maxSymbol = 2 + br.readBits(lengthNBits);
      if (maxSymbol > numSymbols) {
        return false;
      }
    } else {
      maxSymbol = numSymbols;
    }

    var symbol = 0;
    while (symbol < numSymbols) {
      if (maxSymbol-- == 0) {
        break;
      }

      br.fillBitWindow();
      final p =
          tables.currentSegment!.start![br.prefetchBits() & _lengthsTableMask];
      br.bitPos += p.bits;
      final codeLen = p.value;

      if (codeLen < _codeLengthLiterals) {
        codeLengths[symbol++] = codeLen;
        if (codeLen != 0) {
          prevCodeLen = codeLen;
        }
      } else {
        final usePrev = codeLen == _codeLengthRepeatCode;
        final slot = codeLen - _codeLengthLiterals;
        final extraBits = _codeLengthExtraBits[slot];
        final repeatOffset = _codeLengthRepeatOffsets[slot];
        var repeat = br.readBits(extraBits) + repeatOffset;
        if (symbol + repeat > numSymbols) {
          return false;
        }
        final length = usePrev ? prevCodeLen : 0;
        while (repeat-- > 0) {
          codeLengths[symbol++] = length;
        }
      }
    }
    return true;
  }

  int _readHuffmanCode(
      int alphabetSize, Int32List codeLengths, HuffmanTables? table) {
    var size = 0;
    var ok = false;

    final simpleCode = br.readBits(1);
    codeLengths.fillRange(0, alphabetSize, 0);

    // Read symbols, codes & code lengths directly.
    if (simpleCode != 0) {
      final numSymbols = br.readBits(1) + 1;
      final firstSymbolLenCode = br.readBits(1);
      // The first code is either 1 bit or 8 bit code.
      var symbol = br.readBits((firstSymbolLenCode == 0) ? 1 : 8);
      codeLengths[symbol] = 1;
      // The second code (if present), is always 8 bits long.
      if (numSymbols == 2) {
        symbol = br.readBits(8);
        codeLengths[symbol] = 1;
      }
      ok = true;
    } else {
      // Decode Huffman-coded code lengths.
      final codeLengthCodeLengths = Int32List(_numCodeLengthCodes);
      final numCodes = br.readBits(4) + 4;
      //assert(numCodes <= numCodeLengthCodes);

      for (var i = 0; i < numCodes; ++i) {
        codeLengthCodeLengths[_codeLengthCodeOrder[i]] = br.readBits(3);
      }

      ok = _readHuffmanCodeLengths(
          codeLengthCodeLengths, alphabetSize, codeLengths);
    }

    ok = ok && !br.isEOS;
    if (ok) {
      size = _vp8lBuildHuffmanTable(
          table, _huffmanTableBits, codeLengths, alphabetSize);
    }

    return size;
  }

  static const _alphabetSize = <int>[
    _numLiteralCodes + _numLengthCodes,
    _numLiteralCodes,
    _numLiteralCodes,
    _numLiteralCodes,
    _numDistanceCodes
  ];

  // Memory needed for lookup tables of one Huffman tree group. Red, blue, alpha
  // and distance alphabets are constant (256 for red, blue and alpha, 40 for
  // distance) and lookup table sizes for them in worst case are 630 and 410
  // respectively. Size of green alphabet depends on color cache size and is
  // equal to 256 (green component values) + 24 (length prefix values)
  // + color_cache_size (between 0 and 2048).
  // All values computed for 8-bit first level lookup with Mark Adler's tool:
  // https://github.com/madler/zlib/blob/v1.2.5/examples/enough.c
  static const _fixedTableSize = 630 * 3 + 410;
  static const _tableSize = <int>[
    _fixedTableSize + 654,
    _fixedTableSize + 656,
    _fixedTableSize + 658,
    _fixedTableSize + 662,
    _fixedTableSize + 670,
    _fixedTableSize + 686,
    _fixedTableSize + 718,
    _fixedTableSize + 782,
    _fixedTableSize + 912,
    _fixedTableSize + 1168,
    _fixedTableSize + 1680,
    _fixedTableSize + 2704
  ];

  static const _literalMap = <int>[0, 1, 1, 1, 0];

  int _accumulateHCode(HuffmanCode hcode, int shift, HuffmanCode32 huff) {
    huff
      ..bits += hcode.bits
      ..value |= hcode.value << shift;
    //assert(huff->bits <= HUFFMAN_TABLE_BITS);
    return hcode.bits;
  }

  void _buildPackedTable(HTreeGroup htreeGroup) {
    for (var code = 0; code < huffmanPackedTableSize; ++code) {
      var bits = code;
      final huff = htreeGroup.packedTable[bits];
      final hcode = htreeGroup.htrees[_green][bits];
      if (hcode.value >= _numLiteralCodes) {
        huff
          ..bits = hcode.bits + _bitsSpecialMarker
          ..value = hcode.value;
      } else {
        huff
          ..bits = 0
          ..value = 0;
        bits >>= _accumulateHCode(hcode, 8, huff);
        bits >>= _accumulateHCode(htreeGroup.htrees[_red][bits], 16, huff);
        bits >>= _accumulateHCode(htreeGroup.htrees[_blue][bits], 0, huff);
        bits >>= _accumulateHCode(htreeGroup.htrees[_alpha][bits], 24, huff);
      }
    }
  }

  List<HTreeGroup>? _readHuffmanCodesHelper(int colorCacheBits,
      int numHtreeGroups, int numHtreeGroupsMax, Int32List? mapping) {
    final maxAlphabetSize =
        _alphabetSize[0] + ((colorCacheBits > 0) ? 1 << colorCacheBits : 0);
    final tableSize = _tableSize[colorCacheBits];

    if (mapping == null && numHtreeGroups != numHtreeGroupsMax) {
      return null;
    }

    final codeLengths = Int32List(maxAlphabetSize);
    final htreeGroups = List<HTreeGroup>.generate(
        numHtreeGroups, (_) => HTreeGroup(),
        growable: false);

    _huffmanTables = HuffmanTables(numHtreeGroups * tableSize);

    for (var i = 0; i < numHtreeGroupsMax; ++i) {
      if (mapping != null && mapping[i] == -1) {
        for (var j = 0; j < huffmanCodesPerMetaCode; ++j) {
          var alphabetSize = _alphabetSize[j];
          if (j == 0 && colorCacheBits > 0) {
            alphabetSize += 1 << colorCacheBits;
          }
          // Passing in NULL so that nothing gets filled.
          if (_readHuffmanCode(alphabetSize, codeLengths, null) == 0) {
            return null;
          }
        }
      } else {
        var maxBits = 0;
        var isTrivialLiteral = true;
        var totalSize = 0;

        final htreeGroup = htreeGroups[mapping == null ? i : mapping[i]];
        final htrees = htreeGroup.htrees;
        for (var j = 0; j < huffmanCodesPerMetaCode; ++j) {
          var alphabetSize = _alphabetSize[j];
          if (j == 0 && colorCacheBits > 0) {
            alphabetSize += 1 << colorCacheBits;
          }
          final size =
              _readHuffmanCode(alphabetSize, codeLengths, _huffmanTables);
          htrees[j] = _huffmanTables!.currentSegment!.currentTable!;
          if (size == 0) {
            return null;
          }
          if (isTrivialLiteral && _literalMap[j] == 1) {
            isTrivialLiteral = (htrees[j][0].bits == 0);
          }
          totalSize += htrees[j][0].bits;
          _huffmanTables!.currentSegment!.currentOffset += size;
          _huffmanTables!.currentSegment!.currentTable = HuffmanCodeList.from(
              _huffmanTables!.currentSegment!.currentTable!, size);

          if (j <= _alpha) {
            var localMaxBits = codeLengths[0];
            for (var k = 1; k < alphabetSize; ++k) {
              if (codeLengths[k] > localMaxBits) {
                localMaxBits = codeLengths[k];
              }
            }
            maxBits += localMaxBits;
          }
        }

        htreeGroup
          ..isTrivialLiteral = isTrivialLiteral
          ..isTrivialCode = false;
        if (isTrivialLiteral) {
          final red = htrees[_red][0].value;
          final blue = htrees[_blue][0].value;
          final alpha = htrees[_alpha][0].value;
          htreeGroup.literalArb = (alpha << 24) | (red << 16) | blue;
          if (totalSize == 0 && htrees[_green][0].value < _numLengthCodes) {
            htreeGroup
              ..isTrivialCode = true
              ..literalArb |= htrees[_green][0].value << 8;
          }
        }
        htreeGroup.usePackedTable =
            !htreeGroup.isTrivialCode && (maxBits < _huffmanPackedBits);
        if (htreeGroup.usePackedTable) {
          _buildPackedTable(htreeGroup);
        }
      }
    }

    return htreeGroups;
  }

  int _getCopyDistance(int distanceSymbol) {
    if (distanceSymbol < 4) {
      return distanceSymbol + 1;
    }
    final extraBits = (distanceSymbol - 2) >> 1;
    final offset = (2 + (distanceSymbol & 1)) << extraBits;
    return offset + br.readBits(extraBits) + 1;
  }

  int _getCopyLength(int lengthSymbol) => _getCopyDistance(lengthSymbol);

  int _planeCodeToDistance(int xsize, int planeCode) {
    if (planeCode > _codeToPlaneCodes) {
      return planeCode - _codeToPlaneCodes;
    } else {
      final distCode = _codeToPlane[planeCode - 1];
      final yoffset = distCode >> 4;
      final xoffset = 8 - (distCode & 0xf);
      final dist = yoffset * xsize + xoffset;
      // dist<1 can happen if xsize is very small
      return (dist >= 1) ? dist : 1;
    }
  }

  // Computes sampled size of 'size' when sampling using 'sampling bits'.
  static int _subSampleSize(int size, int samplingBits) =>
      (size + (1 << samplingBits) - 1) >> samplingBits;

  // For security reason, we need to remap the color map to span
  // the total possible bundled values, and not just the num_colors.
  bool _expandColorMap(int numColors, VP8LTransform transform) {
    final finalNumColors = 1 << (8 >> transform.bits);
    final newColorMap = Uint32List(finalNumColors);
    final data = Uint8List.view(transform.data!.buffer);
    final newData = Uint8List.view(newColorMap.buffer);

    newColorMap[0] = transform.data![0];

    var len = 4 * numColors;

    int i;
    for (i = 4; i < len; ++i) {
      // Equivalent to AddPixelEq(), on a byte-basis.
      newData[i] = (data[i] + newData[i - 4]) & 0xff;
    }

    for (len = 4 * finalNumColors; i < len; ++i) {
      newData[i] = 0;
    }

    transform.data = newColorMap;

    return true;
  }

  int _getMetaIndex(Uint32List? image, int xsize, int bits, int x, int y) {
    if (bits == 0 || image == null) {
      return 0;
    }
    return image[xsize * (y >> bits) + (x >> bits)];
  }

  HTreeGroup _getHtreeGroupForPos(int x, int y) {
    final metaIndex = _getMetaIndex(
        _huffmanImage, _huffmanXsize, _huffmanSubsampleBits, x, y);
    return _htreeGroups[metaIndex];
  }

  static const _green = 0;
  static const _red = 1;
  static const _blue = 2;
  static const _alpha = 3;
  static const _dist = 4;

  static const _numArgbCacheRows = 16;

  static const _codeToPlaneCodes = 120;
  static const _codeToPlane = <int>[
    0x18,
    0x07,
    0x17,
    0x19,
    0x28,
    0x06,
    0x27,
    0x29,
    0x16,
    0x1a,
    0x26,
    0x2a,
    0x38,
    0x05,
    0x37,
    0x39,
    0x15,
    0x1b,
    0x36,
    0x3a,
    0x25,
    0x2b,
    0x48,
    0x04,
    0x47,
    0x49,
    0x14,
    0x1c,
    0x35,
    0x3b,
    0x46,
    0x4a,
    0x24,
    0x2c,
    0x58,
    0x45,
    0x4b,
    0x34,
    0x3c,
    0x03,
    0x57,
    0x59,
    0x13,
    0x1d,
    0x56,
    0x5a,
    0x23,
    0x2d,
    0x44,
    0x4c,
    0x55,
    0x5b,
    0x33,
    0x3d,
    0x68,
    0x02,
    0x67,
    0x69,
    0x12,
    0x1e,
    0x66,
    0x6a,
    0x22,
    0x2e,
    0x54,
    0x5c,
    0x43,
    0x4d,
    0x65,
    0x6b,
    0x32,
    0x3e,
    0x78,
    0x01,
    0x77,
    0x79,
    0x53,
    0x5d,
    0x11,
    0x1f,
    0x64,
    0x6c,
    0x42,
    0x4e,
    0x76,
    0x7a,
    0x21,
    0x2f,
    0x75,
    0x7b,
    0x31,
    0x3f,
    0x63,
    0x6d,
    0x52,
    0x5e,
    0x00,
    0x74,
    0x7c,
    0x41,
    0x4f,
    0x10,
    0x20,
    0x62,
    0x6e,
    0x30,
    0x73,
    0x7d,
    0x51,
    0x5f,
    0x40,
    0x72,
    0x7e,
    0x61,
    0x6f,
    0x50,
    0x71,
    0x7f,
    0x60,
    0x70
  ];

  static const vp8lMagicByte = 0x2f;
  static const vp8lVersion = 0;

  int _lastPixel = 0;
  int _lastRow = 0;

  int _colorCacheSize = 0;
  VP8LColorCache? _colorCache;

  int _huffmanMask = 0;
  int _huffmanSubsampleBits = 0;
  int _huffmanXsize = 0;
  Uint32List? _huffmanImage;
  int _numHtreeGroups = 0;
  List<HTreeGroup> _htreeGroups = [];
  HuffmanTables? _huffmanTables;
  final List<VP8LTransform> _transforms = [];
  int _transformsSeen = 0;

  Uint32List? _pixels;
  late Uint8List _pixels8;
  int _argbCache = 0; // Offset into _pixels data

  Uint8List? _opaque;

  int _ioWidth = 0;
  int _ioHeight = 0;

  static const argbBlack = 0xff000000;
  static const _maxCacheBits = 11;
  static const huffmanCodesPerMetaCode = 5;

  static const _huffmanPackedBits = 6;
  static const huffmanPackedTableSize = 1 << _huffmanPackedBits;

  static const _minHuffmanBits = 2;
  static const _numHuffmanBits = 3;

  static const _defaultCodeLength = 8;
  static const _maxAllowedCodeLength = 15;

  static const _numLiteralCodes = 256;
  static const _numLengthCodes = 24;
  static const _numDistanceCodes = 40;

  static const _packedNonLiteralCode = 0;
  static const _bitsSpecialMarker = 0x100;
}

@internal
class InternalVP8L extends VP8L {
  InternalVP8L(InputBuffer input, WebPInfo webp) : super(input, webp);

  List<VP8LTransform> get transforms => _transforms;

  Uint32List? get pixels => _pixels;

  Uint8List? get opaque => _opaque;

  set opaque(Uint8List? value) => _opaque = value;

  int? get ioWidth => _ioWidth;

  set ioWidth(int? width) => _ioWidth = width ?? 0;

  int? get ioHeight => _ioHeight;

  set ioHeight(int? height) => _ioHeight = height ?? 0;

  bool decodeImageData(Uint32List data, int width, int height, int lastRow,
          void Function(int, bool) processFunc) =>
      _decodeImageData(data, width, height, lastRow, processFunc);

  Uint32List? decodeImageStream(int xsize, int ysize, bool isLevel0) =>
      _decodeImageStream(xsize, ysize, isLevel0);

  bool allocateInternalBuffers32b(int finalWidth) =>
      _allocateInternalBuffers32b(finalWidth);

  bool allocateInternalBuffers8b() => _allocateInternalBuffers8b();

  bool decodeAlphaData(int width, int height, int lastRow) =>
      _decodeAlphaData(width, height, lastRow);

  bool is8bOptimizable() => _is8bOptimizable();

  void extractAlphaRows(int row, bool waitForBiggestBatch) =>
      _extractAlphaRows(row, waitForBiggestBatch);

  static int subSampleSize(int size, int samplingBits) =>
      VP8L._subSampleSize(size, samplingBits);
}
