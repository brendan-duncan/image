import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:image/src/formats/webp/vp8l_encoder.dart';
import 'package:image/src/formats/webp/webp_container.dart';
import 'package:test/test.dart';

void main() {
  group('WebP animation', () {
    // The encoder only writes frames that replace the canvas, so a file that
    // asks for blending has to be built here
    Uint8List blendedAnimation(Color color) {
      final image = Image(width: 2, height: 2, numChannels: 4)..clear(color);
      final frame = [WebPChunk('VP8L', VP8LEncoder().encodeVP8L(image))];
      return buildRiff([
        WebPChunk('VP8X', vp8xChunkData(18, 2, 2)),
        WebPChunk('ANIM', animChunkData(0, 0, 0, 0, 0)),
        for (var i = 0; i < 2; i++)
          WebPChunk(
              'ANMF',
              anmfChunkData(
                  x: 0,
                  y: 0,
                  width: 2,
                  height: 2,
                  duration: 100,
                  clearToBackground: false,
                  blend: true,
                  frame: frame)),
      ]);
    }

    test('a translucent frame keeps its colour over the empty canvas', () {
      // Nothing under it to dilute the colour with
      final decoded =
          decodeWebP(blendedAnimation(ColorRgba8(200, 100, 50, 128)))!;
      final p = decoded.frames[0].getPixel(0, 0);
      expect([p.r, p.g, p.b, p.a], equals([200, 100, 50, 128]));
    });

    test('two translucent frames of one colour keep that colour', () {
      // 128 over 128 covers 192/255, and the colour cannot move
      final decoded =
          decodeWebP(blendedAnimation(ColorRgba8(200, 100, 50, 128)))!;
      final p = decoded.frames[1].getPixel(0, 0);
      expect(p.a, closeTo(192, 1));
      expect(p.r, closeTo(200, 1));
      expect(p.g, closeTo(100, 1));
      expect(p.b, closeTo(50, 1));
    });

    test('an opaque frame over a translucent one replaces it', () {
      // The case every gif2webp file exercises, and the reason nothing caught
      // the two above
      final decoded =
          decodeWebP(blendedAnimation(ColorRgba8(200, 100, 50, 255)))!;
      final p = decoded.frames[1].getPixel(0, 0);
      expect([p.r, p.g, p.b, p.a], equals([200, 100, 50, 255]));
    });

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

    test(
        'a frame that cannot be decoded does not dispose in place of the '
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
