library image_test;

import 'dart:io' as Io;
import 'package:image/image.dart';
import 'package:unittest/unittest.dart';

part 'font_test.dart';
part 'jpeg_test.dart';
part 'png_test.dart';
part 'tga_test.dart';

void main() {
  defineTgaTests();
  defineJpegTests();
  definePngTests();
  defineFontTests();
  defineImageTests();
}


void defineImageTests() {
  group('image', () {
    Io.File file = new Io.File('res/trees.png');
    Image image = readPng(file.readAsBytesSync());

    test('fill', () {
      Image f = new Image(10, 10);
      int c = getColor(128, 255, 128, 255);
      fill(f, c);
      for (int i = 0; i < f.buffer.length; ++i) {
        expect(f.buffer[i], equals(c));
      }
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/fill.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('fillRectanlge', () {
      Image f = new Image.from(image);
      int c = getColor(128, 255, 128, 255);
      fillRectangle(f, 50, 50, 100, 100, c);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/fillRectanlge.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('brightness', () {
      Image f = new Image.from(image);
      brightness(f, 100);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/brightness.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('colorOffset', () {
      Image f = new Image.from(image);
      colorOffset(f, 50, 0, 0, 0);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/colorOffset.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('contrast', () {
      Image f = new Image.from(image);
      contrast(f, 150);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/contrast.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('edgeDetectQuick', () {
      Image f = new Image.from(image);
      edgeDetectQuick(f);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/edgeDetectQuick.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('emboss', () {
      Image f = new Image.from(image);
      emboss(f);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/emboss.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('gaussianBlur', () {
      Image f = new Image.from(image);
      Image g = copyGaussianBlur(f, 5);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/gaussianBlur.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(g));
    });

    test('grayscale', () {
      Image f = new Image.from(image);
      grayscale(f);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/grayscale.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('meanRemoval', () {
      Image f = new Image.from(image);
      meanRemoval(f);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/meanRemoval.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('negate', () {
      Image f = new Image.from(image);
      negate(f);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/negate.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('pixelate', () {
      Image f = new Image.from(image);
      pixelate(f, 20, mode: PIXELATE_UPPERLEFT);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/PIXELATE_UPPERLEFT.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));

      f = new Image.from(image);
      pixelate(f, 20, mode: PIXELATE_AVERAGE);
      // Save the image as a PNG.
      fp = new Io.File('out/PIXELATE_AVERAGE.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('remapColors', () {
      Image f = new Image.from(image);
      remapColors(f, red: GREEN, green: RED);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/remapColors.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });

    test('smooth', () {
      Image f = new Image.from(image);
      smooth(f, 10);
      // Save the image as a PNG.
      Io.File fp = new Io.File('out/smooth.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(f));
    });
  });
}
