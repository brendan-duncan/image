part of image_test;


void defineWebPTests() {
  Io.File script = new Io.File(Io.Platform.script.toFilePath());
  String path = script.parent.path + '/res/webp';

  Io.Directory dir = new Io.Directory(path);
  List files = dir.listSync();

  group('WebP/getInfo', () {
    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.webp')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();

        WebPInfo data = new WebPDecoder().startDecode(bytes);
        if (data == null) {
          throw new ImageException('Unable to parse WebP info: $name.');
        }

        if (_webp_tests.containsKey(name)) {
          expect(data.format, equals(_webp_tests[name]['format']));
          expect(data.width, equals(_webp_tests[name]['width']));
          expect(data.height, equals(_webp_tests[name]['height']));
          expect(data.hasAlpha, equals(_webp_tests[name]['hasAlpha']));
          expect(data.hasAnimation, equals(_webp_tests[name]['hasAnimation']));
        }
      });
    }
  });

  /*List<int> bytes = new Io.File(path + '/1_webp_ll.webp')
                          .readAsBytesSync();
  Image image = new WebPDecoder().decodeImage(bytes);
  List<int> png = new PngEncoder().encode(image);
  new Io.File('out/webp/decode.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);*/

  /*Animation anim = new WebPDecoder().decodeAnimation(bytes);
  for (int i = 0; i < anim.numFrames; ++i) {
    AnimationFrame frame = anim[i];
    List<int> png = new PngEncoder().encode(frame.image);
    new Io.File('out/webp/comp_$i.png')
          ..writeAsBytesSync(png);
  }*/

  group('WebP/decodeImage', () {
    test('validate', () {
      Io.File file = new Io.File(path + '/2b.webp');
      List<int> bytes = file.readAsBytesSync();
      Image image = new WebPDecoder().decodeImage(bytes);
      List<int> png = new PngEncoder().encodeImage(image);
      new Io.File('out/webp/decode.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);

      // Validate decoding.
      file = new Io.File(path + '/2b.png');
      bytes = file.readAsBytesSync();
      Image debugImage = new PngDecoder().decodeImage(bytes);
      bool found = false;
      for (int y = 0; y < debugImage.height && !found; ++y) {
        for (int x = 0; x < debugImage.width; ++x) {
          int dc = debugImage.getPixel(x, y);
          int c = image.getPixel(x, y);
          expect(c, equals(dc));
        }
      }
    });

    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.webp')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();
        Image image = new WebPDecoder().decodeImage(bytes);
        if (image == null) {
          throw new ImageException('Unable to decode WebP Image: $name.');
        }

        List<int> png = new PngEncoder().encodeImage(image);
        new Io.File('out/webp/${name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);
      });
    }
  });
}


const Map _webp_tests = const {
'1.webp': const {
  'format': 1,
  'width': 550,
  'height': 368,
  'hasAlpha': false,
  'hasAnimation': false },
'1_webp_a.webp': const {
  'format': 1,
  'width': 400,
  'height': 301,
  'hasAlpha': true,
  'hasAnimation': false },
'1_webp_ll.webp': const {
    'format': 2,
    'width': 400,
    'height': 301,
    'hasAlpha': true,
    'hasAnimation': false },
'2.webp': const {
    'format': 1,
    'width': 550,
    'height': 404,
    'hasAlpha': false,
    'hasAnimation': false },
'2b.webp': const {
    'format': 1,
    'width': 75,
    'height': 55,
    'hasAlpha': false,
    'hasAnimation': false },
'2_webp_a.webp': const {
    'format': 1,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false },
'2_webp_ll.webp': const {
    'format': 2,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false },
'3.webp': const {
    'format': 1,
    'width': 1280,
    'height': 720,
    'hasAlpha': false,
    'hasAnimation': false },
'3_webp_a.webp': const {
    'format': 1,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false },
'3_webp_ll.webp': const {
    'format': 2,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false },
'4.webp': const {
    'format': 1,
    'width': 1024,
    'height': 772,
    'hasAlpha': false,
    'hasAnimation': false },
'4_webp_a.webp': const {
    'format': 1,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false },
'4_webp_ll.webp': const {
    'format': 2,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false },
'5.webp': const {
    'format': 1,
    'width': 1024,
    'height': 752,
    'hasAlpha': false,
    'hasAnimation': false },
'5_webp_a.webp': const {
    'format': 1,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false },
'5_webp_ll.webp': const {
    'format': 2,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false },
'BladeRunner.webp': const {
    'format': 3,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true },
'BladeRunner_lossy.webp': const {
    'format': 3,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true },
'Contact.webp': const {
    'format': 3,
    'width': 500,
    'height': 219,
    'hasAlpha': true,
    'hasAnimation': true },
'Contact_lossy.webp': const {
    'format': 3,
    'width': 500,
    'height': 219,
    'hasAlpha': true,
    'hasAnimation': true },
'GenevaDrive.webp': const {
    'format': 3,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true },
'GenevaDrive_lossy.webp': const {
    'format': 3,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true },
'red.webp': const {
    'format': 1,
    'width': 32,
    'height': 32,
    'hasAlpha': false,
    'hasAnimation': false },
'SteamEngine.webp': const {
    'format': 3,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true },
'SteamEngine_lossy.webp': const {
    'format': 3,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true }
};
