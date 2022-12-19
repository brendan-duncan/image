import '../../exif/exif_tag.dart';
import '../../exif/ifd_value.dart';
import '../../util/input_buffer.dart';

class TiffEntry {
  int tag;
  IfdValueType type;
  int count;
  int valueOffset;
  IfdValue? value;
  InputBuffer p;

  TiffEntry(this.tag, this.type, this.count, this.p, this.valueOffset);

  @override
  String toString() {
    final exifTag = exifImageTags[tag];
    if (exifTag != null) {
      return '${exifTag.name}: $type $count';
    }
    return '<$tag>: $type $count';
  }

  bool get isValid => type != IfdValueType.none;

  int get typeSize => isValid ? ifdValueTypeSize[type.index] : 0;

  bool get isString => type == IfdValueType.ascii;

  IfdValue? read() {
    if (value != null) {
      return value;
    }
    p.offset = valueOffset;
    final data = p.readBytes(count * typeSize);
    switch (type) {
      case IfdValueType.byte:
        return value = IfdByteValue.data(data, count);
      case IfdValueType.ascii:
        return value = IfdAsciiValue.data(data, count);
      case IfdValueType.undefined:
        return value = IfdByteValue.data(data, count);
      case IfdValueType.short:
        return value = IfdShortValue.data(data, count);
      case IfdValueType.long:
        return value = IfdLongValue.data(data, count);
      case IfdValueType.rational:
        return value = IfdRationalValue.data(data, count);
      case IfdValueType.single:
        return value = IfdSingleValue.data(data, count);
      case IfdValueType.double:
        return value = IfdDoubleValue.data(data, count);
      case IfdValueType.sByte:
        return value = IfdSByteValue.data(data, count);
      case IfdValueType.sShort:
        return value = IfdSShortValue.data(data, count);
      case IfdValueType.sLong:
        return value = IfdSLongValue.data(data, count);
      case IfdValueType.sRational:
        return value = IfdSRationalValue.data(data, count);
      case IfdValueType.none:
        return null;
    }
  }
}
