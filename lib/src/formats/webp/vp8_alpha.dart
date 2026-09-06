/// Coding the alpha channel of a lossy WebP.
///
/// VP8 itself has no alpha, so transparency travels in its own chunk: the
/// plane is optionally predicted from its neighbours and then compressed with
/// the lossless coder, which handles a single 8-bit plane well because it is
/// usually mostly flat.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8l_encoder.dart';
import 'webp_filters.dart';

/// Compression methods of the alpha chunk.
const _alphaNoCompression = 0;
const _alphaLosslessCompression = 1;

/// How hard to look for a predictive filter.
const alphaFilterNone = 0;
const alphaFilterFast = 1;
const alphaFilterBest = 2;

/// The value the ALPH header's preprocessing field takes when the plane was
/// reduced to fewer levels.
const _alphaPreprocessedLevels = 1;

/// Below this many distinct values, filtering only gets in the way.
const _minColorsForFilterNone = 16;

/// Encodes the alpha plane as the payload of an `ALPH` chunk.
///
/// [filtering] is [alphaFilterNone], [alphaFilterFast] or [alphaFilterBest];
/// the last tries every filter and keeps the smallest result.
///
/// [quality] below 100 reduces the plane to fewer distinct levels first, which
/// costs fidelity in the transparency but compresses much better. At 100 the
/// plane is coded exactly.
@internal
Uint8List encodeAlphaChunk(Uint8List alpha, int width, int height,
    {int filtering = alphaFilterFast,
    bool compress = true,
    int quality = 100}) {
  var reducedLevels = false;
  if (quality < 100) {
    // libwebp's mapping: sixteen levels already give a low error against the
    // original, so that is where the moderate quality 70 lands.
    final levels = quality <= 70 ? 2 + quality ~/ 5 : 16 + (quality - 70) * 8;
    alpha = quantizeLevels(alpha, levels);
    reducedLevels = true;
  }
  final candidates = _filtersToTry(alpha, width, height, filtering);
  final scratch = candidates.length == 1 && candidates.first == 0
      ? null
      : Uint8List(width * height);

  Uint8List? best;
  for (final filter in candidates) {
    final source = _applyFilter(alpha, width, height, filter, scratch);
    final chunk =
        _encodeOne(source, width, height, filter, compress, reducedLevels);
    if (best == null || chunk.length < best.length) {
      best = chunk;
    }
  }
  return best!;
}

/// Reduces [data] to at most [levels] distinct values, by Lloyd's algorithm on
/// its histogram.
///
/// The smallest and largest values are pinned, so a plane that runs from fully
/// transparent to fully opaque still does. Returns [data] itself when it
/// already has few enough values, and a new list otherwise, so the caller's
/// plane is never modified.
@internal
Uint8List quantizeLevels(Uint8List data, int levels) {
  if (levels < 2 || levels > 256 || data.isEmpty) {
    return data;
  }
  final freq = Int32List(256);
  var minS = 255;
  var maxS = 0;
  var distinct = 0;
  for (final v in data) {
    if (freq[v] == 0) {
      distinct++;
    }
    freq[v]++;
    if (v < minS) {
      minS = v;
    }
    if (v > maxS) {
      maxS = v;
    }
  }
  if (distinct <= levels) {
    return data;
  }

  // Centroids start spread evenly over the range in use.
  final centroid = Float64List(256);
  for (var i = 0; i < levels; i++) {
    centroid[i] = minS + (maxS - minS) * i / (levels - 1);
  }
  final slotOf = Int32List(256);

  final errThreshold = 1e-4 * data.length;
  var lastErr = 1e38;
  for (var iter = 0; iter < _maxQuantIters; iter++) {
    final sum = Float64List(256);
    final count = Float64List(256);
    var slot = 0;
    // The values are walked in order, so the nearest centroid only ever moves
    // forwards and the assignment is one pass rather than a search per value.
    for (var s = minS; s <= maxS; s++) {
      while (slot < levels - 1 && 2 * s > centroid[slot] + centroid[slot + 1]) {
        slot++;
      }
      if (freq[s] > 0) {
        sum[slot] += s * freq[s];
        count[slot] += freq[s];
      }
      slotOf[s] = slot;
    }
    // The end points stay put; only the interior centroids move to the mean of
    // what they were given.
    if (levels > 2) {
      for (var i = 1; i < levels - 1; i++) {
        if (count[i] > 0) {
          centroid[i] = sum[i] / count[i];
        }
      }
    }
    var err = 0.0;
    for (var s = minS; s <= maxS; s++) {
      final d = s - centroid[slotOf[s]];
      err += freq[s] * d * d;
    }
    // Stop as soon as another pass would not be worth it.
    if (lastErr - err < errThreshold) {
      break;
    }
    lastErr = err;
  }

  // Collapse the two indirections into one byte-to-byte map before remapping.
  final map = Uint8List(256);
  for (var s = minS; s <= maxS; s++) {
    map[s] = (centroid[slotOf[s]] + 0.5).toInt();
  }
  final out = Uint8List(data.length);
  for (var i = 0; i < data.length; i++) {
    out[i] = map[data[i]];
  }
  return out;
}

