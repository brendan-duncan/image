import 'dart:typed_data';

import '../../util/input_buffer.dart';

class WebPFilters {
  // Filters.
  static const int FILTER_NONE = 0;
  static const int FILTER_HORIZONTAL = 1;
  static const int FILTER_VERTICAL = 2;
  static const int FILTER_GRADIENT = 3;
  static const int FILTER_LAST = FILTER_GRADIENT + 1;  // end marker
  static const int FILTER_BEST = 5;
  static const int FILTER_FAST = 6;

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

  static void horizontalFilter(Uint8List data, int width, int height,
                               int stride, Uint8List filteredData) {
    _doHorizontalFilter(data, width, height, stride, 0, height, false,
                        filteredData);
  }

  static void horizontalUnfilter(int width, int height, int stride, int row,
                                 int numRows, Uint8List data) {
    _doHorizontalFilter(data, width, height, stride, row, numRows, true, data);
  }

  static void verticalFilter(Uint8List data, int width, int height,
                             int stride, Uint8List filteredData) {
    _doVerticalFilter(data, width, height, stride, 0, height, false,
                      filteredData);
  }

  static void verticalUnfilter(int width, int height, int stride, int row,
                               int num_rows, Uint8List data) {
    _doVerticalFilter(data, width, height, stride, row, num_rows, true, data);
  }

  static void gradientFilter(Uint8List data, int width, int height,
                             int stride, Uint8List filteredData) {
    _doGradientFilter(data, width, height, stride, 0, height, false,
                      filteredData);
  }

  static void gradientUnfilter(int width, int height, int stride, int row,
                               int num_rows, Uint8List data) {
    _doGradientFilter(data, width, height, stride, row, num_rows, true, data);
  }

  static void _predictLine(InputBuffer src, InputBuffer pred, InputBuffer dst, int length,
                           bool inverse) {
    if (inverse) {
      for (int i = 0; i < length; ++i) {
        dst[i] = src[i] + pred[i];
      }
    } else {
      for (int i = 0; i < length; ++i) {
        dst[i] = src[i] - pred[i];
      }
    }
  }

  static void _doHorizontalFilter(Uint8List src,
                                  int width, int height, int stride,
                                  int row, int numRows,
                                  bool inverse, Uint8List out) {
    final int startOffset = row * stride;
    final int lastRow = row + numRows;
    InputBuffer s = new InputBuffer(src, offset: startOffset);
    InputBuffer o = new InputBuffer(src, offset: startOffset);
    InputBuffer preds = new InputBuffer.from(inverse ? o : s);

    if (row == 0) {
      // Leftmost pixel is the same as input for topmost scanline.
      o[0] = s[0];
      _predictLine(new InputBuffer.from(s, offset: 1), preds,
                   new InputBuffer.from(o, offset: 1), width - 1, inverse);
      row = 1;
      preds.offset += stride;
      s.offset += stride;
      o.offset += stride;
    }

    // Filter line-by-line.
    while (row < lastRow) {
      // Leftmost pixel is predicted from above.
      _predictLine(s, new InputBuffer.from(preds, offset: -stride), o, 1, inverse);
      _predictLine(new InputBuffer.from(s, offset: 1), preds,
                   new InputBuffer.from(o, offset: 1), width - 1, inverse);
      ++row;
      preds.offset += stride;
      s.offset += stride;
      o.offset += stride;
    }
  }

  static void _doVerticalFilter(Uint8List src,
                               int width, int height, int stride,
                               int row, int numRows,
                               bool inverse, Uint8List out) {
    final int startOffset = row * stride;
    final int last_row = row + numRows;
    InputBuffer s = new InputBuffer(src, offset: startOffset);
    InputBuffer o = new InputBuffer(out, offset: startOffset);
    InputBuffer preds = new InputBuffer.from(inverse ? o : s);

    if (row == 0) {
      // Very first top-left pixel is copied.
      o[0] = s[0];
      // Rest of top scan-line is left-predicted.
      _predictLine(new InputBuffer.from(s, offset: 1), preds,
                   new InputBuffer.from(o, offset: 1), width - 1,
                   inverse);
      row = 1;
      s.offset += stride;
      o.offset += stride;
    } else {
      // We are starting from in-between. Make sure 'preds' points to prev row.
      preds.offset -= stride;
    }

    // Filter line-by-line.
    while (row < last_row) {
      _predictLine(s, preds, o, width, inverse);
      ++row;
      preds.offset += stride;
      s.offset += stride;
      o.offset += stride;
    }
  }

  static int _gradientPredictor(int a, int b, int c) {
    final int g = a + b - c;
    return ((g & ~0xff) == 0) ? g : (g < 0) ? 0 : 255;  // clip to 8bit
  }

  static void _doGradientFilter(Uint8List src,
                                int width, int height, int stride,
                                int row, int numRows,
                                bool inverse, Uint8List out) {
    final int startOffset = row * stride;
    final int lastRow = row + numRows;
    InputBuffer s = new InputBuffer(src, offset: startOffset);
    InputBuffer o = new InputBuffer(out, offset: startOffset);
    InputBuffer preds = new InputBuffer.from(inverse ? o : s);

    // left prediction for top scan-line
    if (row == 0) {
      o[0] = s[0];
      _predictLine(new InputBuffer.from(s, offset: 1), preds,
                   new InputBuffer.from(o, offset: 1), width - 1, inverse);
      row = 1;
      preds.offset += stride;
      s.offset += stride;
      o.offset += stride;
    }

    // Filter line-by-line.
    while (row < lastRow) {
      // leftmost pixel: predict from above.
      _predictLine(s, new InputBuffer.from(preds, offset: -stride),
                   o, 1, inverse);
      for (int w = 1; w < width; ++w) {
        final int pred = _gradientPredictor(preds[w - 1],
            preds[w - stride],
            preds[w - stride - 1]);
        o[w] = s[w] + (inverse ? pred : -pred);
      }
      ++row;
      preds.offset += stride;
      s.offset += stride;
      o.offset += stride;
    }
  }
}
