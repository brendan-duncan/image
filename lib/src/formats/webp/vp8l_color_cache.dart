import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8l_color_hash.dart';

@internal
class VP8LColorCache {
  final Uint32List colors; // color entries
  final int hashShift; // Hash shift: 32 - hash_bits.

  VP8LColorCache(int hashBits)
      : colors = Uint32List(1 << hashBits),
        hashShift = 32 - hashBits;

  void insert(int argb) {
    colors[colorCacheKey(argb, hashShift)] = argb;
  }

  int lookup(int key) => colors[key];
}
