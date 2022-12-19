import 'package:image/image.dart';
import 'package:test/test.dart';

void imageFloat64Test() {
  test('float64', () {
    final i1 = Image(2, 2, format: Format.float64, numChannels: 1);
    expect(i1.width, equals(2));
    expect(i1.height, equals(2));
    expect(i1.numChannels, equals(1));
    expect(i1.format, Format.float64);
    i1..setPixelColor(0, 0, 32)
    ..setPixelColor(1, 0, 64)
    ..setPixelColor(0, 1, -75)
    ..setPixelColor(1, 1, -115);
    expect(i1.getPixel(0, 0), equals([32]));
    expect(i1.getPixel(1, 0), equals([64]));
    expect(i1.getPixel(0, 1), equals([-75]));
    expect(i1.getPixel(1, 1), equals([-115]));

    final i2 = Image(2, 2, format: Format.float64, numChannels: 2);
    expect(i2.width, equals(2));
    expect(i2.height, equals(2));
    expect(i2.numChannels, equals(2));
    i2..setPixelColor(0, 0, 32, 64)
    ..setPixelColor(1, 0, 64, 32)
    ..setPixelColor(0, 1, -58, 52)
    ..setPixelColor(1, 1, 110, 84);
    expect(i2.getPixel(0, 0), equals([32, 64]));
    expect(i2.getPixel(1, 0), equals([64, 32]));
    expect(i2.getPixel(0, 1), equals([-58, 52]));
    expect(i2.getPixel(1, 1), equals([110, 84]));

    final i3 = Image(2, 2, format: Format.float64);
    expect(i3.width, equals(2));
    expect(i3.height, equals(2));
    expect(i3.numChannels, equals(3));
    i3..setPixelColor(0, 0, 32, 64, 86)
    ..setPixelColor(1, 0, 64, 32, 14)
    ..setPixelColor(0, 1, -58, 52, 5)
    ..setPixelColor(1, 1, 110, 84, 94);
    expect(i3.getPixel(0, 0), equals([32, 64, 86]));
    expect(i3.getPixel(1, 0), equals([64, 32, 14]));
    expect(i3.getPixel(0, 1), equals([-58, 52, 5]));
    expect(i3.getPixel(1, 1), equals([110, 84, 94]));

    final i4 = Image(2, 2, format: Format.float64, numChannels: 4);
    expect(i4.width, equals(2));
    expect(i4.height, equals(2));
    expect(i4.numChannels, equals(4));
    i4..setPixelColor(0, 0, 32, 64, 86, 44)
    ..setPixelColor(1, 0, 64, 32, 14, 14)
    ..setPixelColor(0, 1, 12, 52, 5, 52)
    ..setPixelColor(1, 1, 100, 84, 94, 82);
    expect(i4.getPixel(0, 0), equals([32, 64, 86, 44]));
    expect(i4.getPixel(1, 0), equals([64, 32, 14, 14]));
    expect(i4.getPixel(0, 1), equals([12, 52, 5, 52]));
    expect(i4.getPixel(1, 1), equals([100, 84, 94, 82]));
  });
}
