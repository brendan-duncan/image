part of image_test;


void definePvrtcTests() {
  group('PVRTC', () {
    test('encode', () {
      Image image = new Image(64, 64);
      image.fill(getColor(100, 200, 255));

      // Encode the image to PVRTC
      var pvrtc = new PvrtcEncoder().encodeRgb4Bpp(image);

      Image decoded = new PvrtcDecoder().decodeRgb4Bpp(image.width, image.height, pvrtc);
      new Io.File('out/pvrtc/test.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(decoded));

      List<int> pvr = new PvrtcEncoder().encodePvr(image);
      new Io.File('out/pvrtc/test.pvr')
          ..createSync(recursive: true)
          ..writeAsBytesSync(pvr);
    });
  });
}
