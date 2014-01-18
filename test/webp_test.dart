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

        WebPData data = new WebPDecoder().getInfo(bytes);
        if (data == null) {
          throw new ImageException('Unable to parse WebP info.');
        }

        print('$name');
        print('    format: ${data.format}');
        print('    width: ${data.width}');
        print('    height: ${data.height}');
        print('    format: ${data.format}');
        print('    hasAlpha: ${data.hasAlpha}');
        print('    hasAnimation: ${data.hasAnimation}');
      });
    }
  });
}
