/// Turning pixels into the token stream a VP8L image codes: literals and LZ77
/// back-references.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8l_color_hash.dart';
import 'vp8l_huffman_encoder.dart' as huffman;

/// The token stream for one image: literals and back-references in the order
/// they are coded, plus where in the image each one starts.
///
/// Typed arrays: a literal-heavy image has a token per pixel, and a growable
/// `List<int>` that long costs eight bytes an element plus doubling slack.
@internal
class VP8LBackwardRefs {
  VP8LBackwardRefs(this.isLiteral, this.literalIndex, this.length,
      this.distance, this.position);

  /// One entry per token: nonzero if it is a literal.
  final Uint8List isLiteral;

  /// Pixel index of each literal, in literal order.
  final Int32List literalIndex;

  /// Match length of each back-reference, in back-reference order.
  final Int32List length;

  /// Match distance of each back-reference, in back-reference order.
  final Int32List distance;

  /// Pixel index each token starts at, in token order. Meta Huffman uses this
  /// to decide which group of codes a token belongs to.
  final Int32List position;
}

/// A parse of the image: how many pixels the token starting at each position
/// covers, and at what distance. Positions inside a token are never read.
///
/// The two arrays are sized together so a caller cannot mismatch them. The
/// code that fills them runs without bounds checks.
@internal
class VP8LCover {
  VP8LCover(this.numPixels)
      : cover = Int32List(numPixels),
        distance = Int32List(numPixels);

  /// Length of both arrays. Nothing that reads them checks bounds, so a second
  /// length kept alongside corrupts memory instead of throwing.
  final int numPixels;

  final Int32List cover;
  final Int32List distance;
}

/// How far back the chain of candidate positions is followed.
///
/// libwebp's `GetMaxItersForQuality` tops out at 86 even at quality 100, and it
/// is the value tuned over a far wider corpus than anything measured here.
const _maxChain = 86;

/// Bits of a packed match holding the length, as in libwebp's `offset_length_`
@internal
const matchLengthBits = 12;

/// Longest match the tokenizer will emit.
@internal
const maxMatchLength = (1 << matchLengthBits) - 1;

/// Distances stop at 1048576, and the first 120 values are taken by the
/// near-neighbour plane codes, leaving this as the real maximum
@internal
const maxMatchDistance = 1048456;

/// The longest match reachable from each position
///
/// A parse that considers every way of covering the image needs the answer at
/// every pixel, so the whole table is built up front.
@internal
class VP8LMatches {
  VP8LMatches(this.match, this.cheapDistances);

  /// Distance above [matchLengthBits], length below; length zero means nothing
  /// matches and the distance is meaningless
  final Uint32List match;

  @pragma('vm:prefer-inline')
  int lengthAt(int i) => match[i] & maxMatchLength;

  @pragma('vm:prefer-inline')
  int distanceAt(int i) => match[i] >> matchLengthBits;

  /// Offsets landing on the near-neighbour plane codes, the cheapest distances
  /// the format has, where a shorter match can beat a longer one from the chain
  final Int32List cheapDistances;
}

