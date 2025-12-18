// ignore_for_file: avoid_print, lines_longer_than_80_chars
//This little tool dumps information about the APP1 Exif block in a JPEG file.
//usage: "dart run tools/dump_app1.dart <jpeg-file>"

import 'dart:io';
import 'dart:typed_data';
import 'package:image/src/formats/jpeg/jpeg_util.dart';
import 'package:image/src/util/input_buffer.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tools/dump_app1.dart <jpeg-file>');
    exit(1);
  }

  final path = args[0];
  final file = File(path);
  if (!file.existsSync()) {
    print('File not found: $path');
    exit(2);
  }

  final bytes = file.readAsBytesSync();

  // Find the first APP1 marker containing Exif\0\0
  var found = false;
  int app1Pos = -1;
  int app1Length = 0;
  for (var i = 0; i < bytes.length - 3; i++) {
    if (bytes[i] == 0xff) {
      final marker = bytes[i + 1] & 0xff;
      if (marker == 0xe1) {
        app1Length = ((bytes[i + 2] & 0xff) << 8) | (bytes[i + 3] & 0xff);
        // length includes the two length bytes, content starts at i+4
        final sigStart = i + 4;
        if (sigStart + 6 <= bytes.length) {
          final sig = ((bytes[sigStart] & 0xff) << 24) |
              ((bytes[sigStart + 1] & 0xff) << 16) |
              ((bytes[sigStart + 2] & 0xff) << 8) |
              (bytes[sigStart + 3] & 0xff);
          // 'Exif' in ASCII is 0x45786966
          if (sig == 0x45786966) {
            found = true;
            app1Pos = i;
            break;
          }
        }
      }
    }
  }

  if (!found) {
    print('No APP1 Exif block found in $path');
    exit(0);
  }

  print(
      'Found APP1 at offset: 0x${app1Pos.toRadixString(16)} (decimal $app1Pos)');
  print('APP1 length (including length field): $app1Length');

  final contentStart = app1Pos + 4;
  final contentEnd = app1Pos + 2 + app1Length;
  final app1 = bytes.sublist(contentStart, contentEnd);

  print('First 16 bytes of APP1 payload:');
  print(app1.sublist(0, app1.length < 16 ? app1.length : 16));

  final block = InputBuffer(app1, bigEndian: true);

  // Read Exif signature and two zero bytes (as jpeg_util expects)
  final signature = block.readUint32();
  final zero = block.readUint16();
  print(
      'Signature: 0x${signature.toRadixString(16)}; zero: 0x${zero.toRadixString(16)}');

  // Now parse TIFF header
  final blockOffset = block.offset; // should be 6 relative to app1 start
  final endian = block.readUint16();
  final isII = endian == 0x4949;
  final isMM = endian == 0x4d4d;
  if (!isII && !isMM) {
    print('Unknown TIFF endianness: 0x${endian.toRadixString(16)}');
    exit(0);
  }
  block.bigEndian = isMM;
  final magic = block.readUint16();
  final ifd0Offset = block.readUint32();
  print('TIFF endianness: ${isMM ? 'MM (big)' : 'II (little)'}');
  print('TIFF magic: 0x${magic.toRadixString(16)}; IFD0 offset: $ifd0Offset');

  // Jump to IFD0
  block.offset = blockOffset + ifd0Offset;
  final numEntries = block.readUint16();
  print(
      'IFD0 entries: $numEntries; IFD0 offset (absolute in APP1 payload): ${block.offset - 2}');

  int? exifSubIfdOffset;
  for (var i = 0; i < numEntries; ++i) {
    final tag = block.readUint16();
    final valueOrOffset = block.readUint32();
    if (tag == 0x8769) {
      exifSubIfdOffset = valueOrOffset;
    }
  }

  final nextIfdOffset = block.readUint32();
  print('IFD0 -> next IFD offset (IFD1): $nextIfdOffset');
  if (exifSubIfdOffset != null) {
    print('ExifIFD pointer (0x8769) value: $exifSubIfdOffset');
  } else {
    print('No ExifIFD pointer (0x8769) found in IFD0');
  }

  if (nextIfdOffset != 0 && exifSubIfdOffset != null) {
    if (nextIfdOffset < exifSubIfdOffset) {
      print(
          'Warning: IFD1 pointer points before ExifIFD (likely cause of exiftool warning)');
    } else if (nextIfdOffset == exifSubIfdOffset) {
      print('IFD1 pointer equals ExifIFD offset (suspicious)');
    } else {
      print('IFD1 pointer is after ExifIFD (looks sane)');
    }
  }

  // Also try to decode using library parser
  try {
    final exif = JpegUtil().decodeExif(Uint8List.fromList(bytes));
    if (exif == null) {
      print('Library decodeExif could not parse EXIF');
    } else {
      print('Library parsed EXIF directories: ${exif.directories.keys}');
    }
  } catch (e) {
    print('decodeExif threw: $e');
  }
}
