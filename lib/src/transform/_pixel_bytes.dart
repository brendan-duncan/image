import 'dart:typed_data';

import '../image/image.dart';

/// The number of bytes per pixel of [image]'s data, for transforms that move
/// whole pixels by copying their bytes. Returns 0 if a pixel isn't a whole
/// number of bytes, or the rows aren't tightly packed.
int bytesPerPixel(Image image) {
  final data = image.data;
  if (data == null) {
    return 0;
  }
  final bits = image.bitsPerChannel * data.numChannels;
  if (bits & 7 != 0) {
    return 0;
  }
  final k = bits >> 3;
  return data.rowStride == image.width * k ? k : 0;
}

/// Swaps the [k] byte pixels at byte offsets [i] and [j] of [bytes].
void swapPixels(Uint8List bytes, int i, int j, int k) {
  for (var c = 0; c < k; ++c) {
    final t = bytes[i + c];
    bytes[i + c] = bytes[j + c];
    bytes[j + c] = t;
  }
}

/// Reverses the order of the [n] [k] byte pixels starting at byte offset
/// [start] of [bytes].
void reversePixels(Uint8List bytes, int start, int n, int k) {
  for (var i = start, j = start + (n - 1) * k; i < j; i += k, j -= k) {
    swapPixels(bytes, i, j, k);
  }
}
