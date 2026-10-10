import '../image/image.dart';

/// Returns a copy of the pixels of [frame], for filters that read the original
/// while writing the frame. [scratch], the copy made for a previous frame, is
/// reused when it has the same layout.
Image copyFrameReusing(Image frame, Image? scratch) {
  if (scratch != null &&
      scratch.width == frame.width &&
      scratch.height == frame.height &&
      scratch.format == frame.format &&
      scratch.numChannels == frame.numChannels &&
      !frame.hasPalette &&
      !scratch.hasPalette) {
    final bytes = frame.toUint8List();
    scratch.toUint8List().setRange(0, bytes.length, bytes);
    return scratch;
  }
  return Image.from(frame, noAnimation: true);
}
