part of image;

class VP8LBitReader {
  Arc.InputStream input;
  int buffer = 0; // pre-fetched bits
  int bitPos = 0; // current bit-reading position in val_

  VP8LBitReader(this.input) {
    for (int i = 0; i < VALUE_SIZE; ++i) {
      buffer |= input.readByte() << (8 * i);
    }
  }

  /**
   * Return the prefetched bits, so they can be looked up.
   */
  int prefetchBits() {
    return buffer >> bitPos;
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
      /*#if (defined(__x86_64__) || defined(_M_X64))
        buffer >>= WBITS;
        bitPos -= WBITS;
        // The expression below needs a little-endian arch to work correctly.
        // This gives a large speedup for decoding speed.
        buffer |= *(const vp8l_val_t*)(br->buf_ + br->pos_) << (LBITS - WBITS);
        br->pos_ += LOG8_WBITS;
        return;
      #endif*/
      _shiftBytes(); // Slow path.
    }
  }

  /**
   * Reads the specified number of bits from Read Buffer.
   */
  int readBits(int n_bits) {
    // Flag an error if end_of_stream or n_bits is more than allowed limit.
    if (!isEOS && n_bits < MAX_NUM_BIT_READ) {
      final int val = (buffer >> bitPos) & BIT_MASK[n_bits];
      bitPos += n_bits;
      _shiftBytes();
      return val;
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
