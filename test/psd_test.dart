part of image_test;


void definePsdTests() {
  Io.File script = new Io.File(Io.Platform.script.toFilePath());
  String path = script.parent.path + '/res/psd';

  Io.Directory dir = new Io.Directory(path);
  List files = dir.listSync();

  for (var f in files) {
    if (f is! Io.File || !f.path.endsWith('.psd')) {
      continue;
    }

    String name = f.path.split(new RegExp(r'(/|\\)')).last;
    print('Decoding $name');

    PsdDecoder psd = new PsdDecoder();
    Image img = psd.decodeImage(f.readAsBytesSync());

    if (img != null) {
      List<int> png = new PngEncoder().encodeImage(img);
      new Io.File('out/psd/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);
    } else {
      print('Unable to decode $name');
    }
  }

  //PsdDecoder psd = new PsdDecoder();
  //Image img = psd.decodeImage(new Io.File('res/psd/fence_01_01.psd').readAsBytesSync());
  /*PsdImage psdImg = psd.decodePsd(new Io.File('res/psd/fence_01_01.psd').readAsBytesSync());
  PsdLayer l = psdImg.layers[0];
  PsdChannel ch = l.getChannel(PsdChannel.ALPHA);
  Image img = new Image(l.width, l.height);
  var p = img.getBytes();
  for (int y = 0, si = 0, di = 0; y < l.height; ++y) {
    for (int x = 0; x < l.width; ++x, ++si) {
      int s = ch.data[si];
      p[di++] = s;
      p[di++] = s;
      p[di++] = s;
      p[di++] = 255;
    }
  }*/

  /*List<int> png = new PngEncoder().encodeImage(img);
  new Io.File('out/psd/fence_01_01.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);*/
  /*List<int> layers_psd = new Io.File('res/psd/layers.psd').readAsBytesSync();

  List<int> bytes = new Io.File('res/psd/layers.png').readAsBytesSync();
  Image pngImage = new PngDecoder().decodeImage(bytes);

  group('PSD', () {
    test('isValid', () {
      PsdDecoder psd = new PsdDecoder();
      expect(psd.isValidFile(layers_psd), equals(true));
    });

    test('startDecode', () {
      PsdDecoder psd = new PsdDecoder();
      PsdImage info = psd.startDecode(layers_psd);

      expect(info.width, equals(512));
      expect(info.height, equals(256));
      expect(info.channels, equals(3));
      expect(info.depth, equals(8));
      expect(info.colorMode, equals(3));
    });

    Image layerImage;
    test('decodeImage', () {
      PsdDecoder psd = new PsdDecoder();
      layerImage = psd.decodeImage(layers_psd);
      expect(layerImage.width, equals(pngImage.width));
      expect(layerImage.height, equals(pngImage.height));

      List<int> png = new PngEncoder().encodeImage(layerImage);
      new Io.File('out/psd/layers.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);
    });
  });*/
}
