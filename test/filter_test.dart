import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  group('filter', () {
    var image = readJpg(File('test/res/jpg/portrait_5.jpg').readAsBytesSync());
    image = copyResize(image, width: 400);
    var image2 = readPng(File('test/res/png/alpha_edge.png').readAsBytesSync());

    test('fill', () {
      final f = Image(10, 10, channels: Channels.rgb);
      f.fill(getColor(128, 64, 32, 255));
      final fp = File('$tmpPath/out/fill.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('fillRect', () {
      final f = Image.from(image);
      fillRect(f, 50, 50, 150, 150, getColor(128, 255, 128, 255));
      fillRect(f, 250, -10, 100, 750, getColor(255, 128, 128, 128));
      final fp = File('$tmpPath/out/fillRect.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('floodFill', () {
      final s = readJpg(File('test/res/oblique.jpg').readAsBytesSync());
      final c = s.getPixel(50, 50);
      fillFlood(s, 50, 50, c, threshold: 15.6);
      final fp = File('$tmpPath/out/fillFlood.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(s));
    });

    test('copyCrop', () {
      final s = readPng(File('test/res/png/lenna.png').readAsBytesSync());
      final d = copyCrop(s, 200, 200, 5000, 5000);
      final fp = File('$tmpPath/out/copyCrop.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(d));
    });

    test('copyRectify', () {
      final s = readJpg(File('test/res/oblique.jpg').readAsBytesSync());
      final d = Image(92, 119);
      copyRectify(s,
          topLeft: Point(16, 32),
          topRight: Point(79, 39),
          bottomLeft: Point(16, 151),
          bottomRight: Point(108, 141),
          toImage: d);
      final fp = File('$tmpPath/out/oblique.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(d));
    });

    test('copyInto', () {
      final s = Image.from(image);
      final d =
          Image(image.width + 20, image.height + 20, channels: image.channels);
      fill(d, 0xff0000ff);
      copyInto(d, s, dstX: 10, dstY: 10);
      copyInto(d, image2, dstX: 10, dstY: 10);

      File('$tmpPath/out/copyInto.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(d));
    });

    test('add', () {
      var i1 = Image.from(image);
      final i2 = Image.from(image2);
      i1 += i2;

      final fp = File('$tmpPath/out/add.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(i1));
    });

    test('sub', () {
      var i1 = Image.from(image);
      final i2 = Image.from(image2);
      i1 -= i2;

      final fp = File('$tmpPath/out/sub.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(i1));
    });

    test('or', () {
      var i1 = Image.from(image);
      final i2 = Image.from(image2);
      i1 |= i2;

      final fp = File('$tmpPath/out/or.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(i1));
    });

    test('and', () {
      var i1 = Image.from(image);
      final i2 = Image.from(image2);
      i1 &= i2;

      final fp = File('$tmpPath/out/and.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(i1));
    });

    test('draw shapes', () {
      final f = Image.from(image);
      final c1 = getColor(128, 255, 128, 255);
      drawLine(f, 0, 0, f.width, f.height, c1, thickness: 3);
      final c2 = getColor(255, 128, 128, 255);
      drawLine(f, f.width, 0, 0, f.height, c2, thickness: 5, antialias: true);
      drawCircle(f, 100, 100, 50, c1);
      drawRect(f, 50, 50, 150, 150, c2);

      final fp = File('$tmpPath/out/drawShapes.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('drawImage', () {
      final dst = Image(1000, 1000);
      fill(dst, getColor(0, 255, 0));
      final src = Image(100, 100);
      fill(src, getColor(255, 0, 0));
      drawImage(dst, src, blend: false, dstX: 100, dstY: 100);
      File('$tmpPath/out/drawImage.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(dst));
    });

    test('brightness', () {
      final f = Image.from(image);
      brightness(f, 100);
      final fp = File('$tmpPath/out/brightness.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('copyResize', () {
      final f = copyResize(image, height: 100);
      expect(f.height, equals(100));
      final fp = File('$tmpPath/out/copyResize.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('colorOffset', () {
      var f = Image.from(image);
      colorOffset(f, red: 100);

      File('$tmpPath/out/colorOffset.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(f));

      f = Image(48, 48);
      colorOffset(f, red: 255);
      File('$tmpPath/out/colorOffset_red.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(f));

      f = Image(48, 48);
      colorOffset(f, green: 255);
      File('$tmpPath/out/colorOffset_green.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(f));

      f = Image(48, 48);
      colorOffset(f, blue: 255);
      File('$tmpPath/out/colorOffset_blue.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(f));
    });

    test('contrast', () {
      final f = Image.from(image);
      contrast(f, 150);

      final fp = File('$tmpPath/out/contrast.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('adjustColor:saturation', () {
      final f = Image.from(image);
      adjustColor(f, saturation: 0.35);

      final fp = File('$tmpPath/out/adjustColor_saturation.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('adjustColor:gamma', () {
      final f = Image.from(image);
      adjustColor(f, gamma: 1.0 / 2.2);

      final fp = File('$tmpPath/out/adjustColor_gamma.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('adjustColor:hue', () {
      final f = Image.from(image);
      adjustColor(f, hue: 75.0, gamma: 0.75, amount: 0.35);

      final fp = File('$tmpPath/out/adjustColor_hue.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('emboss', () {
      final f = Image.from(image);
      emboss(f);

      final fp = File('$tmpPath/out/emboss.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('sobel', () {
      var f = readPng(File('test/res/png/lenna.png').readAsBytesSync());
      sobel(f);

      final fp = File('$tmpPath/out/sobel.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('gaussianBlur', () {
      final f = Image.from(image);
      gaussianBlur(f, 10);

      final fp = File('$tmpPath/out/gaussianBlur.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('grayscale', () {
      final f = Image.from(image);
      grayscale(f);

      final fp = File('$tmpPath/out/grayscale.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('invert', () {
      final f = Image.from(image);
      invert(f);

      final fp = File('$tmpPath/out/invert.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('NOISE_GAUSSIAN', () {
      final f = Image.from(image);
      noise(f, 10.0, type: NoiseType.gaussian);

      final fp = File('$tmpPath/out/noise_gaussian.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('NOISE_UNIFORM', () {
      final f = Image.from(image);
      noise(f, 10.0, type: NoiseType.uniform);

      final fp = File('$tmpPath/out/noise_uniform.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('NOISE_SALT_PEPPER', () {
      final f = Image.from(image);
      noise(f, 10.0, type: NoiseType.salt_pepper);

      final fp = File('$tmpPath/out/noise_salt_pepper.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('NOISE_POISSON', () {
      final f = Image.from(image);
      noise(f, 10.0, type: NoiseType.poisson);

      final fp = File('$tmpPath/out/noise_poisson.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('NOISE_RICE', () {
      final f = Image.from(image);
      noise(f, 10.0, type: NoiseType.rice);

      final fp = File('$tmpPath/out/noise_rice.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('normalize', () {
      final f = Image.from(image);
      normalize(f, 100, 255);

      final fp = File('$tmpPath/out/normalize.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('pixelate', () {
      var f = Image.from(image);
      pixelate(f, 20, mode: PixelateMode.upperLeft);

      var fp = File('$tmpPath/out/PIXELATE_UPPERLEFT.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));

      f = Image.from(image);
      pixelate(f, 20, mode: PixelateMode.average);

      fp = File('$tmpPath/out/PIXELATE_AVERAGE.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('remapColors', () {
      final f = Image.from(image);
      f.channels = Channels.rgba;
      remapColors(f,
          red: Channel.green, green: Channel.red, alpha: Channel.luminance);

      final fp = File('$tmpPath/out/remapColors.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('rotate_90', () {
      final f = Image.from(image);
      final r = copyRotate(f, 90);

      final fp = File('$tmpPath/out/rotate_90.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });

    test('rotate_180', () {
      final f = Image.from(image);
      final r = copyRotate(f, 180);

      final fp = File('$tmpPath/out/rotate_180.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });

    test('rotate_270', () {
      final f = Image.from(image);
      final r = copyRotate(f, 270);

      final fp = File('$tmpPath/out/rotate_270.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });

    test('rotate_45', () {
      var f = Image.from(image);
      f = copyRotate(f, 45);

      final fp = File('$tmpPath/out/rotate_45.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('smooth', () {
      final f = Image.from(image);
      smooth(f, 10);

      final fp = File('$tmpPath/out/smooth.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('sepia', () {
      final f = Image.from(image);
      sepia(f);

      final fp = File('$tmpPath/out/sepia.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('vignette', () {
      final f = Image.from(image);
      vignette(f);

      final fp = File('$tmpPath/out/vignette.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('octree quantize', () {
      var f = readPng(File('test/res/png/lenna.png').readAsBytesSync());

      quantize(f, numberOfColors: 16, method: QuantizeMethod.octree);
      // ignore: prefer_collection_literals
      var colors = Set<int>();
      for (var y = 0; y < f.height; ++y) {
        for (var x = 0; x < f.width; ++x) {
          colors.add(f.getPixel(x, y));
        }
      }
      final fp = File('$tmpPath/out/quantize_octree.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('neural quantize', () {
      var f = readPng(File('test/res/png/lenna.png').readAsBytesSync());

      quantize(f, numberOfColors: 16, method: QuantizeMethod.neuralNet);
      // ignore: prefer_collection_literals
      var colors = Set<int>();
      for (var y = 0; y < f.height; ++y) {
        for (var x = 0; x < f.width; ++x) {
          colors.add(f.getPixel(x, y));
        }
      }
      var fp = File('$tmpPath/out/quantize_neural.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('trim', () {
      var image = readPng(File('test/res/png/trim.png').readAsBytesSync());
      var trimmed = trim(image, mode: TrimMode.transparent);
      File('$tmpPath/out/trim.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(trimmed));
      expect(trimmed.width, equals(64));
      expect(trimmed.height, equals(56));

      trimmed = trim(image, mode: TrimMode.topLeftColor);
      File('$tmpPath/out/trim_topLeftColor.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(trimmed));
      expect(trimmed.width, equals(64));
      expect(trimmed.height, equals(56));

      trimmed = trim(image, mode: TrimMode.bottomRightColor);
      File('$tmpPath/out/trim_bottomRightColor.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(trimmed));
      expect(trimmed.width, equals(64));
      expect(trimmed.height, equals(56));
    });

    test('dropShadow', () {
      var s = Image.from(image2);
      var d = dropShadow(s, 5, 5, 10);

      File('$tmpPath/out/dropShadow.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(d));

      s = Image.from(image2);
      d = dropShadow(s, -5, 5, 10);

      File('$tmpPath/out/dropShadow-2.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(d));

      s = Image.from(image2);
      d = dropShadow(s, 5, -5, 10);

      File('$tmpPath/out/dropShadow-3.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(d));

      s = Image.from(image2);
      d = dropShadow(s, -5, -5, 10);

      File('$tmpPath/out/dropShadow-4.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(d));

      s = Image(256, 256);
      s.fill(0);
      drawString(s, arial_48, 30, 100, 'Shadow', color: getColor(255, 0, 0));
      d = dropShadow(s, -3, -3, 5);

      File('$tmpPath/out/dropShadow-5.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(d));
    });

    test('flip horizontal', () {
      final f = Image.from(image);
      final r = flip(f, Flip.horizontal);

      final fp = File('$tmpPath/out/flipH.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });
    test('flip vertical', () {
      final f = Image.from(image);
      final r = flip(f, Flip.vertical);

      final fp = File('$tmpPath/out/flipV.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });

    test('flip both', () {
      final f = Image.from(image);
      final r = flip(f, Flip.both);

      final fp = File('$tmpPath/out/flipHV.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });
  });
}
