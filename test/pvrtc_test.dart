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

      Image decoded = new PvrtcDecoder().decodeRgb4bpp(image.width, image.height, pvrtc);
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

      Image decoded = new PvrtcDecoder().decodeRgba4bpp(image.width, image.height, pvrtc);
      new Io.File('out/pvrtc/alpha_after.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(decoded));

      List<int> pvr = new PvrtcEncoder().encodePvr(image);
      new Io.File('out/pvrtc/alpha.pvr')
          ..createSync(recursive: true)
          ..writeAsBytesSync(pvr);
    });
  });

  group('PVR Decode', (){
    String path = script.parent.path;

    Io.Directory dir = new Io.Directory('res/pvr');
    List files = dir.listSync();
    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.pvr')) {
        continue;
      }
      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test(name, () {
        List<int> bytes = f.readAsBytesSync();
        Image img = new PvrtcDecoder().decodePvr(bytes);
        assert(img != null);
        new Io.File('out/pvrtc/pvr_$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(encodePng(img));
      });
    }
  });
}
