part of image_test;

void definePvrtcTests() {
  group('PVRTC', () {
    test('encode_rgb_4bpp', () {
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

    test('encode_rgba_4bpp', () {
      List<int> bytes = new Io.File('res/png/alpha_edge.png').readAsBytesSync();
      Image image = new PngDecoder().decodeImage(bytes);

      new Io.File('out/pvrtc/alpha_before.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      var pvrtc = new PvrtcEncoder().encodeRgba4Bpp(image);

      Image decoded = new PvrtcDecoder().decodeRgba4Bpp(image.width, image.height, pvrtc);
      new Io.File('out/pvrtc/alpha_after.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(decoded));

      List<int> pvr = new PvrtcEncoder().encodePvr(image);
      new Io.File('out/pvrtc/alpha.pvr')
          ..createSync(recursive: true)
          ..writeAsBytesSync(pvr);
    });
  });
}
