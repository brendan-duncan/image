import 'dart:typed_data';

import '../util/bit_utils.dart';
import '../util/input_buffer.dart';
import '../util/output_buffer.dart';
import '../util/rational.dart';

enum IfdValueType {
  none,
  byte,
  ascii,
  short,
  long,
  rational,
  sByte,
  undefined,
  sShort,
  sLong,
  sRational,
  single,
  double
}

const ifdValueTypeSize = [
  0,
  1,
  1,
  2,
  4,
  8,
  1,
  1,
  2,
  4,
  8,
  4,
  8
];

abstract class IfdValue {
  IfdValue clone();

  IfdValueType get type;
  int get length;

  int get dataSize => ifdValueTypeSize[type.index] * length;

  String get typeString => type.name;

  bool toBool([int index = 0]) => false;
  int toInt([int index = 0]) => 0;
  double toDouble([int index = 0]) => 0.0;
  Uint8List toData() => Uint8List(0);
  @override
  String toString() => "";
  Rational toRational([int index = 0]) => Rational(0, 1);

  @override
  bool operator ==(Object other) =>
      other is IfdValue &&
      type == other.type &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => 0;

  void write(OutputBuffer out);

  void setBool(bool v, [int index = 0]) {}
  void setInt(int v, [int index = 0]) {}
  void setDouble(double v, [int index = 0]) {}
  void setRational(int numerator, int denomitator, [int index = 0]) {}
  void setString(String v) {}
}

class IfdByteValue extends IfdValue {
  Uint8List value;

  IfdByteValue(int value)
      : value = Uint8List(1) {
    this.value[0] = value;
  }

  IfdByteValue.list(Uint8List value)
    : value = Uint8List.fromList(value);

  IfdByteValue.data(InputBuffer data, int count)
      : value = Uint8List.fromList(data.readBytes(count).toUint8List());

  @override
  IfdValue clone() => IfdByteValue.list(value);

