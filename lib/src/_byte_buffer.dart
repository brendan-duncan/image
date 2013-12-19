part of dart_image;

class _ByteBuffer {
  List<int> buffer;
  int position = 0;

  _ByteBuffer() :
    buffer = new List<int>(),
    position = 0;

  _ByteBuffer.fromList(this.buffer) :
    position = 0;

  void resetTo(List<int> buffer) {
    this.buffer = buffer;
    position = 0;
  }

  int get length => buffer.length;

  bool get isEOF => position >= buffer.length;

  int readByte() {
    return buffer[position++];
  }

  List<int> readBytes(int count) {
    List<int> bytes = buffer.sublist(position, position + count);
    position += bytes.length;
    return bytes;
  }

  void skip(int count) {
    position += count;
  }

  int readUint16() {
    int value = (buffer[position] << 8) | buffer[position + 1];
    position += 2;
    return value;
  }

  int readUInt32() {
    int b1 = buffer[position++];
    int b2 = buffer[position++];
    int b3 = buffer[position++];
    int b4 = buffer[position++];
    return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
  }


  int peakAtOffset(int offset) {
    return buffer[position + offset];
  }

  void writeByte(int value) {
    buffer.add(value & 0xFF);
  }

  void writeBytes(List<int> bytes) {
    buffer.addAll(bytes);
  }

  void writeBits(List bs) {
    var value = bs[0];
    var posval = bs[1] - 1;
    while (posval >= 0) {
      if ((value & (1 << posval)) != 0) {
        _bytenew |= (1 << _bytepos);
      }
      posval--;
      _bytepos--;
      if (_bytepos < 0) {
        if (_bytenew == 0xFF) {
          writeByte(0xFF);
          writeByte(0);
        } else {
          writeByte(_bytenew);
        }
        _bytepos = 7;
        _bytenew = 0;
      }
    }
  }

  writeUint16(int value) {
    writeByte((value >> 8) & 0xFF);
    writeByte((value) & 0xFF);
  }

  void writeUint32(int value) {
    writeByte((value >> 24) & 0xFF);
    writeByte((value >> 16) & 0xFF);
    writeByte((value >> 8) & 0xFF);
    writeByte((value) & 0xFF);
  }

  void resetBits() {
    _bytenew = 0;
    _bytepos = 7;
  }

  int _bytenew = 0;
  int _bytepos = 7;
}
