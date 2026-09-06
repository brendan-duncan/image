/// Choosing a VP8L color cache size, and working out which literals it turns
/// into cache references.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8l_color_hash.dart';
import 'vp8l_huffman_encoder.dart' as huffman;

/// Cache sizes considered by [selectColorCacheBits]. A small image cannot
/// pay back the cost of describing a large alphabet, so a mid size is offered
/// as well. libwebp never emits more than 10 bits, so neither does this.
const _colorCacheCandidates = [0, 8, 10];

/// Picks the color cache size that codes the token stream most compactly and
/// fills [outKeys] with the cache key of every literal that becomes a cache
/// reference, or -1 for literals that stay full pixels. Returns the chosen
/// number of cache bits, or 0 when no cache pays for itself.
@internal
int selectColorCacheBits(
    Uint8List r,
    Uint8List g,
    Uint8List b,
    Uint8List a,
    Uint8List tokenIsLit,
    Int32List tokenLitIdx,
    Int32List tokenLen,
    Int32List tokenDist,
    int width,
    Int32List outKeys) {
  var bestBits = 0;
  var bestCost = double.infinity;
  Int32List? bestKeys;

  for (final bits in _colorCacheCandidates) {
    final keys = Int32List(outKeys.length);
    if (bits > 0) {
      _walkColorCache(
          r, g, b, a, tokenIsLit, tokenLitIdx, tokenLen, bits, keys);
    } else {
      keys.fillRange(0, keys.length, -1);
    }

    final cost = _estimateCost(r, g, b, a, tokenIsLit, tokenLitIdx, tokenLen,
        tokenDist, width, bits, keys);
    if (cost < bestCost) {
      bestCost = cost;
      bestBits = bits;
      bestKeys = keys;
    }
  }

  outKeys.setAll(0, bestKeys!);
  return bestBits;
}

/// Replays the token stream while maintaining the decoder's color cache, and
/// records for each literal the key that would reproduce it, or -1.
@pragma('vm:unsafe:no-bounds-checks')
void _walkColorCache(
    Uint8List r,
    Uint8List g,
    Uint8List b,
    Uint8List a,
    Uint8List tokenIsLit,
    Int32List tokenLitIdx,
    Int32List tokenLen,
    int cacheBits,
    Int32List outKeys) {
  final cache = Uint32List(1 << cacheBits);
  // Color 0 is a legitimate value, so slot occupancy is tracked separately
  // rather than inferred from the stored color.
  final filled = Uint8List(1 << cacheBits);
  final shift = 32 - cacheBits;
  var litPtr = 0;
  var refPtr = 0;
  var pos = 0;

  int argbOf(int idx) =>
      (a[idx] << 24) | (r[idx] << 16) | (g[idx] << 8) | b[idx];
  int keyOf(int argb) => colorCacheKey(argb, shift);

  for (final isLit in tokenIsLit) {
    if (isLit != 0) {
      final argb = argbOf(tokenLitIdx[litPtr]);
      final key = keyOf(argb);
      // A pixel is only inserted once it has been coded, so the lookup sees
      // exactly the pixels before it, which is what the decoder does too.
      outKeys[litPtr] = (filled[key] != 0 && cache[key] == argb) ? key : -1;
      cache[key] = argb;
      filled[key] = 1;
      litPtr++;
      pos++;
    } else {
      final len = tokenLen[refPtr++];
      for (var k = 0; k < len; k++) {
        final argb = argbOf(pos + k);
        final key = keyOf(argb);
        cache[key] = argb;
        filled[key] = 1;
      }
      pos += len;
    }
  }
}

/// Approximate coded size of the token stream in bits for one cache
/// configuration. Extra bits for lengths and distances are the same for every
/// configuration and are left out.
@pragma('vm:unsafe:no-bounds-checks')
double _estimateCost(
    Uint8List r,
    Uint8List g,
    Uint8List b,
    Uint8List a,
    Uint8List tokenIsLit,
    Int32List tokenLitIdx,
    Int32List tokenLen,
    Int32List tokenDist,
    int width,
    int cacheBits,
    Int32List keys) {
  final cacheSize = cacheBits > 0 ? 1 << cacheBits : 0;
  final greenFreq = List<int>.filled(280 + cacheSize, 0);
  final redFreq = List<int>.filled(256, 0);
  final blueFreq = List<int>.filled(256, 0);
  final alphaFreq = List<int>.filled(256, 0);
  final distFreq = List<int>.filled(40, 0);

  var litPtr = 0;
  var refPtr = 0;
  for (final isLit in tokenIsLit) {
    if (isLit != 0) {
      final key = keys[litPtr];
      final idx = tokenLitIdx[litPtr++];
      if (key >= 0) {
        greenFreq[280 + key]++;
      } else {
        greenFreq[g[idx]]++;
        redFreq[r[idx]]++;
        blueFreq[b[idx]]++;
        alphaFreq[a[idx]]++;
      }
    } else {
      greenFreq[huffman.lengthSymbol(tokenLen[refPtr])]++;
      distFreq[huffman
          .prefixCode(huffman.distToPlaneCode(width, tokenDist[refPtr]))]++;
      refPtr++;
    }
  }

  var bits = _entropy(greenFreq) +
      _entropy(redFreq) +
      _entropy(blueFreq) +
      _entropy(alphaFreq) +
      _entropy(distFreq);

  // Every symbol a tree actually uses has to be described in the header,
  // which is what stops an oversized cache from looking free.
  for (final freq in [greenFreq, redFreq, blueFreq, alphaFreq, distFreq]) {
    for (final f in freq) {
      if (f > 0) {
        bits += 4;
      }
    }
  }

  return bits;
}

/// Shannon entropy of [freq] in bits: what an ideal prefix code would cost.
double _entropy(List<int> freq) {
  var total = 0;
  for (final f in freq) {
    total += f;
  }
  if (total == 0) {
    return 0;
  }
  var bits = 0.0;
  for (final f in freq) {
    if (f > 0) {
      bits -= f * (math.log(f / total) / math.ln2);
    }
  }
  return bits;
}
