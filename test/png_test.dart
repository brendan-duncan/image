part of image_test;

void definePngTests() {
  group('PNG', () {
    test('encode', () {
      Image image = new Image(64, 64);
      image.fill(getColor(100, 200, 255));

      // Encode the image to PNG
      List<int> png = new PngEncoder().encodeImage(image);
      new Io.File('out/encode.png')
            .writeAsBytesSync(png);
    });

    test('decode', () {
      List<int> bytes = new Io.File('out/encode.png').readAsBytesSync();
      Image image = new PngDecoder().decodeImage(bytes);

      expect(image.width, equals(64));
      expect(image.height, equals(64));
      var c = getColor(100, 200, 255);
      for (int i = 0, len = image.length; i < len; ++i) {
        expect(image[i], equals(c));
      }

      List<int> png = new PngEncoder().encodeImage(image);
      new Io.File('out/decode.png')
            .writeAsBytesSync(png);
    });

    Io.File script = new Io.File(Io.Platform.script.toFilePath());
    String path = script.parent.path + '/res/png';

    Io.Directory dir = new Io.Directory(path);
    List files = dir.listSync();

    for (var f in files) {
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
      String name = f.path.split(new RegExp(r'(/|\\)')).last;

      test('PNG $name', () {
        Io.File file = f;

        // x* png's are corrupted and are supposed to crash.
        if (name.startsWith('x')) {
          try {
            Image image = new PngDecoder().decodeImage(file.readAsBytesSync());
            throw new ImageException('This image should not have loaded: $name.');
          } catch (e) {
          }
        } else {
          Image image = new PngDecoder().decodeImage(file.readAsBytesSync());
          List<int> png = new PngEncoder().encodeImage(image);
          new Io.File('out/png/${name}')
                ..createSync(recursive: true)
                ..writeAsBytesSync(png);
        }
      });
    }
  });
}
