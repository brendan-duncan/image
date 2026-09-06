/// Symbol statistics for a VP8L stream, and the clustering that turns
/// per-region statistics into meta Huffman groups.
///
/// A single set of Huffman codes has to serve the whole image, so a photo with
/// a flat sky above busy foliage pays for one compromise distribution. Meta
/// Huffman lets regions with different statistics use different codes; the work
/// here is deciding which regions should share.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../../util/_internal.dart';

/// Natural logs of the small integers, since every log taken here is of a
/// symbol count.
///
/// Clustering asks for the entropy of a histogram against every open group, so
/// these are taken by the million, and almost all counts are small. Values come
/// from `math.log` itself, so tabulating them changes no result.
final Float64List _logOfInt = () {
  final t = Float64List(_logTableSize);
  for (var i = 1; i < _logTableSize; i++) {
    t[i] = math.log(i.toDouble());
  }
  return t;
}();

const _logTableSize = 4096;

@pragma('vm:prefer-inline')
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
double _logInt(int n) =>
    n < _logTableSize ? _logOfInt[n] : math.log(n.toDouble());

/// Symbol counts for one region: the five alphabets a VP8L stream codes with.
@internal
class VP8LHistogram {
  VP8LHistogram(this.greenSize)
      : green = Uint32List(greenSize),
        red = Uint32List(256),
        blue = Uint32List(256),
        alpha = Uint32List(256),
        dist = Uint32List(40);

  /// 280 literal and length symbols, plus one per color cache entry.
  final int greenSize;
  final Uint32List green;
  final Uint32List red;
  final Uint32List blue;
  final Uint32List alpha;
  final Uint32List dist;

  void addLiteral(int r, int g, int b, int a) {
    if (green[g]++ == 0) _touch(0, g);
    if (red[r]++ == 0) _touch(1, r);
    if (blue[b]++ == 0) _touch(2, b);
    if (alpha[a]++ == 0) _touch(3, a);
  }

  void addCacheRef(int key) {
    if (green[280 + key]++ == 0) _touch(0, 280 + key);
  }

  void addCopy(int lengthSymbol, int distSymbol) {
    if (green[lengthSymbol]++ == 0) _touch(0, lengthSymbol);
    if (dist[distSymbol]++ == 0) _touch(4, distSymbol);
  }

  void addTo(VP8LHistogram other) {
    for (var k = 0; k < 5; k++) {
      final mine = _arrays[k];
      final theirs = other._arrays[k];
      final touched = _touchedIdx[k];
      final n = _touchedCount[k];
      for (var j = 0; j < n; j++) {
        final i = touched[j];
        if (theirs[i] == 0) {
          other._touch(k, i);
        }
        theirs[i] += mine[i];
      }
    }
    other._statsValid = false;
  }

  VP8LHistogram clone() {
    final c = VP8LHistogram(greenSize);
    addTo(c);
    return c;
  }

  /// Estimated cost in bits of coding this region plus describing its codes.
  ///
  /// The entropy is what an ideal prefix code would spend; the per-symbol term
  /// stands in for the code length table in the header, and is what stops
  /// clustering from splitting into ever more groups that each code little.
  double get cost {
    _ensureStats();
    var c = 0.0;
    for (var k = 0; k < 5; k++) {
      c += _entropyOf(_sum[k], _total[k]) + _used[k] * _bitsPerDescribedSymbol;
    }
    return c;
  }

  /// Cost of the histogram this and [other] would sum to, without building it.
  ///
  /// The clustering asks this for every block against every open group. Both
  /// terms of the entropy are kept as running sums, so only the symbols the
  /// block actually touches have to be revisited, rather than the whole
  /// alphabet.
  @pragma('vm:unsafe:no-bounds-checks')
  double mergedCostWith(VP8LHistogram other) {
    _ensureStats();
    other._ensureStats();
    var c = 0.0;
    for (var k = 0; k < 5; k++) {
      final mine = _arrays[k];
      final theirs = other._arrays[k];
      var sum = _sum[k];
      var used = _used[k];
      final touched = other._touchedIdx[k];
      final n = other._touchedCount[k];
      for (var j = 0; j < n; j++) {
        final i = touched[j];
        final a = mine[i];
        final b = theirs[i];
        if (a > 0) {
          sum += a * _logInt(a);
        } else {
          used++;
        }
        final merged = a + b;
        sum -= merged * _logInt(merged);
      }
      c += _entropyOf(sum, _total[k] + other._total[k]) +
          used * _bitsPerDescribedSymbol;
    }
    return c;
  }

