import 'dart:math';

import '../color/channel.dart';
import '../color/format.dart';
import '../image/image.dart';
import '../util/color_util.dart';
import '../util/math_util.dart';

enum HistogramEqualizeMode { grayscale, color }

/// Spread the histogram of the input image into a relatively linear cumulative
/// distribution.
///
/// The output dynamic range can be specified by setting [outputRangeMin] or
/// [outputRangeMax]. By default, the output range is set to
/// [0..maxChannelValue]. Out-of-bound inputs will be clamped.
///
/// The [mode] argument specifies whether the transformation operates in
/// `grayscale` or `color` mode. In `grayscale` mode, the histogram is spread
/// based on pixel luminance. In `color` mode, pixels are first transformed to
/// HSL space, stretched along the L dimension, and then converted back to RGB
/// space to preserve color accuracy.
///
/// Note: This function only works with discrete intensity levels and images
/// with 3 or more channels. Any floating-point image will be converted to
/// [Format.uint8] internally. If you need higher precision than 256 intensity
/// levels, convert your input image to a higher-precision format (e.g.
/// [Format.uint16] or [Format.uint32]) before calling this function.
Image histogramEqualization(Image src,
    {HistogramEqualizeMode mode = HistogramEqualizeMode.grayscale,
    num? outputRangeMin,
    num? outputRangeMax,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (src.hasPalette) {
    src = src.convert(numChannels: max(src.numChannels, 3));
  }
  // The algorithm only works with discrete intensity levels at the moment.
  if (src.formatType == FormatType.float) {
    src =
        src.convert(format: Format.uint8, numChannels: max(src.numChannels, 3));
  }
  // The luminance accessor of a pixel object with channel < 3 is
  // ill-formed, this is a work around.
  if (src.numChannels < 3) {
    src = src.convert(numChannels: 3);
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

    num validPixelCounts = 0;
    for (final p in frame) {
      if ((src.hasAlpha) && (p.a == 0)) {
        continue;
      }
      final l = mode == HistogramEqualizeMode.grayscale
          ? p.luminance
          : rgbToHsl(p.r, p.g, p.b)[2] * src.maxChannelValue;
      H[l.round()]++;
      validPixelCounts++;
    }

    final double numPixelPerBin = validPixelCounts / numOutputBin;
    final List<num> Hmap = List<num>.generate(
        src.maxChannelValue.ceil() + 1, (x) => x,
        growable: false);
    num pCounter = 0;
    // works out a new mapping from scanning the darkest up to mid luminance
    for (var l = 0; l < H.length / 2; ++l) {
      Hmap[l] = (pCounter / numPixelPerBin).round() + outputRangeMin;
      pCounter += H[l];
    }

    pCounter = 0;
    // works out a new mapping from scanning the brightest down to mid luminance
    for (var l = H.length - 1; l >= H.length / 2; --l) {
      Hmap[l] = outputRangeMax - (pCounter ~/ numPixelPerBin).round();
      pCounter += H[l];
    }

    // produce output
    _applyHistogramTransform(frame, Hmap, mode, src.maxChannelValue,
        mask: mask, maskChannel: maskChannel);
  }

  return src;
}

/// Linearly stretch the histogram of the input image to span the available
/// dynamic range. This function finds the low and high bounds of the histogram
/// and rescales intensity levels linearly as follows:
/// `I_out = (I_in - Low) * (Out_max - Out_min) / (High - Low) + Out_min`
///
/// The [stretchClipRatio] parameter controls how many intensity levels at both
/// ends of the histogram are ignored. By default, [stretchClipRatio] is set to
/// `0.015`, meaning that pixels with intensities below the 1.5th percentile or
/// above the 98.5th percentile are clipped and mapped to the corresponding
/// ends of the output dynamic range.
///
/// The output dynamic range can be specified by setting [outputRangeMin] or
/// [outputRangeMax]. By default, the output range is set to
/// [0..maxChannelValue]. Out-of-bound inputs will be clamped.
///
/// The [mode] argument specifies whether the transformation operates in
/// `grayscale` or `color` mode. In `grayscale` mode, the histogram is spread
/// based on pixel luminance. In `color` mode, pixels are first transformed to
/// HSL space, stretched along the L dimension, and then converted back to RGB
/// space to preserve color accuracy.
///
/// Note: This function only works with discrete intensity levels and images
/// with 3 or more channels. Any floating-point image will be converted to
/// [Format.uint8] internally. If you need higher precision than 256 intensity
/// levels, convert your input image to a higher-precision format (e.g.
/// [Format.uint16] or [Format.uint32]) before calling this function.
Image histogramStretch(Image src,
    {HistogramEqualizeMode mode = HistogramEqualizeMode.grayscale,
    num? outputRangeMin,
    num? outputRangeMax,
    double stretchClipRatio = 0.015,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (src.hasPalette) {
    src = src.convert(numChannels: max(src.numChannels, 3));
  }
  // The algorithm only works with discrete intensity levels at the moment.
  if (src.formatType == FormatType.float) {
    src =
        src.convert(format: Format.uint8, numChannels: max(src.numChannels, 3));
  }
  // The luminance accessor of a pixel object with channel < 3 is
  // ill-formed, this is a work around.
  if (src.numChannels < 3) {
    src = src.convert(numChannels: 3);
  }

  outputRangeMin = min(max(0, outputRangeMin ?? 0), src.maxChannelValue);
  outputRangeMax =
      min(max(0, outputRangeMax ?? src.maxChannelValue), src.maxChannelValue);

  for (final frame in src.frames) {
    // Take histogram
    final List<num> H = List<num>.generate(
        src.maxChannelValue.ceil() + 1, (_) => 0,
        growable: false);
    num validPixelCounts = 0;
    for (final p in frame) {
      if ((src.hasAlpha) && (p.a == 0)) {
        continue;
      }
      final l = mode == HistogramEqualizeMode.grayscale
          ? p.luminance
          : (rgbToHsl(p.r, p.g, p.b)[2] * src.maxChannelValue);
      H[l.round()]++;
      validPixelCounts++;
    }

    // Find the high & low percentile
    int lowPercentileBin = 0;
    int highPercentileBin = 0;
    num pCounter = 0;
    for (var l = 0; l < H.length; ++l) {
      pCounter += H[l];
      if (pCounter / validPixelCounts < stretchClipRatio) {
        lowPercentileBin++;
      }
      if (pCounter / validPixelCounts < 1 - stretchClipRatio) {
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
    final inputDynamicRange = highPercentileBin - lowPercentileBin;
    final outputDynamicRange = outputRangeMax - outputRangeMin;
    for (var l = 0; l < H.length; ++l) {
      final newIntensityLv =
          (l - lowPercentileBin) * outputDynamicRange / inputDynamicRange +
              outputRangeMin;
      Hmap[l] =
          max(outputRangeMin, min(newIntensityLv.round(), outputDynamicRange));
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
    if ((frame.hasAlpha) && (p.a == 0)) {
      continue;
    }
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
