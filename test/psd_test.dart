part of image_test;


void definePsdTests() {
  Io.File script = new Io.File(Io.Platform.script.toFilePath());
  String path = script.parent.path + '/res/psd';

  Io.Directory dir = new Io.Directory(path);
  List files = dir.listSync();

  group('PSD', () {
    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.psd')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test(name, () {
        print('Decoding $name');

        Image psd = new PsdDecoder().decodeImage(f.readAsBytesSync());

        if (psd != null) {
          List<int> outPng = new PngEncoder().encodeImage(psd);
          new Io.File('out/psd/$name.png')
                ..createSync(recursive: true)
                ..writeAsBytesSync(outPng);
        } else {
          throw 'Unable to decode $name';
        }
      });
    }
  });
}
