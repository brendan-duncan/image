import '../util/image_exception.dart';

/// Throws an [ImageException] if a [width] x [height] image is empty, unless
/// [allowEmpty], or has more than [maxPixels] pixels. A [maxPixels] <= 0
/// disables the limit.
void checkPixels(int width, int height, int maxPixels,
    {bool allowEmpty = false}) {
  if (allowEmpty ? width < 0 || height < 0 : width < 1 || height < 1) {
    throw ImageException('Invalid image dimensions ${width}x$height');
  }
  if (maxPixels > 0 && width * height > maxPixels) {
    throw ImageException('Image dimensions ${width}x$height exceed the '
        'maximum of $maxPixels pixels');
  }
}

/// Tracks the pixels of the frames decoded for an animation, throwing an
/// [ImageException] once they exceed [maxPixels].
class PixelBudget {
  final int maxPixels;
  int _total = 0;

  PixelBudget(this.maxPixels);

  void add(int width, int height) {
    _total += width * height;
    if (maxPixels > 0 && _total > maxPixels) {
      throw ImageException('Animation frames exceed the maximum of '
          '$maxPixels pixels');
    }
  }
}
