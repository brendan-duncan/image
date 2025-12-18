import 'dart:typed_data';

import '../../util/_internal.dart';
import '../../util/bit_utils.dart';
import '../../util/input_buffer.dart';
import 'vp8l.dart';

@internal
enum VP8LImageTransformType {
  predictor,
  crossColor,
  subtractGreen,
  colorIndexing
}

@internal
class VP8LTransform {
  VP8LImageTransformType type = VP8LImageTransformType.predictor;
  int xsize = 0;
  int ysize = 0;
  Uint32List? data;
  int bits = 0;

  void inverseTransform(int rowStart, int rowEnd, Uint32List inData, int inPtr,
      Uint32List outData, int outPtr) {
    final width = xsize;

    switch (type) {
      case VP8LImageTransformType.subtractGreen:
        addGreenToBlueAndRed(outData, outPtr, (rowEnd - rowStart) * width);
        break;
      case VP8LImageTransformType.predictor:
        predictorInverseTransform(
            rowStart, rowEnd, inData, inPtr, outData, outPtr);
        if (rowEnd != ysize) {
          // The last predicted row in this iteration will be the top-pred row
          // for the first row in next iteration.
          final start = outPtr - width;
          final end = start + width;
          final offset = outPtr + (rowEnd - rowStart - 1) * width;
          outData.setRange(start, end, inData, offset);
        }
        break;
      case VP8LImageTransformType.crossColor:
        colorSpaceInverseTransform(
            rowStart, rowEnd, inData, inPtr, outData, outPtr);
        break;
      case VP8LImageTransformType.colorIndexing:
        if (inPtr == outPtr && bits > 0) {
          // Move packed pixels to the end of unpacked region, so that unpacking
          // can occur seamlessly.
          // Also, note that this is the only transform that applies on
          // the effective width of VP8LSubSampleSize(xsize_, bits_). All other
          // transforms work on effective width of xsize_.
          final outStride = (rowEnd - rowStart) * width;
          final inStride =
              (rowEnd - rowStart) * InternalVP8L.subSampleSize(xsize, bits);

          final src = outPtr + outStride - inStride;
          outData.setRange(src, src + inStride, inData, outPtr);

          colorIndexInverseTransform(
              rowStart, rowEnd, inData, src, outData, outPtr);
        } else {
          colorIndexInverseTransform(
              rowStart, rowEnd, inData, inPtr, outData, outPtr);
        }
        break;
    }
  }

  void colorIndexInverseTransformAlpha(
      int yStart, int yEnd, InputBuffer src, InputBuffer dst) {
    final bitsPerPixel = 8 >> bits;
    final width = xsize;
    final colorMap = data;
    if (bitsPerPixel < 8) {
      final pixelsPerByte = 1 << bits;
      final countMask = pixelsPerByte - 1;
      final bitMask = (1 << bitsPerPixel) - 1;
      for (var y = yStart; y < yEnd; ++y) {
        var packedPixels = 0;
        for (var x = 0; x < width; ++x) {
          // We need to load fresh 'packed_pixels' once every
          // 'pixels_per_byte' increments of x. Fortunately, pixels_per_byte
          // is a power of 2, so can just use a mask for that, instead of
          // decrementing a counter.
          if ((x & countMask) == 0) {
            packedPixels = _getAlphaIndex(src[0]);
            src.offset++;
          }
          final p = _getAlphaValue(colorMap![packedPixels & bitMask]);
          dst[0] = p;
          dst.offset++;
          packedPixels >>= bitsPerPixel;
        }
      }
    } else {
      for (var y = yStart; y < yEnd; ++y) {
        for (var x = 0; x < width; ++x) {
          final index = _getAlphaIndex(src[0]);
          src.offset++;
          dst[0] = _getAlphaValue(colorMap![index]);
          dst.offset++;
        }
      }
    }
  }

