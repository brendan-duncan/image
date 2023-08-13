import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    for (ExpandCanvasPosition position in ExpandCanvasPosition.values) {
      test('copyExpandCanvas - $position', () {
        final img =
            decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;

        final expandedCanvas = copyExpandCanvas(
          img,
          newWidth: img.width * 2,
          newHeight: img.height * 2,
          position: position,
          backgroundColor: ColorRgb8(255, 255, 255),
        );

        File('$testOutputPath/transform/copyExpandCanvas_$position.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(expandedCanvas));
      });
    }

    // Test with default parameters
    test('copyExpandCanvas - default parameters', () {
      final img =
          decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;

      final expandedCanvas = copyExpandCanvas(
        img,
        newWidth: img.width * 2,
        newHeight: img.height * 2,
      );

      File('$testOutputPath/transform/copyExpandCanvas_default.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(expandedCanvas));
    });

    // Test with toImage parameter
    test('copyExpandCanvas - with toImage', () {
      final img =
          decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;

      final toImage = Image(width: img.width * 2, height: img.height * 2);

      final expandedCanvas = copyExpandCanvas(
        img,
        newWidth: img.width * 2,
        newHeight: img.height * 2,
        toImage: toImage,
      );

      File('$testOutputPath/transform/copyExpandCanvas_toImage.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(expandedCanvas));
    });

    // Test with only padding parameter
    test('copyExpandCanvas - with padding', () {
      final img =
          decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;

      final expandedCanvas = copyExpandCanvas(
        img,
        padding: 50,
      );

      File('$testOutputPath/transform/copyExpandCanvas_padding.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(expandedCanvas));
    });

    // Test with both new dimensions and padding parameters
    test('copyExpandCanvas - with new dimensions and padding', () {
      final img =
          decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!;

      expect(
        () => copyExpandCanvas(
          img,
          newWidth: img.width * 2,
          newHeight: img.height * 2,
          padding: 50,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
