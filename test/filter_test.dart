import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('filter', () {
    var image = readJpg(new File('test/res/jpg/portrait_5.jpg').readAsBytesSync());
    image = copyResize(image, 400);
    var image2 = readPng(new File('test/res/png/alpha_edge.png').readAsBytesSync());

    test('fill', () {
      Image f = new Image(10, 10, Image.RGB);
      f.fill(getColor(128, 64, 32, 255));
      File fp = new File('out/fill.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('fillRect', () {
      Image f = new Image.from(image);
      int c = getColor(128, 255, 128, 255);
      fillRect(f, 50, 50, 150, 150, c);
      File fp = new File('out/fillRect.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('copyRectify', () {
      Image s = readJpg(new File('test/res/oblique.jpg').readAsBytesSync());
      Image d = Image(92, 119);
      copyRectify(s, topLeft: Point(16, 32),
          topRight: Point(79, 39),
          bottomLeft: Point(16, 151),
          bottomRight: Point(108, 141), toImage: d);
      File fp = new File('out/oblique.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(d));
    });

    test('copyInto', () {
      Image s = new Image.from(image);
      Image d = new Image(image.width + 20, image.height + 20, image.format);
      fill(d, 0xff0000ff);
      copyInto(d, s, dstX: 10, dstY: 10);
      copyInto(d, image2, dstX: 10, dstY: 10);

      new File('out/copyInto.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(d));
    });

    test('add', () {
      Image i1 = new Image.from(image);
      Image i2 = new Image.from(image2);
      i1 += i2;

      File fp = new File('out/add.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(i1));
    });

    test('sub', () {
      Image i1 = new Image.from(image);
      Image i2 = new Image.from(image2);
      i1 -= i2;

      File fp = new File('out/sub.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(i1));
    });

    test('or', () {
      Image i1 = new Image.from(image);
      Image i2 = new Image.from(image2);
      i1 |= i2;

      File fp = new File('out/or.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(i1));
    });

    test('and', () {
      Image i1 = new Image.from(image);
      Image i2 = new Image.from(image2);
      i1 &= i2;

      File fp = new File('out/and.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(i1));
    });

    test('draw shapes', () {
      Image f = new Image.from(image);
      int c1 = getColor(128, 255, 128, 255);
      drawLine(f, 0, 0, f.width, f.height, c1, thickness: 3);
      int c2 = getColor(255, 128, 128, 255);
      drawLine(f, f.width, 0, 0, f.height, c2, thickness: 5, antialias: true);
      drawCircle(f, 100, 100, 50, c1);
      drawRect(f, 50, 50, 150, 150, c2);

      File fp = new File('out/drawShapes.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('brightness', () {
      Image f = new Image.from(image);
      brightness(f, 100);
      File fp = new File('out/brightness.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('copyResize', () {
      Image f = copyResize(image, -1, 100);
      expect(f.height, equals(100));
      File fp = new File('out/copyResize.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('colorOffset', () {
      Image f = new Image.from(image);
      colorOffset(f, 50, 0, 0, 0);

      File fp = new File('out/colorOffset.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('contrast', () {
      Image f = new Image.from(image);
      contrast(f, 150);

      File fp = new File('out/contrast.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('adjustColor:saturation', () {
      Image f = new Image.from(image);
      adjustColor(f, saturation: 0.35);

      File fp = new File('out/adjustColor_saturation.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('adjustColor:gamma', () {
      Image f = new Image.from(image);
      adjustColor(f, gamma: 1.0 / 2.2);

      File fp = new File('out/adjustColor_gamma.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('adjustColor:hue', () {
      Image f = new Image.from(image);
      adjustColor(f, hue: 75.0, gamma: 0.75, amount: 0.35);

      File fp = new File('out/adjustColor_hue.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('emboss', () {
      Image f = new Image.from(image);
      emboss(f);

      File fp = new File('out/emboss.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('sobel', () {
      Image f = new Image.from(image);
      sobel(f);

      File fp = new File('out/sobel.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('gaussianBlur', () {
      Image f = new Image.from(image);
      gaussianBlur(f, 10);

      File fp = new File('out/gaussianBlur.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('grayscale', () {
      Image f = new Image.from(image);
      grayscale(f);

      File fp = new File('out/grayscale.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('invert', () {
      Image f = new Image.from(image);
      invert(f);

      File fp = new File('out/invert.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('NOISE_GAUSSIAN', () {
      Image f = new Image.from(image);
      noise(f, 10.0, type: NOISE_GAUSSIAN);

      File fp = new File('out/noise_gaussian.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('NOISE_UNIFORM', () {
      Image f = new Image.from(image);
      noise(f, 10.0, type: NOISE_UNIFORM);

      File fp = new File('out/noise_uniform.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('NOISE_SALT_PEPPER', () {
      Image f = new Image.from(image);
      noise(f, 10.0, type: NOISE_SALT_PEPPER);

      File fp = new File('out/noise_salt_pepper.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('NOISE_POISSON', () {
      Image f = new Image.from(image);
      noise(f, 10.0, type: NOISE_POISSON);

      File fp = new File('out/noise_poisson.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('NOISE_RICE', () {
      Image f = new Image.from(image);
      noise(f, 10.0, type: NOISE_RICE);

      File fp = new File('out/noise_rice.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('normalize', () {
      Image f = new Image.from(image);
      normalize(f, 100, 255);

      File fp = new File('out/normalize.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('pixelate', () {
      Image f = new Image.from(image);
      pixelate(f, 20, mode: PIXELATE_UPPERLEFT);

      File fp = new File('out/PIXELATE_UPPERLEFT.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));

      f = new Image.from(image);
      pixelate(f, 20, mode: PIXELATE_AVERAGE);

      fp = new File('out/PIXELATE_AVERAGE.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('remapColors', () {
      Image f = new Image.from(image);
      f.format = Image.RGBA;
      remapColors(f, red: GREEN, green: RED, alpha: LUMINANCE);

      File fp = new File('out/remapColors.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('rotate_90', () {
      Image f = new Image.from(image);
      Image r = copyRotate(f, 90);

      File fp = new File('out/rotate_90.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });

    test('rotate_180', () {
      Image f = new Image.from(image);
      Image r = copyRotate(f, 180);

      File fp = new File('out/rotate_180.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });

    test('rotate_270', () {
      Image f = new Image.from(image);
      Image r = copyRotate(f, 270);

      File fp = new File('out/rotate_270.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });

    test('rotate_45', () {
      Image f = new Image.from(image);
      f = copyRotate(f, 45);

      File fp = new File('out/rotate_45.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('smooth', () {
      Image f = new Image.from(image);
      smooth(f, 10);

      File fp = new File('out/smooth.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('sepia', () {
      Image f = new Image.from(image);
      sepia(f);

      File fp = new File('out/sepia.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('vignette', () {
      Image f = new Image.from(image);
      vignette(f);

      File fp = new File('out/vignette.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('quantize', () {
      Image f = new Image.from(image);
      quantize(f);

      File fp = new File('out/quantize.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(f));
    });

    test('trim', () {
      Image image = readPng(new File('test/res/png/trim.png').readAsBytesSync());
      Image trimmed = trim(image, mode: TRIM_TRANSPARENT);
      expect(trimmed.width, equals(64));
      expect(trimmed.height, equals(56));
      new File('out/trim.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(trimmed));
    });

    test('dropShadow', () {
      Image s = new Image.from(image2);
      Image d = dropShadow(s, 5, 5, 10);

      new File('out/dropShadow.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(d));

      s = new Image.from(image2);
      d = dropShadow(s, -5, 5, 10);

      new File('out/dropShadow-2.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(d));

      s = new Image.from(image2);
      d = dropShadow(s, 5, -5, 10);

      new File('out/dropShadow-3.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(d));

      s = new Image.from(image2);
      d = dropShadow(s, -5, -5, 10);

      new File('out/dropShadow-4.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(d));

      s = new Image(256, 256);
      s.fill(0);
      drawString(s, arial_48, 30, 100, 'Shadow', color: getColor(255, 0, 0));
      d = dropShadow(s, -3, -3, 5);

      new File('out/dropShadow-5.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writePng(d));
    });

    test('flip horzontal', () {
      Image f = new Image.from(image);
      Image r = flip(f, 1);

      File fp = new File('out/flipH.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });
    test('flip vertical', () {
      Image f = new Image.from(image);
      Image r = flip(f, 2);

      File fp = new File('out/flipV.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });

    test('flip both', () {
      Image f = new Image.from(image);
      Image r = flip(f, 3);

      File fp = new File('out/flipHV.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writeJpg(r));
    });
  });
}
