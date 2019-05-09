import 'dart:typed_data';

import '../image_exception.dart';
import '../internal/bit_operators.dart';

/// A buffer that can be read as a stream of bytes.
class InputBuffer {
  List<int> buffer;
  final int start;
  final int end;
  int offset;
  bool bigEndian;

  /// Create a InputStream for reading from a List<int>
  InputBuffer(List<int> buffer, {this.bigEndian: false, int offset: 0, int length})
      : this.buffer = buffer,
        this.start = offset,
        this.offset = offset,
        this.end = (length == null) ? buffer.length : offset + length;

  /// Create a copy of [other].
  InputBuffer.from(InputBuffer other, {int offset: 0, int length})
      : this.buffer = other.buffer,
        this.offset = other.offset + offset,
        this.start = other.start,
        this.end =
            (length == null) ? other.end : other.offset + offset + length,
        this.bigEndian = other.bigEndian;

  ///  The current read position relative to the start of the buffer.
  int get position => offset - start;

  /// How many bytes are left in the stream.
  int get length => end - offset;

  /// Is the current position at the end of the stream?
  bool get isEOS => offset >= end;

  /// Reset to the beginning of the stream.
  void rewind() {
    offset = start;
  }

  /// Access the buffer relative from the current position.
  int operator [](int index) => buffer[offset + index];

  /// Set a buffer element relative to the current position.
  operator []=(int index, int value) => buffer[offset + index] = value;

  /// Copy data from [other] to this buffer, at [start] offset from the
  /// current read position, and [length] number of bytes. [offset] is
  /// the offset in [other] to start reading.
  void memcpy(int start, int length, dynamic other, [int offset = 0]) {
    if (other is InputBuffer) {
      buffer.setRange(this.offset + start, this.offset + start + length,
          other.buffer, other.offset + offset);
    } else {
      buffer.setRange(this.offset + start, this.offset + start + length,
          other as List<int>, offset);
    }
  }

  /// Set a range of bytes in this buffer to [value], at [start] offset from the
  ///current read position, and [length] number of bytes.
  void memset(int start, int length, int value) {
    buffer.fillRange(offset + start, offset + start + length, value);
  }

  /// Return a InputStream to read a subset of this stream.  It does not
  /// move the read position of this stream.  [position] is specified relative
  /// to the start of the buffer.  If [position] is not specified, the current
  /// read position is used. If [length] is not specified, the remainder of this
  /// stream is used.
  InputBuffer subset(int count, {int position, int offset: 0}) {
    int pos = position != null ? start + position : this.offset;
    pos += offset;

    return new InputBuffer(buffer,
        bigEndian: bigEndian, offset: pos, length: count);
  }

  /// Returns the position of the given [value] within the buffer, starting
  /// from the current read position with the given [offset].  The position
  /// returned is relative to the start of the buffer, or -1 if the [value]
  /// was not found.
  int indexOf(int value, [int offset = 0]) {
    for (int i = this.offset + offset, end = this.offset + length;
        i < end;
        ++i) {
      if (buffer[i] == value) {
        return i - this.start;
      }
    }
    return -1;
  }

  /// Read [count] bytes from an [offset] of the current read position, without
  /// moving the read position.
  InputBuffer peekBytes(int count, [int offset = 0]) {
    return subset(count, offset: offset);
  }

  /// Move the read position by [count] bytes.
  void skip(int count) {
    offset += count;
  }

  /// Read a single byte.
  int readByte() {
    return buffer[offset++];
  }

  int readInt8() {
    return uint8ToInt8(readByte());
  }

  /// Read [count] bytes from the stream.
  InputBuffer readBytes(int count) {
    InputBuffer bytes = subset(count);
    offset += bytes.length;
    return bytes;
  }

