part of image;

class _ByteBuffer {
  final List<int> buffer;
  int position = 0;

  _ByteBuffer() :
    buffer = new List<int>(),
    position = 0;

  _ByteBuffer.fromList(this.buffer) :
    position = 0;

  int get length => buffer.length;

  int readByte() {
    return buffer[position++];
  }

  int readUint16() {
    int value = (buffer[position] << 8) | buffer[position + 1];
    position += 2;
    return value;
  }

  List<int> readBlock() {
    int length = readUint16();
    List<int> array = buffer.sublist(position, position + length - 2);
    position += array.length;
    return array;
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

  void writeBits(bs) {
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

  writeWord(int value) {
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
