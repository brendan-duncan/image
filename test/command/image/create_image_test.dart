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
          File('$testOutputPath/cmd/createImage_1.png').existsSync(), isTrue);
      expect(
          File('$testOutputPath/cmd/createImage_2.png').existsSync(), isTrue);
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
  });
}
