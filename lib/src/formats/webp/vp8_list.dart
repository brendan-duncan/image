part of image;

class VP8List {
  var buffer;
  int offset;

  VP8List(other, [this.offset = 0]) {
    if (other is VP8List) {
      this.buffer = other.buffer;
      this.offset += other.offset;
    } else {
      this.buffer = other;
    }
  }

  operator+(int add) => offset += add;

  int operator[](int index) => buffer[offset + index];

  operator[]=(int index, int value) => buffer[offset + index] = value;

  int get length => buffer.length - offset;

  void setRange(int start, int length, other, [int offset = 0]) {
    if (other is VP8List) {
      buffer.setRange(this.offset + start, this.offset + start + length,
          other.buffer, other.offset + offset);
    } else {
      buffer.setRange(offset + start, offset + start + length,
                      other, offset);
    }
  }

  void fillRange(int start, int length, int value) {
    buffer.fillRange(offset + start, offset + start + length, value);
  }

  Data.Uint8List toUint8List([int offset = 0]) {
    return new Data.Uint8List.view(buffer.buffer, this.offset + offset);
  }
}
