import 'dart:math';
import 'dart:typed_data';

import 'input_buffer.dart';

class OutputBuffer {
  int length;
  bool bigEndian;

  /// Create a byte buffer for writing.
  OutputBuffer({int? size = _blockSize, this.bigEndian = false})
      : _buffer = Uint8List(size ?? _blockSize),
        length = 0;

  void rewind() {
    length = 0;
  }

  /// Get the resulting bytes from the buffer.
  Uint8List getBytes() => Uint8List.view(_buffer.buffer, 0, length);

  /// Clear the buffer.
  void clear() {
    _buffer = Uint8List(_blockSize);
    length = 0;
  }

  /// Write a byte to the end of the buffer.
  void writeByte(int value) {
    if (length == _buffer.length) {
      _expandBuffer(length + 1);
    }
    _buffer[length++] = value & 0xff;
  }

  /// Write a set of bytes to the end of the buffer.
  void writeBytes(List<int> bytes, [int? len]) {
    len ??= bytes.length;
    if (length + len > _buffer.length) {
      _expandBuffer(length + len);
    }
    _buffer.setRange(length, length + len, bytes);
    length += len;
  }

  void writeBuffer(InputBuffer bytes) {
    final bytesLength = bytes.length;
    final requiredLength = length + bytesLength;
    if (requiredLength > _buffer.length) {
      _expandBuffer(requiredLength);
    }
    _buffer.setRange(length, requiredLength, bytes.buffer, bytes.offset);
    length += bytesLength;
  }

  /// Write a 16-bit word to the end of the buffer.
  void writeUint16(int value) {
    if (bigEndian) {
      writeByte((value >> 8) & 0xff);
      writeByte(value & 0xff);
      return;
    }
    writeByte(value & 0xff);
    writeByte((value >> 8) & 0xff);
  }

  /// Write a 32-bit word to the end of the buffer.
  void writeUint32(int value) {
    if (bigEndian) {
      writeByte((value >> 24) & 0xff);
      writeByte((value >> 16) & 0xff);
      writeByte((value >> 8) & 0xff);
      writeByte(value & 0xff);
      return;
    }
    writeByte(value & 0xff);
    writeByte((value >> 8) & 0xff);
    writeByte((value >> 16) & 0xff);
    writeByte((value >> 24) & 0xff);
  }

  void writeFloat32(double value) {
    final fb = Float32List(1);
    fb[0] = value;
    final b = Uint8List.view(fb.buffer);
    if (bigEndian) {
      writeByte(b[3]);
      writeByte(b[2]);
      writeByte(b[1]);
      writeByte(b[0]);
      return;
    }
    writeByte(b[0]);
    writeByte(b[1]);
    writeByte(b[2]);
    writeByte(b[3]);
  }

  void writeFloat64(double value) {
    final fb = Float64List(1);
    fb[0] = value;
    final b = Uint8List.view(fb.buffer);
    if (bigEndian) {
      writeByte(b[7]);
      writeByte(b[6]);
      writeByte(b[5]);
      writeByte(b[4]);
      writeByte(b[3]);
      writeByte(b[2]);
      writeByte(b[1]);
      writeByte(b[0]);
      return;
    }
    writeByte(b[0]);
    writeByte(b[1]);
    writeByte(b[2]);
    writeByte(b[3]);
    writeByte(b[4]);
    writeByte(b[5]);
    writeByte(b[6]);
    writeByte(b[7]);
  }

  /// Return the subset of the buffer in the range \[start, end\].
  /// If [start] or [end] are < 0 then it is relative to the end of the buffer.
  /// If [end] is not specified (or null), then it is the end of the buffer.
  /// This is equivalent to the python list range operator.
  List<int> subset(int start, [int? end]) {
    if (start < 0) {
      start = length + start;
    }

    if (end == null) {
      end = length;
    } else if (end < 0) {
      end = length + end;
    }

    return Uint8List.view(_buffer.buffer, start, end - start);
  }

  /// Grow the buffer to hold at least [requiredLength] bytes. The capacity
  /// grows geometrically so a sequence of writes costs amortized linear time;
  /// 3x copies fewer bytes than 2x, and unused capacity is mostly untouched
  /// pages. A single large write gets a block of headroom instead, so a few
  /// trailing bytes (such as a chunk CRC) don't grow a large buffer again.
  void _expandBuffer(int requiredLength) {
    final newLength = max(_buffer.length * 3, requiredLength + _blockSize);
    _buffer = Uint8List(newLength)..setRange(0, length, _buffer);
  }

  static const _blockSize = 0x2000; // 8k block-size
  Uint8List _buffer;
}
