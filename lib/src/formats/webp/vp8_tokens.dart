/// A recording of every bit the encoder wants to write, before it knows the
/// probabilities to write them with.
///
/// Coefficient probabilities are chosen from the statistics of the whole
/// frame, but the mode decisions that produce those statistics need to be made
/// first. Storing the decisions as (bit, which probability) pairs lets the
/// frame be coded once, with the final probabilities, after everything is
/// known.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8_bool_encoder.dart';
import 'vp8_proba.dart';

/// Marks a token whose probability is a constant of the syntax rather than an
/// index into the adaptive table.
const _fixedProba = 1 << 14;

@internal
class VP8TokenBuffer {
  Uint16List _tokens = Uint16List(8192);
  int _length = 0;

  int get length => _length;

  void clear() {
    _length = 0;
  }

  @pragma('vm:prefer-inline')
  void _push(int token) {
    if (_length == _tokens.length) {
      _grow();
    }
    _tokens[_length++] = token;
  }

  void _grow() {
    _tokens = Uint16List(_tokens.length * 2)..setRange(0, _length, _tokens);
  }

  /// Records [bit] coded through the probability at [probaIdx], and counts it.
  @pragma('vm:prefer-inline')
  int add(VP8EncProba proba, int bit, int probaIdx) {
    _push((bit << 15) | probaIdx);
    return proba.recordStats(bit, probaIdx);
  }

  /// As [add], but counting the event against a different slot than the one it
  /// is coded with, which is what the escape codes of large levels do.
  @pragma('vm:prefer-inline')
  int addStat(VP8EncProba proba, int bit, int probaIdx, int statIdx) {
    _push((bit << 15) | probaIdx);
    return proba.recordStats(bit, statIdx);
  }

  /// Records [bit] coded with a fixed probability.
  @pragma('vm:prefer-inline')
  void addConstant(int bit, int proba) {
    _push((bit << 15) | _fixedProba | proba);
  }

  /// Writes everything recorded, using [probas] for the adaptive tokens.
  void emit(VP8BoolEncoder bw, Uint8List probas) {
    for (var i = 0; i < _length; i++) {
      final token = _tokens[i];
      final bit = (token >> 15) & 1;
      if (token & _fixedProba != 0) {
        bw.putBit(bit, token & 0xff);
      } else {
        bw.putBit(bit, probas[token & 0x3fff]);
      }
    }
  }

  /// What [emit] would produce, in 1/256ths of a bit.
  int estimateSize(Uint8List probas) {
    var size = 0;
    for (var i = 0; i < _length; i++) {
      final token = _tokens[i];
      final bit = (token >> 15) & 1;
      if (token & _fixedProba != 0) {
        size += bitCost(bit, token & 0xff);
      } else {
        size += bitCost(bit, probas[token & 0x3fff]);
      }
    }
    return size;
  }
}
