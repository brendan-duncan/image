import 'dart:typed_data';

import '../../util/_internal.dart';

@internal

/// Bit writer that packs bits LSB-first into bytes.
///
/// The bytes go into a typed array: a growable `List<int>` holds a tagged word
/// per element, eight bytes for every output byte.
class VP8LBitWriter {
  Uint8List _bytes = Uint8List(4096);
  int _length = 0;
  int _currentByte = 0;
  int _usedBits = 0;

  void _grow() {
    _bytes = Uint8List(_bytes.length * 2)..setRange(0, _length, _bytes);
  }

  @pragma('vm:unsafe:no-bounds-checks')
  void writeBits(int value, int numBits) {
    while (numBits > 0) {
      final available = 8 - _usedBits;
      final bitsToWrite = numBits < available ? numBits : available;
      final mask = (1 << bitsToWrite) - 1;
      _currentByte |= (value & mask) << _usedBits;
      value >>= bitsToWrite;
      numBits -= bitsToWrite;
      _usedBits += bitsToWrite;
      if (_usedBits == 8) {
        if (_length == _bytes.length) {
          _grow();
        }
        _bytes[_length++] = _currentByte;
        _currentByte = 0;
        _usedBits = 0;
      }
    }
  }

  void flush() {
    if (_usedBits > 0) {
      if (_length == _bytes.length) {
        _grow();
      }
      _bytes[_length++] = _currentByte;
      _currentByte = 0;
      _usedBits = 0;
    }
  }

  /// The bytes written so far, without the doubling slack behind them.
  Uint8List getBytes() => _length == _bytes.length
      ? _bytes
      : Uint8List.fromList(Uint8List.sublistView(_bytes, 0, _length));
}
