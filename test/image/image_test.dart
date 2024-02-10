import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Image', () {
    test('empty', () {
      final i0 = Image.empty();
      expect(i0.isValid, equals(false));

      final i1 = Image.empty();
      expect(i1.isValid, equals(false));
    });

    test('rowStride', () {
      for (final format in Format.values) {
        final img = Image(width: 10, height: 1, format: format);
        expect(img.rowStride, getRowStride(10, 3, format));
      }
    });

    test('fromResized', () {
      final i1 =
          Image(width: 20, height: 20, withPalette: true, numChannels: 4);

      i1
        ..addFrame(Image(width: 20, height: 20, palette: i1.palette))
        ..addFrame(Image(width: 20, height: 20, palette: i1.palette));

      for (var i = 0; i < 256; ++i) {
        i1.palette?.setRgba(i, i, i, i, i);
      }

      final i2 = Image.fromResized(i1, width: 10, height: 10);

      for (final img in i2.frames) {
        for (var i = 0; i < 256; ++i) {
          expect(img.palette?.get(i, 0), equals(i));
          expect(img.palette?.get(i, 1), equals(i));
          expect(img.palette?.get(i, 2), equals(i));
          expect(img.palette?.get(i, 3), equals(i));
        }
      }
    });

    test('fromBytes', () {
      const w = 256;
      const h = 256;
      const w2 = 300;
      const stride = w2 * 3;
      final bytes = Uint8List(h * stride);
      for (var y = 0, i = 0; y < h; ++y) {
        for (var x = 0; x < w2; ++x) {
          bytes[i++] = x < 256 ? x : 255;
          bytes[i++] = x < 256 ? y : 0;
          bytes[i++] = x < 256 ? 0 : 255;
        }
      }

      final img = Image.fromBytes(
          width: w, height: h, bytes: bytes.buffer, rowStride: stride);
      expect(img.width, equals(w));
      expect(img.height, equals(h));
      expect(img.numChannels, equals(3));
      for (final p in img) {
        expect(p.r, equals(p.x));
        expect(p.g, equals(p.y));
        expect(p.b, equals(0));
      }

      final img2 = Image.fromBytes(
          width: w,
          height: h,
          bytes: bytes.buffer,
          rowStride: stride,
          order: ChannelOrder.bgr);
      expect(img.width, equals(w));
      expect(img.height, equals(h));
      expect(img.numChannels, equals(3));
      for (final p in img2) {
        expect(p.r, equals(0));
        expect(p.g, equals(p.y));
        expect(p.b, equals(p.x));
      }

      img2.remapChannels(ChannelOrder.bgr);
      for (final p in img2) {
        expect(p.r, equals(p.x));
        expect(p.g, equals(p.y));
        expect(p.b, equals(0));
      }
    });

    test('fromBytes order', () {
      const w = 256;
      const h = 256;
      const w2 = 300;
      const stride = w2 * 4;
      final bytes = Uint8List(h * stride);
      for (var y = 0, i = 0; y < h; ++y) {
        for (var x = 0; x < w2; ++x) {
          bytes[i++] = 255;
          bytes[i++] = 200;
          bytes[i++] = 128;
          bytes[i++] = 64;
        }
      }

      final img = Image.fromBytes(
          width: 256,
          height: 256,
          bytes: bytes.buffer,
          rowStride: stride,
          order: ChannelOrder.bgra);
      expect(img.width, equals(w));
      expect(img.height, equals(h));
      expect(img.numChannels, equals(4));
      for (final p in img) {
        expect(p.r, equals(128));
        expect(p.g, equals(200));
        expect(p.b, equals(255));
        expect(p.a, equals(64));
      }

      img.remapChannels(ChannelOrder.bgra);
      for (final p in img) {
        expect(p.r, equals(255));
        expect(p.g, equals(200));
        expect(p.b, equals(128));
        expect(p.a, equals(64));
      }
    });

    test('getPixel iterator', () {
      final i0 = Image(width: 10, height: 10);
      final p = i0.getPixel(0, 5);
      int x = 0;
      int y = 5;
      do {
        expect(x, equals(p.x));
        expect(y, equals(p.y));
        x++;
        if (x == 10) {
          x = 0;
          y++;
        }
      } while (p.moveNext());
    });

    test('getRange', () {
      final i0 = Image(width: 10, height: 10);
      int x = 0;
      int y = 0;
      final iter = i0.getRange(0, 0, 10, 10);
      while (iter.moveNext()) {
        expect(x, equals(iter.current.x));
        expect(y, equals(iter.current.y));
        x++;
        if (x == 10) {
          x = 0;
          y++;
        }
      }
    });

    test('convert', () async {
      final rgba8p = Image(
          width: 256, height: 256, numChannels: 4, withPalette: true)
        ..addFrame(
            Image(width: 256, height: 256, numChannels: 4, withPalette: true));

      for (final frame in rgba8p.frames) {
        for (var pi = 0; pi < frame.palette!.numColors; ++pi) {
          frame.palette!.setRgba(pi, pi, pi, pi, 255);
        }
        for (final p in frame) {
          p.index = ((frame.frameIndex * 10) + p.x) % 255;
        }
      }

      await encodeGifFile('$testOutputPath/image/convert_1.gif', rgba8p);

      final rgba8 = rgba8p.convert(numChannels: 4, alpha: 255);

      expect(rgba8.numFrames, equals(2));
      expect(rgba8.hasPalette, equals(false));
      expect(rgba8.numChannels, equals(4));
      expect(rgba8.frames[1].hasPalette, equals(false));
      expect(rgba8.frames[1].numChannels, equals(4));

      for (final frame in rgba8.frames) {
        for (final p in frame) {
          final v = ((frame.frameIndex * 10) + p.x) % 255;
          expect(p.r, equals(v));
          expect(p.g, equals(v));
          expect(p.b, equals(v));
          expect(p.a, equals(255));
        }
      }
    });

    test('alpha_bmp_1bpp', () async {
      final img = await decodePngFile('test/_data/png/alpha_bmp.png');
      final bg = Image(width: img!.width, height: img.height)
        ..clear(ColorRgb8(255, 255, 255));
      compositeImage(bg, img);
      final bpp1 = bg.convert(format: Format.uint1, numChannels: 1);
      await encodeBmpFile('$testOutputPath/bmp/alpha_bmp_cvt.bmp', bpp1);
    });

    test('GetBytes', () {
      final i1 = Image(width: 10, height: 10)..setPixelRgb(0, 0, 32, 64, 128);
      final b1 = i1.getBytes();
      expect(b1.length, equals(10 * 10 * 3));
      expect(b1[0], equals(32));
      expect(b1[1], equals(64));
      expect(b1[2], equals(128));
    });

    test('GetBytes rgb->argb', () {
      final i1 = Image(width: 1, height: 1)..setPixelRgb(0, 0, 32, 64, 128);
      final b1 = i1.getBytes(order: ChannelOrder.argb);
      expect(b1.length, equals(4));
      expect(b1[0], equals(255));
      expect(b1[1], equals(32));
      expect(b1[2], equals(64));
      expect(b1[3], equals(128));
    });
  });
}
