/// The hash a VP8L color cache is addressed by, and the 32-bit multiply the
/// match finder shares with it.
library;

import '../../util/_internal.dart';

/// The low 32 bits of `a * b`, with no intermediate above the 53 bits an int is
/// exact to on the web.
@internal
@pragma('vm:prefer-inline')
int mul32(int a, int b) {
  final lo = (a & 0xffff) * b;
  final hi = ((a >>> 16) * b) & 0xffff;
  return (lo + hi * 0x10000) & 0xffffffff;
}

const _hashMultiplier = 0x1e35a7bd;

/// The cache slot [argb] belongs in, for a cache of `32 - hashShift` bits.
///
/// The encoder writes the slot it computed and the decoder answers from the
/// slot it computed, so the two have to agree to the bit. The product reaches
/// 2^62, which a plain multiply rounds on the web.
@internal
@pragma('vm:prefer-inline')
int colorCacheKey(int argb, int hashShift) =>
    mul32(argb, _hashMultiplier) >> hashShift;
