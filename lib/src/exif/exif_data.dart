import '../util/input_buffer.dart';
import '../util/output_buffer.dart';
import 'exif_tag.dart';
import 'ifd_container.dart';
import 'ifd_directory.dart';
import 'ifd_value.dart';

class ExifData extends IfdContainer {
  ExifData()
    : super();

  ExifData.from(ExifData? other)
    : super.from(other);

  ExifData.fromInputBuffer(InputBuffer input)
    : super() {
    read(input);
  }

  ExifData clone() => ExifData.from(this);

  bool hasTag(int tag) {
    for (var directory in directories.values) {
      if (directory.containsKey(tag)) {
        return true;
      }
    }
    return false;
  }

  IfdDirectory get imageIfd => this['ifd0'];

  IfdDirectory get thumbnailIfd => this['ifd1'];

  IfdDirectory get exifIfd => this['ifd0'].sub['exif'];

  IfdDirectory get gpsIfd => this['ifd0'].sub['gps'];

  IfdDirectory get interopIfd => this['ifd0'].sub['interop'];

  IfdValue? getTag(int tag) {
    for (var directory in directories.values) {
      if (directory.containsKey(tag)) {
        return directory[tag];
      }
    }
    return null;
  }

  String getTagName(int tag) {
    if (!ExifImageTags.containsKey(tag)) {
      return '<unknown>';
    }
    return ExifImageTags[tag]!.name;
  }

  String toString() {
    final s = StringBuffer();
    for (var name in directories.keys) {
      s.write('$name\n');
      final directory = directories[name]!;
      for (var tag in directory.keys) {
        var value = directory[tag];
        if (value == null) {
          s.write('\t${getTagName(tag)}\n');
        } else {
          s.write('\t${getTagName(tag)}: $value\n');
        }
      }
      for (var subName in directory.sub.keys) {
        s.write('$subName\n');
        final subDirectory = directory.sub[subName];
        for (var tag in subDirectory.keys) {
          var value = subDirectory[tag];
          if (value == null) {
            s.write('\t${getTagName(tag)}\n');
          } else {
            s.write('\t${getTagName(tag)}: $value\n');
          }
        }
      }
    }
    return s.toString();
  }

  void write(OutputBuffer out) {
    final saveEndian = out.bigEndian;
    out.bigEndian = true;

    // Tiff header
    out.writeUint16(0x4d4d); // big endian
    out.writeUint16(0x002a);
    out.writeUint32(8); // offset to first ifd block

    if (directories['ifd0'] == null)
      directories['ifd0'] = IfdDirectory();

    var dataOffset = 8; // offset to first ifd block, from start of tiff header
    var offsets = <String,int>{};

    for (var name in directories.keys) {
      final ifd = directories[name]!;
      offsets[name] = dataOffset;

      if (ifd.sub.containsKey('exif')) {
        ifd[0x8769] = IfdLongValue(0);
      } else {
        ifd.data.remove(0x8769);
      }

      if (ifd.sub.containsKey('interop')) {
        ifd[0xA005] = IfdLongValue(0);
      } else {
        ifd.data.remove(0xA005);
      }

      if (ifd.sub.containsKey('gps')) {
        ifd[0x8825] = IfdLongValue(0);
      } else {
        ifd.data.remove(0x8825);
      }

      // ifd block size
      dataOffset += 2 + (12 * ifd.values.length) + 4;

      // storage for large tag values
      for (var value in ifd.values) {
        final dataSize = value.dataSize;
        if (dataSize > 4) {
          dataOffset += dataSize;
        }
      }

      // storage for sub-ifd blocks
      for (var subName in ifd.sub.keys) {
        final subIfd = ifd.sub[subName];
        offsets[subName] = dataOffset;
        int subSize = 2 + (12 * subIfd.values.length);
        for (var value in subIfd.values) {
          final dataSize = value.dataSize;
          if (dataSize > 4) {
            subSize += dataSize;
          }
        }
        dataOffset += subSize;
      }
    }

    var numIfd = directories.keys.length;
    for (int i = 0; i < numIfd; ++i) {
      final name = directories.keys.elementAt(i);
      final ifd = directories.values.elementAt(i);

      if (ifd.sub.containsKey('exif')) {
        ifd[0x8769]!.setInt(offsets['exif']!);
      }

      if (ifd.sub.containsKey('interop')) {
        ifd[0xA005]!.setInt(offsets['interop']!);
      }

      if (ifd.sub.containsKey('gps')) {
        ifd[0x8825]!.setInt(offsets['gps']!);
      }

      final ifdOffset = offsets[name]!;
      final dataOffset = ifdOffset + 2 + (12 * ifd.values.length) + 4;

      _writeDirectory(out, ifd, dataOffset);

      if (i == numIfd - 1) {
        out.writeUint32(0);
      } else {
        final nextName = directories.keys.elementAt(i + 1);
        out.writeUint32(offsets[nextName]!);
      }

      _writeDirectoryLargeValues(out, ifd);

      for (var subName in ifd.sub.keys) {
        final subIfd = ifd.sub[subName];
        final subOffset = offsets[subName]!;
        final dataOffset = subOffset + 2 + (12 * subIfd.values.length);
        _writeDirectory(out, subIfd, dataOffset);
        _writeDirectoryLargeValues(out, subIfd);
      }
    }

    out.bigEndian = saveEndian;
  }