/// Finds the best match at every position.
///
/// Positions are visited from the end backwards, because a match found at one
/// position usually answers for its neighbours too: if the same distance still
/// matches one pixel to the left, that pixel's best match is this one grown by
/// one, and no search is needed for it. On flat or repetitive images a single
/// search then covers a whole run, which is most of what makes such images
/// cheap to encode. libwebp does the same in `VP8LHashChainFill`.
@internal
@pragma('vm:unsafe:no-bounds-checks')
VP8LMatches computeMatches(Uint8List r, Uint8List g, Uint8List b, Uint8List a,
    int numPixels, int width) {
  // Bounds checks are off here, so the lengths are the contract.
  if (r.length < numPixels ||
      g.length < numPixels ||
      b.length < numPixels ||
      a.length < numPixels) {
    throw ArgumentError('computeMatches needs $numPixels of every plane');
  }
  final lz = _Lz77(r, g, b, a, numPixels)..fillChain();
  final px = lz._px;
  final prev = lz._prev;
  final match = Uint32List(numPixels);

  // The offsets reaching the nearest plane codes: the pixel before, the one
  // before that, and the three directly above and to either side.
  //
  // libwebp's kLZ77Box strategy tries every offset whose plane code is a near
  // neighbour, some ninety of them. Carrying the next ring out as well was
  // measured at 0.04 points of the corpus for 19% more encode time, which is
  // the wrong way round while size is inside budget and speed is not.
  final cheapDistances = Int32List.fromList(<int>[
    1,
    2,
    width - 1,
    width,
    width + 1
  ].where((d) => d >= 1 && d < numPixels).toSet().toList()
    ..sort());
  final numCheap = cheapDistances.length;
  if (numCheap > 5) {
    throw StateError('the near-neighbour walk has five slots, not $numCheap');
  }

  // A run at an offset is the run one to the right plus one, and this walk and
  // the search below both go right to left, so a counter per offset replaces a
  // table. An unused slot gets a distance no position reaches, pinning it at 0
  final slots = Int32List(5)..fillRange(0, 5, numPixels);
  for (var c = 0; c < numCheap; c++) {
    slots[c] = cheapDistances[c];
  }
  final d0 = slots[0];
  final d1 = slots[1];
  final d2 = slots[2];
  final d3 = slots[3];
  final d4 = slots[4];
  var n0 = 0;
  var n1 = 0;
  var n2 = 0;
  var n3 = 0;
  var n4 = 0;
  var cheapAt = numPixels;

  var i = numPixels - 1;
  while (i > 0) {
    while (cheapAt > i) {
      final p = cheapAt - 1;
      final at = px[p];
      n0 =
          p >= d0 && at == px[p - d0] ? (n0 < maxMatchLength ? n0 + 1 : n0) : 0;
      n1 =
          p >= d1 && at == px[p - d1] ? (n1 < maxMatchLength ? n1 + 1 : n1) : 0;
      n2 =
          p >= d2 && at == px[p - d2] ? (n2 < maxMatchLength ? n2 + 1 : n2) : 0;
      n3 =
          p >= d3 && at == px[p - d3] ? (n3 < maxMatchLength ? n3 + 1 : n3) : 0;
      n4 =
          p >= d4 && at == px[p - d4] ? (n4 < maxMatchLength ? n4 + 1 : n4) : 0;
      cheapAt = p;
    }
    var maxLen = numPixels - i;
    if (maxLen > maxMatchLength) {
      maxLen = maxMatchLength;
    }
    var best = 0;
    var bestDist = 0;

    // The near-neighbour runs cost nothing to try and are the cheapest
    // distances the format has, so they go first: any can leave the chain with
    // nothing to beat and be skipped entirely
    if (n0 > best) {
      best = n0;
      bestDist = d0;
    }
    if (n1 > best) {
      best = n1;
      bestDist = d1;
    }
    if (n2 > best) {
      best = n2;
      bestDist = d2;
    }
    if (n3 > best) {
      best = n3;
      bestDist = d3;
    }
    if (n4 > best) {
      best = n4;
      bestDist = d4;
    }

    if (best < maxLen) {
      // Past a few hundred pixels a longer match saves almost nothing, so the
      // walk gives up rather than chasing the last few.
      final enough = maxLen < 256 ? maxLen : 256;
      var c = prev[i];
      var steps = 0;
      while (c >= 0 && steps < _maxChain) {
        steps++;
        final dist = i - c;
        if (dist > maxMatchDistance) {
          break;
        }
        // Only a longer match can win, so the pixel one past the current best
        // is a cheap rejection.
        if (px[c + best] == px[i + best]) {
          var len = 0;
          while (len < maxLen && px[i + len] == px[c + len]) {
            len++;
          }
          if (len > best) {
            best = len;
            bestDist = dist;
            if (best >= enough) {
              break;
            }
          }
        }
        c = prev[c];
      }
    }

    match[i] = (bestDist << matchLengthBits) | best;

    // Carry the match left for as long as it keeps matching.
    var j = i;
    while (bestDist > 0 && best < maxMatchLength) {
      final k = j - 1;
      if (k <= 0 || k < bestDist || px[k - bestDist] != px[k]) {
        break;
      }
      best++;
      match[k] = (bestDist << matchLengthBits) | best;
      j = k;
    }
    i = j - 1;
  }
  return VP8LMatches(match, cheapDistances);
}

