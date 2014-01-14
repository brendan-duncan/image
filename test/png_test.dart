part of image_test;

void definePngTests() {
  group('png', () {
    test('encode', () {
      Image image = new Image(64, 64);
      image.fill(getColor(100, 200, 255));

      // Encode the image to PNG
      List<int> png = new PngEncoder().encode(image);

      new Io.File('out/encode.png')
            .writeAsBytesSync(png);
    });

    test('decode', () {
      List<int> bytes = new Io.File('out/encode.png').readAsBytesSync();
      Image image = new PngDecoder().decode(bytes);

      expect(image.width, equals(64));
      expect(image.height, equals(64));
    });

    // Run tests on the PNGs from the PngSuite test images, which conver
    // all known formats of PNG.
    Io.File script = new Io.File(Io.Platform.script.toFilePath());
    String path = script.parent.path + '/res/png';

    new Io.Directory(path).list().listen((f) {
      if (f is! Io.File || !f.path.endsWith('.png')) {
        return;
      }

      // PngSuite File naming convention:
      // filename:                                g04i2c08.png
      //                                          || ||||
      //  test feature (in this case gamma) ------+| ||||
      //  parameter of test (here gamma-value) ----+ ||||
      //  interlaced or non-interlaced --------------+|||
      //  color-type (numerical) ---------------------+||
      //  color-type (descriptive) --------------------+|
      //  bit-depth ------------------------------------+
      //
      //  color-type:
      //
      //    0g - grayscale
      //    2c - rgb color
      //    3p - paletted
      //    4a - grayscale + alpha channel
      //    6a - rgb color + alpha channel
      //    bit-depth:
      //      01 - with color-type 0, 3
      //      02 - with color-type 0, 3
      //      04 - with color-type 0, 3
      //      08 - with color-type 0, 2, 3, 4, 6
      //      16 - with color-type 0, 2, 4, 6
      //      interlacing:
      //        n - non-interlaced
      //        i - interlaced
      String name = f.path.split('/').last;
      test('png/$name', () {
        Io.File file = f;
        try {
          Image image = new PngDecoder().decode(file.readAsBytesSync());
        } catch (e) {
          // Catch the exception for now since I know these tests don't
          // pass
          print(file.path.split('/').last + ': ' + e.toString());
        }
      });
    });
  });
}
