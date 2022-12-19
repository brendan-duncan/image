import 'dart:typed_data';

import '../util/rational.dart';
import 'exif_tag.dart';
import 'ifd_container.dart';
import 'ifd_value.dart';

class IfdDirectory {
  final data = Map<int, IfdValue>();
  final sub = IfdContainer();

  Iterable<int> get keys => data.keys;
  Iterable<IfdValue> get values => data.values;

  bool get isEmpty => data.isEmpty && sub.isEmpty;

  bool containsKey(int tag) => data.containsKey(tag);

  IfdValue? operator[](Object? tag) {
    if (tag is String) {
      tag = exifTagNameToID[tag];
    }
    if (tag is int) {
      return data[tag];
    }
    return null;
  }

  void operator[]=(Object? tag, Object? value) {
    if (tag is String) {
      tag = exifTagNameToID[tag];
    }
    if (tag is! int) {
      return;
    }

    if (value == null) {
      data.remove(tag);
    } else {
      if (value is IfdValue) {
        data[tag] = value;
      } else {
        final tagInfo = ExifImageTags[tag];
        if (tagInfo != null) {
          final tagType = tagInfo.type;
          final tagCount = tagInfo.count;
          switch (tagType) {
            case IfdValueType.byte:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = IfdByteValue.list(Uint8List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = IfdByteValue(value);
              }
              break;
            case IfdValueType.ascii:
              if (value is String) {
                data[tag] = IfdAsciiValue(value);
              }
              break;
            case IfdValueType.short:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = IfdShortValue.list(Uint16List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = IfdShortValue(value);
              }
              break;
            case IfdValueType.long:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = IfdLongValue.list(Uint32List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = IfdLongValue(value);
              }
              break;
            case IfdValueType.rational:
              if (value is List<Rational> && value.length == tagCount) {
                data[tag] = IfdRationalValue.list(value);
              } else if (tagCount == 1 && value is List<int> &&
                  value.length == 2) {
                data[tag] = IfdRationalValue(value[0], value[1]);
              } else if (tagCount == 1 && value is Rational) {
                data[tag] = IfdRationalValue.from(value);
              } else if (value is List<List<int>> && value.length == tagCount) {
                data[tag] = IfdRationalValue.list(
                    List<Rational>.generate(value.length,
                            (index) => Rational(value[index][0],
                                value[index][1])));
              }
              break;
            case IfdValueType.sByte:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = IfdSByteValue.list(Int8List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = IfdSByteValue(value);
              }
              break;
            case IfdValueType.undefined:
              if (value is List<int>) {
                data[tag] = ExifUndefinedValue.list(Uint8List.fromList(value));
              }
              break;
            case IfdValueType.sShort:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = IfdSShortValue.list(Int16List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = IfdSShortValue(value);
              }
              break;
            case IfdValueType.sLong:
              if (value is List<int> && value.length == tagCount) {
                data[tag] = IfdSLongValue.list(Int32List.fromList(value));
              } else if (value is int && tagCount == 1) {
                data[tag] = IfdSLongValue(value);
              }
              break;
            case IfdValueType.sRational:
              if (value is List<Rational> && value.length == tagCount) {
                data[tag] = IfdSRationalValue.list(value);
              } else if (tagCount == 1 && value is List<int> &&
                  value.length == 2) {
                data[tag] = IfdSRationalValue(value[0], value[1]);
              } else if (tagCount == 1 && value is Rational) {
                data[tag] = IfdSRationalValue.from(value);
              } else if (value is List<List<int>> && value.length == tagCount) {
                data[tag] = IfdSRationalValue.list(
                    List<Rational>.generate(value.length,
                            (index) => Rational(value[index][0],
                                value[index][1])));
              }
              break;
            case IfdValueType.single:
              if (value is List<double> && value.length == tagCount) {
                data[tag] = IfdSingleValue.list(Float32List.fromList(value));
              } else if (value is double && tagCount == 1) {
                data[tag] = IfdSingleValue(value);
              } else if (value is int && tagCount == 1) {
                data[tag] = IfdSingleValue(value.toDouble());
              }
              break;
            case IfdValueType.double:
              if (value is List<double> && value.length == tagCount) {
                data[tag] = IfdDoubleValue.list(Float64List.fromList(value));
              } else if (value is double && tagCount == 1) {
                data[tag] = IfdDoubleValue(value);
              } else if (value is int && tagCount == 1) {
                data[tag] = IfdDoubleValue(value.toDouble());
              }
              break;
            case IfdValueType.none:
              break;
          }
        }
      }
    }
  }

