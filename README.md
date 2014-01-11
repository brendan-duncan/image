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
- Image **brightness**(Image src, int brightness);<br>
  _Adjust the brightness of the image._<br>
- Image **colorOffset**(Image src, int red, int green, int blue, int alpha);<br>
  _Apply an offset to the colors of the image._<br>
- Image **contrast**(Image src, num contrast);<br>
  _Apply the Contrast convolution filter to the image._<br>
- Image **convolution**(Image src, List<num> filter, num filterDiv, num offset);<br>
  _Apply a convolution filter to the image._<br>
- Image **copyCrop**(Image src, int x, int y, int w, int h);<br>
  _Create a cropped copy of the image._<br>
- Image **copyGaussianBlur**(Image src, int radius);<br>
  _Create a blurred copy of the image._<br>
- Image **copyInto**(Image dst, Image src, int dst_x, int dst_y, int src_x, int src_y, int dst_w, int dst_h, int src_w, int src_h);<br>
  _Copy an area of src into dst.<br>
- Image **copyResize**(Image src, int width, [int height = -1]);<br>
  _Create a resized copy of the image._<br>
- Image **drawChar**(Image image, BitmapFont font, int x, int y, String string, {int color: 0xffffffff});<br>
  _Draw a single character with the given font._<br>
- Image **drawLine**(Image image, int x1, int y1, int x2, int y2, int color,
                     {bool antialias: false, num thickness: 1});<br>
  _Draw a line._<br>
- Image **drawString**(Image image, BitmapFont font, int x, int y, String string, {int color: 0xffffffff});<br>
  _Draw the string with the given font._<br>
- Image **dropShadow**(Image src, int hshadow, int vshadow, int blur,
                   {int shadowColor: 0x000000a0});<br>
  _Create a drop-shadow effect._<br>
- Image **edgeDetectQuick**(Image src);<br>
  _Apply the EdgeDetect convolution filter._<br>
- Image **emboss**(Image src);<br>
  _Apply the Emboss convolution filter._<br>
- Image **fill**(Image image, int color);<br>
  _Fill the image with the given color._<br>
- Image **fillRect**(Image src, int x, int y, int w, int h, int color);<br>
  _Fill a rectangle with the given color._<br>
- Image **flip**(Image src, int mode);<br>
  _Flip the image with FLIP_HORIZONTAL, FLIP_VERTICAL, or FLIP_BOTH.<br>
- Image **grayscale**(Image src);<br>
  _Convert the colors of the image to grayscale.<br>
- Image **invert**(Image src);<br>
  _Inver the colors of the image.<br>
- Image **meanRemoval**(Image src);<br>
  _Apply MeanRemoval convolution filter to the image.<br>
- Image **pixelate**(Image src, int blockSize, {int mode: PIXELATE_UPPERLEFT});<br>
  _Pixelate the image._<br>
- BitmapFont **readFontZip**(List<int> bytes);<br>
  _Load a BitmapFont from a zip file._<br>
- BitmapFont **readFont**(String fnt, Image page);<br>
  _Load a BitmapFont from a font file and image._<br>
- Image **readJpg**(List<int> bytes);<br>
  _Load an Image from JPG formatted data._<br>
- Image **readPng**(List<int> bytes);<br>
  _Load an Image from PNG formatted data._<br>
- Image **readTga**(List<int> bytes);<br>
  _Load an Image from TGA formatted data._<br>
- Image **remapColors**(Image src, {int red: RED, int green: GREEN, int blue: BLUE, int alpha: ALPHA});<br>
  _Remap the color channels of an image._<br>
- Image **smooth**(Image src, num w);<br>
  _Apply a smooth convolution filter to the image._<br>
- List<int> **writeJpg**(Image image, {int quality: 100});<br>
  _Generate JPG formatted data for the given image._<br>
- List<int> **writePng**(Image image, {int level: 6});<br>
  _Generate PNG formatted data for the given image._<br>
- List<int> **writeTga**(Image image);<br>
  _Generate TGA formatted data for the given image._<br>
