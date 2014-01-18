part of image_test;

void defineWebPTests() {
  group('WebP/getInfo', () {
    Io.File script = new Io.File(Io.Platform.script.toFilePath());
    String path = script.parent.path + '/res/webp';

    Io.Directory dir = new Io.Directory(path);
    List files = dir.listSync();
    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.webp')) {
        return;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();

        WebPFeatures features = new WebPDecoder().getInfo(bytes);
        if (features == null) {
          throw new ImageException('Unable to parse WebP info.');
        }

        print('$name');
        print('    format: ${features.format}');
        print('    width: ${features.width}');
        print('    height: ${features.height}');
        print('    format: ${features.format}');
        print('    hasAlpha: ${features.hasAlpha}');
        print('    hasAnimation: ${features.hasAnimation}');
      });
    }
  });
}
