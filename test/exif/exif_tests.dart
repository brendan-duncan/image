import 'package:image/image.dart';
import 'package:test/test.dart';

void ExifTests() {
  group('Exif', () {
    test('write/read', () {
      final exif = ExifData();
      exif.imageIfd[0] = IfdShortValue(124);
      exif.imageIfd[1] = IfdLongValue(52141);
      exif.imageIfd[2] = IfdSShortValue(-42);
      exif.imageIfd[3] = IfdSLongValue(-42141);
      exif.imageIfd[4] = IfdRationalValue(72, 1);
      exif.imageIfd[5] = IfdSRationalValue(-50, 5);

      exif.imageIfd.sub['exif'][0] = IfdShortValue(124);
      exif.imageIfd.sub['exif'][1] = IfdLongValue(52141);
      exif.imageIfd.sub['exif'][2] = IfdSShortValue(-42);
      exif.imageIfd.sub['exif'][3] = IfdSLongValue(-42141);
      exif.imageIfd.sub['exif'][4] = IfdRationalValue(72, 1);
      exif.imageIfd.sub['exif'][5] = IfdSRationalValue(-50, 5);

      exif.thumbnailIfd[0] = IfdShortValue(124);
      exif.thumbnailIfd[1] = IfdLongValue(52141);
      exif.thumbnailIfd[2] = IfdSShortValue(-42);
      exif.thumbnailIfd[3] = IfdSLongValue(-42141);
      exif.thumbnailIfd[4] = IfdRationalValue(72, 1);
      exif.thumbnailIfd[5] = IfdSRationalValue(-50, 5);

      final out = OutputBuffer();
      exif.write(out);

      final exif2 = ExifData();
      final input = InputBuffer(out.getBytes());
      exif2.read(input);

      expect(exif2.imageIfd.values.length, equals(exif.imageIfd.values.length));
      for (int i = 0; i < exif2.imageIfd.values.length; ++i) {
        expect(exif2.imageIfd[i], equals(exif.imageIfd[i]));
      }
      expect(exif2.imageIfd.sub.keys.length, equals(1));
      expect(exif2.imageIfd.sub.keys.elementAt(0), equals('exif'));
      for (int i = 0; i < exif2.imageIfd.sub['exif'].values.length; ++i) {
        expect(exif2.imageIfd.sub['exif'][i], equals(exif.imageIfd.sub['exif'][i]));
      }

      expect(exif2.thumbnailIfd.values.length, equals(exif.thumbnailIfd.values.length));
      for (int i = 0; i < exif2.thumbnailIfd.values.length; ++i) {
        expect(exif2.thumbnailIfd[i], equals(exif.thumbnailIfd[i]));
      }
    });
  });
}
