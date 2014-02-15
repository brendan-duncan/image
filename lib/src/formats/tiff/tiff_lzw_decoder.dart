part of image;

/**
 * TODO this is very slow!  Switch to link-list method GifDecoder is using,
 * or, better yet, abstract the LzwDecoder and add to archive.
 */
class LzwDecoder {
  void decode(Buffer p, List<int> out) {
    this.out = out;
    int outLen = out.length;
    outIndex = 0;
    data = p;

    if (data[0] == 0x00 && data[1] == 0x01) {
      throw new ImageException("Invalid LZW Data");
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
        if (code < tableIndex) {
          string = stringTable[code];
          _writeString(string);
          _addStringToTable(stringTable[oldCode], string[0]);
          oldCode = code;
        } else {
          string = stringTable[oldCode];
          string = _composeString(string, string[0]);
          _writeString(string);
          _addNewStringToTable(string);
          oldCode = code;
        }
      }

      code = _getNextCode();
    }
  }

  /**
   * Write out the string just uncompressed.
   */
  void _writeString(List<int> string) {
    for (int i = 0, len = string.length; i < len; i++) {
      out[outIndex++] = string[i];
    }
  }

  void _addStringToTable(List<int> string, int newString) {
    string = new List<int>.from(string);
    string.add(newString);

    // Add this new String to the table
    stringTable[tableIndex++] = string;

    if (tableIndex == 511) {
      bitsToGet = 10;
    } else if (tableIndex == 1023) {
      bitsToGet = 11;
    } else if (tableIndex == 2047) {
      bitsToGet = 12;
    }
  }

  void _addNewStringToTable(List<int> string) {
    // Add this new String to the table
    stringTable[tableIndex++] = string;

    if (tableIndex == 511) {
      bitsToGet = 10;
    } else if (tableIndex == 1023) {
      bitsToGet = 11;
    } else if (tableIndex == 2047) {
      bitsToGet = 12;
    }
  }

  /**
   * Append [newString] to the end of [oldString].
   */
  List<int> _composeString(List<int> string, int newString) {
    string = new List<int>.from(string);
    string.add(newString);
    return string;
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
    stringTable = new List<List<int>>(LZ_MAX_CODE + 1);
    for (int i = 0; i < 256; i++) {
      stringTable[i] = [i];
    }
    tableIndex = 258;
    bitsToGet = 9;
  }

  int tableIndex;
  int bitsToGet = 9;
  int bytePointer = 0;
  int bitPointer = 0;
  int nextData = 0;
  int nextBits = 0;
  Buffer data;

  List<List<int>> stringTable;
  List<int> out;
  int outIndex;

  static const int LZ_MAX_CODE = 4095;
  static const int NO_SUCH_CODE = 4098;
  static const List<int> AND_TABLE = const [511, 1023, 2047, 4095];
}
