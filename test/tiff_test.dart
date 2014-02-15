part of image_test;

void defineTiffTests() {
  Io.File script = new Io.File(Io.Platform.script.toFilePath());
  String path = script.parent.path + '/res/tiff';

  Io.Directory dir = new Io.Directory(path);
  if (!dir.existsSync()) {
    return;
  }
  List files = dir.listSync();

  group('TIFF', () {
    for (var f in files) {
      if (f is! Io.File ||
          (!f.path.endsWith('.tif') && !f.path.endsWith('.tiff'))) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;

      test('$name', () {
        print(name);
        List<int> bytes = f.readAsBytesSync();
        Image image = new TiffDecoder().decodeImage(bytes);
        if (image == null) {
          throw new ImageException('Unable to decode TIFF Image: $name.');
        }

        List<int> png = new PngEncoder().encodeImage(image);
        new Io.File('out/tif/${name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);
      });
    }
  });
}
