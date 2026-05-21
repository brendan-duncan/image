import 'package:image/image.dart';
import 'package:test/test.dart';

import '../../_test_util.dart';

void main() {
  group('Command', () {
    test('filter', () async {
      Command()
        ..decodeGifFile('test/_data/gif/cars.gif')
        ..filter(
          (image) => drawString(
            image,
            '${image.frameIndex}',
            font: arial14,
            x: 10,
            y: 10,
          ),
        )
        ..writeToFile('$testOutputPath/cmd/cars.gif')
        ..execute();
    });

    // The filter command applies a function to every pixel; the result
    // must match calling the same function directly on the same input.
    test('filter result matches direct function call', () async {
      final src = horizontalGradient(32, 16);

      // Apply grayscale via Command.
      final cmdResult = await (Command()
            ..image(src.clone())
            ..filter(grayscale))
          .getImage();

      // Apply grayscale directly.
      final direct = grayscale(src.clone());

      expect(cmdResult, isNotNull);
      testImageEquals(cmdResult!, direct);
    });

    // A filter that returns a new image (instead of the same one) is handled
    // correctly: the output image is the new image.
    test('filter that returns a new image is used as output', () async {
      final src = solidImage(8, 8, ColorRgb8(10, 20, 30));
      const newW = 4;
      const newH = 4;

      final result = await (Command()
            ..image(src)
            ..filter((img) => Image(width: newW, height: newH)))
          .getImage();

      expect(result, isNotNull);
      expect(result!.width, equals(newW));
      expect(result.height, equals(newH));
    });

    // A filter that mutates and returns the same image leaves it as the output.
    test('filter that mutates in-place is reflected in output', () async {
      final src = solidImage(8, 8, ColorRgb8(0, 0, 0));

      final result = await (Command()
            ..image(src.clone())
            ..filter((img) {
              // Paint every pixel red.
              for (final p in img) {
                p.setRgb(255, 0, 0);
              }
              return img;
            }))
          .getImage();

      expect(result, isNotNull);
      expectSolidColor(result!, ColorRgb8(255, 0, 0));
    });

    // Applying invert via Command.filter should match calling invert directly.
    test('filter invert matches direct invert call', () async {
      final src = quadrantImage(16, 16);

      final cmdResult = await (Command()
            ..image(src.clone())
            ..filter(invert))
          .getImage();

      final direct = invert(src.clone());

      expect(cmdResult, isNotNull);
      testImageEquals(cmdResult!, direct);
    });
  });
}
