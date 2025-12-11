import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:image/src/formats/jpeg/jpeg_util.dart';
import 'package:test/test.dart';

void main() {
  test('injectExif -> decodeExif roundtrip', () {
    final file = File('test/_data/jpg/jpgwithoutexifblock.jpg');
    expect(file.existsSync(), isTrue, reason: 'test image must exist');

    final origBytes = file.readAsBytesSync();
    // Work on a copy of the original bytes so the on-disk file is not altered.
    final bytes = Uint8List.fromList(origBytes);

    // Build a minimal ExifData and inject it. Set the tag on the image IFD
    // because `make` is a property of an IfdDirectory, not ExifData itself.
    final exif = ExifData();
    exif.imageIfd.make = 'dart-image-test';

    final injected = JpegUtil().injectExif(exif, bytes);
    expect(injected, isNotNull, reason: 'injectExif should return data');

    final decoded = JpegUtil().decodeExif(injected!);
    expect(decoded, isNotNull, reason: 'decodeExif should parse injected EXIF');

    // Verify the tag round-trips (make lives on the image IFD)
    expect(decoded!.imageIfd.make, equals('dart-image-test'));
  });
}
