import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    group('gif', () {
      test('anim_palette', () async {
        final g1 = await decodeGifFile('test/_data/gif/anim_palette.gif');
        await encodeGifFile('$testOutputPath/gif/anim_palette.gif', g1!);
      });

      test('hand_anim', () async {
        final g1 = await decodeGifFile('test/_data/gif/hand_anim.gif');
        await encodeGifFile('$testOutputPath/gif/hand_anim.gif', g1!);
      });

      test('hand_anim resize', () async {
        final g1 = await decodeGifFile('test/_data/gif/hand_anim.gif');
        final g2 =
            copyResize(g1!, width: g1.width ~/ 2, height: g1.height ~/ 2);
        for (var f in g2.frames) {
          final p1 = g1.frames[f.frameIndex].getPixel(0, 0);
          final p2 = f.getPixel(0, 0);
          expect(p1, equals(p2));
          final g3 = encodeGif(f, singleFrame: true);
          File('$testOutputPath/gif/hand_${f.frameIndex}.gif')
            ..createSync(recursive: true)
            ..writeAsBytesSync(g3);
        }
        await encodeGifFile('$testOutputPath/gif/hand_anim_resize.gif', g2);
      });

      test('transparencyAnim', () async {
        final g1 = await decodePngFile('test/_data/png/g1.png');
        final g2 = await decodePngFile('test/_data/png/g2.png');
        final g3 = await decodePngFile('test/_data/png/g3.png');
        g1!.addFrame(g2);
        g1.addFrame(g3);
        await encodeGifFile('$testOutputPath/gif/transparencyAnim.gif', g1);
      });

      test('cmd', () async {
        await (Command()
              ..decodeGifFile('test/_data/gif/cars.gif')
              ..copyResize(width: 64)
              ..encodeGifFile('$testOutputPath/gif/cars_cmd.gif'))
            .execute();
      });

      test('convert animated', () async {
        final anim = await decodeGifFile('test/_data/gif/cars.gif');
        final rgba8 =
            anim!.convert(format: Format.uint8, numChannels: 4, alpha: 255);
        expect(rgba8.numFrames, equals(anim.numFrames));
        for (final frame in rgba8.frames) {
          await encodePngFile(
              '$testOutputPath/gif/cars_${frame.frameIndex}.png', frame,
              singleFrame: true);
        }
        await encodePngFile('$testOutputPath/gif/cars.png', rgba8);
      });

      final dir = Directory('test/_data/gif');
      final files = dir.listSync();
      for (var f in files.whereType<File>()) {
        if (!f.path.endsWith('.gif')) {
          continue;
        }

        final name = f.uri.pathSegments.last;
        test(name, () {
          final bytes = f.readAsBytesSync();
          final anim = GifDecoder().decode(bytes);
          expect(anim, isNotNull);

          if (anim != null) {
            final gif = encodeGif(anim);
            if (anim.length > 1) {
              File('$testOutputPath/gif/${name}_anim.gif')
                ..createSync(recursive: true)
                ..writeAsBytesSync(gif);
            }

            for (var frame in anim.frames) {
              final gif = encodeGif(frame, singleFrame: true);
              File('$testOutputPath/gif/${name}_${frame.frameIndex}.gif')
                ..createSync(recursive: true)
                ..writeAsBytesSync(gif);
            }

            final a2 = decodeGif(gif)!;
            expect(a2, isNotNull);
            expect(a2.length, equals(anim.length));
            expect(a2.width, equals(anim.width));
            expect(a2.height, equals(anim.height));
            for (var frame in anim.frames) {
              final i2 = a2.frames[frame.frameIndex];
              for (final p in frame) {
                final p2 = i2.getPixel(p.x, p.y);
                expect(p, equals(p2));
              }
            }
          }
        });
      }

      test('encodeAnimation', () {
        final anim = Image(width: 480, height: 120)..loopCount = 10;
        for (var i = 0; i < 10; i++) {
          final image = i == 0 ? anim : anim.addFrame();
          drawString(image, i.toString(), font: arial48, x: 100, y: 60);
        }

        final gif = encodeGif(anim);
        File('$testOutputPath/gif/encodeAnimation.gif')
          ..createSync(recursive: true)
          ..writeAsBytesSync(gif);

        final anim2 = GifDecoder().decode(gif)!;
        expect(anim2.numFrames, equals(10));
        expect(anim2.loopCount, equals(10));
      });

      test('encodeAnimation with variable FPS', () {
        final anim = Image(width: 480, height: 120);
        for (var i = 1; i <= 3; i++) {
          final image = i == 1 ? anim : anim.addFrame()
            ..frameDuration = i * 1000;
          drawString(image, 'This frame is $i second(s) long',
              font: arial24, x: 50, y: 50);
        }

        const name = 'encodeAnimation_variable_fps';
        final gif = encodeGif(anim);
        File('$testOutputPath/gif/$name.gif')
          ..createSync(recursive: true)
          ..writeAsBytesSync(gif);

        final anim2 = GifDecoder().decode(gif)!;
        expect(anim2.numFrames, equals(3));
        expect(anim2.loopCount, equals(0));
        expect(anim2.frames[0].frameDuration, equals(1000));
        expect(anim2.frames[1].frameDuration, equals(2000));
        expect(anim2.frames[2].frameDuration, equals(3000));
      });

      test('encode_small_gif', () {
        final image =
            decodeGif(File('test/_data/gif/buck_24.gif').readAsBytesSync())!;
        final resized = copyResize(image, width: 16, height: 16);
        final gif = encodeGif(resized);
        File('$testOutputPath/gif/encode_small_gif.gif')
          ..createSync(recursive: true)
          ..writeAsBytesSync(gif);
      });
    });
  });
}