  @override
  IfdValueType get type => IfdValueType.byte;
  
  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdByteValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];

  @override
  void setInt(int v, [int index = 0]) { value[index] = v; }

  @override
  Uint8List toData() => value;

  @override
  void write(OutputBuffer out) {
    out.writeBytes(value);
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdAsciiValue extends IfdValue {
  String value;

  IfdAsciiValue(this.value);

  IfdAsciiValue.list(List<int> value)
      : value = String.fromCharCodes(value);

  IfdAsciiValue.data(InputBuffer data, int count)
      : value = count == 0 ? data.readString() : data.readString(count - 1);

  IfdAsciiValue.string(this.value);

  @override
  IfdValue clone() => IfdAsciiValue.string(value);

  @override
  IfdValueType get type => IfdValueType.ascii;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdAsciiValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => value.hashCode;

  @override
  Uint8List toData() => Uint8List.fromList(value.codeUnits);

  @override
  void write(OutputBuffer out) {
    out.writeBytes(value.codeUnits);
  }

  @override
  String toString() => value;
  @override
  void setString(String v) { value = v; }
}

class IfdShortValue extends IfdValue {
  Uint16List value;

  IfdShortValue(int value)
      : value = Uint16List(1) {
    this.value[0] = value;
  }

  IfdShortValue.list(List<int> value)
      : value = Uint16List.fromList(value);

  IfdShortValue.data(InputBuffer data, int count)
      : value = Uint16List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readUint16();
    }
  }

  @override
  IfdValue clone() => IfdShortValue.list(value);

  @override
  IfdValueType get type => IfdValueType.short;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdShortValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];
  @override
  void setInt(int v, [int index = 0]) { value[index] = v; }

  @override
  void write(OutputBuffer out) {
    final l = value.length;
    for (var i = 0; i < l; ++i) {
      out.writeUint16(value[i]);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdLongValue extends IfdValue {
  Uint32List value;

  IfdLongValue(int value)
      : value = Uint32List(1) {
    this.value[0] = value;
  }

  IfdLongValue.list(List<int> value)
      : value = Uint32List.fromList(value);

  IfdLongValue.data(InputBuffer data, int count)
      : value = Uint32List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readUint32();
    }
  }

  @override
  IfdValue clone() => IfdLongValue.list(value);

  @override
  IfdValueType get type => IfdValueType.long;

  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
    other is IfdLongValue &&
        length == other.length &&
        hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];
  @override
  void setInt(int v, [int index = 0]) { value[index] = v; }

  @override
  Uint8List toData() => Uint8List.view(value.buffer);

  @override
  void write(OutputBuffer out) {
    final l = value.length;
    for (int i = 0; i < l; ++i) {
      out.writeUint32(value[i]);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdRationalValue extends IfdValue {
  List<Rational> value;

  IfdRationalValue(int numerator, int denominator)
      : value = [Rational(numerator, denominator)];

  IfdRationalValue.from(Rational r)
      : value = [Rational(r.numerator, r.denominator)];

  IfdRationalValue.list(List<Rational> value)
      : value = List<Rational>.from(value);

  IfdRationalValue.data(InputBuffer data, int count)
    : value = List<Rational>.generate(count, (i) =>
        Rational(data.readUint32(), data.readUint32()));

  @override
  IfdValue clone() => IfdRationalValue.list(value);

  @override
  IfdValueType get type => IfdValueType.rational;

  @override
  int get length => value.length;

  @override
  int toInt([int index = 0]) => value[index].toInt();
  @override
  double toDouble([int index = 0]) => value[index].toDouble();
  @override
  Rational toRational([int index = 0]) => value[index];

  @override
  bool operator ==(Object other) =>
      other is IfdRationalValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  void setRational(int numerator, int denomitator, [int index = 0]) {
    value[index].numerator = numerator;
    value[index].denominator = denomitator;
  }

  @override
  void write(OutputBuffer out) {
    for (var v in value) {
      out..writeUint32(v.numerator)
        ..writeUint32(v.denominator);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdSByteValue extends IfdValue {
  Int8List value;

  IfdSByteValue(int value)
      : value = Int8List(1) {
    this.value[0] = value;
  }

  IfdSByteValue.list(List<int> value)
      : value = Int8List.fromList(value);

  IfdSByteValue.data(InputBuffer data, int count)
      : value = Int8List.fromList(
          Int8List.view(data.toUint8List().buffer, 0, count));

  @override
  IfdValue clone() => IfdSByteValue.list(value);
  @override
  IfdValueType get type => IfdValueType.sByte;
  @override
  int get length => value.length;

  @override
  bool operator ==(Object other) =>
      other is IfdSByteValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];
  @override
  void setInt(int v, [int index = 0]) { value[index] = v; }

  @override
  Uint8List toData() => Uint8List.view(value.buffer);

  @override
  void write(OutputBuffer out) {
    out.writeBytes(Uint8List.view(value.buffer));
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdSShortValue extends IfdValue {
  Int16List value;

  IfdSShortValue(int value)
      : value = Int16List(1) {
    this.value[0] = value;
  }

  IfdSShortValue.list(List<int> value)
      : value = Int16List.fromList(value);

  IfdSShortValue.data(InputBuffer data, int count)
      : value = Int16List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readInt16();
    }
  }

  @override
  IfdValue clone() => IfdSShortValue.list(value);
  @override
  IfdValueType get type => IfdValueType.sShort;
  @override
  int get length => value.length;

  @override
  bool operator==(Object other) =>
      other is IfdSShortValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];

  @override
  void setInt(int v, [int index = 0]) { value[index] = v; }

  @override
  Uint8List toData() => Uint8List.view(value.buffer);

  @override
  void write(OutputBuffer out) {
    final v = Int16List(1);
    final vb = Uint16List.view(v.buffer);
    final l = value.length;
    for (var i = 0; i < l; ++i) {
      v[0] = value[i];
      out.writeUint16(vb[0]);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdSLongValue extends IfdValue {
  Int32List value;

  IfdSLongValue(int value)
      : value = Int32List(1) {
    this.value[0] = value;
  }

  IfdSLongValue.list(List<int> value)
      : value = Int32List.fromList(value);

  IfdSLongValue.data(InputBuffer data, int count)
      : value = Int32List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readInt32();
    }
  }

  @override
  IfdValue clone() => IfdSLongValue.list(value);

  @override
  IfdValueType get type => IfdValueType.sLong;

  @override
  int get length => value.length;

  @override
  bool operator==(Object other) =>
      other is IfdSLongValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index];

  @override
  void setInt(int v, [int index = 0]) { value[index] = v; }

  @override
  Uint8List toData() => Uint8List.view(value.buffer);

  @override
  void write(OutputBuffer out) {
    final l = value.length;
    for (var i = 0; i < l; ++i) {
      out.writeUint32(int32ToUint32(value[i]));
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdSRationalValue extends IfdValue {
  List<Rational> value;

  IfdSRationalValue(int numerator, int denominator)
      : value = [Rational(numerator, denominator)];

  IfdSRationalValue.from(Rational value)
      : value = [value];

  IfdSRationalValue.data(InputBuffer data, int count)
      : value = List<Rational>.generate(count, (i) =>
        Rational(data.readInt32(), data.readInt32()));

  IfdSRationalValue.list(List<Rational> value)
      : value = List<Rational>.from(value);

  @override
  IfdValue clone() => IfdSRationalValue.list(value);

  @override
  IfdValueType get type => IfdValueType.sRational;

  @override
  int get length => value.length;

  @override
  bool operator==(Object other) =>
      other is IfdSRationalValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  int toInt([int index = 0]) => value[index].toInt();

  @override
  double toDouble([int index = 0]) => value[index].toDouble();

  @override
  void setRational(int numerator, int denomitator, [int index = 0]) {
    value[index].numerator = numerator;
    value[index].denominator = denomitator;
  }

  @override
  void write(OutputBuffer out) {
    for (var v in value) {
      out..writeUint32(int32ToUint32(v.numerator))
      ..writeUint32(int32ToUint32(v.denominator));
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdSingleValue extends IfdValue {
  Float32List value;

  IfdSingleValue(double value)
      : value = Float32List(1) {
    this.value[0] = value;
  }

  IfdSingleValue.list(List<double> value)
      : value = Float32List.fromList(value);

  IfdSingleValue.data(InputBuffer data, int count)
      : value = Float32List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readFloat32();
    }
  }

  @override
  IfdValue clone() => IfdSingleValue.list(value);

  @override
  IfdValueType get type => IfdValueType.single;

  @override
  int get length => value.length;

  @override
  bool operator==(Object other) =>
      other is IfdSingleValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  Uint8List toData() => Uint8List.view(value.buffer);

  @override
  double toDouble([int index = 0]) => value[index];

  @override
  void setDouble(double v, [int index = 0]) { value[index] = v; }

  @override
  void write(OutputBuffer out) {
    final l = value.length;
    for (var i = 0; i < l; ++i) {
      out.writeFloat32(value[i]);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class IfdDoubleValue extends IfdValue {
  Float64List value;

  IfdDoubleValue(double value)
      : value = Float64List(1) {
    this.value[0] = value;
  }

  IfdDoubleValue.list(List<double> value)
      : value = Float64List.fromList(value);

  IfdDoubleValue.data(InputBuffer data, int count)
      : value = Float64List(count) {
    for (int i = 0; i < count; ++i) {
      value[i] = data.readFloat32();
    }
  }

  @override
  IfdValue clone() => IfdDoubleValue.list(value);

  @override
  IfdValueType get type => IfdValueType.double;

  @override
  int get length => value.length;

  @override
  bool operator==(Object other) =>
      other is IfdDoubleValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  double toDouble([int index = 0]) => value[index];

  @override
  void setDouble(double v, [int index = 0]) { value[index] = v; }

  @override
  Uint8List toData() => Uint8List.view(value.buffer);

  @override
  void write(OutputBuffer out) {
    final l = value.length;
    for (var i = 0; i < l; ++i) {
      out.writeFloat64(value[i]);
    }
  }

  @override
  String toString() => value.length == 1 ? '${value[0]}' : '$value';
}

class ExifUndefinedValue extends IfdValue {
  Uint8List value;

  ExifUndefinedValue.list(List<int> value)
      : value = Uint8List.fromList(value);

  ExifUndefinedValue.data(InputBuffer data, int count)
      : value = Uint8List.fromList(data.readBytes(count).toUint8List());

  @override
  IfdValue clone() => ExifUndefinedValue.list(value);

  @override
  IfdValueType get type => IfdValueType.undefined;

  @override
  int get length => value.length;

  @override
  Uint8List toData() => value;

  @override
  bool operator==(Object other) =>
      other is ExifUndefinedValue &&
      length == other.length &&
      hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAll(value);

  @override
  void write(OutputBuffer out) {
    out.writeBytes(value);
  }

  @override
  String toString() => '<data>';
}
