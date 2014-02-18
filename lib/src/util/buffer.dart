part of image;

/**
 * A helper class to work with List and TypedData in a way similar to pointers
 * in C.
 */
class Buffer {
  final List<int> data;
  final int start;
  final int end;
  int offset;
  int byteOrder;

  Buffer(List<int> buffer, {this.offset: 0, int length: -1,
         this.byteOrder: LITTLE_ENDIAN}) :
    data = buffer,
    start = 0,
    end = (length < 0 || length > buffer.length) ? buffer.length :
          length {
    offset += start;
  }

  Buffer.from(Buffer other, {this.offset: 0, int length: -1}) :
    data = other.data,
    start = other.offset,
    end = (length < 0) ? other.data.length :
          (other.offset + length > other.data.length) ? other.data.length :
          other.offset + length,
    byteOrder = other.byteOrder {
    offset += start;
  }

  /**
   * Are we at the end of the buffer?
   */
  bool get isEOS => offset >= end;

  /**
   * How many bytes remaining in the buffer?
   */
  int get length => end - offset;

  /**
   * Get a byte in the buffer relative to the current read position.
   */
  int operator[](int index) => data[offset + index];

  /**
   * Set a byte in the buffer relative to the current read position.
   */
  operator[]=(int index, int value) => data[offset + index] = value;

  /**
   * Copy data from [other] to this buffer, at [start] offset from the
   * current read position, and [length] number of bytes.  [offset] is
   * the offset in [other] to start reading.
   */
  void memcpy(int start, int length, other, [int offset = 0]) {
    if (other is Buffer) {
      data.setRange(this.offset + start, this.offset + start + length,
                    other.data, other.offset + offset);
    } else {
      data.setRange(this.offset + start, this.offset + start + length,
                    other, offset);
    }
  }

  /**
   * Set a range of bytes in this buffer to [value], at [start] offset from the
   * current read poisiton, and [length] number of bytes.
   */
  void memset(int start, int length, int value) {
    data.fillRange(offset + start, offset + start + length, value);
  }

  /**
   * Read a single byte.
   */
  int readByte() {
    return data[offset++];
  }

  /**
   * Read [count] bytes from the buffer.
   */
  Buffer readBytes(int count) {
    Buffer out = new Buffer.from(this, offset: offset, length: count);
    offset += out.length;
    return out;
  }

  /**
   * Read a null-terminated string, or if [len] is provided, that number of
   * bytes returned as a string.
   */
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
      throw new ArchiveException('EOF reached without finding string terminator');
    }

    return new String.fromCharCodes(toList(0, len));
  }

  /**
   * Read a 16-bit word from the stream.
   */
  int readUint16() {
    int b1 = data[offset++] & 0xff;
    int b2 = data[offset++] & 0xff;
    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 8) | b2;
    }
    return (b2 << 8) | b1;
  }

  /**
   * Read a 24-bit word from the stream.
   */
  int readUint24() {
    int b1 = data[offset++] & 0xff;
    int b2 = data[offset++] & 0xff;
    int b3 = data[offset++] & 0xff;
    if (byteOrder == BIG_ENDIAN) {
      return b3 | (b2 << 8) | (b1 << 16);
    }
    return b1 | (b2 << 8) | (b3 << 16);
  }

  /**
   * Read a 32-bit word from the stream.
   */
  int readUint32() {
    int b1 = data[offset++] & 0xff;
    int b2 = data[offset++] & 0xff;
    int b3 = data[offset++] & 0xff;
    int b4 = data[offset++] & 0xff;
    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }
    return (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
  }

  /**
   * This assumes buffer is a Typed
   */
  Uint8List toUint8List([int offset = 0, int length = 0]) {
    if (data is Uint8List) {
      Uint8List d = data;
      return new Uint8List.view(d.buffer,
              d.offsetInBytes + this.offset + offset,
              length <= 0 ? this.length - offset : length);
    }

    return new Uint8List.fromList(toList(offset, length));
  }

  List<int> toList([int offset = 0, int length = 0]) {
    int s = start + this.offset + offset;
    int e = (length <= 0) ? end : s + length;
    return data.sublist(s, e);
  }
}
