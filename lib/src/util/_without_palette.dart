import '../image/image.dart';
import '_internal.dart';

/// [src] with each palette frame converted to the channels of its own
/// palette: convert(numChannels: src.numChannels) gives every frame the
/// channels of the first, so GIF frames with a 4 channel palette lost alpha.
@internal
Image withoutPalette(Image src) {
  Image? first;
  for (final frame in src.frames) {
    final converted = frame.hasPalette
        ? frame.convert(numChannels: frame.numChannels, noAnimation: true)
        : Image.from(frame, noAnimation: true);
    first?.addFrame(converted);
    first ??= converted;
  }

  return first!;
}
