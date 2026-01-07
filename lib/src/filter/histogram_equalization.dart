import 'dart:math';
import '../color/channel.dart';
import '../image/image.dart';
import '../util/color_util.dart';
import '../util/math_util.dart';

enum HistogramEqualizeMode { grayscale, color }

Image histogramEqualization(Image src,
    {HistogramEqualizeMode mode = HistogramEqualizeMode.grayscale,
    num? outputRangeMin,
    num? outputRangeMax,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }

  outputRangeMin = min(max(0, outputRangeMin ?? 0), src.maxChannelValue);
  outputRangeMax =
      min(max(0, outputRangeMax ?? src.maxChannelValue), src.maxChannelValue);
  final num numOutputBin = outputRangeMax - outputRangeMin + 1;

  for (final frame in src.frames) {
    // Take histogram
    final List<num> H = List<num>.generate(
        src.maxChannelValue.ceil() + 1, (_) => 0,
        growable: false);

    for (final p in frame) {
      final l = mode == HistogramEqualizeMode.grayscale
          ? p.luminance
          : rgbToHsl(p.r, p.g, p.b)[2] * src.maxChannelValue;
      H[l.round()]++;
    }

    final double numPixelPerBin = frame.width * frame.height / numOutputBin;
    final List<num> Hmap = List<num>.generate(
        src.maxChannelValue.ceil() + 1, (x) => x,
        growable: false);
    num pCounter = 0;
    // works out a new mapping from scanning the darkest up to mid luminance
    for (var l = 0; l < H.length / 2; ++l) {
      Hmap[l] = (pCounter / numPixelPerBin).round() + outputRangeMin;
      //print("$l:, ${Hmap[l]}");
      pCounter += H[l];
    }

    pCounter = 0;
    // works out a new mapping from scanning the brightest down to mid luminance
    for (var l = H.length - 1; l >= H.length / 2; --l) {
      Hmap[l] = outputRangeMax - (pCounter ~/ numPixelPerBin).round();
      //print("$l: ${Hmap[l]}");
      pCounter += H[l];
    }

    // produce output
    _applyHistogramTransform(frame, Hmap, mode, src.maxChannelValue,
        mask: mask, maskChannel: maskChannel);
  }

  return src;
}

Image histogramStretch(Image src,
    {HistogramEqualizeMode mode = HistogramEqualizeMode.grayscale,
    num? outputRangeMin,
    num? outputRangeMax,
    double stretchClipRatio = 0.015,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }

  outputRangeMin = min(max(0, outputRangeMin ?? 0), src.maxChannelValue);
  outputRangeMax =
      min(max(0, outputRangeMax ?? src.maxChannelValue), src.maxChannelValue);

  for (final frame in src.frames) {
    final int numPixel = frame.width * frame.height;

    // Take histogram
    final List<num> H = List<num>.generate(
        src.maxChannelValue.ceil() + 1, (_) => 0,
        growable: false);

    for (final p in frame) {
      final l = mode == HistogramEqualizeMode.grayscale
          ? p.luminance
          : (rgbToHsl(p.r, p.g, p.b)[2] * src.maxChannelValue);
      H[l.round()]++;
    }

    // Find the high & low percentile
    int lowPercentileBin = 0;
    int highPercentileBin = 0;
    num pCounter = 0;
    for (var l = 0; l < H.length; ++l) {
      pCounter += H[l];
      if (pCounter / numPixel < stretchClipRatio) {
        lowPercentileBin++;
      }
      if (pCounter / numPixel < 1 - stretchClipRatio) {
        highPercentileBin++;
      }
    }
    // Make sure highPercentileBin - lowPercentileBin >= 1
    highPercentileBin = min(src.maxChannelValue.ceil(),
        max(lowPercentileBin + 1, highPercentileBin));
    lowPercentileBin = max(0, min(lowPercentileBin, highPercentileBin - 1));

    final List<num> Hmap = List<num>.generate(
        src.maxChannelValue.ceil() + 1, (x) => x,
        growable: false);
    // works out a new mapping by re-scaling dynamic range
    for (var l = 0; l < H.length; ++l) {
      Hmap[l] = ((l - lowPercentileBin) /
                  (highPercentileBin - lowPercentileBin) *
                  (outputRangeMax - outputRangeMin) +
              outputRangeMin)
          .round();
      //print(Hmap[l]);
    }

    // produce output
    _applyHistogramTransform(frame, Hmap, mode, src.maxChannelValue,
        mask: mask, maskChannel: maskChannel);
  }

  return src;
}

void _applyHistogramTransform(Image frame, List<num> Hmap,
    HistogramEqualizeMode mode, num maxChannelValue,
    {Image? mask, Channel maskChannel = Channel.luminance}) {
  for (final p in frame) {
    if (mode == HistogramEqualizeMode.grayscale) {
      final newl = Hmap[p.luminance.round()];

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      if (msk == null) {
        p
          ..r = newl
          ..g = newl
          ..b = newl;
      } else {
        p
          ..r = mix(p.r, newl, msk)
          ..g = mix(p.g, newl, msk)
          ..b = mix(p.b, newl, msk);
      }
    } else {
      // color mode
      final hsl = rgbToHsl(p.r, p.g, p.b);
      final newl = Hmap[(hsl[2] * maxChannelValue).round()];
      final List<int> newRGB = [0, 0, 0];
      hslToRgb(hsl[0], hsl[1], newl / maxChannelValue, newRGB);

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      if (msk == null) {
        p
          ..r = newRGB[0]
          ..g = newRGB[1]
          ..b = newRGB[2];
      } else {
        p
          ..r = mix(p.r, newRGB[0], msk)
          ..g = mix(p.g, newRGB[1], msk)
          ..b = mix(p.b, newRGB[2], msk);
      }
    }
  }
}
