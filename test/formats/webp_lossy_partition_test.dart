import 'dart:math';

import 'package:image/image.dart';
import 'package:image/src/formats/webp/vp8_config.dart';
import 'package:image/src/formats/webp/vp8_encoder.dart';
import 'package:image/src/formats/webp/vp8_yuv.dart';
import 'package:image/src/formats/webp/webp_container.dart';
import 'package:test/test.dart';

// Partition #0 holds every macroblock's modes and the format caps it at 512k,
// which only a picture of well over 100 megapixels reaches. The limit is
// lowered here so the same code paths run on a small one
void main() {
  group('WebP lossy partition #0', () {
    // Busy enough that the mode search wants 4x4 modes in most macroblocks
    Image noise(int w, int h) {
      final rnd = Random(7);
      final image = Image(width: w, height: h);
      for (final p in image) {
        p.setRgb(rnd.nextInt(256), rnd.nextInt(256), rnd.nextInt(256));
      }
      return image;
    }

    Image decode(VP8Encoder encoder) =>
        decodeWebP(buildRiff([WebPChunk('VP8 ', encoder.encode())]))!;

    const fullI4Bits = 256 * 16 * 16;

    test('a picture that fits codes in one pass with 4x4 modes on', () {
      final encoder = VP8Encoder(VP8Config(), importYuv(noise(64, 64)));
      decode(encoder);
      expect(encoder.enc.maxI4HeaderBits, equals(fullI4Bits));
      expect(encoder.enc.mbType, contains(0),
          reason: 'noise is expected to use 4x4 modes somewhere');
    });

    test('modes that overflow are coded again with fewer 4x4 bits', () {
      // 52 bytes over the headroom: too few for the first pass, enough once
      // 4x4 modes are held back
      final encoder = VP8Encoder(VP8Config(), importYuv(noise(64, 64)),
          partition0Limit: 2100);
      final decoded = decode(encoder);

      expect(encoder.enc.maxI4HeaderBits, lessThan(fullI4Bits));
      expect(encoder.enc.maxI4HeaderBits, greaterThan(0),
          reason: 'the retries stop as soon as the modes fit');
      expect(decoded.width, equals(64));
      expect(decoded.height, equals(64));
    });

    test('the retries go as far as turning 4x4 modes off', () {
      // Under the headroom no estimate fits, so only the floor stops them
      final encoder = VP8Encoder(VP8Config(), importYuv(noise(64, 64)),
          partition0Limit: 2047);
      final decoded = decode(encoder);

      expect(encoder.enc.maxI4HeaderBits, equals(0));
      expect(encoder.enc.mbType, everyElement(equals(1)),
          reason: 'with no bits left for 4x4 modes every macroblock is 16x16');
      expect(decoded.width, equals(64));
    });

    test('the retried picture decodes as closely as a normal one', () {
      final source = noise(64, 64);
      double error(Image decoded) {
        var sum = 0;
        for (final p in source) {
          final q = decoded.getPixel(p.x, p.y);
          sum += (p.r - q.r).abs().toInt() +
              (p.g - q.g).abs().toInt() +
              (p.b - q.b).abs().toInt();
        }
        return sum / (3 * 64 * 64);
      }

      final normal = error(decode(VP8Encoder(VP8Config(), importYuv(source))));
      final retried = error(decode(
          VP8Encoder(VP8Config(), importYuv(source), partition0Limit: 2047)));
      // 16x16 modes alone cost some quality, not the picture
      expect(retried, lessThan(normal * 1.5));
    });

    test('modes that cannot fit even as 16x16 fail cleanly', () {
      final encoder = VP8Encoder(VP8Config(), importYuv(noise(64, 64)),
          partition0Limit: 64);
      expect(encoder.encode, throwsA(isA<ImageException>()));
    });
  });
}
