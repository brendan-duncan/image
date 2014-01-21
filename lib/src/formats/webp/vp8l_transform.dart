part of image;

class VP8LTransform {
  int type = 0;
  int xsize = 0;
  int ysize = 0;
  Data.Uint32List data;
  int bits = 0;

  void inverseTransform(int rowStart, int rowEnd,
                        Data.Uint32List pixels,
                        int rowsIn, int rowsOut) {
    final int width = xsize;

    switch (type) {
      case WebP.SUBTRACT_GREEN:
        _addGreenToBlueAndRed(pixels, rowsOut,
                              rowsOut + (rowEnd - rowStart) * width);
        break;
      case WebP.PREDICTOR_TRANSFORM:
        _predictorInverseTransform(pixels, rowStart, rowEnd, rowsOut);
        if (rowEnd != ysize) {
          // The last predicted row in this iteration will be the top-pred row
          // for the first row in next iteration.
          int start = rowsOut - width;
          int end = start + width;
          int offset = rowsOut + (rowEnd - rowStart - 1) * width;
          pixels.setRange(start, end, pixels, offset);
        }
        break;
      case WebP.CROSS_COLOR_TRANSFORM:
        _colorSpaceInverseTransform(pixels, rowStart, rowEnd, rowsOut);
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
          pixels.setRange(src, src + inStride, pixels, rowsOut);
          //memmove(src, rowsOut, inStride * sizeof(*src));

          _colorIndexInverseTransform(pixels, rowStart, rowEnd, src, rowsOut);
        } else {
          _colorIndexInverseTransform(pixels, rowStart, rowEnd, rowsIn, rowsOut);
        }
        break;
    }
  }

  void _colorIndexInverseTransform(Data.Uint32List pixels,
                 int yStart, int yEnd, int src, int dst) {
    /*const int bits_per_pixel = 8 >> transform->bits_;
    const int width = transform->xsize_;
    const uint32_t* const color_map = transform->data_;
    if (bits_per_pixel < 8) {
      const int pixels_per_byte = 1 << transform->bits_;
      const int count_mask = pixels_per_byte - 1;
      const uint32_t bit_mask = (1 << bits_per_pixel) - 1;
      for (y = y_start; y < y_end; ++y) {
        uint32_t packed_pixels = 0;
        int x;
        for (x = 0; x < width; ++x) {
          /* We need to load fresh 'packed_pixels' once every                */
          /* 'pixels_per_byte' increments of x. Fortunately, pixels_per_byte */
          /* is a power of 2, so can just use a mask for that, instead of    */
          /* decrementing a counter.                                         */
          if ((x & count_mask) == 0) packed_pixels = GET_INDEX(*src++);
          *dst++ = GET_VALUE(color_map[packed_pixels & bit_mask]);
          packed_pixels >>= bits_per_pixel;
        }
      }
    } else {
      for (y = y_start; y < y_end; ++y) {
        int x;
        for (x = 0; x < width; ++x) {
          *dst++ = GET_VALUE(color_map[GET_INDEX(*src++)]);
        }
      }
    }*/
  }

  /**
   * Color space inverse transform.
   */
  void _colorSpaceInverseTransform(Data.Uint32List pixels,
                                   int yStart, int yEnd, int data) {
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
        pixels[data + x] = m.transformColor(pixels[data + x], true);
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
  void _predictorInverseTransform(Data.Uint32List pixels,
                                  int yStart, int yEnd, int data) {
    /*final int width = xsize;
    if (yStart == 0) {  // First Row follows the L (mode=1) mode.
      final int pred0 = _predictor0(pixels[data - 1]);
      _addPixelsEq(pixels, data, pred0);
      for (int x = 1; x < width; ++x) {
        final int pred1 = _predictor1(pixels[data + x - 1]);
        _addPixelsEq(pixels, data + x, pred1);
      }
      data += width;
      ++yStart;
    }

    {
      int y = yStart;
      final int mask = (1 << bits) - 1;
      final int tilesPerRow = Vp8l._subSampleSize(width, bits);
      int predModeBase = (y >> bits) * tilesPerRow; //this.data +

      while (y < yEnd) {
        final int pred2 = _predictor2(pixels[data - 1], data - width, pixels);
        final int predModeSrc = predModeBase; //this.data +

        // First pixel follows the T (mode=2) mode.
        _addPixelsEq(data, pred2);

        // .. the rest:
        var predFunc = PREDICTORS[((*pred_mode_src++) >> 8) & 0xf];
        for (int x = 1; x < width; ++x) {
          if ((x & mask) == 0) {    // start of tile. Read predictor function.
            predFunc = PREDICTORS[((*pred_mode_src++) >> 8) & 0xf];
          }
          int pred = predFunc(data[x - 1], data + x - width);
          _addPixelsEq(data + x, pred);
        }

        data += width;
        ++y;

        if ((y & mask) == 0) {   // Use the same mask, since tiles are squares.
          predModeBase += tilesPerRow;
        }
      }
    }*/
  }

  /**
   * Add green to blue and red channels (i.e. perform the inverse transform of
   * 'subtract green').
   */
  void _addGreenToBlueAndRed(Data.Uint32List pixels, int data, int dataEnd) {
    while (data < dataEnd) {
      final int argb = pixels[data];
      final int green = ((argb >> 8) & 0xff);
      int redBlue = (argb & 0x00ff00ff);
      redBlue += (green << 16) | green;
      redBlue &= 0x00ff00ff;
      pixels[data++] = (argb & 0xff00ff00) | redBlue;
    }
  }
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
    data[0] = (colorCode >>  0) & 0xff;
    data[1] = (colorCode >>  8) & 0xff;
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
      newRed += colorTransformDelta(greenToRed, green);
      newRed &= 0xff;
      newBlue += colorTransformDelta(greenToBlue, green);
      newBlue += colorTransformDelta(redToBlue, newRed);
      newBlue &= 0xff;
    } else {
      newRed -= colorTransformDelta(greenToRed, green);
      newRed &= 0xff;
      newBlue -= colorTransformDelta(greenToBlue, green);
      newBlue -= colorTransformDelta(redToBlue, red);
      newBlue &= 0xff;
    }

    return (argb & 0xff00ff00) | (newRed << 16) | (newBlue);
  }

  int colorTransformDelta(int colorPred, int color) {
    return (colorPred * color) >> 5;
  }
}
