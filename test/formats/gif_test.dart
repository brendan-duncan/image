import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void GifTest() {
  group('GIF', () {
    final dir = Directory('test/data/gif');
    final files = dir.listSync();
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.gif')) {
        continue;
      }

      final name = f.uri.pathSegments.last;
      test(name, () {
        final bytes = f.readAsBytesSync();
        final anim = GifDecoder().decodeAnimation(bytes);
        expect(anim, isNotNull);

        if (anim != null) {
          final gif = encodeGifAnimation(anim);
          if (anim.length > 1) {
            File('$tmpPath/out/gif/${name}_anim.gif')
              ..createSync(recursive: true)
              ..writeAsBytesSync(gif);
          }

          for (var frame in anim) {
            final gif = encodeGif(frame);
            File('$tmpPath/out/gif/${name}_${frame.frameInfo.index}.gif')
              ..createSync(recursive: true)
              ..writeAsBytesSync(gif);
          }

          final a2 = decodeGifAnimation(gif)!;
          expect(a2, isNotNull);
          expect(a2.length, equals(anim.length));
          expect(a2.width, equals(anim.width));
          expect(a2.height, equals(anim.height));
          for (var frame in anim) {
            final i2 = a2[frame.frameInfo.index];
            for (var p in frame) {
              var p2 = i2.getPixel(p.x, p.y);
              expect(p, equals(p2));
            }
          }
        }
      });
    }

    test('encodeAnimation', () {
      final anim = Animation();
      anim.loopCount = 10;
      for (var i = 0; i < 10; i++) {
        final image = Image(480, 120);
        drawString(image, arial48, 100, 60, i.toString());
        anim.addFrame(image);
      }

      final gif = encodeGifAnimation(anim);
      File('$tmpPath/out/gif/encodeAnimation.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gif);

      final anim2 = GifDecoder().decodeAnimation(gif)!;
      expect(anim2.length, equals(10));
      expect(anim2.loopCount, equals(10));
    });

    test('encodeAnimation with variable FPS', () {
      final anim = Animation();
      for (var i = 1; i <= 3; i++) {
        final image = Image(480, 120);
        image.frameInfo.duration = i * 1000;
        drawString(image, arial24, 50, 50, 'This frame is $i second(s) long');
        anim.addFrame(image);
      }

      final gif = encodeGifAnimation(anim);
      File('$tmpPath/out/gif/encodeAnimation_variable_fps.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gif);

      final anim2 = GifDecoder().decodeAnimation(gif)!;
      expect(anim2.length, equals(3));
      expect(anim2.loopCount, equals(0));
      expect(anim2[0].frameInfo.duration, equals(1000));
      expect(anim2[1].frameInfo.duration, equals(2000));
      expect(anim2[2].frameInfo.duration, equals(3000));
    });

    test('encode_small_gif', () {
      final image = decodeGif(
          File('test/data/gif/buck_24.gif').readAsBytesSync())!;
      final resized = copyResize(image, width: 16, height: 16);
      final gif = encodeGif(resized);
      File('$tmpPath/out/gif/encode_small_gif.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gif);
    });
  });
}
