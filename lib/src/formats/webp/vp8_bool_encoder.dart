/// The boolean (binary arithmetic) coder that VP8 writes everything through.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';

/// `renormSizes[range] = 8 - log2(range)`.
final _norm = Uint8List.fromList(const [
  7, 6, 6, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4, //
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  0
]);

/// `newRange[range] = ((range + 1) << renormSize) - 1`.
final _newRange = Uint8List.fromList(const [
  127, 127, 191, 127, 159, 191, 223, 127, 143, 159, 175, 191, 207, 223, 239, //
  127, 135, 143, 151, 159, 167, 175, 183, 191, 199, 207, 215, 223, 231, 239,
  247, 127, 131, 135, 139, 143, 147, 151, 155, 159, 163, 167, 171, 175, 179,
  183, 187, 191, 195, 199, 203, 207, 211, 215, 219, 223, 227, 231, 235, 239,
  243, 247, 251, 127, 129, 131, 133, 135, 137, 139, 141, 143, 145, 147, 149,
  151, 153, 155, 157, 159, 161, 163, 165, 167, 169, 171, 173, 175, 177, 179,
  181, 183, 185, 187, 189, 191, 193, 195, 197, 199, 201, 203, 205, 207, 209,
  211, 213, 215, 217, 219, 221, 223, 225, 227, 229, 231, 233, 235, 237, 239,
  241, 243, 245, 247, 249, 251, 253, 127
]);

/// Writes bits under a probability model, as described in RFC 6386 section 7.
///
/// Every symbol costs a probability that it is zero, in 1/256ths; a symbol that
/// matches its probability costs a fraction of a bit. The coder keeps an
/// interval (`_range`, `_value`) and narrows it per symbol, emitting bytes as
/// they become fixed.
///
/// Bytes of 0xff cannot be emitted immediately, because a later carry has to be
/// able to propagate through them, so they are counted in `_run` and written
/// once the carry is known.
@internal
class VP8BoolEncoder {
  VP8BoolEncoder([int expectedSize = 1024])
      : _buf = Uint8List(expectedSize < 1024 ? 1024 : expectedSize);

  // The tables are held per instance: a field load beats the initialisation
  // guard a top-level `final` carries on every access, and `putBit` is the
  // single hottest call in the encoder.
  final Uint8List _normTable = _norm;
  final Uint8List _newRangeTable = _newRange;

  Uint8List _buf;
  int _pos = 0;

  int _range = 255 - 1;
  int _value = 0;

  /// Number of pending 0xff bytes whose carry is not yet decided.
  int _run = 0;

  /// Number of bits held in [_value] beyond the eight being assembled.
  int _nbBits = -8;

  /// Bytes written so far.
  int get length => _pos;

  /// The approximate write position, in bits.
  int get bitPosition => (_pos + _run) * 8 + 8 + _nbBits;

  @pragma('vm:prefer-inline')
  @pragma('vm:unsafe:no-bounds-checks')
  @pragma('vm:unsafe:no-interrupts')
  int putBit(int bit, int prob) {
    final split = (_range * prob) >> 8;
    if (bit != 0) {
      _value += split + 1;
      _range -= split + 1;
    } else {
      _range = split;
    }
    if (_range < 127) {
      final shift = _normTable[_range];
      _range = _newRangeTable[_range];
      _value <<= shift;
      _nbBits += shift;
      if (_nbBits > 0) {
        _flush();
      }
    }
    return bit;
  }

  @pragma('vm:prefer-inline')
  @pragma('vm:unsafe:no-bounds-checks')
  @pragma('vm:unsafe:no-interrupts')
  int putBitUniform(int bit) {
    final split = _range >> 1;
    if (bit != 0) {
      _value += split + 1;
      _range -= split + 1;
    } else {
      _range = split;
    }
    if (_range < 127) {
      _range = _newRangeTable[_range];
      _value <<= 1;
      _nbBits += 1;
      if (_nbBits > 0) {
        _flush();
      }
    }
    return bit;
  }

  void putBits(int value, int nbBits) {
    for (var mask = 1 << (nbBits - 1); mask != 0; mask >>= 1) {
      putBitUniform(value & mask);
    }
  }

  void putSignedBits(int value, int nbBits) {
    if (putBitUniform(value != 0 ? 1 : 0) == 0) {
      return;
    }
    if (value < 0) {
      putBits(((-value) << 1) | 1, nbBits + 1);
    } else {
      putBits(value << 1, nbBits + 1);
    }
  }

  void _flush() {
    final s = 8 + _nbBits;
    final bits = _value >> s;
    _value -= bits << s;
    _nbBits -= 8;
    if ((bits & 0xff) != 0xff) {
      var pos = _pos;
      _reserve(_run + 1);
      if (bits & 0x100 != 0) {
        // Overflow: propagate the carry back over the pending 0xff bytes.
        if (pos > 0) {
          _buf[pos - 1]++;
        }
      }
      if (_run > 0) {
        final value = (bits & 0x100) != 0 ? 0x00 : 0xff;
        for (; _run > 0; --_run) {
          _buf[pos++] = value;
        }
      }
      _buf[pos++] = bits & 0xff;
      _pos = pos;
    } else {
      _run++;
    }
  }

  void _reserve(int extra) {
    final needed = _pos + extra;
    if (needed <= _buf.length) {
      return;
    }
    var size = _buf.length * 2;
    if (size < needed) {
      size = needed;
    }
    _buf = Uint8List(size)..setRange(0, _pos, _buf);
  }

  /// Appends raw bytes. Only valid once [finish] has flushed the coder.
  void append(Uint8List data) {
    _reserve(data.length);
    _buf.setRange(_pos, _pos + data.length, data);
    _pos += data.length;
  }

  /// Flushes the pending bits and returns everything written.
  ///
  /// The returned list is a view on the internal buffer; the coder must not be
  /// used again except through [append].
  Uint8List finish() {
    putBits(0, 9 - _nbBits);
    _nbBits = 0; // pad with zeroes
    _flush();
    return Uint8List.sublistView(_buf, 0, _pos);
  }
}