  void colorIndexInverseTransform(int yStart, int yEnd, Uint32List inData,
      int src, Uint32List outData, int dst) {
    final bitsPerPixel = 8 >> bits;
    final width = xsize;
    final colorMap = data;
    if (bitsPerPixel < 8) {
      final pixelsPerByte = 1 << bits;
      final countMask = pixelsPerByte - 1;
      final bitMask = (1 << bitsPerPixel) - 1;
      for (var y = yStart; y < yEnd; ++y) {
        var packedPixels = 0;
        for (var x = 0; x < width; ++x) {
          // We need to load fresh 'packedPixels' once every
          // 'pixels_per_byte' increments of x. Fortunately, pixels_per_byte
          // is a power of 2, so can just use a mask for that, instead of
          // decrementing a counter.
          if ((x & countMask) == 0) {
            packedPixels = _getARGBIndex(inData[src++]);
          }
          outData[dst++] = _getARGBValue(colorMap![packedPixels & bitMask]);
          packedPixels >>= bitsPerPixel;
        }
      }
    } else {
      for (var y = yStart; y < yEnd; ++y) {
        for (var x = 0; x < width; ++x) {
          outData[dst++] =
              _getARGBValue(colorMap![_getARGBIndex(inData[src++])]);
        }
      }
    }
  }

  // Color space inverse transform.
  void colorSpaceInverseTransform(int yStart, int yEnd, Uint32List inData,
      int inPtr, Uint32List outData, int outPtr) {
    final width = xsize;
    final mask = (1 << bits) - 1;
    final tilesPerRow = InternalVP8L.subSampleSize(width, bits);
    var y = yStart;
    var predRow = (y >> bits) * tilesPerRow; //this.data +

    while (y < yEnd) {
      var pred = predRow; // this.data+
      final m = _VP8LMultipliers();

      for (var x = 0; x < width; ++x) {
        if ((x & mask) == 0) {
          m.colorCode = this.data![pred++];
        }

        outData[outPtr + x] = m.transformColor(inData[inPtr + x], true);
      }

      outPtr += width;
      inPtr += width;
      ++y;

      if ((y & mask) == 0) {
        predRow += tilesPerRow;
      }
    }
  }

  int _addPixels(int a, int b) {
    final alphaAndGreen = (a & 0xff00ff00) + (b & 0xff00ff00);
    final redAndBlue = (a & 0x00ff00ff) + (b & 0x00ff00ff);
    return (alphaAndGreen & 0xff00ff00) | (redAndBlue & 0x00ff00ff);
  }

  // Inverse prediction.
  void predictorInverseTransform(int yStart, int yEnd, Uint32List inData,
      int inPtr, Uint32List outData, int outPtr) {
    final width = xsize;

    if (yStart == 0) {
      //PredictorAdd0_C(in, NULL, 1, out);
      outData[outPtr] = _addPixels(inData[inPtr], VP8L.argbBlack);

      //PredictorAdd1_C(in + 1, NULL, width - 1, out + 1);
      {
        final inPtr1 = inPtr + 1;
        final outPtr1 = outPtr + 1;
        final length = width - 1;
        var left = outData[outPtr];
        for (var i = 0; i < length; ++i) {
          left = _addPixels(inData[inPtr1 + i], left);
          outData[outPtr1 + i] = left;
        }
      }

      inPtr += width;
      outPtr += width;
      ++yStart;
    }

    var y = yStart;
    final tileWidth = 1 << bits;
    final mask = tileWidth - 1;
    final tilesPerRow = InternalVP8L.subSampleSize(width, bits);
    var predModeBase = (y >> bits) * tilesPerRow; //this.data +

    while (y < yEnd) {
      var predModeSrc = predModeBase;

      // First pixel follows the T (mode=2) mode.
      //PredictorAdd2_C(in, out - width, 1, out);
      {
        // VP8LPredictor2_C(&out[-1], out - width);
        final pred = outData[outPtr - width];
        outData[outPtr] = _addPixels(inData[inPtr], pred);
      }

      var x = 1;
      while (x < width) {
        final predIndex = (data![predModeSrc++] >> 8) & 0xf;
        final predFunc = _predictors[predIndex];
        var xEnd = (x & ~mask) + tileWidth;
        if (xEnd > width) {
          xEnd = width;
        }

        // pred_func(in + x, out + x - width, x_end - x, out + x);
        final inPtr2 = inPtr + x;
        final upperPtr2 = outPtr + x - width;
        final numPixels = xEnd - x;
        final outPtr2 = outPtr + x;

        if (predIndex == 0) {
          for (var i = 0; i < numPixels; ++i) {
            outData[outPtr2 + i] =
                _addPixels(inData[inPtr2 + i], VP8L.argbBlack);
          }
        } else if (predIndex == 1) {
          var left = outData[outPtr2 - 1];
          for (var i = 0; i < numPixels; ++i) {
            left = _addPixels(inData[inPtr2 + i], left);
            outData[outPtr2 + i] = left;
          }
        } else {
          for (var i = 0; i < numPixels; ++i) {
            final pred =
                predFunc(outData[outPtr2 + i - 1], outData, upperPtr2 + i);
            outData[outPtr2 + i] = _addPixels(inData[inPtr2 + i], pred);
          }
        }
        x = xEnd;
      }

      inPtr += width;
      outPtr += width;
      ++y;

      if ((y & mask) == 0) {
        // Use the same mask, since tiles are squares.
        predModeBase += tilesPerRow;
      }
    }
  }

