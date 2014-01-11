# image

##Overview

A Dart library to encode and decode various image formats.

The library has no reliance on `dart:io`, so it can be used for both server and
web applications. The image library currently supports the following 
formats:

- PNG
- JPG
- TGA

##Sample

Load a jpeg, resize it, and save it as a png:

    import 'dart:io' as Io;
    import 'package:image/image.dart';
    void main() {
      // Read a jpeg image from file.
      Image image = readJpg(new Io.File('res/cat-eye04.jpg').readAsBytesSync());

      // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
      Image thumbnail = copyResize(image, 120);
    
      // Save the thumbnail as a PNG.
      new Io.File('out/thumbnail-cat-eye04.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(writePng(thumbnail));
    }

##Image Functions
- Image **brightness**(Image src, int brightness);
- Image **colorOffset**(Image src, int red, int green, int blue, int alpha);
- Image **contrast**(Image src, num contrast);
- Image **convolution**(Image src, List<num> filter, num filterDiv, num offset);
- Image **copyCrop**(Image src, int x, int y, int w, int h);
- Image **copyGaussianBlur**(Image src, int radius);
- Image **copyInto**(Image dst, Image src, int dst_x, int dst_y, int src_x, int src_y, int dst_w, int dst_h, int src_w, int src_h);
- Image **copyResize**(Image src, int width, [int height = -1]);
- Image **drawChar**(Image image, BitmapFont font, int x, int y, String string, {int color: 0xffffffff});
- Image **drawLine**(Image image, int x1, int y1, int x2, int y2, int color,
                     {bool antialias: false, num thickness: 1});
- Image **drawString**(Image image, BitmapFont font, int x, int y, String string, {int color: 0xffffffff});
- Image **dropShadow**(Image src, int hshadow, int vshadow, int blur,
                   {int shadowColor: 0x000000a0});
- Image **edgeDetectQuick**(Image src);
- Image **emboss**(Image src);             
- Image **fill**(Image image, int color);
- Image **fillRect**(Image src, int x, int y, int w, int h, int color);
- Image **flip**(Image src, int mode);
- Image **grayscale**(Image src);
- Image **invert**(Image src);
- Image **meanRemoval**(Image src);
- Image **pixelate**(Image src, int blockSize, {int mode: PIXELATE_UPPERLEFT});
- BitmapFont **readFontZip**(List<int> bytes);
- BitmapFont **readFont**(String fnt, Image page);
- Image **readJpg**(List<int> bytes);
- Image **readPng**(List<int> bytes);
- Image **readTga**(List<int> bytes);
- Image **remapColors**(Image src, {int red: RED, int green: GREEN, int blue: BLUE, int alpha: ALPHA});
- Image **smooth**(Image src, num w);
- List<int> **writeJpg**(Image image, {int quality: 100});
- List<int> **writePng**(Image image, {int level: 6});
- List<int> **writeTga**(Image image);
