import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:image/src/formats/jpeg/jpeg_util.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

void main() {
  final dir = Directory('test/_data/jpg');
  final jpgFiles = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.jpg'))
      .toList();

  for (final file in jpgFiles) {
    test('injectExif realistic tags roundtrip: \\${file.path}', () async {
      expect(file.existsSync(), isTrue, reason: 'test image must exist');

      final orig = await file.readAsBytes();
      final ExifData? exif = JpegUtil().decodeExif(orig);

      // Ensure EXIF container and required directories exist
      final ExifData data = exif ?? ExifData();

      final fmt = DateFormat('yyyy:MM:dd HH:mm:ss');
      final dt = fmt.format(DateTime.now());

      // Write tags by name into proper directories
      data.imageIfd['DateTime'] = dt;
      data.exifIfd['DateTimeOriginal'] = dt;
      data.exifIfd['DateTimeDigitized'] = dt;

      final Uint8List? out = JpegUtil().injectExif(data, orig);
      expect(out, isNotNull, reason: 'injectExif should return data');

      final ExifData? decoded = JpegUtil().decodeExif(out!);
      expect(decoded, isNotNull,
          reason: 'decodeExif should parse injected EXIF');

      // Verify the tag round-trips (extract string from IfdValueAscii)
      String? getAsciiValue(dynamic v) {
        if (v == null) {
          return null;
        }
        if (v is String) {
          return v;
        }
        if (v is IfdValueAscii) {
          return v.value;
        }
        return v.toString();
      }

      expect(getAsciiValue(decoded!.imageIfd['DateTime']), equals(dt));
      expect(getAsciiValue(decoded.exifIfd['DateTimeOriginal']), equals(dt));
      expect(getAsciiValue(decoded.exifIfd['DateTimeDigitized']), equals(dt));
    });
  }
}
