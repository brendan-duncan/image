part of image_test;

void definePsdTests() {
  List<int> layers_psd = new Io.File('res/psd/layers.psd').readAsBytesSync();

  group('PSD', () {
    test('isValid', () {
      PsdDecoder psd = new PsdDecoder();
      expect(psd.isValidFile(layers_psd), equals(true));
    });

    test('startDecode', () {
      PsdDecoder psd = new PsdDecoder();
      PsdInfo info = psd.startDecode(layers_psd);

      expect(info.width, equals(512));
      expect(info.height, equals(256));
      expect(info.channels, equals(3));
      expect(info.depth, equals(8));
      expect(info.colorMode, equals(3));
    });

    test('decodeImage', () {
      PsdDecoder psd = new PsdDecoder();
      Image image = psd.decodeImage(layers_psd);
      expect(image.width, equals(512));
      expect(image.height, equals(256));

      List<int> png = new PngEncoder().encodeImage(image);
      new Io.File('out/psd/layers.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);
    });
  });


}