  // Add green to blue and red channels (i.e. perform the inverse transform of
  // 'subtract green').
  void addGreenToBlueAndRed(Uint32List data, int ptr, int length) {
    for (var i = 0; i < length; ++i) {
      final argb = data[ptr + i];
      final green = (argb >> 8) & 0xff;
      var redBlue = argb & 0x00ff00ff;
      redBlue += (green << 16) | green;
      redBlue &= 0x00ff00ff;
      data[ptr + i] = (argb & 0xff00ff00) | redBlue;
    }
  }

  static int _getARGBIndex(int idx) => (idx >> 8) & 0xff;

  static int _getAlphaIndex(int idx) => idx;

  static int _getARGBValue(int val) => val;

  static int _getAlphaValue(int val) => (val >> 8) & 0xff;

  static int _average2(int a0, int a1) =>
      (((a0 ^ a1) & 0xfefefefe) >> 1) + (a0 & a1);

  static int _average3(int a0, int a1, int a2) =>
      _average2(_average2(a0, a2), a1);

  static int _average4(int a0, int a1, int a2, int a3) =>
      _average2(_average2(a0, a1), _average2(a2, a3));

  // Return 0, when a is a negative integer.
  // Return 255, when a is positive.
  static int _clip255(int a) {
    if (a < 0) {
      return 0;
    }
    if (a > 255) {
      return 255;
    }
    return a;
  }

  static int _addSubtractComponentFull(int a, int b, int c) =>
      _clip255(a + b - c);

