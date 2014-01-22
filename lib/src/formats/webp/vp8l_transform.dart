part of image;

class VP8LTransform {
  int type = 0;
  int xsize = 0;
  int ysize = 0;
  Data.Uint32List data;
  int bits = 0;

  void inverseTransform(int rowStart, int rowEnd,
                        Data.Uint32List inData,
                        int rowsIn,
                        Data.Uint32List outData,
                        int rowsOut) {
    final int width = xsize;

    switch (type) {
      case WebP.SUBTRACT_GREEN:
        addGreenToBlueAndRed(outData, rowsOut,
                             rowsOut + (rowEnd - rowStart) * width);
        break;
      case WebP.PREDICTOR_TRANSFORM:
        predictorInverseTransform(rowStart, rowEnd, outData, rowsOut);
        if (rowEnd != ysize) {
          // The last predicted row in this iteration will be the top-pred row
          // for the first row in next iteration.
          int start = rowsOut - width;
          int end = start + width;
          int offset = rowsOut + (rowEnd - rowStart - 1) * width;
          outData.setRange(start, end, inData, offset);
        }
        break;
      case WebP.CROSS_COLOR_TRANSFORM:
        colorSpaceInverseTransform(rowStart, rowEnd, outData, rowsOut);
        break;
      case WebP.COLOR_INDEXING_TRANSFORM:
        if (rowsIn == rowsOut && bits > 0) {
          // Move packed pixels to the end of unpacked region, so that unpacking
          // can occur seamlessly.
          // Also, note that this is the only transform that applies on
          // the effective width of VP8LSubSampleSize(xsize_, bits_). All other
          // transforms work on effective width of xsize_.
          final int outStride = (rowEnd - rowStart) * width;
          final int inStride = (rowEnd - rowStart) *
                                Vp8l._subSampleSize(xsize, bits);

          int src = rowsOut + outStride - inStride;
          outData.setRange(src, src + inStride, inData, rowsOut);

          colorIndexInverseTransform(rowStart, rowEnd, inData, src,
                                      outData, rowsOut);
        } else {
          colorIndexInverseTransform(rowStart, rowEnd, inData, rowsIn,
                                      outData, rowsOut);
        }
        break;
    }
  }

  void colorIndexInverseTransformAlpha(int yStart, int yEnd,
                                       Data.Uint8List inData, int src,
                                       Data.Uint8List outData, int dst) {
    final int bitsPerPixel = 8 >> bits;
    final int width = xsize;
    Data.Uint32List colorMap = this.data;
    if (bitsPerPixel < 8) {
      final int pixelsPerByte = 1 << bits;
      final int countMask = pixelsPerByte - 1;
      final bit_mask = (1 << bitsPerPixel) - 1;
      for (int y = yStart; y < yEnd; ++y) {
        int packed_pixels = 0;
        for (int x = 0; x < width; ++x) {
          // We need to load fresh 'packed_pixels' once every
          // 'pixels_per_byte' increments of x. Fortunately, pixels_per_byte
          // is a power of 2, so can just use a mask for that, instead of
          // decrementing a counter.
          if ((x & countMask) == 0) {
            packed_pixels = _getAlphaIndex(inData[src++]);
          }
          outData[dst++] = _getAlphaValue(colorMap[packed_pixels & bit_mask]);
          packed_pixels >>= bitsPerPixel;
        }
      }
    } else {
      for (int y = yStart; y < yEnd; ++y) {
        for (int x = 0; x < width; ++x) {
          int index = _getAlphaIndex(inData[src++]);
          outData[dst++] = _getAlphaValue(colorMap[index]);
        }
      }
    }
  }

