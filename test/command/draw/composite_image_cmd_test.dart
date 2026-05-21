import 'package:image/image.dart';
import 'package:test/test.dart';

import '../../_test_util.dart';

void main() {
  group('Command', () {
    test('compositeImage', () {
      final fg = Command()
        ..decodeTgaFile('test/_data/tga/globe.tga')
        ..convert(numChannels: 4)
        ..filter((image) {
          for (final p in image) {
            if (p.r == 0 && p.g == 0 && p.b == 0) {
              p.a = 0;
            }
          }
          return image;
        });

      Command()
        ..decodePngFile('test/_data/png/buck_24.png')
        ..compositeImage(fg, dstX: 50, dstY: 50)
        ..writeToFile('$testOutputPath/cmd/compositeImage.png')
        ..execute();
    });

    // Compositing a solid-colour foreground over a background at a known
    // offset with BlendMode.direct writes the fg colour into that region.
    test('compositeImage writes fg pixels into the destination region',
        () async {
      // 4x4 blue foreground Command.
      final fgCmd = Command()
        ..createImage(width: 4, height: 4)
        ..fill(color: ColorRgb8(0, 0, 255));

      // Build a 16x16 red background image directly, then composite over it.
      final bg = solidImage(16, 16, ColorRgb8(255, 0, 0));
      final result = await (Command()
            ..image(bg)
            ..compositeImage(fgCmd, dstX: 6, dstY: 6, blend: BlendMode.direct))
          .getImage();

      expect(result, isNotNull);
      // A pixel inside the composited region should be blue.
      final inside = result!.getPixel(7, 7);
      expect(inside.r, equals(0), reason: 'r inside composite region');
      expect(inside.g, equals(0), reason: 'g inside composite region');
      expect(inside.b, equals(255), reason: 'b inside composite region');

      // A pixel outside the composited region should remain red.
      final outside = result.getPixel(0, 0);
      expect(outside.r, equals(255), reason: 'r outside composite region');
      expect(outside.g, equals(0), reason: 'g outside composite region');
      expect(outside.b, equals(0), reason: 'b outside composite region');
    });

    // The output image has the same dimensions as the destination (background).
    test('compositeImage preserves destination dimensions', () async {
      final fgCmd = Command()
        ..createImage(width: 5, height: 5)
        ..fill(color: ColorRgb8(255, 255, 0));

      final bg = solidImage(20, 30, ColorRgb8(128, 128, 128));
      final result = await (Command()
            ..image(bg)
            ..compositeImage(fgCmd))
          .getImage();

      expect(result, isNotNull);
      expect(result!.width, equals(20));
      expect(result.height, equals(30));
    });

    // Centred composite: the fg is placed at the centre of the background.
    test('compositeImage center flag places fg at center', () async {
      final fgCmd = Command()
        ..createImage(width: 4, height: 4)
        ..fill(color: ColorRgb8(255, 0, 255));

      // 16x16 green background; 4x4 fg centred → placed at (6,6)–(9,9).
      final bg = solidImage(16, 16, ColorRgb8(0, 255, 0));
      final result = await (Command()
            ..image(bg)
            ..compositeImage(fgCmd, blend: BlendMode.direct, center: true))
          .getImage();

      expect(result, isNotNull);
      final centre = result!.getPixel(7, 7);
      expect(centre.r, equals(255));
      expect(centre.b, equals(255));
    });
  });
}
