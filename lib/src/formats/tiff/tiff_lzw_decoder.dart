part of image;

class LzwDecoder {
  void decode(Buffer p, List<int> out) {
    this.out = out;
    int outLen = out.length;
    outIndex = 0;
    data = p;

    if (data[0] == 0x00 && data[1] == 0x01) {
      throw new ImageException('Invalid LZW Data');
    }

    _initializeStringTable();

    bytePointer = 0;
    bitPointer = 0;
    nextData = 0;
    nextBits = 0;

    int code;
    int oldCode = 0;
    List<int> string;

    code = _getNextCode();
    while ((code != 257) && outIndex != outLen) {
      if (code == 256) {
        _initializeStringTable();
        code = _getNextCode();
        if (code == 257) {
          break;
        }

        out[outIndex++] = code;
        oldCode = code;
      } else {
        if (code < _tableIndex) {
          _getString(code);
          for (int i = _bufferLength - 1; i >= 0; --i) {
            out[outIndex++] = _buffer[i];
          }
          _addString(oldCode, _buffer[_bufferLength - 1]);
          oldCode = code;
        } else {
          _getString(oldCode);
          for (int i = _bufferLength - 1; i >= 0; --i) {
            out[outIndex++] = _buffer[i];
          }
          out[outIndex++] = _buffer[_bufferLength - 1];
          _addString(oldCode, _buffer[_bufferLength - 1]);

          oldCode = code;
        }
      }

      code = _getNextCode();
    }
  }

  void _addString(int string, int newString) {
    _table[_tableIndex] = newString;
    _prefix[_tableIndex] = string;
    _tableIndex++;

    if (_tableIndex == 511) {
      bitsToGet = 10;
    } else if (_tableIndex == 1023) {
      bitsToGet = 11;
    } else if (_tableIndex == 2047) {
      bitsToGet = 12;
    }
  }

  void _getString(int code) {
    _bufferLength = 0;
    int c = code;
    _buffer[_bufferLength++] = _table[c];
    c = _prefix[c];
    while (c != NO_SUCH_CODE) {
      _buffer[_bufferLength++] = _table[c];
      c = _prefix[c];
    }
  }

  /**
   * Returns the next 9, 10, 11 or 12 bits
   */
  int _getNextCode() {
    // Attempt to get the next code. The exception is caught to make
    // this robust to cases wherein the EndOfInformation code has been
    // omitted from a strip. Examples of such cases have been observed
    // in practice.
    if (data.isEOS) {
      return 257;
    }
    nextData = (nextData << 8) | (data[bytePointer++] & 0xff);
    nextBits += 8;

    if (nextBits < bitsToGet) {
      if (data.isEOS) {
        return 257;
      }
      nextData = (nextData << 8) | (data[bytePointer++] & 0xff);
      nextBits += 8;
    }

    int code = (nextData >> (nextBits - bitsToGet)) & AND_TABLE[bitsToGet - 9];
    nextBits -= bitsToGet;

    return code;
  }

  /**
   * Initialize the string table.
   */
  void _initializeStringTable() {
    _table = new Uint8List(LZ_MAX_CODE + 1);
    _prefix = new Uint32List(LZ_MAX_CODE + 1);
    _prefix.fillRange(0, _prefix.length, NO_SUCH_CODE);

    for (int i = 0; i < 256; i++) {
      _table[i] = i;
    }

    bitsToGet = 9;

    _tableIndex = 258;
  }

  int bitsToGet = 9;
  int bytePointer = 0;
  int bitPointer = 0;
  int nextData = 0;
  int nextBits = 0;
  Buffer data;

  List<int> out;
  int outIndex;

  Uint8List _buffer = new Uint8List(256);
  Uint8List _table;
  Uint32List _prefix;
  int _tableIndex;
  int _bufferLength;

  static const int LZ_MAX_CODE = 4095;
  static const int NO_SUCH_CODE = 4098;
  static const List<int> AND_TABLE = const [511, 1023, 2047, 4095];
}
