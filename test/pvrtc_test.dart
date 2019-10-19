import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('PVRTC', () {
    test('encode_rgb_4bpp', () {
      List<int> bytes = File('test/res/tga/globe.tga').readAsBytesSync();
      Image image = TgaDecoder().decodeImage(bytes);

      new File('out/pvrtc/globe_before.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      var pvrtc = PvrtcEncoder().encodeRgb4Bpp(image);

      Image decoded =
          PvrtcDecoder().decodeRgb4bpp(image.width, image.height, pvrtc);
      new File('out/pvrtc/globe_after.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(decoded));

      List<int> pvr = PvrtcEncoder().encodePvr(image);
      new File('out/pvrtc/globe.pvr')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pvr);
    });

    test('encode_rgba_4bpp', () {
      List<int> bytes = File('test/res/png/alpha_edge.png').readAsBytesSync();
      Image image = PngDecoder().decodeImage(bytes);

      new File('out/pvrtc/alpha_before.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      var pvrtc = PvrtcEncoder().encodeRgba4Bpp(image);

      Image decoded =
          PvrtcDecoder().decodeRgba4bpp(image.width, image.height, pvrtc);
      new File('out/pvrtc/alpha_after.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(decoded));

      List<int> pvr = PvrtcEncoder().encodePvr(image);
      new File('out/pvrtc/alpha.pvr')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pvr);
    });
  });

  group('PVR Decode', () {
    Directory dir = Directory('test/res/pvr');
    var files = dir.listSync();
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.pvr')) {
        continue;
      }
      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test(name, () {
        List<int> bytes = (f as File).readAsBytesSync();
        Image img = PvrtcDecoder().decodePvr(bytes);
        assert(img != null);
        new File('out/pvrtc/pvr_$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(img));
      });
    }
  });
}
