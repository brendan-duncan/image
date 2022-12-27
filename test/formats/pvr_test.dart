import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void pvrTest() {
  group('pvrtc', () {
    test('globe', () {
      final bytes = File('test/_data/pvr/globe.pvr').readAsBytesSync();
      final image = PvrDecoder().decode(bytes)!;
      File('$testOutputPath/pvr/globe.pvr.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));
    });

    /*test('encode_rgba_4bpp', () {
      final bytes = File('test/_data/png/alpha_edge.png').readAsBytesSync();
      final image = PngDecoder().decode(bytes)!;

      File('$testOutputPath/pvr/alpha_before.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      final pvr = PvrEncoder().encode(image);

      final decoded = PvrDecoder().decode(image.width, image.height,
          pvr);
      File('$testOutputPath/pvr/alpha_after.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(decoded));

      final pvr = PvrEncoder().encodePvr(image);
      File('$testOutputPath/pvr/alpha.pvr')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pvr);
    });*/

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
          final img = PvrDecoder().decode(bytes)!;
          File('$testOutputPath/pvr/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(encodePng(img));
        });
      }
    });
  });
}
