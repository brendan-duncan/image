import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../../_test_util.dart';

void main() {
  group('Command', () {
    test('createImage', () async {
      await (Command()
            ..createImage(width: 256, height: 256)
            ..filter((image) {
              for (final p in image) {
                p
                  ..r = p.x
                  ..g = p.y;
              }
              return image;
            })
            ..writeToFile('$testOutputPath/cmd/createImage_1.png')
            ..createImage(width: 128, height: 128)
            ..filter((image) {
              for (final p in image) {
                p
                  ..g = p.x
                  ..b = p.y;
              }
              return image;
            })
            ..writeToFile('$testOutputPath/cmd/createImage_2.png'))
          .execute();

      expect(
        File('$testOutputPath/cmd/createImage_1.png').existsSync(),
        isTrue,
      );
      expect(
        File('$testOutputPath/cmd/createImage_2.png').existsSync(),
        isTrue,
      );
    });

    test('Futures', () async {
      final image = Image(width: 256, height: 256);

      final List<Future<Uint8List>> resTask = [];
      const curW = 128;
      const curH = 128;
      for (var curY = 0; curY < image.height; curY += curH) {
        for (var curX = 0; curX < image.width; curX += curW) {
          final task = Future(() async {
            final cmd = Command()
              ..image(image) // This will copy the image to the isolate
              ..copyCrop(x: curX, y: curY, width: curW, height: curH)
              ..encodeJpg();
            // Execute the commands in an Isolate thread and wait for the
            // results.
            final result = await cmd.executeThread();
            // The resulting bytes of the last command
            return result.outputBytes!;
          });
          resTask.add(task);
        }
      }

      await Future.wait(resTask).then((value) {
        // 4 jpeg files with the cropped images
        expect(value.length, equals(4));
      });
    });

    // createImage produces an image with the requested dimensions and format.
    test('createImage yields correct dimensions', () async {
      final img =
          await (Command()..createImage(width: 40, height: 25)).getImage();
      expect(img, isNotNull);
      expect(img!.width, equals(40));
      expect(img.height, equals(25));
    });

    // Default format is uint8 with 3 channels.
    test('createImage default format is uint8 with 3 channels', () async {
      final img =
          await (Command()..createImage(width: 8, height: 8)).getImage();
      expect(img, isNotNull);
      expect(img!.format, equals(Format.uint8));
      expect(img.numChannels, equals(3));
    });

    // Explicit numChannels is respected.
    test('createImage respects numChannels', () async {
      final img = await (Command()
            ..createImage(width: 8, height: 8, numChannels: 4))
          .getImage();
      expect(img, isNotNull);
      expect(img!.numChannels, equals(4));
    });

    // createImage then fill: every pixel has the fill colour.
    test('createImage then fill produces a solid-colour image', () async {
      final img = await (Command()
            ..createImage(width: 10, height: 10)
            ..fill(color: ColorRgb8(100, 150, 200)))
          .getImage();
      expect(img, isNotNull);
      expectSolidColor(img!, ColorRgb8(100, 150, 200));
    });

    // A filter applied after createImage sees the new image (not a prior one).
    test('createImage in a chain resets to the new image', () async {
      // First image is 16x16 red, second is 8x8 green.
      final result = await (Command()
            ..createImage(width: 16, height: 16)
            ..fill(color: ColorRgb8(255, 0, 0))
            ..createImage(width: 8, height: 8)
            ..fill(color: ColorRgb8(0, 255, 0)))
          .getImage();

      // The final image should be the second createImage: 8x8 green.
      expect(result, isNotNull);
      expect(result!.width, equals(8));
      expect(result.height, equals(8));
      expectSolidColor(result, ColorRgb8(0, 255, 0));
    });
  });
}