  int _writeDirectory(OutputBuffer out, IfdDirectory ifd, int dataOffset) {
    out.writeUint16(ifd.keys.length);
    for (var tag in ifd.keys) {
      final value = ifd[tag]!;

      out.writeUint16(tag);
      out.writeUint16(value.type.index);
      out.writeUint32(value.length);

      var size = value.dataSize;
      if (size <= 4) {
        value.write(out);
        while (size < 4) {
          out.writeByte(0);
          size++;
        }
      } else {
        out.writeUint32(dataOffset);
        dataOffset += size;
      }
    }
    return dataOffset;
  }

  void _writeDirectoryLargeValues(OutputBuffer out, IfdDirectory ifd) {
    for (var value in ifd.values) {
      var size = value.dataSize;
      if (size > 4) {
        value.write(out);
      }
    }
  }

  bool read(InputBuffer block) {
    final saveEndian = block.bigEndian;
    block.bigEndian = true;

    int blockOffset = block.offset;

    // Tiff header
    int endian = block.readUint16();
    if (endian == 0x4949) { // II
      block.bigEndian = false;
      if (block.readUint16() != 0x2a00) {
        block.bigEndian = saveEndian;
        return false;
      }
    } else if (endian == 0x4d4d) { // MM
      block.bigEndian = true;
      if (block.readUint16() != 0x002a) {
        block.bigEndian = saveEndian;
        return false;
      }
    } else {
      return false;
    }

    int ifdOffset = block.readUint32();

    // IFD blocks
    var index = 0;
    while (ifdOffset > 0) {
      block.offset = blockOffset + ifdOffset;

      final directory = IfdDirectory();
      final numEntries = block.readUint16();
      final dir = List<_ExifEntry>.generate(numEntries, (i) =>
          _readEntry(block, blockOffset));

      for (var entry in dir) {
        if (entry.value != null) {
          directory[entry.tag] = entry.value!;
        }
      }
      directories['ifd$index'] = directory;
      index++;

      ifdOffset = block.readUint32();
    }

    const subTags = {
      0x8769: 'exif',
      0xA005: 'interop',
      0x8825: 'gps',
    };

    for (var d in directories.values) {
      for (var dt in subTags.keys) {
        if (d.containsKey(dt)) { // ExifOffset
          int ifdOffset = d[dt]!.toInt();
          block.offset = blockOffset + ifdOffset;
          final directory = IfdDirectory();
          final numEntries = block.readUint16();
          final dir = List<_ExifEntry>.generate(numEntries, (i) =>
              _readEntry(block, blockOffset));

          for (var entry in dir) {
            if (entry.value != null) {
              directory[entry.tag] = entry.value!;
            }
          }
          d.sub[subTags[dt]!] = directory;
        }
      }
    }

    block.bigEndian = saveEndian;
    return false;
  }

  _ExifEntry _readEntry(InputBuffer block, int blockOffset) {
    final tag = block.readUint16();
    final format = block.readUint16();
    final count = block.readUint32();

    final entry = _ExifEntry(tag, null);

    if (format > IfdValueType.values.length)
      return entry;

    final f = IfdValueType.values[format];
    final fsize = ifdValueTypeSize[format];
    final size = count * fsize;

    final endOffset = block.offset + 4;

    if (size > 4) {
      final fieldOffset = block.readUint32();
      block.offset = fieldOffset + blockOffset;
    }

    if (block.offset + size > block.end) {
      return entry;
    }

    final data = block.readBytes(size);

    switch (f) {
      case IfdValueType.none:
        break;
      case IfdValueType.sByte:
        entry.value = IfdSByteValue.data(data, count);
        break;
      case IfdValueType.byte:
        entry.value = IfdByteValue.data(data, count);
        break;
      case IfdValueType.undefined:
        entry.value = ExifUndefinedValue.data(data, count);
        break;
      case IfdValueType.ascii:
        entry.value = IfdAsciiValue.data(data, count);
        break;
      case IfdValueType.short:
        entry.value = IfdShortValue.data(data, count);
        break;
      case IfdValueType.long:
        entry.value = IfdLongValue.data(data, count);
        break;
      case IfdValueType.rational:
        entry.value = IfdRationalValue.data(data, count);
        break;
      case IfdValueType.sRational:
        entry.value = IfdSRationalValue.data(data, count);
        break;
      case IfdValueType.sShort:
        entry.value = IfdSShortValue.data(data, count);
        break;
      case IfdValueType.sLong:
        entry.value = IfdSLongValue.data(data, count);
        break;
      case IfdValueType.single:
        entry.value = IfdSingleValue.data(data, count);
        break;
      case IfdValueType.double:
        entry.value = IfdDoubleValue.data(data, count);
        break;
    }

    block.offset = endOffset;

    return entry;
  }
}

class _ExifEntry {
  int tag;
  IfdValue? value;
  _ExifEntry(this.tag, this.value);
}