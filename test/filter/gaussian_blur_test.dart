import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('gaussianBlur', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      gaussianBlur(i0, radius: 10);
      File('$testOutputPath/filter/gaussianBlur.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));
      expect(i0.numChannels, equals(orig.numChannels));

      // Blurring keeps the overall brightness, lowers the variance and
      // removes most of the pixel-to-pixel detail.
      expect(imageMean(i0), closeTo(imageMean(orig), 2));
      expect(imageVariance(i0), lessThan(imageVariance(orig)));
      double detail(Image img) {
        var sum = 0.0;
        for (var y = 0; y < img.height; ++y) {
          for (var x = 1; x < img.width; ++x) {
            final a = img.getPixel(x - 1, y);
            final b = img.getPixel(x, y);
            sum += (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs();
          }
        }
        return sum;
      }

      expect(detail(i0), lessThan(detail(orig) / 4));

      // A single bright dot spreads into a symmetric, center-peaked blob.
      final dot = Image(width: 21, height: 21)..setPixelRgb(10, 10, 255, 0, 0);
      gaussianBlur(dot, radius: 3);
      final peak = dot.getPixel(10, 10).r;
      expect(peak, greaterThan(0));
      expect(peak, lessThan(255));
      expect(dot.getPixel(11, 10).r, greaterThan(0));
      expect(dot.getPixel(11, 10).r, lessThan(peak));
      expect(dot.getPixel(12, 10).r, lessThan(dot.getPixel(11, 10).r));
      expect(dot.getPixel(9, 10).r, equals(dot.getPixel(11, 10).r));
      expect(dot.getPixel(10, 9).r, equals(dot.getPixel(10, 11).r));
      expect(dot.getPixel(10, 9).r, equals(dot.getPixel(11, 10).r));
      // Nothing spreads beyond the radius, or into other channels.
      expect(dot.getPixel(14, 10).r, equals(0));
      expect(dot.getPixel(10, 6).r, equals(0));
      for (final p in dot) {
        expect(p.g, equals(0));
        expect(p.b, equals(0));
      }
    });

    test('gaussianBlur preserves dimensions', () {
      final src = checkerImage(64, 48);
      final result = gaussianBlur(src.clone(), radius: 4);
      // dimensions must be unchanged after blur
      expect(result.width, equals(64));
      expect(result.height, equals(48));
    });

    test('gaussianBlur with radius 0 leaves image unchanged', () {
      final src = checkerImage(32, 32);
      // radius <= 0 is a no-op per source
      testImageEquals(gaussianBlur(src.clone(), radius: 0), src);
    });

    test('gaussianBlur on a solid-color image leaves it unchanged', () {
      final src = solidImage(32, 32, ColorRgb8(100, 150, 200));
      // A normalized Gaussian kernel on uniform input is a weighted average of
      // identical values.  Two-pass floating-point accumulation may introduce
      // up to ±2 LSB rounding error.
      expectImagesClose(gaussianBlur(src.clone(), radius: 5), src,
          tolerance: 2);
    });

    test('gaussianBlur reduces variance of a non-uniform image', () {
      final src = checkerImage(64, 64, cell: 4);
      final blurred = gaussianBlur(src.clone(), radius: 6);
      // blurring smooths out high-frequency content → lower variance
      expect(imageVariance(blurred), lessThan(imageVariance(src)));
    });

    test('gaussianBlur blurs every frame', () {
      final src = checkerImage(32, 32, cell: 4)
        ..addFrame(checkerImage(32, 32, cell: 4));
      final blurred = gaussianBlur(src.clone(), radius: 3);
      expect(blurred.numFrames, equals(2));
      for (final frame in blurred.frames) {
        expect(imageVariance(frame), lessThan(imageVariance(src)));
      }
    });

    test('gaussianBlur with a radius larger than the image', () {
      for (final format in [Format.uint8, Format.uint16]) {
        final src = Image(width: 6, height: 4, format: format)
          ..clear(ColorRgb8(100, 150, 200));
        final blurred = gaussianBlur(src.clone(), radius: 20);
        expectImagesClose(blurred, src, tolerance: 2);
      }
    });
  });
}