/// How many refinement passes the level quantizer may take.
const _maxQuantIters = 6;

List<int> _filtersToTry(Uint8List alpha, int width, int height, int filtering) {
  if (filtering == alphaFilterNone) {
    return const [WebPFilters.filterNone];
  }
  if (filtering == alphaFilterBest) {
    return const [
      WebPFilters.filterNone,
      WebPFilters.filterHorizontal,
      WebPFilters.filterVertical,
      WebPFilters.filterGradient
    ];
  }
  final numColors = _countColors(alpha);
  final estimated = numColors <= _minColorsForFilterNone
      ? WebPFilters.filterNone
      : _estimateBestFilter(alpha, width, height);
  if (estimated == WebPFilters.filterNone) {
    return [WebPFilters.filterNone];
  }
  // The estimate reads gradients and misses planes that code better unfiltered,
  // so no filtering is weighed whatever it said.
  return [WebPFilters.filterNone, estimated];
}

Uint8List _applyFilter(
    Uint8List alpha, int width, int height, int filter, Uint8List? scratch) {
  final f = WebPFilters.filters[filter];
  if (f == null) {
    return alpha;
  }
  f(alpha, width, height, width, scratch!);
  return scratch;
}

/// Builds one candidate chunk: the header byte and the coded plane.
Uint8List _encodeOne(Uint8List source, int width, int height, int filter,
    bool compress, bool reducedLevels) {
  var method = compress ? _alphaLosslessCompression : _alphaNoCompression;
  Uint8List data;
  if (compress) {
    final zero = Uint8List(width * height);
    // The plane travels in the green channel, which is the one the lossless
    // coder predicts the other two against, so it pays nothing for them.
    // `exact` has to be on: every pixel here has an alpha of zero, and
    // flattening what sits underneath would erase the plane itself.
    data = VP8LEncoder(exact: true).encodeStream(
        zero, source, zero, zero, width, height,
        alphaIsUsed: true);
    if (data.length > source.length) {
      // Compression made it bigger, which happens on noisy planes.
      method = _alphaNoCompression;
      data = source;
    }
  } else {
    data = source;
  }

  final out = Uint8List(1 + data.length)
    ..[0] = method |
        (filter << 2) |
        (reducedLevels ? _alphaPreprocessedLevels << 4 : 0)
    ..setRange(1, 1 + data.length, data);
  return out;
}

int _countColors(Uint8List alpha) {
  final seen = Uint8List(256);
  for (var i = 0; i < alpha.length; i++) {
    seen[alpha[i]] = 1;
  }
  var colors = 0;
  for (var i = 0; i < 256; i++) {
    colors += seen[i];
  }
  return colors;
}

/// Guesses which filter will code smallest, without trying any of them.
///
/// For each filter it records which of sixteen buckets of prediction error
/// occur at all, and scores a filter by the sum of the buckets it touches: a
/// filter whose errors stay in the low buckets scores low. Only every other
/// pixel is sampled, which is enough to tell the filters apart.
int _estimateBestFilter(Uint8List data, int width, int height) {
  const smax = 16;
  final bins = List.generate(4, (_) => Uint8List(smax), growable: false);

  for (var j = 2; j < height - 1; j += 2) {
    final p = j * width;
    var mean = data[p];
    for (var i = 2; i < width - 1; i += 2) {
      final v = data[p + i];
      final gradient = _clip8(
          data[p + i - 1] + data[p + i - width] - data[p + i - width - 1]);
      bins[WebPFilters.filterNone][(v - mean).abs() >> 4] = 1;
      bins[WebPFilters.filterHorizontal][(v - data[p + i - 1]).abs() >> 4] = 1;
      bins[WebPFilters.filterVertical][(v - data[p + i - width]).abs() >> 4] =
          1;
      bins[WebPFilters.filterGradient][(v - gradient).abs() >> 4] = 1;
      mean = (3 * mean + v + 2) >> 2;
    }
  }

  var bestFilter = WebPFilters.filterNone;
  var bestScore = 0x7fffffff;
  for (var filter = 0; filter < 4; filter++) {
    var score = 0;
    for (var i = 0; i < smax; i++) {
      if (bins[filter][i] > 0) {
        score += i;
      }
    }
    if (score < bestScore) {
      bestScore = score;
      bestFilter = filter;
    }
  }
  return bestFilter;
}

@pragma('vm:prefer-inline')
int _clip8(int v) => v & ~0xff == 0
    ? v
    : v < 0
        ? 0
        : 255;
