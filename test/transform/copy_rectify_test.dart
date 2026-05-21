import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

/// Returns the four corner [Point]s of [img] as (TL, TR, BL, BR).
List<Point> _corners(Image img) {
  final w = img.width.toDouble();
  final h = img.height.toDouble();
  return [
    Point(),               // (0, 0) — top-left
    Point(w - 1),          // (w-1, 0) — top-right
    Point()..y = h - 1,    // (0, h-1) — bottom-left
    Point(w - 1, h - 1),
  ];
}

void main() {
  group('Transform', () {
    test('copyRectify', () {
      final img = decodeJpg(
        File('test/_data/jpg/oblique.jpg').readAsBytesSync(),
      )!;

      final i0 = copyRectify(
        img,
        topLeft: Point(16, 32),
        topRight: Point(79, 39),
        bottomLeft: Point(16, 151),
        bottomRight: Point(108, 141),
        interpolation: Interpolation.cubic,
      );

      File('$testOutputPath/transform/copyRectify.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    // Rectifying with the four actual image corners is approximately identity.
    test('rectify with actual corners is approximately identity', () {
      final src = quadrantImage(16, 16);
      final c = _corners(src);
      // nearest interpolation (the default) keeps pixel values exact.
      final result = copyRectify(
        src,
        topLeft: c[0],
        topRight: c[1],
        bottomLeft: c[2],
        bottomRight: c[3],
      );
      // With identity corners the result should be pixel-equal to the source.
      expectImagesClose(result, src);
    });

    // Result has the same dimensions as the source when no toImage is given.
    test('result dimensions match source', () {
      final src = solidImage(20, 30, ColorRgb8(100, 150, 200));
      final c = _corners(src);
      final result = copyRectify(
        src,
        topLeft: c[0],
        topRight: c[1],
        bottomLeft: c[2],
        bottomRight: c[3],
      );
      expect(result.width, equals(src.width));
      expect(result.height, equals(src.height));
    });

    // copyRectify does not mutate the source image.
    test('copyRectify does not mutate source', () {
      final src = quadrantImage(16, 16);
      final orig = src.clone();
      final c = _corners(src);
      copyRectify(
        src,
        topLeft: c[0],
        topRight: c[1],
        bottomLeft: c[2],
        bottomRight: c[3],
      );
      testImageEquals(src, orig);
    });

    // Providing a toImage target puts pixels into that image and returns it.
    test('toImage target is used and returned', () {
      final src = solidImage(8, 8, ColorRgb8(255, 0, 0));
      final target = Image(width: 8, height: 8);
      final c = _corners(src);
      final result = copyRectify(
        src,
        topLeft: c[0],
        topRight: c[1],
        bottomLeft: c[2],
        bottomRight: c[3],
        toImage: target,
      );
      // The returned object should be the same target instance.
      expect(identical(result, target), isTrue);
      // And it should be filled with the source colour.
      expectSolidColor(result, ColorRgb8(255, 0, 0));
    });
  });
}