  bool get hasImageDescription => data.containsKey(0x010e);
  String? get ImageDescription => data[0x010e]?.toString();
  set ImageDescription(String? value) {
    if (value == null) {
      data.remove(0x010e);
    } else {
      data[0x010e] = IfdAsciiValue(value);
    }
  }

  bool get hasMake => data.containsKey(0x010f);
  String? get Make => data[0x010f]?.toString();
  set Make(String? value) {
    if (value == null) {
      data.remove(0x010f);
    } else {
      data[0x010f] = IfdAsciiValue(value);
    }
  }

  bool get hasModel => data.containsKey(0x0110);
  String? get Model => data[0x0110]?.toString();
  set Model(String? value) {
    if (value == null) {
      data.remove(0x0110);
    } else {
      data[0x0110] = IfdAsciiValue(value);
    }
  }

  bool get hasOrientation => data.containsKey(0x0112);
  int? get Orientation => data[0x0112]?.toInt();
  set Orientation(int? value) {
    if (value == null) {
      data.remove(0x0112);
    } else {
      data[0x0112] = IfdShortValue(value);
    }
  }

  bool _setRational(int tag, Object? value) {
    if (value is Rational) {
      data[tag] = IfdRationalValue.from(value);
      return true;
    } else if (value is List<int>) {
      if (value.length == 2) {
        data[tag] = IfdRationalValue.from(Rational(value[0], value[1]));
        return true;
      }
    }
    return false;
  }

  bool get hasXResolution => data.containsKey(0x011a);
  Rational? get XResolution => data[0x011a]?.toRational();
  set XResolution(Object? value) {
    if (!_setRational(0x011a, value)) {
      data.remove(0x011a);
    }
  }

  bool get hasYResolution => data.containsKey(0x011b);
  Rational? get YResolution => data[0x011b]?.toRational();
  set YResolution(Object? value) {
    if (!_setRational(0x011b, value)) {
      data.remove(0x011b);
    }
  }

  bool get hasResolutionUnit => data.containsKey(0x0128);
  int? get ResolutionUnit => data[0x0128]?.toInt();
  set ResolutionUnit(int? value) {
    if (value == null) {
      data.remove(0x0128);
    } else {
      data[0x0128] = IfdShortValue(value);
    }
  }

  bool get hasImageWidth => data.containsKey(0x0100);
  int? get ImageWidth => data[0x0100]?.toInt();
  set ImageWidth(int? value) {
    if (value == null) {
      data.remove(0x0100);
    } else {
      data[0x0100] = IfdShortValue(value);
    }
  }

  bool get hasImageHeight => data.containsKey(0x0101);
  int? get ImageHeight => data[0x0101]?.toInt();
  set ImageHeight(int? value) {
    if (value == null) {
      data.remove(0x0101);
    } else {
      data[0x0101] = IfdShortValue(value);
    }
  }

  bool get hasSoftware => data.containsKey(0x0131);
  String? get Software => data[0x0131]?.toString();
  set Software(String? value) {
    if (value == null) {
      data.remove(0x0131);
    } else {
      data[0x0131] = IfdAsciiValue(value);
    }
  }

  bool get hasCopyright => data.containsKey(0x8298);
  String? get Copyright => data[0x8298]?.toString();
  set Copyright(String? value) {
    if (value == null) {
      data.remove(0x8298);
    } else {
      data[0x8298] = IfdAsciiValue(value);
    }
  }
}
