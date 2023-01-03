# Image Data

The Image class stores a raster image, that is, a rectangle of pixel data. Images can be created or loaded
from encoded formats such as JPEG or PNG.

### Channels

An image can have 1, 2, 3, or 4 color channels. An RGB image would have 3 channels,
and an RGBA image would have 4 channels. An image can have a palette, in which case it would have
1 channel, where each pixel is an index into the palette.

### ChannelOrder

ImageData stores color channels in RGBA order for 4 channel images, and RGB order for 3 channel images.
Sometimes external image data requires alternative channel ordering, such as ABGR.
The [ChannelOrder](https://pub.dev/documentation/image/latest/image/ChannelOrder.html) enum
defines channel ordering, and certain Image functions can use that to convert the incoming or outgoing
image data.

[Image.fromBytes](https://pub.dev/documentation/image/latest/image/Image/Image.fromBytes.html) can take an optional
`ChannelOrder order` argument to specify the order of the color channels
in image data coming from an external source. If the external image data is defined in BGRA order, you can specify
`Image.fromBytes(order: ChannelOrder.bgra, ...)` to make sure the Image is created with the correct colors.

[Image.getBytes({ChannelOrder? order})](https://pub.dev/documentation/image/latest/image/Image/Image.getBytes.html)
will return the image data as a Uint8List, and if order is specified and
the channels need to be rearranged from RGBA, it will return a new byte buffer with the channel order as requested. 

[Image.remapChannels(ChannelOrder order)](https://pub.dev/documentation/image/latest/image/Image/Image.remapChannels.html) 
will remap the colors of the Image to the requested order in-place. That
means `image.remapChannels(ChannelOrder.bgra).getBytes()` will return the re-arranged channel image data, without the
need to create a new image data buffer.

### Format

The ImageData class stores the pixel data of the Image and can support a wide range of data formats.

The following formats are considered low dynamic range:
* **uint1**: stores a 1-bit value per channel, with a value range of [0, 1].
* **uint2**: stores a 2-bit value per channel, with a value range of [0, 3].
* **uint4**: stores a 4-bit value per channel, with a value range of [0, 15].
* **uint8**: stores an 8-bit value per channel, with a value range of [0, 255].

The following formats are considered high dynamic range:
* **uint16**: stores a 16-bits per channel, with a value range of [0, 65535].
* **uint32**: stores a 32-bits per channel, with a value range of [0, 4294967295].
* **int8**: stores a signed 8-bit value per channel, with a value range of [-127, 127].
* **int16**: stores a signed 16-bit value per channel, with a value range of [-32768, 32767].
* **int32**: stores a signed 32-bit value per channel, with a value range of [-2147483648, 2147483647].
* **float16**: stores a 16-bit floating-point value per channel.
* **float32**: stores a 32-bit floating-point value per channel.
* **float64**: stores a 64-bit floating-point value per channel.

The formats that have fewer than 1 byte per channel, uint1, uint2, and uint4, will be stored in packed bits with a
row stride. That means a uint1 image with 1 channel, will be store 8 pixels per byte. A uint1 image with 4 channels
will store 4-bits per pixel, and 2 pixels per byte. Bit packing is separated per pixel row, so the remaining unused
bits of the last byte of a row will remain unused as padding.

```dart
Format format = image.format; // The Format of the image data.
int bpp = image.bitsPerPixel; // The number of bits per channel
int stride = image.rowStride; // The number of bytes for a single row of pixels.
int size = image.lengthInBytes; // The number of bytes to store all pixel data.
ByteBuffer buffer = image.buffer; // The buffer used to store the pixel data.
Uint8List bytes = image.toUint8List(); // A Uint8List view of the pixel data buffer.
Uint8List bytes = image.getBytes(order: ChannelOrder.abgr); // Like toUint8List, but can remap the color channels.
int numChannels = image.numChannels; // The number of channels per pixel.
bool isLdr = image.isLdrFormat; // Is the pixel format a low dynamic range format?
bool isHdr = image.isHdrFormat; // Is the pixel format a high dynamic range format?
num maxValue = image.maxChannelValue; // The maximum value of a pixel channel.
```

**numChannels** is a bit peculiar. If the Image has a palette, then it will be the number of palette color
channels, not the number of channels for the actual pixel, which will always be 1.

## Palettes

An Image can have a palette, in which case it has 1 channel per pixel which is the index into the palette.
A palette can be of any format and have any number of colors or channels. A palette should have enough
colors for the largest index value used by a pixel.

```dart
bool hasPalette = image.hasPalette; // True if the image has a palette.
Palette? palette = image.palette; // Will be the Palette of image if it has one, otherwise null.
bool supportsPalette = image.supportsPalette; // Will be true if the pixel Format can support a palette.
```
A Palette can have any number of colors, any format, and 1-4 channels per color.
```dart
final palette = image.palette;
if (palette != null) {
  int numColors = palette.numColors; // The number of colors stored by the palette
  int numChannels = palette.numChannels; // The number of channels per color.
  Format format = palette.format; // The color Format of the palette.
  num red = palette.getRed(0); // Get the value of the red channel of the 1st color in the palette.
  num green = palette.getGreen(0); // Get the value of the green channel of the 1st color in the palette.
  num blue = palette.getBlue(0); // Get the value of the blue channel of the 1st color in the palette.
  num alpha = palette.getAlpha(0); // Get the value of the alpha channel of the 1st color in the palette.
  green = palette.get(0, 1); // Get the green (1) channel of the 1st color of the palette.
  palette.set(0, 1, 42); // Set the green (1) channel of the 1st color of the palette.
  palette.setColor(0, 128, 42, 80, 255); // Set the RGBA 1st color of the palette.
}
```

## Animation

Some image formats, such as Gif, PNG, or WebP, support multiple frames for animation or other purposes.
An Image has a frames list. For non-animated images, the frames list will have a single element, the image
itself. For animated images, the frames list will include the other frames of the animation.

```dart
bool hasAnim = image.hasAnimation; // True if the image has more than 1 frame.
int loopCount = image.loopCount; // The repeat count for the animated image, 0 means repeat forever.
FrameType type = image.frameType; // How frames can be interpreted, as animation, pages, or just a sequence of images.
for (final frame in image.frames) { // Iterate over the frames of the image.
  final frameIndex = frame.frameIndex; // The index of the frame in the frame list.
  final duration = frmae.frameDuration; // The duration of the frame, in milliseconds.
}
```
Frames are always stored as full images, meaning they don't support blend modes, clear states, or partial frames.

## Creating Images

Images can be created by [decoding](formats.md) them from an image file, or by manually creating them.

```dart
// Create an image with the default uint8 format and default number of channels, 3.
final rgb8 = Image(width: 256, height: 256);
// Create an 8-bit rgba image.
final rgba8 = Image(width: 256, height: 256, numChannels: 4);
// Create an 8-bit image with an rgb palette.
final rgbPalette = Image(width: 256, height: 256, withPalette: true);
// Create an 8-bit image with an rgba palette.
final rgbaPalette = Image(width: 256, height: 256, numChannels: 4, withPalette: true);
// Create a 1-bit, 1-channel Image.
final bitmap = Image(width: 256, height: 256, format: Format.uint1, numChannels: 1);
// Create a 16-bit floating point rgba image.
final float16Image = Image(width: 256, height: 256, format: Format.float16);
```

### Copying images

```dart
// Create a copy of rgb8
final copyRgb8 = Image.from(rgb8);
// You can also use the clone method
final copyRgba8 = rgba8.clone();
```

### Creating images from external image data

```dart
final image = Image.fromBytes(width: externalImageWidth, height: externalImageHeight,
    bytes: externalImageBytes, rowStride: externalImageRowStride, numChannels: externalImageNumChannels);
```
**rowStride** tells the library how many bytes are in a pixel row of the external image data. By default it will
assume (width * bytesPerPixel) for the rowStride, depending on the format of the image.

## Converting Images

Images will be decoded to a format as close to the encoded format as possible. Decoding a GIF will remain a
paletted 8-bit image, and 1-bit per pixel BMP or TIFF will remain 1-bit per pixel.

Sometimes it's necessary to convert an image to a different format.

```dart
// Convert the image to the uint8 format, with the same number of channels.
Image u8 = image.convert(format: Format.uint8);
// Convert to an RGBA image. If an alpha channel needs to be added, set the alpha of all pixels to the max value of
// the format.
Image rgba = image.convert(numChannels: 4, alpha: image.maxChannelValue);
// Convert to an 8-bit RGBA image, setting all alpha channels to 255 if an alpha channel needed to be added.
Image u8rgba = image.convert(format: Format.uint8, numChannels: 4, alpha: 255);
```

In addition to converting an entire image, you can convert pixel colors individually.
```dart
final pixel = image.getPixel(0, 0);
// Convert the pixel color to an 8-bit rgba color.
final u8rgba = pixel.convert(format: Format.uint8, numChannels: 4, alpha: 255);
```

## Pixel Access

The Pixel class is used for getting and setting the values of a pixel in an image. It is an accessor to
the image data at a particular pixel location.

To get a pixel of an image, you can use 
```dart
final pixel = image.getPixel(x, y);
```
This will return a pixel at the given coordinates. You can get and set channel values using
```dart
pixel.r = 120; // Set the red channel of the pixel.
pixel.g = 50; // Set the green channel of the pixel.
pixel.b = 75; // Set the blue channel of the pixel.
pixel.a = 255; // Set the alpha channel of the pixel.
print(pixel.length); // The number of channels for the pixel
pixel[1] = 50; // Sets the green (index 1) channel of the pixel.
for (final ch in pixel) {
  print(ch); // Will print 120, 50, 75, 255
}
print(pixel.maxChannelValue); // Will print the max value of a channel for the pixel format. For uint8, it will be 255.
print(pixel.x); // The x coordinate of the pixel.
print(pixel.y); // The y coordinate of the pixel.
print(pixel.width); // The width of the image the pixel belongs to.
print(pixel.height); // The height of hte image the pixel belongs to.
```
If the pixel has fewer channels than is set from the Pixel object, the value will be ignored, and 0 will be returned
when asked.

### Normalized Color Values

Pixels and Colors provide accessors for normalized color channels. Normalized color channels are always in the range
[0, 1], a result of dividing the channel by the maxChannelValue of the color. You can get and set a channel value
using normalized channels. This makes it trivial to translate colors between different formats.

```dart
pixel.r = 51;
final rn = pixel.rNormalized; // rNormalized will be 0.2 (51/255)
pixel.rNormalized = 0.5; // Set the normalized value of the red channel. The red value will be 127 (0.5 * 255).floor().
```

### Pixel Luminance (aka Brightness or Grayscale)

Pixels provide a convenience fake channel called **luminance**. It is not available from channel iterators,
but chas a getter. This will calculate the luminance (grayscale) of the pixels color.

```dart
pixel.r = 128;
pixel.g = 255;
pixel.b = 40;
print(pixel.luminance); // The luminance of the color is 192
print(pixel.luminanceNormalized); // The normalized luminance of the color is approximately 0.75.
```

### Pixels of Palette Images

If an image has a palette, then the r, g, b, and a properties of Pixel will return the palette color, not the pixel
index value. Setting the r channel value will set the index value. To get the index value of the pixel, Pixel has an
**index** property.
```dart
print(pixel.index); // Will print the index value of the pixel if the image has a palette, otherwise the red channel.
pixel.index = 5; // Will set the index value of hte pixel if the image has a palette, otherwise the red channel.
```

## Pixel iterators

There are several ways to iterate over the pixels of an Image.

You can iterate over all of the pixels in an image using the Image iterator.
```dart
for (final pixel in image) {
  pixel.r = pixel.x; // Set the red channel to the value of the x coordinate of the pixel.
  pixel.g = pixel.y; // Set the green channel to the value of the y coordinate of the pixel.
  pixel.a = pixel.maxChannelValue; // Make sure the pixel is opaque by setting its alpha to the max value.
}
```

You can iterate over a rectangular range of pixels with a PixelRangeIterator.
```dart
// Iterate over the pixels in a rectangular range with a top-left pixel of x,y and the given width and height. 
final range = image.getRange(x, y, width, height);
while (range.moveNext()) {
  final pixel = range.current;
  pixel.r = pixel.maxChannelValue - pixel.r; // Invert the red channel.
  pixel.g = pixel.maxChannelValue - pixel.g; // Invert the green channel.
  pixel.b = pixel.maxChannelValue - pixel.b; // Invert the blue channel.
}
```

A Pixel itself is also an iterator.
```dart
// Get the first pixel of the last row from the image.
final pixel = image.getPixel(0, image.height - 1);
do {
  pixel.a = 0; // Set the alpha to 0, making it transparent
} while (pixel.moveNext()); // Iterate for the remaining pixels of the image.
```