/// Rebuilds the token stream from a parse that says, for each position, how
/// many pixels the token starting there covers.
///
/// A cover of 1 is a literal; anything longer is a back-reference at the
/// distance the parse chose for that position.
@internal
VP8LBackwardRefs refsFromCover(VP8LCover parse) {
  final numPixels = parse.numPixels;
  final cover = parse.cover;
  final coverDistance = parse.distance;

  // Counted first so every array is allocated at its final size.
  var numTokens = 0;
  var numLiterals = 0;
  for (var i = 0; i < numPixels;) {
    final n = cover[i];
    numTokens++;
    if (n <= 1) {
      numLiterals++;
      i++;
    } else {
      i += n;
    }
  }

  final isLiteral = Uint8List(numTokens);
  final literalIndex = Int32List(numLiterals);
  final length = Int32List(numTokens - numLiterals);
  final distance = Int32List(numTokens - numLiterals);
  final positions = Int32List(numTokens);
  var t = 0;
  var lit = 0;
  var ref = 0;
  for (var i = 0; i < numPixels;) {
    final n = cover[i];
    positions[t] = i;
    if (n <= 1) {
      isLiteral[t] = 1;
      literalIndex[lit++] = i;
      i++;
    } else {
      length[ref] = n;
      distance[ref++] = coverDistance[i];
      i += n;
    }
    t++;
  }
  return VP8LBackwardRefs(isLiteral, literalIndex, length, distance, positions);
}

/// The hash chain the match search walks.
class _Lz77 {
  _Lz77(Uint8List r, Uint8List g, Uint8List b, Uint8List a, this._numPixels)
      : _px = Uint32List(_numPixels),
        _prev = Int32List(_numPixels) {
    var hashBits = 1;
    while ((1 << hashBits) < _numPixels && hashBits < 18) {
      hashBits++;
    }
    _shift = 32 - hashBits;
    _head = Int32List(1 << hashBits)..fillRange(0, 1 << hashBits, -1);

    // Pixels packed one word each, so matching compares a single value per
    // position instead of four, which is most of what this loop does.
    final px = _px;
    for (var i = 0; i < _numPixels; i++) {
      px[i] = (g[i] << 24) | (r[i] << 16) | (b[i] << 8) | a[i];
    }
  }

  final int _numPixels;
  final Uint32List _px;
  final Int32List _prev;
  late final Int32List _head;
  late final int _shift;

  /// libwebp's own pair hash, kept in 32-bit arithmetic.
  ///
  /// A 64-bit multiply would be the obvious way to mix two pixels, but on the
  /// web an int is a double: only the low 53 bits of a product survive, and a
  /// 64-bit constant is not even expressible. Two 32-bit multiplies say the
  /// same thing on every platform.
  @pragma('vm:prefer-inline')
  int _hash(int first, int second) =>
      ((mul32(second, 0xc6a4a793) + mul32(first, 0x5bd1e996)) & 0xffffffff) >>>
      _shift;

  /// Links every position to the previous one that hashes the same.
  ///
  /// Positions are keyed on the pair of pixels starting there: one pixel alone
  /// puts far too many positions in a slot, and no match shorter than three
  /// pixels is ever coded, so keying on two loses nothing.
  ///
  /// libwebp keys a run of identical pixels on its colour and how much of it
  /// is left, to spread the run across slots. Tried here and reverted: it made
  /// the PNG suite 11% larger and the encode 36% slower. With a pair key, the
  /// most recent entry in a run's slot is the immediately preceding pixel, so
  /// the search finds a full-length match at distance 1, the cheapest distance
  /// code there is, on its first step. Spreading the run replaces that with
  /// distant candidates, which libwebp can afford because it tries an RLE pass
  /// as a separate strategy
  @pragma('vm:unsafe:no-bounds-checks')
  void fillChain() {
    final n = _numPixels;
    if (n <= 2) {
      return;
    }
    final px = _px;
    final prev = _prev;
    final head = _head;
    for (var pos = 0; pos < n - 1; pos++) {
      final h = _hash(px[pos], px[pos + 1]);
      prev[pos] = head[h];
      head[h] = pos;
    }
    // The last position starts no pair, so nothing links to it.
    prev[n - 1] = -1;
  }
}

