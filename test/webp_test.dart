part of image_test;

void defineWebPTests() {
  Io.File script = new Io.File(Io.Platform.script.toFilePath());
  String path = script.parent.path + '/res/webp';

  Io.Directory dir = new Io.Directory(path);
  List files = dir.listSync();

  /*Io.File file = new Io.File(path + '/1_webp_a.webp');
  List<int> bytes = file.readAsBytesSync();
  Image image = new WebPDecoder().decodeImage(bytes);
  print('${image.width} ${image.height}');*/

  group('WebP/getInfo', () {
    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.webp')) {
        return;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();

        WebPData data = new WebPDecoder().getInfo(bytes);
        if (data == null) {
          throw new ImageException('Unable to parse WebP info: $name.');
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

  group('WebP/decodeImage', () {
    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.webp')) {
        return;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();
        Image image = new WebPDecoder().decodeImage(bytes);
        if (image == null) {
          throw new ImageException('Unable to decode WebP Image: $name.');
        }

        List<int> png = new PngEncoder().encode(image);
        new Io.File('out/webp/${name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);
      });
    }
  });
}
