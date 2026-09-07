import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('WebP animation', () {
    // Written by gif2webp: frame 1 is 80x80 at (80,40) and disposes, frame 2
    // is 40x40 elsewhere, so the vacated rectangle has to stay open. The
    // encoder here only writes whole canvas frames and cannot produce this
    final source = File('test/_data/webp/dispose_partial.webp');

    test('decode keeps what a partial frame did not dispose', () {
      final decoded = decodeWebP(source.readAsBytesSync())!;
      expect(decoded.numFrames, equals(3));
      final last = decoded.frames[2];

      // Inside the rectangle frame 1 vacated
      expect(last.getPixel(120, 80).a, equals(0),
          reason: 'the disposed rectangle must be cleared');

      // Outside it, where frame 0 has to survive
      final bg = last.getPixel(12, 12);
      expect([bg.r, bg.g, bg.b, bg.a], equals([40, 170, 70, 255]),
          reason: 'dispose must not reach outside the frame that asked for it');
    });

    test('a frame that cannot be decoded does not dispose in place of the '
        'frame before it', () {
      // One byte changed: frame 2's chunk tag reads VP9L, so only that frame
      // is lost while every chunk size stays valid. libwebp drops it and still
      // clears frame 1's rectangle
      final damaged = File('test/_data/webp/dispose_skipped_frame.webp');
      final decoded = decodeWebP(damaged.readAsBytesSync())!;

      expect(decoded.numFrames, equals(4));
      for (var i = 2; i < decoded.numFrames; i++) {
        expect(decoded.frames[i].getPixel(120, 80).a, equals(0),
            reason: 'frame $i still carries what frame 1 disposed');
      }
    });

    test('every frame knows its own index', () {
      // addFrame sets frameIndex before deciding whether to add, so frames[0]
      // handed in twice gets numbered 1. convolution and bumpToNormal address
      // a parallel frame list by this field and then hit the wrong frame
      for (final path in const [
        'test/_data/webp/dispose_partial.webp',
        'test/_data/webp/dispose_skipped_frame.webp',
      ]) {
        final decoded = decodeWebP(File(path).readAsBytesSync())!;
        expect([for (final f in decoded.frames) f.frameIndex],
            equals([for (var i = 0; i < decoded.numFrames; i++) i]),
            reason: path);
      }
    });

    test('decode then encode does not lose the background', () {
      final original = decodeWebP(source.readAsBytesSync())!;
      final again = decodeWebP(encodeWebP(original))!;

      expect(again.numFrames, equals(original.numFrames));
      for (var i = 0; i < again.numFrames; i++) {
        for (final at in const [
          [12, 12],
          [200, 140],
          [30, 30],
          [120, 80],
        ]) {
          final a = original.frames[i].getPixel(at[0], at[1]);
          final b = again.frames[i].getPixel(at[0], at[1]);
          expect([b.r, b.g, b.b, b.a], equals([a.r, a.g, a.b, a.a]),
              reason: 'frame $i at ${at[0]},${at[1]}');
        }
      }
    });
  });
}
