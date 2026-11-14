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