  /// Read a null-terminated string, or if [len] is provided, that number of
  /// bytes returned as a string.
  String readString([int len]) {
    if (len == null) {
      List<int> codes = [];
      while (!isEOS) {
        int c = readByte();
        if (c == 0) {
          return new String.fromCharCodes(codes);
        }
        codes.add(c);
      }
      throw new ImageException('EOF reached without finding string terminator');
    }

    InputBuffer s = readBytes(len);
    Uint8List bytes = s.toUint8List();
    String str = String.fromCharCodes(bytes);
    return str;
  }

  /// Read a 16-bit word from the stream.
  int readUint16() {
    int b1 = buffer[offset++] & 0xff;
    int b2 = buffer[offset++] & 0xff;
    if (bigEndian) {
      return (b1 << 8) | b2;
    }
    return (b2 << 8) | b1;
  }

  /// Read a 16-bit word from the stream.
  int readInt16() {
    return uint16ToInt16(readUint16());
  }

  /// Read a 24-bit word from the stream.
  int readUint24() {
    int b1 = buffer[offset++] & 0xff;
    int b2 = buffer[offset++] & 0xff;
    int b3 = buffer[offset++] & 0xff;
    if (bigEndian) {
      return b3 | (b2 << 8) | (b1 << 16);
    }
    return b1 | (b2 << 8) | (b3 << 16);
  }

  /// Read a 32-bit word from the stream.
  int readUint32() {
    int b1 = buffer[offset++] & 0xff;
    int b2 = buffer[offset++] & 0xff;
    int b3 = buffer[offset++] & 0xff;
    int b4 = buffer[offset++] & 0xff;
    if (bigEndian) {
      return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }
    return (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
  }

  /// Read a signed 32-bit integer from the stream.
  int readInt32() {
    return uint32ToInt32(readUint32());
  }

  /// Read a 32-bit float.
  double readFloat32() {
    return uint32ToFloat32(readUint32());
  }

  /// Read a 64-bit float.
  double readFloat64() {
    return uint64ToFloat64(readUint64());
  }

  /// Read a 64-bit word form the stream.
  int readUint64() {
    int b1 = buffer[offset++] & 0xff;
    int b2 = buffer[offset++] & 0xff;
    int b3 = buffer[offset++] & 0xff;
    int b4 = buffer[offset++] & 0xff;
    int b5 = buffer[offset++] & 0xff;
    int b6 = buffer[offset++] & 0xff;
    int b7 = buffer[offset++] & 0xff;
    int b8 = buffer[offset++] & 0xff;
    if (bigEndian) {
      return (b1 << 56) |
          (b2 << 48) |
          (b3 << 40) |
          (b4 << 32) |
          (b5 << 24) |
          (b6 << 16) |
          (b7 << 8) |
          b8;
    }
    return (b8 << 56) |
        (b7 << 48) |
        (b6 << 40) |
        (b5 << 32) |
        (b4 << 24) |
        (b3 << 16) |
        (b2 << 8) |
        b1;
  }

  List<int> toList([int offset = 0, int length = 0]) {
    if (buffer is Uint8List) {
      return toUint8List(offset, length);
    }
    int s = start + this.offset + offset;
    int e = (length <= 0) ? end : s + length;
    return buffer.sublist(s, e);
  }

  Uint8List toUint8List([int offset = 0, int length]) {
    int len = length != null ? length : this.length - offset;
    if (buffer is Uint8List) {
      Uint8List b = buffer as Uint8List;
      return new Uint8List.view(
          b.buffer, b.offsetInBytes + this.offset + offset, len);
    }
    return new Uint8List.fromList(
        buffer.sublist(this.offset + offset, this.offset + offset + len));
  }

  Uint32List toUint32List([int offset = 0]) {
    if (buffer is Uint8List) {
      Uint8List b = buffer as Uint8List;
      return new Uint32List.view(
          b.buffer, b.offsetInBytes + this.offset + offset);
    }
    return new Uint32List.view(toUint8List().buffer);
  }
}
