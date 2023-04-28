import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Exif', () {
    test('write/read', () {
      final exif = ExifData();
      exif.imageIfd[0] = IfdValueShort(124);
      exif.imageIfd[1] = IfdValueLong(52141);
      exif.imageIfd[2] = IfdValueSShort(-42);
      exif.imageIfd[3] = IfdValueSLong(-42141);
      exif.imageIfd[4] = IfdValueRational(72, 1);
      exif.imageIfd[5] = IfdValueSRational(-50, 5);
      exif.imageIfd[6] = IfdValueAscii('this is an exif string');
      exif.imageIfd[7] = IfdValueUndefined.list([1, 2, 3, 4]);

      exif.imageIfd.sub['exif'][0] = IfdValueShort(124);
      exif.imageIfd.sub['exif'][1] = IfdValueLong(52141);
      exif.imageIfd.sub['exif'][2] = IfdValueSShort(-42);
      exif.imageIfd.sub['exif'][3] = IfdValueSLong(-42141);
      exif.imageIfd.sub['exif'][4] = IfdValueRational(72, 1);
      exif.imageIfd.sub['exif'][5] = IfdValueSRational(-50, 5);
      exif.imageIfd.sub['exif'][6] = IfdValueAscii('this is an exif string');
      exif.imageIfd.sub['exif'][7] = IfdValueUndefined.list([5, 6, 7, 8]);

      exif.thumbnailIfd[0] = IfdValueShort(124);
      exif.thumbnailIfd[1] = IfdValueLong(52141);
      exif.thumbnailIfd[2] = IfdValueSShort(-42);
      exif.thumbnailIfd[3] = IfdValueSLong(-42141);
      exif.thumbnailIfd[4] = IfdValueRational(72, 1);
      exif.thumbnailIfd[5] = IfdValueSRational(-50, 5);
      exif.thumbnailIfd[7] = IfdValueUndefined.list([9, 10, 11, 12]);

      final out = OutputBuffer();
      exif.write(out);

      final exif1 = ExifData();
      final input = InputBuffer(out.getBytes());
      exif1.read(input);
      final exif2 = exif1.clone();

      expect(exif2.imageIfd.values.length, equals(exif.imageIfd.values.length));
      for (int i = 0; i < exif2.imageIfd.values.length; ++i) {
        expect(exif2.imageIfd[i], equals(exif.imageIfd[i]));
      }
      expect(exif2.imageIfd.sub.keys.length, equals(1));
      expect(exif2.imageIfd.sub.keys.elementAt(0), equals('exif'));
      for (int i = 0; i < exif2.imageIfd.sub['exif'].values.length; ++i) {
        expect(exif2.imageIfd.sub['exif'][i],
            equals(exif.imageIfd.sub['exif'][i]));
      }

      expect(exif2.thumbnailIfd.values.length,
          equals(exif.thumbnailIfd.values.length));
      for (int i = 0; i < exif2.thumbnailIfd.values.length; ++i) {
        expect(exif2.thumbnailIfd[i], equals(exif.thumbnailIfd[i]));
      }
    });
  });
}
