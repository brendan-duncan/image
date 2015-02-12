part of image_test;

void defineTgaTests() {
  Io.File script = new Io.File(Io.Platform.script.toFilePath());
  String path = script.parent.path;

  Io.Directory dir = new Io.Directory(path + '/res/tga');
  if (!dir.existsSync()) {
    return;
  }
  List files = dir.listSync();

  group('TGA', () {
    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.tga')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();
        Image image = new TgaDecoder().decodeImage(bytes);
        if (image == null) {
          throw new ImageException('Unable to decode TGA Image: $name.');
        }

        List<int> png = new PngEncoder().encodeImage(image);
        new Io.File(path + '/out/tga/${name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);
      });
    }

    test('decode/encode', () {
      List<int> bytes = new Io.File(path + '/res/tga/globe.tga').readAsBytesSync();

      // Decode the image from file.
      Image image = new TgaDecoder().decodeImage(bytes);
      expect(image.width, equals(128));
      expect(image.height, equals(128));

      // Encode the image as a tga
      List<int> tga = new TgaEncoder().encodeImage(image);

      Io.File out = new Io.File(path + '/out/globe.tga')
                          ..createSync(recursive: true)
                          ..writeAsBytesSync(tga);

      // Decode the encoded image, make sure it's the same as the original.
      Image image2 = new TgaDecoder().decodeImage(tga);
      expect(image2.width, equals(128));
      expect(image2.height, equals(128));
    });
  });
}
