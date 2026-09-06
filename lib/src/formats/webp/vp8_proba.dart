/// The adaptive probability model of the lossy encoder.
///
/// VP8 codes every coefficient through a probability chosen by the type of
/// block, how far into the block the coefficient sits (its band) and how large
/// its neighbours were (its context). The encoder starts from the default
/// table, counts what it actually coded, and writes back the probabilities that
/// pay for themselves.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8_bool_encoder.dart';
import 'vp8_cost_tables.dart';
import 'vp8_tables.dart';

/// Highest level whose cost still varies with its context; above this the
/// variable part is constant and lives in [kLevelFixedCosts].
const maxVariableLevel = 67;

/// Number of probabilities in the coefficient table.
const _numCoeffProbas = numTypes * numBands * numCtx * numProbas;

/// One cost table per (type, band, context), holding levels 0..67.
const _costTableSize = maxVariableLevel + 1;

Uint8List _flatten(List<List<List<List<int>>>> table) {
  final flat = Uint8List(_numCoeffProbas);
  var i = 0;
  for (final t in table) {
    for (final b in t) {
      for (final c in b) {
        for (final p in c) {
          flat[i++] = p;
        }
      }
    }
  }
  return flat;
}

final _defaultProbas = _flatten(kCoeffsProba0);
final _updateProbas = _flatten(kCoeffsUpdateProba);

/// The cost of coding [bit] when zero has probability [proba] out of 256.
@pragma('vm:prefer-inline')
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
int bitCost(int bit, int proba) =>
    bit == 0 ? kEntropyCost[proba] : kEntropyCost[255 - proba];

/// The probability state of one frame.
@internal
class VP8EncProba {
  VP8EncProba() {
    coeffs.setAll(0, _defaultProbas);
  }

  /// Probabilities, indexed by `((type * numBands + band) * numCtx + ctx) *
  /// numProbas + p`.
  final coeffs = Uint8List(_numCoeffProbas);

  /// How often each probability was exercised, and how often the bit was one.
  ///
  /// The count is in the upper sixteen bits and the number of ones in the
  /// lower sixteen, so one add records both.
  final stats = Uint32List(_numCoeffProbas);

  /// The cost of each level, per (type, band, context).
  final levelCost = Uint16List(numTypes * numBands * numCtx * _costTableSize);

  /// Where in [levelCost] the table for `(type, position, ctx)` starts.
  ///
  /// The bands repeat, so this saves a lookup through [kBands] in the inner
  /// loops that price a block.
  final costBase = Int32List(numTypes * 16 * numCtx);

  /// Probabilities of the segment tree.
  final segments = Uint8List(3)..fillRange(0, 3, 255);

  int skipProba = 0;

  /// Whether a per-macroblock skip flag is coded at all.
  bool useSkipProba = false;

  /// Number of macroblocks that turned out to be entirely zero.
  int nbSkip = 0;

  /// Whether [coeffs] changed since [levelCost] was last computed.
  bool dirty = true;

  /// The cost of one coefficient, given the base of its cost table.
  @pragma('vm:prefer-inline')
  @pragma('vm:unsafe:no-bounds-checks')
  @pragma('vm:unsafe:no-interrupts')
  int levelCostAt(int base, int level) =>
      kLevelFixedCosts[level] +
      levelCost[base + (level > maxVariableLevel ? maxVariableLevel : level)];

  /// Recomputes [levelCost] from [coeffs].
  void calculateLevelCosts() {
    if (!dirty) {
      return;
    }
    for (var ctype = 0; ctype < numTypes; ctype++) {
      for (var band = 0; band < numBands; band++) {
        for (var ctx = 0; ctx < numCtx; ctx++) {
          final p = ((ctype * numBands + band) * numCtx + ctx) * numProbas;
          final table =
              ((ctype * numBands + band) * numCtx + ctx) * _costTableSize;
          // A non-zero context has already paid for the "not the end of the
          // block" bit; a zero context has not, so it is added here.
          final cost0 = ctx > 0 ? bitCost(1, coeffs[p]) : 0;
          final nonZero = bitCost(1, coeffs[p + 1]) + cost0;
          levelCost[table] = bitCost(0, coeffs[p + 1]) + cost0;
          for (var v = 1; v <= maxVariableLevel; v++) {
            levelCost[table + v] = nonZero + _variableLevelCost(v, p);
          }
        }
      }
      for (var n = 0; n < 16; n++) {
        for (var ctx = 0; ctx < numCtx; ctx++) {
          costBase[(ctype * 16 + n) * numCtx + ctx] =
              ((ctype * numBands + kBands[n]) * numCtx + ctx) * _costTableSize;
        }
      }
    }
    dirty = false;
  }

  /// The context-dependent part of the cost of coding [level].
  int _variableLevelCost(int level, int p) {
    var pattern = kLevelCodes[level - 1][0];
    var bits = kLevelCodes[level - 1][1];
    var cost = 0;
    for (var i = 2; pattern != 0; i++) {
      if (pattern & 1 != 0) {
        cost += bitCost(bits & 1, coeffs[p + i]);
      }
      bits >>= 1;
      pattern >>= 1;
    }
    return cost;
  }

  /// Records that [bit] was coded through the counter at [at].
  @pragma('vm:prefer-inline')
  int recordStats(int bit, int at) {
    var p = stats[at];
    // Halve both counters before the total can overflow its sixteen bits.
    if (p >= 0xfffe0000) {
      p = ((p + 1) >> 1) & 0x7fff7fff;
    }
    stats[at] = p + 0x00010000 + bit;
    return bit;
  }

  void resetTokenStats() {
    stats.fillRange(0, stats.length, 0);
  }

  /// Adopts the probabilities the statistics suggest, wherever they pay for
  /// the eight bits it costs to signal them.
  ///
  /// Returns the cost of coding the updates, in 1/256ths of a bit.
  int finalizeTokenProbas() {
    var hasChanged = false;
    var size = 0;
    for (var i = 0; i < _numCoeffProbas; i++) {
      final stat = stats[i];
      final nb = stat & 0xffff;
      final total = (stat >> 16) & 0xffff;
      final updateProba = _updateProbas[i];
      final oldP = _defaultProbas[i];
      final newP = _calcTokenProba(nb, total);
      final oldCost = _branchCost(nb, total, oldP) + bitCost(0, updateProba);
      final newCost =
          _branchCost(nb, total, newP) + bitCost(1, updateProba) + 8 * 256;
      final useNewP = oldCost > newCost;
      size += bitCost(useNewP ? 1 : 0, updateProba);
      if (useNewP) {
        coeffs[i] = newP;
        hasChanged |= newP != oldP;
        size += 8 * 256;
      } else {
        coeffs[i] = oldP;
      }
    }
    dirty = hasChanged;
    return size;
  }

  /// Writes the probability updates into the frame header.
  void write(VP8BoolEncoder bw) {
    for (var i = 0; i < _numCoeffProbas; i++) {
      final p0 = coeffs[i];
      final update = p0 != _defaultProbas[i];
      if (bw.putBit(update ? 1 : 0, _updateProbas[i]) != 0) {
        bw.putBits(p0, 8);
      }
    }
    if (bw.putBitUniform(useSkipProba ? 1 : 0) != 0) {
      bw.putBits(skipProba, 8);
    }
  }
}

int _calcTokenProba(int nb, int total) =>
    nb != 0 ? 255 - nb * 255 ~/ total : 255;

/// The cost of coding [nb] ones and `total - nb` zeroes at [proba].
int _branchCost(int nb, int total, int proba) =>
    nb * bitCost(1, proba) + (total - nb) * bitCost(0, proba);
