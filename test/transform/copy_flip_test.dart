import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('copyFlip', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;

      final ih = copyFlip(img, direction: FlipDirection.horizontal);
      expect(ih.numChannels, equals(ih.numChannels));
      File('$testOutputPath/transform/copyFlip_h.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(ih));

      final iv = copyFlip(img, direction: FlipDirection.vertical);
      expect(iv.numChannels, equals(ih.numChannels));
      File('$testOutputPath/transform/copyFlip_v.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(iv));

      final ib = copyFlip(img, direction: FlipDirection.both);
      expect(ib.numChannels, equals(ih.numChannels));
      File('$testOutputPath/transform/copyFlip_b.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(ib));
    });

    // copyFlip returns a NEW image and does not mutate the source.
    test('copyFlip does not mutate the source image', () {
      final src = quadrantImage(16, 16);
      final orig = src.clone();
      copyFlip(src, direction: FlipDirection.horizontal);
      testImageEquals(src, orig);
    });

    // Flipping horizontally twice is an involution — result equals the source.
    test('horizontal flip twice restores the original', () {
      final src = quadrantImage(16, 16);
      final flippedTwice = copyFlip(
        copyFlip(src, direction: FlipDirection.horizontal),
        direction: FlipDirection.horizontal,
      );
      testImageEquals(flippedTwice, src);
    });

    // Flipping vertically twice is an involution.
    test('vertical flip twice restores the original', () {
      final src = quadrantImage(16, 16);
      final flippedTwice = copyFlip(
        copyFlip(src, direction: FlipDirection.vertical),
        direction: FlipDirection.vertical,
      );
      testImageEquals(flippedTwice, src);
    });

    // Flipping both axes twice is an involution.
    test('both-axis flip twice restores the original', () {
      final src = quadrantImage(16, 16);
      final flippedTwice = copyFlip(
        copyFlip(src, direction: FlipDirection.both),
        direction: FlipDirection.both,
      );
      testImageEquals(flippedTwice, src);
    });

    // On a quadrant image, a horizontal flip swaps left and right quadrants.
    // top-left (red) should move to the top-right corner, and vice-versa.
    test('horizontal flip swaps left/right quadrants', () {
      // quadrantImage default: TL=red, TR=green, BL=blue, BR=yellow
      final src = quadrantImage(16, 16);
      final flipped = copyFlip(src, direction: FlipDirection.horizontal);

      // After horizontal flip, top-left corner pixel should be green (was TR).
      final topLeft = flipped.getPixel(0, 0);
      expect(topLeft.r, equals(0), reason: 'TL red after h-flip');
      expect(topLeft.g, equals(255), reason: 'TL green after h-flip');
      expect(topLeft.b, equals(0), reason: 'TL blue after h-flip');

      // Top-right corner pixel should be red (was TL).
      final topRight = flipped.getPixel(15, 0);
      expect(topRight.r, equals(255), reason: 'TR red after h-flip');
      expect(topRight.g, equals(0), reason: 'TR green after h-flip');
      expect(topRight.b, equals(0), reason: 'TR blue after h-flip');
    });

    // On a quadrant image, a vertical flip swaps top and bottom quadrants.
    test('vertical flip swaps top/bottom quadrants', () {
      final src = quadrantImage(16, 16);
      final flipped = copyFlip(src, direction: FlipDirection.vertical);

      // After vertical flip, top-left corner should be blue (was BL).
      final topLeft = flipped.getPixel(0, 0);
      expect(topLeft.r, equals(0), reason: 'TL red after v-flip');
      expect(topLeft.g, equals(0), reason: 'TL green after v-flip');
      expect(topLeft.b, equals(255), reason: 'TL blue after v-flip');

      // Bottom-left corner should be red (was TL).
      final bottomLeft = flipped.getPixel(0, 15);
      expect(bottomLeft.r, equals(255), reason: 'BL red after v-flip');
      expect(bottomLeft.g, equals(0), reason: 'BL green after v-flip');
      expect(bottomLeft.b, equals(0), reason: 'BL blue after v-flip');
    });

    // Flipping both axes is equivalent to horizontal then vertical.
    test('both flip equals horizontal then vertical flip', () {
      final src = quadrantImage(16, 16);
      final bothFlip = copyFlip(src, direction: FlipDirection.both);
      final hvFlip = copyFlip(
        copyFlip(src, direction: FlipDirection.horizontal),
        direction: FlipDirection.vertical,
      );
      testImageEquals(bothFlip, hvFlip);
    });

    // Dimensions are preserved for all flip directions.
    test('copyFlip preserves image dimensions', () {
      final src = quadrantImage(20, 10);
      for (final dir in FlipDirection.values) {
        final result = copyFlip(src, direction: dir);
        expect(result.width, equals(src.width),
            reason: 'width for $dir');
        expect(result.height, equals(src.height),
            reason: 'height for $dir');
      }
    });
  });
}
