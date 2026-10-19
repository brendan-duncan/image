import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('copyImageChannels', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!.convert(numChannels: 4);

      final maskImage = Image(width: 256, height: 256);
      fillCircle(
        maskImage,
        x: 128,
        y: 128,
        radius: 128,
        color: ColorRgb8(255, 255, 255),
      );

      copyImageChannels(
        i0,
        from: maskImage,
        scaled: true,
        alpha: Channel.luminance,
      );
      File('$testOutputPath/filter/copyImageChannels.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('copyImageChannels preserves dimensions', () {
      final dst = solidImage(16, 16, ColorRgb8(100, 150, 200), numChannels: 4);
      final from = solidImage(16, 16, ColorRgb8(10, 20, 30));
      copyImageChannels(dst, from: from, red: Channel.green);
      // Copying a channel must not resize the destination.
      expect(dst.width, equals(16));
      expect(dst.height, equals(16));
    });

    test('copyImageChannels returns the src image', () {
      final dst = solidImage(8, 8, ColorRgb8(100, 100, 100), numChannels: 4);
      final from = solidImage(8, 8, ColorRgb8(50, 50, 50));
      final result = copyImageChannels(dst, from: from, red: Channel.red);
      expect(identical(result, dst), isTrue);
    });

    test('copyImageChannels copies red channel from source', () {
      // dst has r=100; from has r=200.
      // After copying red from from, dst.r==200.
      final dst = solidImage(8, 8, ColorRgb8(100, 100, 100), numChannels: 4);
      final from = solidImage(8, 8, ColorRgb8(200, 50, 30));
      copyImageChannels(dst, from: from, red: Channel.red);
      for (final p in dst) {
        expect(p.r, equals(200),
            reason: 'red channel not copied at ${p.x},${p.y}');
        // green and blue are not specified, so they stay from dst (100).
        expect(p.g, equals(100),
            reason: 'green should be unchanged at ${p.x},${p.y}');
        expect(p.b, equals(100),
            reason: 'blue should be unchanged at ${p.x},${p.y}');
      }
    });

    test('copyImageChannels copies blue channel from source', () {
      // dst has b=50; from has b=180. After copying blue from from, dst.b==180.
      final dst = solidImage(8, 8, ColorRgb8(10, 20, 50), numChannels: 4);
      final from = solidImage(8, 8, ColorRgb8(90, 100, 180));
      copyImageChannels(dst, from: from, blue: Channel.blue);
      for (final p in dst) {
        expect(p.b, equals(180),
            reason: 'blue channel not copied at ${p.x},${p.y}');
        // red and green are unspecified, so they stay from dst.
        expect(p.r, equals(10),
            reason: 'red should be unchanged at ${p.x},${p.y}');
        expect(p.g, equals(20),
            reason: 'green should be unchanged at ${p.x},${p.y}');
      }
    });

    test('copyImageChannels with no channels specified is a no-op', () {
      // When no channel override is given, each channel retains dst's value.
      final dst = solidImage(8, 8, ColorRgb8(10, 20, 30), numChannels: 4);
      final orig = dst.clone();
      final from = solidImage(8, 8, ColorRgb8(200, 200, 200));
      copyImageChannels(dst, from: from);
      testImageEquals(dst, orig);
    });
  });
}
