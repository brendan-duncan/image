import '../util/image_exception.dart';

/// Throws an [ImageException] if a [width] x [height] image is empty, unless
/// [allowEmpty], or has more than [maxPixels] pixels. A [maxPixels] <= 0
/// disables the limit.
void checkPixels(int width, int height, int maxPixels,
    {bool allowEmpty = false}) {
  if (allowEmpty ? width < 0 || height < 0 : width < 1 || height < 1) {
    throw ImageException('Invalid image dimensions ${width}x$height');
  }
  if (maxPixels > 0 && _exceeds(width, height, maxPixels)) {
    throw ImageException('Image dimensions ${width}x$height exceed the '
        'maximum of $maxPixels pixels');
  }
}

/// How many images of up to 4 samples a pixel an image with [samples] a pixel
/// counts as. A pixel limit bounds memory only for a bounded pixel size, and
/// formats with any number of channels would otherwise multiply it.
int pixelPlanes(int samples) => samples <= 4 ? 1 : (samples + 3) ~/ 4;

/// Throws an [ImageException] if a [width] x [height] image with [samples]
/// samples a pixel takes the memory of more than [maxPixels] pixels of 4
/// samples. The dimensions themselves are for [checkPixels].
void checkSamples(int width, int height, int samples, int maxPixels) {
  final planes = pixelPlanes(samples);
  if (maxPixels > 0 &&
      planes > 1 &&
      width > 0 &&
      height > 0 &&
      (_exceeds(width, height, maxPixels) ||
          _exceeds(width * height, planes, maxPixels))) {
    throw ImageException('Image of ${width}x$height with $samples samples a '
        'pixel exceeds the maximum of $maxPixels pixels');
  }
}

/// Whether [a] * [b] > [limit], for non-negative values, without computing
/// the product, which overflows for sizes read from 32 or 64 bit fields.
bool _exceeds(int a, int b, int limit) => b != 0 && a > limit ~/ b;

/// Tracks the pixels of the frames decoded for an animation, throwing an
/// [ImageException] once they exceed [maxPixels].
class PixelBudget {
  final int maxPixels;

  /// What the pixels are of, for the exception message.
  final String what;
  int _total = 0;

  PixelBudget(this.maxPixels, {this.what = 'Animation frames'});

  /// Adds [count] frames of [width] x [height].
  void add(int width, int height, [int count = 1]) {
    if (width <= 0 || height <= 0 || count <= 0) {
      return;
    }
    if (maxPixels <= 0) {
      return;
    }
    final remaining = maxPixels - _total;
    if (_exceeds(width, height, remaining) ||
        _exceeds(width * height, count, remaining)) {
      throw ImageException('$what exceed the maximum of $maxPixels pixels');
    }
    _total += width * height * count;
  }
}
