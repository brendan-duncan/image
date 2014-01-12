# image

##Overview

A Dart library to encode and decode various image formats.

The library has no reliance on `dart:io`, so it can be used for both server and
web applications. The image library currently supports the following 
formats:

- PNG
- JPG
- TGA

##Samples

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

Create an image, draw some text, save it as a png:

    import 'dart:io' as Io;
    import 'package:image/image.dart';
    void main() {
      // Create an image
      Image image = new Image(320, 240);
      
      // Fill it with a solid color (blue)
      fill(image, getColor(0, 0, 255));
      
      // Draw some text using 24pt arial font
      drawString(image, arial_24, 0, 0, 'Hello World');
      
      // Draw a line
      drawLine(image, 0, 0, 320, 240, getColor(255, 0, 0), thickness: 3);
      
      // Blur the image
      image = copyGaussianBlur(image, 10);
      
      // Generate a PNG
      List<int> png = writePng(image);
      
      // Save it to disk
      new Io.File('out/test.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);
    }

You ca
    
##Image Functions
- Image **brightness**(Image src, int brightness);

  _Adjust the brightness of the image._
  
- Image **bumpToNormal**(Image src, {double strength: 2.0});

  _Generate a normal map from a heightfield bump image._
  
- Image **colorOffset**(Image src, int red, int green, int blue, int alpha);

  _Apply an offset to the colors of the image._
  
- Image **contrast**(Image src, num contrast);

  _Apply the Contrast convolution filter to the image._
  
- Image **convolution**(Image src, List<num> filter, num filterDiv, num offset);

  _Apply a convolution filter to the image._
  
- Image **copyCrop**(Image src, int x, int y, int w, int h);

  _Create a cropped copy of the image._
  
- Image **copyGaussianBlur**(Image src, int radius);

  _Create a blurred copy of the image._
  
- Image **copyInto**(Image dst, Image src, int dst_x, int dst_y, int src_x, int src_y, int dst_w, int dst_h, int src_w, int src_h);

  _Copy an area of src into dst.
  
- Image **copyResize**(Image src, int width, [int height = -1]);

  _Create a resized copy of the image._
  
- Image **drawChar**(Image image, BitmapFont font, int x, int y, String string, {int color: 0xffffffff});

  _Draw a single character with the given font._
  
- Image **drawCircle**(Image image, int x0, int y0, int radius, int color);
  
  _Draw a circle._
  
- Image **drawLine**(Image image, int x1, int y1, int x2, int y2, int color,
                     {bool antialias: false, num thickness: 1});
                     
  _Draw a line._
  
- Image **drawNoise**(Image image, double sigma, {int type: NOISE_GAUSSIAN, Math.Random random});

  _Add random noise to pixel values._
  
- Image **drawPixel**(Image image, int x, int y, int color, [int opacity = 0xff]);

  _Draw a single pixel into the image, applying alpha and opacity blending._
  
- Image **drawString**(Image image, BitmapFont font, int x, int y, String string, {int color: 0xffffffff});

  _Draw the string with the given font._
  
- Image **dropShadow**(Image src, int hshadow, int vshadow, int blur,
                   {int shadowColor: 0x000000a0});
                   
  _Create a drop-shadow effect._
  
- Image **edgeDetectQuick**(Image src);

  _Apply the EdgeDetect convolution filter._
  
- Image **emboss**(Image src);

  _Apply the Emboss convolution filter._
  
- Image **fill**(Image image, int color);

  _Fill the image with the given color._
  
- Image **fillRect**(Image src, int x, int y, int w, int h, int color);

  _Fill a rectangle with the given color._
  
- Image **flip**(Image src, int mode);

  _Flip the image with FLIP_HORIZONTAL, FLIP_VERTICAL, or FLIP_BOTH._
  
- Image **grayscale**(Image src);

  _Convert the colors of the image to grayscale._
  
- Image **invert**(Image src);

  _Inver the colors of the image._
  
- Image **meanRemoval**(Image src);

  _Apply MeanRemoval convolution filter to the image._
  
- Image **normalize**(Image src, int minValue, int maxValue);

  _Linearly normalize the pixel values of the image._
  
- Image **pixelate**(Image src, int blockSize, {int mode: PIXELATE_UPPERLEFT});

  _Pixelate the image._
  
- BitmapFont **readFontZip**(List<int> bytes);

  _Load a BitmapFont from a zip file._
  
- BitmapFont **readFont**(String fnt, Image page);

  _Load a BitmapFont from a font file and image._
  
- Image **readJpg**(List<int> bytes);

  _Load an Image from JPG formatted data._
  
- Image **readPng**(List<int> bytes);

  _Load an Image from PNG formatted data._
  
- Image **readTga**(List<int> bytes);

  _Load an Image from TGA formatted data._
  
- Image **remapColors**(Image src, {int red: RED, int green: GREEN, int blue: BLUE, int alpha: ALPHA});

  _Remap the color channels of an image._
  
- Image **smooth**(Image src, num w);

  _Apply a smooth convolution filter to the image._
  
- List<int> **writeJpg**(Image image, {int quality: 100});

  _Generate JPG formatted data for the given image._
  
- List<int> **writePng**(Image image, {int level: 6});

  _Generate PNG formatted data for the given image._
  
- List<int> **writeTga**(Image image);

  _Generate TGA formatted data for the given image._
