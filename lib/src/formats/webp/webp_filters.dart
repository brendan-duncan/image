part of image;


class WebPFilters {
  static const List FILTERS = const [
      null,              // WEBP_FILTER_NONE
      horizontalFilter,  // WEBP_FILTER_HORIZONTAL
      verticalFilter,    // WEBP_FILTER_VERTICAL
      gradientFilter     // WEBP_FILTER_GRADIENT
  ];


  static const List UNFILTERS = const [
      null,                // WEBP_FILTER_NONE
      horizontalUnfilter,  // WEBP_FILTER_HORIZONTAL
      verticalUnfilter,    // WEBP_FILTER_VERTICAL
      gradientUnfilter     // WEBP_FILTER_GRADIENT
  ];

  static void horizontalFilter(Data.Uint8List data, int width, int height,
                               int stride, Data.Uint8List filteredData) {
    _doHorizontalFilter(data, width, height, stride, 0, height, 0,
                        filteredData);
  }

  static void horizontalUnfilter(int width, int height, int stride, int row,
                                 int numRows, Data.Uint8List data) {
    _doHorizontalFilter(data, width, height, stride, row, numRows, 1, data);
  }

  static void verticalFilter(Data.Uint8List data, int width, int height,
                             int stride, Data.Uint8List filteredData) {
    _doVerticalFilter(data, width, height, stride, 0, height, 0, filteredData);
  }

  static void verticalUnfilter(int width, int height, int stride, int row,
                               int num_rows, Data.Uint8List data) {
    _doVerticalFilter(data, width, height, stride, row, num_rows, 1, data);
  }

  static void gradientFilter(Data.Uint8List data, int width, int height,
                             int stride, Data.Uint8List filtered_data) {
    _doGradientFilter(data, width, height, stride, 0, height, 0, filtered_data);
  }

  static void gradientUnfilter(int width, int height, int stride, int row,
                               int num_rows, Data.Uint8List data) {
    _doGradientFilter(data, width, height, stride, row, num_rows, 1, data);
  }

  static void _doHorizontalFilter(Data.Uint8List src,
                                  int width, int height, int stride,
                                  int row, int num_rows,
                                  int inverse, Data.Uint8List out) {
    /*const uint8_t* preds;
    const size_t start_offset = row * stride;
    const int last_row = row + num_rows;
    SANITY_CHECK(in, out);
    in += start_offset;
    out += start_offset;
    preds = inverse ? out : in;

    if (row == 0) {
      // Leftmost pixel is the same as input for topmost scanline.
      out[0] = in[0];
      PredictLine(in + 1, preds, out + 1, width - 1, inverse);
      row = 1;
      preds += stride;
      in += stride;
      out += stride;
    }

    // Filter line-by-line.
    while (row < last_row) {
      // Leftmost pixel is predicted from above.
      PredictLine(in, preds - stride, out, 1, inverse);
      PredictLine(in + 1, preds, out + 1, width - 1, inverse);
      ++row;
      preds += stride;
      in += stride;
      out += stride;
    }*/
  }

  static void _doVerticalFilter(Data.Uint8List src,
                               int width, int height, int stride,
                               int row, int num_rows,
                               int inverse, Data.Uint8List out) {
    /*const uint8_t* preds;
    const size_t start_offset = row * stride;
    const int last_row = row + num_rows;
    SANITY_CHECK(in, out);
    in += start_offset;
    out += start_offset;
    preds = inverse ? out : in;

    if (row == 0) {
      // Very first top-left pixel is copied.
      out[0] = in[0];
      // Rest of top scan-line is left-predicted.
      PredictLine(in + 1, preds, out + 1, width - 1, inverse);
      row = 1;
      in += stride;
      out += stride;
    } else {
      // We are starting from in-between. Make sure 'preds' points to prev row.
      preds -= stride;
    }

    // Filter line-by-line.
    while (row < last_row) {
      PredictLine(in, preds, out, width, inverse);
      ++row;
      preds += stride;
      in += stride;
      out += stride;
    }*/
  }

  static int _gradientPredictor(int a, int b, int c) {
    final int g = a + b - c;
    return ((g & ~0xff) == 0) ? g : (g < 0) ? 0 : 255;  // clip to 8bit
  }

  static void _doGradientFilter(Data.Uint8List src,
                                int width, int height, int stride,
                                int row, int num_rows,
                                int inverse, Data.Uint8List out) {
    /*const uint8_t* preds;
    const size_t start_offset = row * stride;
    const int last_row = row + num_rows;
    SANITY_CHECK(in, out);
    in += start_offset;
    out += start_offset;
    preds = inverse ? out : in;

    // left prediction for top scan-line
    if (row == 0) {
      out[0] = in[0];
      PredictLine(in + 1, preds, out + 1, width - 1, inverse);
      row = 1;
      preds += stride;
      in += stride;
      out += stride;
    }

    // Filter line-by-line.
    while (row < last_row) {
      int w;
      // leftmost pixel: predict from above.
      PredictLine(in, preds - stride, out, 1, inverse);
      for (w = 1; w < width; ++w) {
        const int pred = GradientPredictor(preds[w - 1],
            preds[w - stride],
            preds[w - stride - 1]);
        out[w] = in[w] + (inverse ? pred : -pred);
      }
      ++row;
      preds += stride;
      in += stride;
      out += stride;
    }*/
  }
}
