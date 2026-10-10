import 'dart:io';
import 'dart:math' show max, min;

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('compositeImage direct: region becomes source color', () {
      // Compositing a fully-opaque solid red src onto a blue dst with
      // BlendMode.direct must set every pixel in the destination rect to red.
      final dst = solidImage(32, 32, ColorRgb8(0, 0, 255));
      final src = solidImage(8, 8, ColorRgb8(255, 0, 0));
      compositeImage(dst, src, dstX: 4, dstY: 4, blend: BlendMode.direct);

      // pixels inside the destination rect are the source color (red)
      for (var y = 4; y < 12; y++) {
        for (var x = 4; x < 12; x++) {
          final p = dst.getPixel(x, y);
          expect(p.r, equals(255),
              reason: 'expected red at ($x,$y), got r=${p.r}');
          expect(p.g, equals(0),
              reason: 'expected red at ($x,$y), got g=${p.g}');
          expect(p.b, equals(0),
              reason: 'expected red at ($x,$y), got b=${p.b}');
        }
      }

      // pixels outside the destination rect remain the original blue
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 32; x++) {
          final p = dst.getPixel(x, y);
          expect(p.b, equals(255),
              reason: 'pixel outside rect ($x,$y) should remain blue');
          expect(p.r, equals(0),
              reason: 'pixel outside rect ($x,$y) should have r=0');
        }
      }
    });

    test('compositeImage direct: pixels outside dst rect are unchanged', () {
      // A solid white background with a small red composite in the center.
      final dst = solidImage(20, 20, ColorRgb8(255, 255, 255));
      final src = solidImage(4, 4, ColorRgb8(0, 0, 0));
      compositeImage(dst, src, dstX: 8, dstY: 8, blend: BlendMode.direct);

      // corner pixels were not touched
      final corner = dst.getPixel(0, 0);
      expect(corner.r, equals(255));
      expect(corner.g, equals(255));
      expect(corner.b, equals(255));

      // center pixel was overwritten
      final center = dst.getPixel(8, 8);
      expect(center.r, equals(0));
      expect(center.g, equals(0));
      expect(center.b, equals(0));
    });

    test('compositeImage2', () async {
      final mask = (await decodePngFile('test/_data/png/logo.png'))!;
      final fg = (await decodePngFile('test/_data/png/colors.png'))!;
      final bg = (await decodePngFile('test/_data/png/buck_24.png'))!;

      final orig = bg.clone();

      compositeImage(bg, fg, mask: mask);

      File('$testOutputPath/draw/compositeImage2.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(bg));

      // The opaque fg is mixed over bg by the mask luminance, looked up at the
      // destination position: bg stays where the mask is black or absent, fg
      // shows where it is white, and fg covers only its own 256 pixel width.
      // The default destination height is clamped to bg, so the taller fg is
      // squashed to fit rather than cropped.
      final fgScaleY = fg.height / bg.height;
      var shown = 0;
      var kept = 0;
      for (final p in bg) {
        final o = orig.getPixel(p.x, p.y);
        final m = p.x < fg.width
            ? mask.getPixelSafe(p.x, p.y).luminanceNormalized
            : 0;
        if (m > 0.99) {
          shown++;
        } else if (m == 0) {
          kept++;
        }
        final f = fg.getPixelSafe(p.x, (p.y * fgScaleY).toInt());
        for (var c = 0; c < 3; ++c) {
          expect(p[c], closeTo(o[c] + (f[c] - o[c]) * m, 1.5),
              reason: 'channel $c at ${p.x},${p.y}');
        }
      }
      expect(shown, greaterThan(0), reason: 'pixels fully masked in');
      expect(kept, greaterThan(0), reason: 'pixels masked out');
    });

    test('compositeImage large foreground', () {
      final i0 = Image(width: 256, height: 256);
      final i1 = Image(width: 512, height: 512, numChannels: 4);
      i0.clear(ColorRgba8(255, 0, 0, 255));
      for (final p in i1) {
        p
          ..r = p.x
          ..g = p.y
          ..a = p.y;
      }

      compositeImage(i0, i1, dstX: 50, dstY: 50, blend: BlendMode.direct);
    });

    test('compositeImage', () async {
      final i0 = Image(width: 256, height: 256);
      final i1 = Image(width: 256, height: 256, numChannels: 4);

      i0.clear(ColorRgba8(255, 0, 0, 255));
      for (final p in i1) {
        p
          ..r = p.x
          ..g = p.y
          ..a = p.y;
      }

      compositeImage(i0, i1, dstX: 50, dstY: 50, dstW: 100, dstH: 100);
      compositeImage(i0, i1, dstX: 100, dstY: 100, dstW: 100, dstH: 100);

      File('$testOutputPath/draw/compositeImage_1.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      // Each composite shrinks i1 to 100x100 at its offset and alpha blends
      // it (alpha = source row) over what is there; the red elsewhere is
      // untouched.
      for (final p in i0) {
        var r = 255.0;
        var g = 0.0;
        for (final d in [50, 100]) {
          final x = p.x - d;
          final y = p.y - d;
          if (x >= 0 && y >= 0 && x < 100 && y < 100) {
            final sx = (x * (256 / 100)).toInt();
            final sy = (y * (256 / 100)).toInt();
            final a = sy / 255;
            r = sx * a + r * (1 - a);
            g = sy * a + g * (1 - a);
          }
        }
        expect(p.r, closeTo(r, 2), reason: 'red at ${p.x},${p.y}');
        expect(p.g, closeTo(g, 2), reason: 'green at ${p.x},${p.y}');
        expect(p.b, equals(0), reason: 'blue at ${p.x},${p.y}');
      }

      var fg = decodeTga(File('test/_data/tga/globe.tga').readAsBytesSync())!;
      fg = fg.convert(numChannels: 4);
      for (final p in fg) {
        if (p.r == 0 && p.g == 0 && p.b == 0) {
          p.a = 0;
        }
      }

      final origBg = (await decodePngFile('test/_data/png/buck_24.png'))!;

      // The fg pixel drawn at ([x],[y]) when fg is placed at (50,50) with
      // the given [size], or null outside of it.
      Pixel? fgAt(num x, num y, int size) {
        final fx = x - 50;
        final fy = y - 50;
        if (fx < 0 || fy < 0 || fx >= size || fy >= size) {
          return null;
        }
        return fg.getPixel((fx * (fg.width / size)).toInt(),
            (fy * (fg.height / size)).toInt());
      }

      // Opaque fg pixels replace bg; transparent ones and the area outside
      // the fg leave bg unchanged.
      void expectOver(Image bg, int size) {
        var covered = 0;
        for (final p in bg) {
          final f = fgAt(p.x, p.y, size);
          final o = origBg.getPixel(p.x, p.y);
          final e = f != null && f.a != 0 ? f : o;
          if (f != null && f.a != 0) {
            covered++;
          }
          expect([p.r, p.g, p.b], equals([e.r, e.g, e.b]),
              reason: 'pixel ${p.x},${p.y}');
        }
        expect(covered, greaterThan(0), reason: 'opaque fg pixels drawn');
      }

      {
        final bg = origBg.clone();
        compositeImage(bg, fg, dstX: 50, dstY: 50);
        File('$testOutputPath/draw/compositeImage.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(bg));
        expectOver(bg, fg.width);
      }

      {
        final bg = origBg.clone();
        compositeImage(bg, fg, dstX: 50, dstY: 50, dstW: 200, dstH: 200);
        File('$testOutputPath/draw/compositeImage_scaled.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(bg));
        expectOver(bg, 200);
      }

      // The expected result of blending an opaque fg value over a bg value
      // for the blend modes with a simple closed form.
      num? blended(BlendMode blend, num f, num b) => switch (blend) {
            BlendMode.direct || BlendMode.alpha => f,
            BlendMode.lighten => max(f, b),
            BlendMode.darken => min(f, b),
            BlendMode.multiply => f * b / 255,
            BlendMode.addition => min(f + b, 255),
            BlendMode.subtract => max(b - f, 0),
            BlendMode.difference => (f - b).abs(),
            BlendMode.screen => 255 - (255 - f) * (255 - b) / 255,
            _ => null,
          };

      for (var blend in BlendMode.values) {
        final bg = origBg.clone();
        compositeImage(bg, fg, dstX: 50, dstY: 50, blend: blend);
        File('$testOutputPath/draw/compositeImage_${blend.name}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(bg));

        var changed = 0;
        for (final p in bg) {
          final f = fgAt(p.x, p.y, fg.width);
          final o = origBg.getPixel(p.x, p.y);
          if (p.r != o.r || p.g != o.g || p.b != o.b) {
            changed++;
          }
          if (f == null || (f.a == 0 && blend != BlendMode.direct)) {
            // Outside fg, or a fully transparent fg pixel.
            expect([p.r, p.g, p.b], equals([o.r, o.g, o.b]),
                reason: '${blend.name}: bg changed at ${p.x},${p.y}');
            continue;
          }
          for (var c = 0; c < 3; ++c) {
            final e = blended(blend, f[c], o[c]);
            if (e != null) {
              expect(p[c], closeTo(e, 1),
                  reason: '${blend.name}: channel $c at ${p.x},${p.y}');
            }
          }
        }
        expect(changed, greaterThan(0), reason: '${blend.name}: no change');
      }

      final mask = Command()
        ..createImage(width: 256, height: 256)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
          x: 128,
          y: 128,
          radius: 30,
          color: ColorRgb8(255, 255, 255),
        )
        ..gaussianBlur(radius: 5);

      final fgCmd = Command()..image(fg);

      final masked = (await (Command()
            ..image(origBg)
            ..copy()
            ..compositeImage(fgCmd, dstX: 50, dstY: 50, mask: mask)
            ..writeToFile('$testOutputPath/draw/compositeImage_mask.png'))
          .getImage())!;

      // The mask is looked up at destination coordinates, so only the fg
      // near (128,128) shows, mixed over bg by the blurred circle.
      final maskImage = (await mask.getImage())!;
      var shown = 0;
      for (final p in masked) {
        final f = fgAt(p.x, p.y, fg.width);
        final o = origBg.getPixel(p.x, p.y);
        final m = f == null || f.a == 0
            ? 0
            : maskImage.getPixel(p.x, p.y).luminanceNormalized;
        if (m > 0.9) {
          shown++;
        }
        for (var c = 0; c < 3; ++c) {
          final e = f == null ? o[c] : o[c] + (f[c] - o[c]) * m;
          expect(p[c], closeTo(e, 1), reason: 'channel $c at ${p.x},${p.y}');
        }
      }
      expect(shown, greaterThan(0), reason: 'fg shown through the mask');
    });
  });
}
