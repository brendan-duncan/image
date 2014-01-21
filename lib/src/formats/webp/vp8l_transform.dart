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
          /*memcpy(rowsOut - width, rowsOut + (row_end - row_start - 1) * width,
              width * sizeof(*rowsOut));*/
        }
        break;
      case WebP.CROSS_COLOR_TRANSFORM:
        //ColorSpaceInverseTransform(transform, row_start, row_end, rowsOut);
        break;
      case WebP.COLOR_INDEXING_TRANSFORM:
        /*if (rowsIn == rowsOut && transform.bits > 0) {
          // Move packed pixels to the end of unpacked region, so that unpacking
          // can occur seamlessly.
          // Also, note that this is the only transform that applies on
          // the effective width of VP8LSubSampleSize(xsize_, bits_). All other
          // transforms work on effective width of xsize_.
          const int out_stride = (row_end - row_start) * width;
          const int in_stride = (row_end - row_start) *
              VP8LSubSampleSize(transform->xsize_, transform->bits_);
          uint32_t* const src = rowsOut + out_stride - in_stride;
          memmove(src, rowsOut, in_stride * sizeof(*src));
          ColorIndexInverseTransform(transform, row_start, row_end, src, rowsOut);
        } else {
          ColorIndexInverseTransform(transform, row_start, row_end, rowsIn, rowsOut);
        }*/
        break;
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
      final int tilesPerRow = _subSampleSize(width, bits);
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