  static int _clampedAddSubtractFull(int c0, int c1, int c2) {
    final a = _addSubtractComponentFull(c0 >> 24, c1 >> 24, c2 >> 24);
    final r = _addSubtractComponentFull(
        (c0 >> 16) & 0xff, (c1 >> 16) & 0xff, (c2 >> 16) & 0xff);
    final g = _addSubtractComponentFull(
        (c0 >> 8) & 0xff, (c1 >> 8) & 0xff, (c2 >> 8) & 0xff);
    final b = _addSubtractComponentFull(c0 & 0xff, c1 & 0xff, c2 & 0xff);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  static int _addSubtractComponentHalf(int a, int b) =>
      _clip255(a + (a - b) ~/ 2);

  static int _clampedAddSubtractHalf(int c0, int c1, int c2) {
    final avg = _average2(c0, c1);
    final a = _addSubtractComponentHalf(avg >> 24, c2 >> 24);
    final r = _addSubtractComponentHalf((avg >> 16) & 0xff, (c2 >> 16) & 0xff);
    final g = _addSubtractComponentHalf((avg >> 8) & 0xff, (c2 >> 8) & 0xff);
    final b = _addSubtractComponentHalf((avg >> 0) & 0xff, (c2 >> 0) & 0xff);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  static int _sub3(int a, int b, int c) {
    final pb = b - c;
    final pa = a - c;
    return pb.abs() - pa.abs();
  }

  static int _select(int a, int b, int c) {
    final paMinusPb = _sub3(a >> 24, b >> 24, c >> 24) +
        _sub3((a >> 16) & 0xff, (b >> 16) & 0xff, (c >> 16) & 0xff) +
        _sub3((a >> 8) & 0xff, (b >> 8) & 0xff, (c >> 8) & 0xff) +
        _sub3(a & 0xff, b & 0xff, c & 0xff);
    return (paMinusPb <= 0) ? a : b;
  }

  //--------------------------------------------------------------------------
  // Predictors

  static int _predictor0(int left, Uint32List data, int topPtr) =>
      VP8L.argbBlack;

  static int _predictor1(int left, Uint32List data, int topPtr) => left;

  static int _predictor2(int left, Uint32List data, int topPtr) => data[topPtr];

  static int _predictor3(int left, Uint32List data, int topPtr) =>
      data[topPtr + 1];

  static int _predictor4(int left, Uint32List data, int topPtr) =>
      data[topPtr - 1];

  static int _predictor5(int left, Uint32List data, int topPtr) =>
      _average3(left, data[topPtr], data[topPtr + 1]);

  static int _predictor6(int left, Uint32List data, int topPtr) =>
      _average2(left, data[topPtr - 1]);

  static int _predictor7(int left, Uint32List data, int topPtr) =>
      _average2(left, data[topPtr]);

  static int _predictor8(int left, Uint32List data, int topPtr) =>
      _average2(data[topPtr - 1], data[topPtr]);

  static int _predictor9(int left, Uint32List data, int topPtr) =>
      _average2(data[topPtr], data[topPtr + 1]);

  static int _predictor10(int left, Uint32List data, int topPtr) =>
      _average4(left, data[topPtr - 1], data[topPtr], data[topPtr + 1]);

  static int _predictor11(int left, Uint32List data, int topPtr) =>
      _select(data[topPtr], left, data[topPtr - 1]);

  static int _predictor12(int left, Uint32List data, int topPtr) =>
      _clampedAddSubtractFull(left, data[topPtr], data[topPtr - 1]);

  static int _predictor13(int left, Uint32List data, int topPtr) =>
      _clampedAddSubtractHalf(left, data[topPtr], data[topPtr - 1]);

  static final _predictors = [
    _predictor0,
    _predictor1,
    _predictor2,
    _predictor3,
    _predictor4,
    _predictor5,
    _predictor6,
    _predictor7,
    _predictor8,
    _predictor9,
    _predictor10,
    _predictor11,
    _predictor12,
    _predictor13,
    _predictor0,
    _predictor0
  ];
}

class _VP8LMultipliers {
  final data = Uint8List(3);

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

  set colorCode(int colorCode) {
    data[0] = (colorCode >> 0) & 0xff;
    data[1] = (colorCode >> 8) & 0xff;
    data[2] = (colorCode >> 16) & 0xff;
  }

  int get colorCode => 0xff000000 | (data[2] << 16) | (data[1] << 8) | data[0];

  int transformColor(int argb, bool inverse) {
    final green = (argb >> 8) & 0xff;
    final red = (argb >> 16) & 0xff;
    var newRed = red;
    var newBlue = argb & 0xff;

    if (inverse) {
      final g = colorTransformDelta(greenToRed, green);
      newRed = (newRed + g) & 0xffffffff;
      newRed &= 0xff;
      newBlue =
          (newBlue + colorTransformDelta(greenToBlue, green)) & 0xffffffff;
      newBlue = (newBlue + colorTransformDelta(redToBlue, newRed)) & 0xffffffff;
      newBlue &= 0xff;
    } else {
      newRed -= colorTransformDelta(greenToRed, green);
      newRed &= 0xff;
      newBlue -= colorTransformDelta(greenToBlue, green);
      newBlue -= colorTransformDelta(redToBlue, red);
      newBlue &= 0xff;
    }

    final c = (argb & 0xff00ff00) | ((newRed << 16) & 0xffffffff) | newBlue;
    return c;
  }

  int colorTransformDelta(int colorPred, int color) {
    // There's a bug in dart2js (issue 16497) that requires I do this a bit
    // convoluted to avoid having the optimizer butcher the code.
    final a = uint8ToInt8(colorPred);
    final b = uint8ToInt8(color);
    final d = int32ToUint32(a * b);
    return d >> 5;
  }
}