  void colorIndexInverseTransform(int yStart, int yEnd,
                                  Data.Uint32List inData, int src,
                                  Data.Uint32List outData, int dst) {
    final int bitsPerPixel = 8 >> bits;
    final int width = xsize;
    Data.Uint32List colorMap = this.data;
    if (bitsPerPixel < 8) {
      final int pixelsPerByte = 1 << bits;
      final int countMask = pixelsPerByte - 1;
      final bit_mask = (1 << bitsPerPixel) - 1;
      for (int y = yStart; y < yEnd; ++y) {
        int packed_pixels = 0;
        for (int x = 0; x < width; ++x) {
          // We need to load fresh 'packed_pixels' once every
          // 'pixels_per_byte' increments of x. Fortunately, pixels_per_byte
          // is a power of 2, so can just use a mask for that, instead of
          // decrementing a counter.
          if ((x & countMask) == 0) {
            packed_pixels = _getARGBIndex(inData[src++]);
          }
          outData[dst++] = _getARGBValue(colorMap[packed_pixels & bit_mask]);
          packed_pixels >>= bitsPerPixel;
        }
      }
    } else {
      for (int y = yStart; y < yEnd; ++y) {
        for (int x = 0; x < width; ++x) {
          outData[dst++] = _getARGBValue(colorMap[_getARGBIndex(inData[src++])]);
        }
      }
    }
  }

  /**
   * Color space inverse transform.
   */
  void colorSpaceInverseTransform(int yStart, int yEnd, Data.Uint32List outData,
                                  int data) {
    final int width = xsize;
    final int mask = (1 << bits) - 1;
    final int tilesPerRow = Vp8l._subSampleSize(width, bits);
    int y = yStart;
    int predRow = (y >> bits) * tilesPerRow; //this.data +

    while (y < yEnd) {
      int pred = predRow; // this.data+
      _VP8LMultipliers m = new _VP8LMultipliers();

      for (int x = 0; x < width; ++x) {
        if ((x & mask) == 0) {
          m.colorCode = this.data[pred++];
        }

        outData[data + x] = m.transformColor(outData[data + x], true);
      }

      data += width;
      ++y;

      if ((y & mask) == 0) {
        predRow += tilesPerRow;;
      }
    }
  }

  /**
   * Inverse prediction.
   */
  void predictorInverseTransform(int yStart, int yEnd, Data.Uint32List outData,
                                 int data) {
    final int width = xsize;
    if (yStart == 0) {  // First Row follows the L (mode=1) mode.
      final int pred0 = _predictor0(outData, outData[data - 1], 0);
      _addPixelsEq(outData, data, pred0);
      for (int x = 1; x < width; ++x) {
        final int pred1 = _predictor1(outData, outData[data + x - 1], 0);
        _addPixelsEq(outData, data + x, pred1);
      }
      data += width;
      ++yStart;
    }

    int y = yStart;
    final int mask = (1 << bits) - 1;
    final int tilesPerRow = Vp8l._subSampleSize(width, bits);
    int predModeBase = (y >> bits) * tilesPerRow; //this.data +

    while (y < yEnd) {
      final int pred2 = _predictor2(outData, outData[data - 1], data - width);
      int predModeSrc = predModeBase; //this.data +

      // First pixel follows the T (mode=2) mode.
      _addPixelsEq(outData, data, pred2);

      // .. the rest:
      var predFunc = PREDICTORS[(this.data[predModeSrc++] >> 8) & 0xf];
      for (int x = 1; x < width; ++x) {
        if ((x & mask) == 0) {    // start of tile. Read predictor function.
          int k = ((this.data[predModeSrc++]) >> 8) & 0xf;
          predFunc = PREDICTORS[k];
        }
        int pred = predFunc(outData, outData[data + x - 1], data + x - width);
        _addPixelsEq(outData, data + x, pred);
      }

      data += width;
      ++y;

      if ((y & mask) == 0) {   // Use the same mask, since tiles are squares.
        predModeBase += tilesPerRow;
      }
    }
  }

  /**
   * Add green to blue and red channels (i.e. perform the inverse transform of
   * 'subtract green').
   */
  void addGreenToBlueAndRed(Data.Uint32List pixels, int data, int dataEnd) {
    while (data < dataEnd) {
      final int argb = pixels[data];
      final int green = ((argb >> 8) & 0xff);
      int redBlue = (argb & 0x00ff00ff);
      redBlue += (green << 16) | green;
      redBlue &= 0x00ff00ff;
      pixels[data++] = (argb & 0xff00ff00) | redBlue;
    }
  }