  /// Entropy in bits from the running sum of -f·ln(f) and the total count.
  static double _entropyOf(double sum, int total) =>
      total == 0 ? 0 : (sum + total * _logInt(total)) / math.ln2;

  late final List<Uint32List> _arrays = [green, red, blue, alpha, dist];

  final Float64List _sum = Float64List(5); // per alphabet: sum of -f*ln(f)
  final Int32List _total = Int32List(5);
  final Int32List _used = Int32List(5);
  var _statsValid = false;

  /// Which symbols of each alphabet this histogram has counted, in the order
  /// they were first reached, with how many in [_touchedCount].
  ///
  /// The alternative is to find them by scanning, but the green alphabet alone
  /// spans over a thousand symbols while a 16x16 block holds at most 256
  /// tokens, and meta Huffman builds one histogram per block. Recording each
  /// symbol as it arrives costs a branch and turns every later pass over this
  /// histogram from the size of the alphabet into the size of what was
  /// actually used.
  final List<Int32List> _touchedIdx = List.filled(5, _noSymbols);
  final Int32List _touchedCount = Int32List(5);

  static final _noSymbols = Int32List(0);

  void _touch(int k, int symbol) {
    var list = _touchedIdx[k];
    final n = _touchedCount[k];
    if (n == list.length) {
      list = Int32List(n == 0 ? 8 : n * 2)..setRange(0, n, _touchedIdx[k]);
      _touchedIdx[k] = list;
    }
    list[n] = symbol;
    _touchedCount[k] = n + 1;
  }

  void _ensureStats() {
    if (_statsValid) {
      return;
    }
    for (var k = 0; k < 5; k++) {
      final freq = _arrays[k];
      final touched = _touchedIdx[k];
      final n = _touchedCount[k];
      var sum = 0.0;
      var total = 0;
      for (var j = 0; j < n; j++) {
        final f = freq[touched[j]];
        sum -= f * _logInt(f);
        total += f;
      }
      _sum[k] = sum;
      _total[k] = total;
      // No symbol is recorded twice and every recorded one has a nonzero
      // count, so the count of them is exactly how many the codes must
      // describe.
      _used[k] = n;
    }
    _statsValid = true;
  }

  /// Rough cost of carrying one symbol through the code length table.
  static const _bitsPerDescribedSymbol = 4.0;
}

