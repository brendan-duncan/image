import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void pvrtcTest() {
  group('pvrtc', () {
    test('globe', () {
      final bytes = File('test/_data/pvr/globe.pvr').readAsBytesSync();
      final image = PvrtcDecoder().decodePvr(bytes)!;
      File('$testOutputPath/pvr/globe.pvr.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));
    });

    test('encode_rgb4bpp', () {
      final image = Image(256, 256);
      for (var p in image) {
        p.setColor(p.x, p.x, p.x);
      }

      File('$testOutputPath/pvr/rgb4bpp_before.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));

      final pvr = PvrtcEncoder().encodeRgb4bpp(image);
      File('$testOutputPath/pvr/rgb4bpp.pvr')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pvr);

      final decoded = PvrtcDecoder().decodeRgb4bpp(image.width,
          image.height, pvr);
      File('$testOutputPath/pvr/rgb4bpp.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(decoded));
    });

    test('encode_rgba_4bpp', () {
      final bytes = File('test/_data/png/alpha_edge.png').readAsBytesSync();
      final image = PngDecoder().decode(bytes)!;

      File('$testOutputPath/pvr/alpha_before.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      final pvrtc = PvrtcEncoder().encodeRgba4bpp(image);

      final decoded = PvrtcDecoder().decodeRgba4bpp(image.width, image.height,
          pvrtc);
      File('$testOutputPath/pvr/alpha_after.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(decoded));

      final pvr = PvrtcEncoder().encodePvr(image);
      File('$testOutputPath/pvr/alpha.pvr')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pvr);
    });

    group('decode', () {
      final dir = Directory('test/_data/pvr');
      final files = dir.listSync();
      for (var f in files.whereType<File>()) {
        if (!f.path.endsWith('.pvr')) {
          continue;
        }
        final name = f.uri.pathSegments.last;
        test(name, () {
          final bytes = f.readAsBytesSync();
          final img = PvrtcDecoder().decodePvr(bytes)!;
          File('$testOutputPath/pvr/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(encodePng(img));
        });
      }
    });
  });
}