  static int _getARGBIndex(int idx) {
    return (idx >> 8) & 0xff;
  }

  static int _getAlphaIndex(int idx) {
    return idx;
  }

  static int _getARGBValue(int val) {
    return val;
  }

  static int _getAlphaValue(int val) {
    return (val >> 8) & 0xff;
  }

  /**
   * In-place sum of each component with mod 256.
   */
  static void _addPixelsEq(Data.Uint32List pixels, int a, int b) {
    int pa = pixels[a];
    final int alphaAndGreen = (pa & 0xff00ff00) + (b & 0xff00ff00);
    final int redAndBlue = (pa & 0x00ff00ff) + (b & 0x00ff00ff);
    pixels[a] = (alphaAndGreen & 0xff00ff00) | (redAndBlue & 0x00ff00ff);
  }

  static int _average2(int a0, int a1) {
    return (((a0 ^ a1) & 0xfefefefe) >> 1) + (a0 & a1);
  }

  static int _average3(int a0, int a1, int a2) {
    return _average2(_average2(a0, a2), a1);
  }

  static int _average4(int a0, int a1, int a2, int a3) {
    return _average2(_average2(a0, a1), _average2(a2, a3));
  }

  static int _clip255(int a) {
    a = _int32ToUint32(a);
    if (a < 256) {
      return a;
    }
    // return 0, when a is a negative integer.
    // return 255, when a is positive.
    return _int32ToUint32(~a) >> 24;
  }

  static int _addSubtractComponentFull(int a, int b, int c) {
    return _clip255(a + b - c);
  }

