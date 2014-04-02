part of image_test;

void definePsdTests() {
  List<int> layers_psd = new Io.File('res/psd/layers.psd').readAsBytesSync();

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
  });
}
