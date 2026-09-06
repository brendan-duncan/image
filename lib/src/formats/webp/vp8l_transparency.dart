/// Clearing the colour hidden under fully transparent pixels.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';

/// Replaces every fully transparent pixel of [argb] with zero.
///
/// Such a pixel shows nothing, but sources usually leave the original
/// background colour under it, which then costs full price to code. Flattening
/// them all to one value turns that into runs. Visible pixels and the alpha
/// channel are untouched.
///
/// libwebp does the same (`WebPReplaceTransparentPixels`) unless given
/// `-exact`.
@internal
void clearTransparentPixels(Uint32List argb) {
  for (var i = 0; i < argb.length; i++) {
    if (argb[i] & 0xff000000 == 0) {
      argb[i] = 0;
    }
  }
}