  static int _clampedAddSubtractFull(int c0, int c1, int c2) {
    final int a = _addSubtractComponentFull(c0 >> 24, c1 >> 24, c2 >> 24);
    final int r = _addSubtractComponentFull((c0 >> 16) & 0xff,
        (c1 >> 16) & 0xff,
        (c2 >> 16) & 0xff);
    final int g = _addSubtractComponentFull((c0 >> 8) & 0xff,
        (c1 >> 8) & 0xff,
        (c2 >> 8) & 0xff);
    final int b = _addSubtractComponentFull(c0 & 0xff, c1 & 0xff, c2 & 0xff);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  static int _addSubtractComponentHalf(int a, int b) {
    return _clip255(a + (a - b) ~/ 2);
  }

  static int _clampedAddSubtractHalf(int c0, int c1, int c2) {
    final int ave = _average2(c0, c1);
    final int a = _addSubtractComponentHalf(ave >> 24, c2 >> 24);
    final int r = _addSubtractComponentHalf((ave >> 16) & 0xff, (c2 >> 16) & 0xff);
    final int g = _addSubtractComponentHalf((ave >> 8) & 0xff, (c2 >> 8) & 0xff);
    final int b = _addSubtractComponentHalf((ave >> 0) & 0xff, (c2 >> 0) & 0xff);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  static int _sub3(int a, int b, int c) {
    final int pb = b - c;
    final int pa = a - c;
    return pb.abs() - pa.abs();
  }

  static int _select(int a, int b, int c) {
    final int pa_minus_pb =
        _sub3((a >> 24)       , (b >> 24)       , (c >> 24)       ) +
        _sub3((a >> 16) & 0xff, (b >> 16) & 0xff, (c >> 16) & 0xff) +
        _sub3((a >>  8) & 0xff, (b >>  8) & 0xff, (c >>  8) & 0xff) +
        _sub3((a      ) & 0xff, (b      ) & 0xff, (c      ) & 0xff);
    return (pa_minus_pb <= 0) ? a : b;
  }

  //--------------------------------------------------------------------------
  // Predictors

  static int _predictor0(Data.Uint32List pixels, int left, int top) {
    return WebP.ARGB_BLACK;
  }

  static int _predictor1(Data.Uint32List pixels, int left, int top) {
    return left;
  }

  static int _predictor2(Data.Uint32List pixels, int left, int top) {
    return pixels[top];
  }

  static int _predictor3(Data.Uint32List pixels, int left, int top) {
    return pixels[top + 1];
  }

  static int _predictor4(Data.Uint32List pixels, int left, int top) {
    return pixels[top -1];
  }

  static int _predictor5(Data.Uint32List pixels, int left, int top) {
    return _average3(left, pixels[top], pixels[top + 1]);
  }

  static int _predictor6(Data.Uint32List pixels, int left, int top) {
    return _average2(left, pixels[top - 1]);
  }

  static int _predictor7(Data.Uint32List pixels, int left, int top) {
    return _average2(left, pixels[top]);
  }

  static int _predictor8(Data.Uint32List pixels, int left, int top) {
    return _average2(pixels[top -1], pixels[top]);
  }

  static int _predictor9(Data.Uint32List pixels, int left, int top) {
    return _average2(pixels[top], pixels[top + 1]);
  }

  static int _predictor10(Data.Uint32List pixels, int left, int top) {
    return _average4(left, pixels[top -1], pixels[top], pixels[top + 1]);
  }

  static int _predictor11(Data.Uint32List pixels, int left, int top) {
    return _select(pixels[top], left, pixels[top - 1]);
  }

  static int _predictor12(Data.Uint32List pixels, int left, int top) {
    return _clampedAddSubtractFull(left, pixels[top], pixels[top - 1]);
  }

  static int _predictor13(Data.Uint32List pixels, int left, int top) {
    return _clampedAddSubtractHalf(left, pixels[top], pixels[top - 1]);
  }

  static final List PREDICTORS = [
    _predictor0, _predictor1, _predictor2, _predictor3,
    _predictor4, _predictor5, _predictor6, _predictor7,
    _predictor8, _predictor9, _predictor10, _predictor11,
    _predictor12, _predictor13,
    _predictor0, _predictor0 ];
}

class _VP8LMultipliers {
  final Data.Uint8List data = new Data.Uint8List(3);

  // Note: the members are uint8_t, so that any negative values are
  // automatically converted to "mod 256" values.
  int get greenToRed => data[0];

  set greenToRed(int m) => data[0] = m;

  int get greenToBlue => data[1];

  set greenToBlue(int m) => data[1] = m;

  int get redToBlue => data[2];

  set redToBlue(int m) => data[2] = m;

  void clear() {
    data[0] = 0;
    data[1] = 0;
    data[2] = 0;
  }

  void set colorCode(int colorCode) {
    data[0] = (colorCode >> 0) & 0xff;
    data[1] = (colorCode >> 8) & 0xff;
    data[2] = (colorCode >> 16) & 0xff;
  }

  int get colorCode => 0xff000000 |
      (data[2] << 16) |
      (data[1] << 8) |
      data[0];


  int transformColor(int argb, bool inverse) {
    final int green = argb >> 8;
    final int red = argb >> 16;
    int newRed = red;
    int newBlue = argb;

    if (inverse) {
      int g = colorTransformDelta(greenToRed, green);
      newRed = (newRed + g) & 0xffffffff;
      newRed &= 0xff;
      newBlue = (newBlue + colorTransformDelta(greenToBlue, green)) & 0xffffffff;
      newBlue = (newBlue + colorTransformDelta(redToBlue, newRed)) & 0xffffffff;
      newBlue &= 0xff;
    } else {
      newRed -= colorTransformDelta(greenToRed, green);
      newRed &= 0xff;
      newBlue -= colorTransformDelta(greenToBlue, green);
      newBlue -= colorTransformDelta(redToBlue, red);
      newBlue &= 0xff;
    }

    return (argb & 0xff00ff00) | ((newRed << 16) & 0xffffffff) | (newBlue);
  }

  int colorTransformDelta(int colorPred, int color) {
    return _int32ToUint32(_uint8ToInt8(colorPred) * _uint8ToInt8(color)) >> 5;
  }
}
