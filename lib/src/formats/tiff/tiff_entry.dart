import '../../image_exception.dart';
import '../../util/input_buffer.dart';
import 'tiff_image.dart';

class TiffEntry {
  int tag;
  int type;
  int numValues;
  int valueOffset;

  TiffEntry(this.tag, this.type, this.numValues);

  String toString() {
    if (TiffImage.TAG_NAME.containsKey(tag)) {
      return '${TiffImage.TAG_NAME[tag]}: $type $numValues';
    }
    return '<$tag>: $type $numValues';
  }

  bool get isValid => type < 13 && type > 0;

  int get typeSize => isValid ? SIZE_OF_TYPE[type] : 0;

  bool get isString => type == TYPE_ASCII;

  int readValue(InputBuffer p) {
    p.offset = valueOffset;
    return _readValue(p);
  }

  List<int> readValues(InputBuffer p) {
    p.offset = valueOffset;
    var values = <int>[];
    for (int i = 0; i < numValues; ++i) {
      values.add(_readValue(p));
    }
    return values;
  }

  String readString(InputBuffer p) {
    if (type != TYPE_ASCII) {
      throw ImageException('readString requires ASCII entity');
    }
    // TODO: ASCII fields can contain multiple strings, separated with a NULL.
    return String.fromCharCodes(readValues(p));
  }

  int _readValue(InputBuffer p) {
    switch (type) {
      case TYPE_BYTE:
      case TYPE_ASCII:
        return p.readByte();
      case TYPE_SHORT:
        return p.readUint16();
      case TYPE_LONG:
        return p.readUint32();
      case TYPE_RATIONAL:
        int num = p.readUint32();
        int den = p.readUint32();
        if (den == 0) {
          return 0;
        }
        return num ~/ den;
      case TYPE_SBYTE:
        throw ImageException('Unhandled value type: SBYTE');
      case TYPE_UNDEFINED:
        return p.readByte();
      case TYPE_SSHORT:
        throw ImageException('Unhandled value type: SSHORT');
      case TYPE_SLONG:
        throw ImageException('Unhandled value type: SLONG');
      case TYPE_SRATIONAL:
        throw ImageException('Unhandled value type: SRATIONAL');
      case TYPE_FLOAT:
        throw ImageException('Unhandled value type: FLOAT');
      case TYPE_DOUBLE:
        throw ImageException('Unhandled value type: DOUBLE');
    }
    return 0;
  }

  static const int TYPE_BYTE = 1;
  static const int TYPE_ASCII = 2;
  static const int TYPE_SHORT = 3;
  static const int TYPE_LONG = 4;
  static const int TYPE_RATIONAL = 5;
  static const int TYPE_SBYTE = 6;
  static const int TYPE_UNDEFINED = 7;
  static const int TYPE_SSHORT = 8;
  static const int TYPE_SLONG = 9;
  static const int TYPE_SRATIONAL = 10;
  static const int TYPE_FLOAT = 11;
  static const int TYPE_DOUBLE = 12;

  static const List<int> SIZE_OF_TYPE = [
    0, //  0 = n/a
    1, //  1 = byte
    1, //  2 = ascii
    2, //  3 = short
    4, //  4 = long
    8, //  5 = rational
    1, //  6 = sbyte
    1, //  7 = undefined
    2, //  8 = sshort
    4, //  9 = slong
    8, // 10 = srational
    4, // 11 = float
    8, // 12 = double
    0
  ];
}
