part of image;

class VP8LBitReader {
  //Arc.InputStream _input;
  //Data.Uint32List _buffer = new Data.Uint32List(2);
  int _bitPos = 0;
  Arc.InputStream input;
  int buffer = 0; // pre-fetched bits
  int bitPos = 0; // current bit-reading position in val_

  VP8LBitReader(this.input) {
    //_input = new Arc.InputStream(input.buffer, byteOrder: input.byteOrder);
    //_input.position = input.position;

    // TODO javascript is not producint the correct value for here.
    // Can this be rewritten to a 32-bit buffer?
    buffer += input.readByte() << (8 * 0);
    buffer += input.readByte() << (8 * 1);
    buffer += input.readByte() << (8 * 2);
    buffer += input.readByte() << (8 * 3);
    buffer += input.readByte() << (8 * 4);
    buffer += input.readByte() << (8 * 5);
    buffer += input.readByte() << (8 * 6);
    buffer += input.readByte() << (8 * 7);
  }

  /**
   * Return the prefetched bits, so they can be looked up.
   */
  int prefetchBits() {
    return (buffer >> bitPos) & 0xffffffff;
  }

  /**
   * For jumping over a number of bits in the bit stream when accessed with
   * prefetchBits and fillBitWindow.
   */
  void setBitPos(int val) {
    bitPos = val;
  }

  bool get isEOS => (input.isEOS && bitPos >= LBITS);

  /**
   * Advances the read buffer by 4 bytes to make room for reading next 32 bits.
   */
  void fillBitWindow() {
    if (bitPos >= WBITS) {
      _shiftBytes();
    }
  }

  /**
   * Reads the specified number of bits from Read Buffer.
   */
  int readBits(int numBits) {
    // Flag an error if end_of_stream or n_bits is more than allowed limit.
    if (!isEOS && numBits < MAX_NUM_BIT_READ) {
      final int value = (buffer >> bitPos) & BIT_MASK[numBits];
      bitPos += numBits;
      _shiftBytes();
      return value;
    } else {
      throw new ImageException('Not enough data in input.');
    }
  }

  /**
   * If not at EOS, reload up to LBITS byte-by-byte
   */
  void _shiftBytes() {
    while (bitPos >= 8 && !input.isEOS) {
      buffer >>= 8;
      buffer |= input.readByte() << (LBITS - 8);
      bitPos -= 8;
    }
  }


  /// The number of bytes used for the bit buffer.
  static const int VALUE_SIZE = 8;
  static const int MAX_NUM_BIT_READ = 25;
  /// Number of bits prefetched.
  static const int LBITS = 64;
  /// Minimum number of bytes needed after fillBitWindow.
  static const int WBITS = 32;
  /// Number of bytes needed to store WBITS bits.
  static const int LOG8_WBITS = 4;
  static const List<int> BIT_MASK = const [
      0, 1, 3, 7, 15, 31, 63, 127, 255, 511, 1023, 2047, 4095, 8191, 16383,
      32767, 65535, 131071, 262143, 524287, 1048575, 2097151, 4194303, 8388607,
      16777215];

}
