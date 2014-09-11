part of image_test;

void defineColorTests() {
  group('Color', () {
    test('RGBA', () {
      int rgba = Color.fromRgba(0xaa, 0xbb, 0xcc, 0xff);
      expect(rgba, equals(0xffccbbaa));

      expect(getRed(rgba), equals(0xaa));
      expect(getGreen(rgba), equals(0xbb));
      expect(getBlue(rgba), equals(0xcc));
      expect(getAlpha(rgba), equals(0xff));

      expect(getChannel(rgba, 0), equals(0xaa));
      expect(getChannel(rgba, 1), equals(0xbb));
      expect(getChannel(rgba, 2), equals(0xcc));
      expect(getChannel(rgba, 3), equals(0xff));
      expect(getChannel(rgba, 4), equals(0xff)); // out-of-bounds returns alpha

      rgba = setChannel(rgba, 0, 0x11);
      rgba = setChannel(rgba, 1, 0x22);
      rgba = setChannel(rgba, 2, 0x33);
      rgba = setChannel(rgba, 3, 0x44);
      expect(rgba, equals(0x44332211));

      rgba = setRed(rgba, 0x55);
      rgba = setGreen(rgba, 0x66);
      rgba = setBlue(rgba, 0x77);
      rgba = setAlpha(rgba, 0x88);
      expect(rgba, equals(0x88776655));
    });

    test('Grayscale', () {
      var rgba = Color.fromRgba(0x55, 0x66, 0x77, 0x88);
      var l = getLuminance(rgba);
      expect(l, equals(0x63));

      l = getLuminanceRGB(0x55, 0x66, 0x77);
      expect(l, equals(0x63));
    });

    test('HSL', () {
      var rgb = hslToRGB(180.0 / 360.0, 0.5, 0.75);
      expect(rgb[0], equals(159));
      expect(rgb[1], equals(223));
      expect(rgb[2], equals(223));

      var hsl = rgbToHSL(rgb[0], rgb[1], rgb[2]);
      expect(hsl[0], closeTo(0.5, 0.001));
      expect(hsl[1], closeTo(0.5, 0.001));
      expect(hsl[2], closeTo(0.75, 0.001));
    });

    test('CMYK', () {
      var rgb = cmykToRGB((0.75 * 255), (0.5 * 255), (0.5 * 255), (0.5 * 255));
      expect(rgb[0], equals(32));
      expect(rgb[1], equals(64));
      expect(rgb[2], equals(64));
    });
  });
}