/// Assigns each block a meta Huffman group, merging blocks whose statistics are
/// close enough that sharing a set of codes costs less than describing another.
///
/// Blocks are visited in raster order and each joins the group it damages
/// least, or starts a new one while [maxGroups] allows. That is one pass rather
/// than the full pairwise search libwebp runs, which keeps this linear in the
/// number of blocks at a small cost in compression. A second pass then revisits
/// every block against the groups that ended up existing, since the first
/// blocks chose from almost nothing.
///
/// [maxGroups] of 16 is measured: 24 buys 0.03% and costs 3% of the encode.
///
/// Returns the group index per block, or null when one group for the whole
/// image is no more expensive than splitting it.
@internal
VP8LClustering? clusterHistograms(List<VP8LHistogram> blocks,
    {int maxGroups = 16}) {
  if (blocks.length < 2) {
    return null;
  }

  final groups = <VP8LHistogram>[];
  final assignment = Int32List(blocks.length);

  for (var i = 0; i < blocks.length; i++) {
    final block = blocks[i];
    if (block.cost == 0) {
      // A block no token starts in can join anything; keep it with group 0.
      assignment[i] = 0;
      if (groups.isEmpty) {
        groups.add(block.clone());
      }
      continue;
    }

    var bestGroup = -1;
    var bestIncrease = double.infinity;
    for (var gi = 0; gi < groups.length; gi++) {
      final increase =
          groups[gi].mergedCostWith(block) - groups[gi].cost - block.cost;
      if (increase < bestIncrease) {
        bestIncrease = increase;
        bestGroup = gi;
      }
    }

    // Starting a group means describing another five code tables, so only do it
    // when merging would cost more than that.
    if (bestGroup < 0 ||
        (bestIncrease > _newGroupCost && groups.length < maxGroups)) {
      assignment[i] = groups.length;
      groups.add(block.clone());
    } else {
      assignment[i] = bestGroup;
      block.addTo(groups[bestGroup]);
    }
  }

  if (groups.length < 2) {
    return null;
  }

  final greenSize = blocks.first.greenSize;

  // Second pass. Each block joined the best group among those that existed
  // when it was reached, which for the first blocks is barely a choice at all.
  // Now that the whole set is known, give every block the group it actually
  // costs least to join and rebuild the groups from that, the way libwebp's
  // HistogramRemap does.
  final rebuilt = List.generate(groups.length, (_) => VP8LHistogram(greenSize),
      growable: false);
  for (var i = 0; i < blocks.length; i++) {
    final block = blocks[i];
    if (block.cost == 0) {
      // A block no token starts in codes nothing either way, so keep it with
      // its neighbour: a run of equal entries is what the entropy image
      // itself compresses best.
      assignment[i] = i > 0 ? assignment[i - 1] : 0;
    } else {
      var best = 0;
      var bestIncrease = double.infinity;
      for (var gi = 0; gi < groups.length; gi++) {
        // The block's own cost is the same whichever group takes it, so only
        // what it adds to the group decides.
        final increase = groups[gi].mergedCostWith(block) - groups[gi].cost;
        if (increase < bestIncrease) {
          bestIncrease = increase;
          best = gi;
        }
      }
      assignment[i] = best;
    }
    block.addTo(rebuilt[assignment[i]]);
  }

  // A group the remap emptied would still cost five code tables to describe,
  // so renumber around it.
  final used = Uint32List(groups.length);
  for (final gi in assignment) {
    used[gi]++;
  }
  final renumbered = Int32List(groups.length);
  final kept = <VP8LHistogram>[];
  for (var gi = 0; gi < groups.length; gi++) {
    renumbered[gi] = kept.length;
    if (used[gi] > 0) {
      kept.add(rebuilt[gi]);
    }
  }
  if (kept.length < 2) {
    return null;
  }
  for (var i = 0; i < assignment.length; i++) {
    assignment[i] = renumbered[assignment[i]];
  }
  groups
    ..clear()
    ..addAll(kept);

  // libwebp follows its clustering with HistogramCombineGreedy, a full pairwise
  // search for groups worth merging. Tried here and measured at 196 bytes over
  // a 330 image corpus, which is nothing: the remap above already separates the
  // groups well enough that no pair is left worth collapsing. libwebp needs it
  // because it has no equivalent of that pass.

  // Compare against coding everything with one set of codes.
  final single = VP8LHistogram(greenSize);
  for (final b in blocks) {
    b.addTo(single);
  }
  var split = 0.0;
  for (final g in groups) {
    split += g.cost;
  }

  // The entropy image has to be stored too. It is itself entropy coded, so
  // charge it the entropy of the group assignment rather than a flat rate:
  // costs from different block sizes are only comparable if this term scales
  // with the block count the way the real stream does.
  final counts = Uint32List(groups.length);
  for (final gi in assignment) {
    counts[gi]++;
  }
  var perBlock = 0.0;
  for (final c in counts) {
    if (c > 0) {
      perBlock -= c * (math.log(c / blocks.length) / math.ln2);
    }
  }
  // Plus the five code tables the entropy image needs for itself.
  split += perBlock + 5 * 32;

  return split < single.cost
      ? VP8LClustering(assignment, groups.length, split)
      : null;
}

/// What another meta Huffman group costs before it can pay for itself: five
/// more code tables to describe.
const _newGroupCost = 5 * 32.0;

/// A block-to-group assignment and what it is estimated to cost.
@internal
class VP8LClustering {
  VP8LClustering(this.assignment, this.numGroups, this.cost);

  /// Meta Huffman group index for each block, in raster order.
  final Int32List assignment;
  final int numGroups;

  /// Estimated bits to code the image this way, entropy image included.
  final double cost;
}
