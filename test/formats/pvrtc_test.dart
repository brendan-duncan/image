import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void PvrtcTest() {
  group('PVRTC', () {
    test('encode_rgb_4bpp', () {
      //final bytes = File('test/data/tga/globe.tga').readAsBytesSync();
      //final image = decodeTga(bytes)!;
      final image = Image(256, 256, numChannels: 4);
      for (var p in image) {
        p.setColor(p.x, p.x, p.x);
      }

      File('$tmpPath/out/pvrtc/globe_before.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      final pvrtc = PvrtcEncoder().encodeRgb4Bpp(image);

      final decoded = PvrtcDecoder().decodeRgb4bpp(image.width, image.height,
          pvrtc);
      File('$tmpPath/out/pvrtc/globe_after.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(decoded));

      final pvr = PvrtcEncoder().encodePvr(image);
      File('$tmpPath/out/pvrtc/globe.pvr')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pvr);
    });

    /*test('encode_rgba_4bpp', () {
      final bytes = File('test/data/png/alpha_edge.png').readAsBytesSync();
      final image = PngDecoder().decodeImage(bytes)!;

      File('$tmpPath/out/pvrtc/alpha_before.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      final pvrtc = PvrtcEncoder().encodeRgba4Bpp(image);

      final decoded = PvrtcDecoder().decodeRgba4bpp(image.width, image.height,
          pvrtc);
      File('$tmpPath/out/pvrtc/alpha_after.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(decoded));

      final pvr = PvrtcEncoder().encodePvr(image);
      File('$tmpPath/out/pvrtc/alpha.pvr')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pvr);
    });
  });

  group('decode', () {
    final dir = Directory('test/data/pvr');
    final files = dir.listSync();
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.pvr')) {
        continue;
      }
      final name = f.uri.pathSegments.last;
      test(name, () {
        final bytes = f.readAsBytesSync();
        final img = PvrtcDecoder().decodePvr(bytes)!;
        File('$tmpPath/out/pvrtc/pvr_$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(img));
      });
    }*/
  });
}
