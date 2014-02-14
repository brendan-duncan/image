part of image;


class TiffLZWDecoder {
  int tableIndex;
  int bitsToGet = 9;
  int bytePointer;
  int bitPointer;
  int dstIndex;
  int width;
  int height;
  int predictor;
  int samplesPerPixel;
  int nextData = 0;
  int nextBits = 0;
  Buffer data;
  List<Uint8List> stringTable;
  List<int> out;
  int outIndex;

  static const List<int> AND_TABLE = const [511, 1023, 2047, 4095];

  TiffLZWDecoder(this.width, this.predictor, this.samplesPerPixel);

  bool decode(Buffer p, List<int> out, int height) {
    this.out = out;
    outIndex = 0;
    data = p;
    if (data[0] == 0x00 && data[1] == 0x01) {
      throw new ImageException("TIFFLZWDecoder0");
    }

    _initializeStringTable();

    bytePointer = 0;
    bitPointer = 0;
    dstIndex = 0;

    nextData = 0;
    nextBits = 0;

    int code;
    int oldCode = 0;
    Uint8List string;

    while (((code = _getNextCode()) != 257) && dstIndex != out.length) {
      if (code == 256) {
        _initializeStringTable();
        code = _getNextCode();
        if (code == 257) {
          break;
        }

        _writeString(stringTable[code]);
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
    }

    // Horizontal Differencing Predictor
    if (predictor == 2) {
      int count;
      for (int j = 0; j < height; j++) {
        count = samplesPerPixel * (j * width + 1);
        for (int i = samplesPerPixel; i < width * samplesPerPixel; i++) {
          out[count] += out[count - samplesPerPixel];
          count++;
        }
      }
    }

    return true;
  }

  /**
   * Write out the string just uncompressed.
   */
  void _writeString(Uint8List string) {
    for (int i = 0; i < string.length; i++) {
      out[outIndex++] = string[i];
    }
  }

  void _addStringToTable(Uint8List oldString, int newString) {
    int length = oldString.length;
    Uint8List string = new Uint8List(length + 1);
    string.setRange(0, length, oldString);
    string[length] = newString;

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

  void _addNewStringToTable(Uint8List string) {
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
  Uint8List _composeString(Uint8List oldString, int newString) {
    int length = oldString.length;
    Uint8List string = new Uint8List(length + 1);
    string.setRange(0, length, oldString);
    string[length] = newString;
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
    stringTable = new List<Uint8List>(4096);
    for (int i = 0; i < 256; i++) {
      Uint8List l = new Uint8List(1);
      l[0] = i;
      stringTable[i] = l;
    }
    tableIndex = 258;
    bitsToGet = 9;
  }
}
