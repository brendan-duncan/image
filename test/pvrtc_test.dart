part of image_test;


void definePvrtcTests() {
  group('PVRTC', () {
    test('encode', () {
      Image image = new Image(64, 64);
      image.fill(getColor(100, 200, 255));

      // Encode the image to PVRTC
      List<int> pvrtc = new PvrtcEncoder().encodeRgb4Bpp(image);
      print(pvrtc.length);

      List<int> pvr = new PvrtcEncoder().encodePvr(image);
      new Io.File('out/test.pvr').writeAsBytesSync(pvr);
    });
  });
}
