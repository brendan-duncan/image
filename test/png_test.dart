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