/// What each symbol costs to code, in bits, estimated from a first pass over
/// the image.
///
/// The tokenizer has to choose between a match and a literal before any Huffman
/// code exists, so it works from the distribution a greedy pass produced. The
/// numbers are approximate, but they rank the choices far better than length
/// alone: a long match to a distant pixel can cost more than a short one near
/// by, and no length comparison sees that.
@internal
class VP8LCostModel {
  VP8LCostModel._(this._green, this._red, this._blue, this._alpha, this._dist);

  final Float64List _green;
  final Float64List _red;
  final Float64List _blue;
  final Float64List _alpha;
  final Float64List _dist;

  /// Builds the model straight from a cover of the image.
  ///
  /// Reading the cover rather than a built token stream keeps the first pass
  /// from materialising a list per token field only to throw it away.
  factory VP8LCostModel.fromCover(VP8LCover parse, Uint8List r, Uint8List g,
      Uint8List b, Uint8List a, int width) {
    final green = Float64List(280);
    final red = Float64List(256);
    final blue = Float64List(256);
    final alpha = Float64List(256);
    final dist = Float64List(40);

    final numPixels = parse.numPixels;
    final cover = parse.cover;
    final coverDistance = parse.distance;
    var i = 0;
    while (i < numPixels) {
      final n = cover[i];
      if (n <= 1) {
        green[g[i]]++;
        red[r[i]]++;
        blue[b[i]]++;
        alpha[a[i]]++;
        i++;
      } else {
        green[huffman.lengthSymbol(n)]++;
        dist[huffman
            .prefixCode(huffman.distToPlaneCode(width, coverDistance[i]))]++;
        i += n;
      }
    }

    return VP8LCostModel._(_toBits(green), _toBits(red), _toBits(blue),
        _toBits(alpha), _toBits(dist));
  }

  /// Bits to code a match of each length, symbol and extra bits together.
  ///
  /// A parse that weighs every length at every position asks for this millions
  /// of times, and it depends on nothing but the length.
  late final Float64List lengthBits = () {
    final t = Float64List(maxMatchLength + 1);
    for (var len = 1; len <= maxMatchLength; len++) {
      final (extra, _) = huffman.lengthExtra(len);
      t[len] = _green[huffman.lengthSymbol(len)] + extra;
    }
    return t;
  }();

  /// Bits to code the distance part of a match at [distance].
  double distanceBits(int distance, int width) {
    final planeCode = huffman.distToPlaneCode(width, distance);
    final (extra, _) = huffman.prefixExtra(planeCode);
    return _dist[huffman.prefixCode(planeCode)] + extra;
  }

  /// Turns counts into bit costs. A symbol the first pass never used still has
  /// to be codeable, so it is charged as if it had appeared once.
  static Float64List _toBits(Float64List freq) {
    var total = 0.0;
    for (final f in freq) {
      total += f;
    }
    if (total == 0) {
      return Float64List(freq.length)..fillRange(0, freq.length, 8);
    }
    final bits = Float64List(freq.length);
    for (var i = 0; i < freq.length; i++) {
      final f = freq[i] > 0 ? freq[i] : 1.0;
      bits[i] = -(math.log(f / (total + 1)) / math.ln2);
    }
    return bits;
  }

  /// Bits to code the pixel at [i] as a literal.
  double literalCost(
          Uint8List r, Uint8List g, Uint8List b, Uint8List a, int i) =>
      _green[g[i]] + _red[r[i]] + _blue[b[i]] + _alpha[a[i]];
}
