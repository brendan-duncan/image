part of image_test;

void definePvrtcTests() {
  group('PVRTC', () {
    test('encode', () {
      List<int> bytes = new Io.File('res/tga/globe.tga').readAsBytesSync();
      Image image = new TgaDecoder().decodeImage(bytes);

      new Io.File('out/pvrtc/globe_before.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      var pvrtc = new PvrtcEncoder().encodeRgb4Bpp(image);

      Image decoded = new PvrtcDecoder().decodeRgb4Bpp(image.width, image.height, pvrtc);
      new Io.File('out/pvrtc/globe_after.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(decoded));

      List<int> pvr = new PvrtcEncoder().encodePvr(image);
      new Io.File('out/pvrtc/globe.pvr')
          ..createSync(recursive: true)
          ..writeAsBytesSync(pvr);
    });

    test('decode', () {
      //var bytes = new Io.File('res/pvr/globe.pvr').readAsBytesSync();
    });
  });
}
