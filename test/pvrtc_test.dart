import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('PVRTC', () {
    test('encode_rgb_4bpp', () {
      var bytes = File('test/res/tga/globe.tga').readAsBytesSync();
      var image = TgaDecoder().decodeImage(bytes);

      File('.dart_tool/out/pvrtc/globe_before.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      var pvrtc = PvrtcEncoder().encodeRgb4Bpp(image);

      var decoded =
          PvrtcDecoder().decodeRgb4bpp(image.width, image.height, pvrtc);
      File('.dart_tool/out/pvrtc/globe_after.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(decoded));

      var pvr = PvrtcEncoder().encodePvr(image);
      File('.dart_tool/out/pvrtc/globe.pvr')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pvr);
    });

    test('encode_rgba_4bpp', () {
      var bytes = File('test/res/png/alpha_edge.png').readAsBytesSync();
      var image = PngDecoder().decodeImage(bytes);

      File('.dart_tool/out/pvrtc/alpha_before.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      var pvrtc = PvrtcEncoder().encodeRgba4Bpp(image);

      var decoded =
          PvrtcDecoder().decodeRgba4bpp(image.width, image.height, pvrtc);
      File('.dart_tool/out/pvrtc/alpha_after.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(decoded));

      var pvr = PvrtcEncoder().encodePvr(image);
      File('.dart_tool/out/pvrtc/alpha.pvr')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pvr);
    });
  });

  group('PVR Decode', () {
    var dir = Directory('test/res/pvr');
    var files = dir.listSync();
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.pvr')) {
        continue;
      }
      var name = f.path.split(RegExp(r'(/|\\)')).last;
      test(name, () {
        List<int> bytes = (f as File).readAsBytesSync();
        var img = PvrtcDecoder().decodePvr(bytes);
        assert(img != null);
        File('.dart_tool/out/pvrtc/pvr_$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(img));
      });
    }
  });
}
