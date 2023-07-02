# Commands and Async Execution

The Command API allows sequences of image commands to be batched and optionally executed on a separate Isolate
thread.

```dart
final cmd = Command()
  ..decodePngFile('image.png')
  ..sepia(amount: 0.5)
  ..vignette()
  ..writeToFile('processedImage.png');
  // Nothing has actually been performed yet;
  // the commands have recorded the information necessary to execute later. 

const useIsolate = true;
if (useIsolate) {
  await cmd.executeThread(); // Executes in a separate Isolate thread.
} else {
  await cmd.execute(); // Executes in the main thread. It is still an async method because file IO is async.
}
```

## Executing Commands in Isolate Threads

Loading and manipulating images is expensive in terms of performance. Image files tend to be large, and Dart has limited
options for high performance execution. One way to help keep the performance issues from affecting your app is to use
multi-threading. For platforms that support it (not the web), Dart provides Isolates as its solution for
multi-threading.

The **Command.executeThread()** method will execute the commands in a separate isolate thread, resolving the promise
when it has finished. 

For platforms that do not support Isolates, executeThread will be the same as execute and run in the main thread.

NOTE: There is some performance overhead to running in an Isolate thread as it has to copy the Image data
from the Isolate to the main thread, but it has the benefit of not locking up the main thread.

## Chaining Commands

The Command class doesn't do anything itself, but when you call one of its methods, it will chain a sub-command.

```dart
final cmd = Command() // Creates a Command object, which doesn't do anything itself.
// Add a decodePngFile sub-command to the Command object
..decodePngFile('image.png')
// Add a vignette sub-command, which gets its input from the previous sub-command
..vignette() 
// Add a writeToFile sub-command, which gets its input from the previous sub-command.
..writeToFile('processedImage.png'); 
```
Commands aren't invoked until the execute or executeThread method is called. executeThread will run the command in
an Isolate thread on platforms that support Isolates.
```dart 
await cmd.execute();
```

Although execute does not run in a separate thread, it is still async because it may have file IO operations. 

You can get the last image that was processed from the command with
```dart
Image? image = await cmd.getImage();
```
If the command hadn't been executed yet, getImage will execute the command. You can also use
```dart
Image? image = await cmd.getImageThread();
```
Which will execute the command in an Isolate thread, if it hadn't already been executed.

If a command encoded an image to an image format, you can get the bytes from the last encoder command with
```dart
Uint8List? bytes = await cmd.getBytes();
```
or
```dart
Uint8List? bytes = await cmd.getBytesThread();
```
to execute the command, if needed, in an Isolate thread and return the bytes from the last encoder command. 

You can chain together multiple image and encoder commands.
```dart
await (Command()
..decodePngFile('image1.png')
..sepia()
..writeToFile('image1_out.png')
..decodeImageFile('image2.png')
..sketch()
..writeToFile('image2_out.png'))
.execute();
```

## Commands
Commands are created from methods of the Command class.

### Image Creation Commands
```dart
/// Use a specific Image.
void image(Image image);

/// Create an Image.
void createImage({ required int width, required int height,
    Format format = Format.uint8, int numChannels = 3,
    bool withPalette = false, Format paletteFormat = Format.uint8,
    Palette? palette, ExifData? exif, IccProfile? iccp, Map<String, String>? textData });

/// Convert an image by changing its format or number of channels.
void convert({ int? numChannels, Format? format, num? alpha,
  bool withPalette = false });

/// Create a copy of the current image.
void copy();

/// Add animation frames to an image.
/// typedef AddFramesFunction = Image? Function(int frameIndex);
void addFrames(int count, AddFramesFunction callback);

/// Call a callback function for each frame of an animated image.
/// typedef FilterFunction = Image Function(Image image);
void forEachFrame(FilterFunction callback);
```

### Format Decoding / Encoding Commands
```dart
void decodeImage(Uint8List data);

void decodeNamedImage(String path, Uint8List data);

void decodeImageFile(String path);

void writeToFile(String path);

void decodeBmp(Uint8List data);

void decodeBmpFile(String path);

void encodeBmp();

void encodeBmpFile(String path);

void encodeCur();

void encodeCurFile(String path);

void decodeExr(Uint8List data);

void decodeExrFile(String path);

void decodeGif(Uint8List data);

void decodeGifFile(String path);

void encodeGif({ int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false });

void encodeGifFile(String path, { int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false });

void decodeIco(Uint8List data);

void decodeIcoFile(String path);

void encodeIco();

void encodeIcoFile(String path);

void decodeJpg(Uint8List data);

void decodeJpgFile(String path);

void encodeJpg({ int quality = 100 });

void encodeJpgFile(String path, { int quality = 100 });

void decodePng(Uint8List data);

void decodePngFile(String path);

void encodePng({ int level = 6, PngFilter filter = PngFilter.paeth });

void encodePngFile(String path, { int level = 6,
    PngFilter filter = PngFilter.paeth });

void decodePsd(Uint8List data);

void decodePsdFile(String path);

void decodePvr(Uint8List data);

void decodePvrFile(String path);

void encodePvr();

void encodePvrFile(String path);

void decodeTga(Uint8List data);

void decodeTgaFile(String path);

void encodeTga();

void encodeTgaFile(String path);

void decodeTiff(Uint8List data);

void decodeTiffFile(String path);

void encodeTiff();

void encodeTiffFile(String path);

void decodeWebP(Uint8List data);

void decodeWebPFile(String path);
```

### Draw Commands
```dart
void drawChar(String char, { required BitmapFont font, required int x,
  required int y, Color? color, Command? mask, Channel maskChannel = Channel.luminance });

void drawCircle({ required int x, required int y, required int radius,
  required Color color, bool antialias = false, Command? mask, Channel maskChannel = Channel.luminance });

void compositeImage(Command? src, { int? dstX, int? dstY, int? dstW,
  int? dstH, int? srcX, int? srcY, int? srcW, int? srcH,
  BlendMode blend = BlendMode.alpha, bool linearBlend = false,
  bool center = false, Command? mask,
  Channel maskChannel = Channel.luminance });

void drawLine({ required int x1, required int y1, required int x2,
  required int y2, required Color color,
  bool antialias = false, num thickness = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void drawPixel(int x, int y, Color color, {
  BlendMode blend = BlendMode.alpha, bool linearBlend = false,
  Command? mask, Channel maskChannel = Channel.luminance });

void drawPolygon({ required List<Point> vertices, required Color color,
  Command? mask, Channel maskChannel = Channel.luminance });

void drawRect({ required int x1, required int y1, required int x2,
  required int y2, required Color color, num thickness = 1, num radius = 0,
  Command? mask, Channel maskChannel = Channel.luminance });

void drawString(String string, { required BitmapFont font, required int x,
  required int y, Color? color, bool wrap = false,
  bool rightJustify = false, Command? mask,
  Channel maskChannel = Channel.luminance });

void fill({ required Color color, Command? mask,
  Channel maskChannel = Channel.luminance });

void fillCircle({ required int x, required int y, required int radius,
  required Color color, bool antialias = false, Command? mask,
  Channel maskChannel = Channel.luminance });

void fillFlood({ required int x, required int y, required Color color,
  num threshold = 0.0, bool compareAlpha = false, Command? mask,
  Channel maskChannel = Channel.luminance });

void fillPolygon({ required List<Point> vertices, required Color color,
  Command? mask, Channel maskChannel = Channel.luminance });

void fillRect({ required int x1, required int y1, required int x2,
  required int y2, required Color color, num radius = 0, Command? mask,
  Channel maskChannel = Channel.luminance });
```

### Filtering Commands 

```dart
void adjustColor({ Color? blacks, Color? whites, Color? mids,
  num? contrast, num? saturation, num? brightness,
  num? gamma, num? exposure, num? hue, num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void billboard({ num grid = 10, num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void bleachBypass({ num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void bulgeDistortion({ int? centerX, int? centerY,
  num? radius, num scale = 0.5,
  Interpolation interpolation = Interpolation.nearest, Command? mask,
  Channel maskChannel = Channel.luminance });

void bumpToNormal({ num strength = 2 });

void chromaticAberration({ int shift = 5, Command? mask,
  Channel maskChannel = Channel.luminance });

void colorHalftone({ num amount = 1, int? centerX, int? centerY,
  num angle = 180, num size = 5, Command? mask,
  Channel maskChannel = Channel.luminance });

void colorOffset({ num red = 0, num green = 0, num blue = 0,
  num alpha = 0, Command? mask, Channel maskChannel = Channel.luminance });

void contrast({ required num contrast, Command? mask,
  Channel maskChannel = Channel.luminance });

void convolution({ required List<num> filter, num div = 1.0, num offset = 0,
  num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void copyImageChannels({ required Command? from, bool scaled = false,
  Channel? red, Channel? green, Channel? blue, Channel? alpha,
  Command? mask, Channel maskChannel = Channel.luminance});

void ditherImage({ Quantizer? quantizer,
  DitherKernel kernel = DitherKernel.floydSteinberg,
  bool serpentine = false });

void dotScreen({ num angle = 180, num size = 5.75, int? centerX,
  int? centerY, num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void dropShadow(int hShadow, int vShadow, int blur, { Color? shadowColor });

void edgeGlow({ num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void emboss({ num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void gamma({ required num gamma, Command? mask,
  Channel maskChannel = Channel.luminance });

void gaussianBlur({ required int radius, Command? mask,
  Channel maskChannel = Channel.luminance });

void grayscale({ num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void hdrToLdr({ num? exposure });

void hexagonPixelate({ int? centerX, int? centerY, int size = 5,
  num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void invert({ Command? mask,
  Channel maskChannel = Channel.luminance });

void luminanceThreshold({ num threshold = 0.5, bool outputColor = false,
  num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void monochrome({ Color? color, num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void noise(num sigma, { NoiseType type = NoiseType.gaussian,
  Random? random, Command? mask,
  Channel maskChannel = Channel.luminance });

void normalize({ required num min, required num max, Command? mask,
  Channel maskChannel = Channel.luminance });

void pixelate({ required int size, PixelateMode mode = PixelateMode.upperLeft,
  Command? mask, Channel maskChannel = Channel.luminance });

void quantize({ int numberOfColors = 256,
  QuantizeMethod method = QuantizeMethod.neuralNet,
  DitherKernel dither = DitherKernel.none,
  bool ditherSerpentine = false });

void reinhardTonemap({ Command? mask,
  Channel maskChannel = Channel.luminance });

void remapColors({ Channel red = Channel.red,
  Channel green = Channel.green,
  Channel blue = Channel.blue,
  Channel alpha = Channel.alpha });

void scaleRgba({ required Color scale, Command? mask,
  Channel maskChannel = Channel.luminance });

void separableConvolution({ required SeparableKernel kernel, Command? mask,
  Channel maskChannel = Channel.luminance });

void sepia({ num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void sketch({ num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void smooth({ required num weight, Command? mask,
  Channel maskChannel = Channel.luminance });

void sobel({ num amount = 1, Command? mask,
  Channel maskChannel = Channel.luminance });

void stretchDistortion({ int? centerX, int? centerY,
  Interpolation interpolation = Interpolation.nearest, Command? mask,
  Channel maskChannel = Channel.luminance });

void vignette({ num start = 0.3, num end = 0.75, Color? color,
  num amount = 0.8, Command? mask,
  Channel maskChannel = Channel.luminance });

/// Run an arbitrary function on the image within the Command graph.
/// A FilterFunction is in the `form Image function(Image)`. A new Image
/// can be returned, replacing the given Image; or the given Image can be
/// returned.
///
/// @example
/// final image = Command()
/// ..createImage(width: 256, height: 256)
/// ..filter((image) {
///   for (final pixel in image) {
///     pixel.r = pixel.x;
///     pixel.g = pixel.y;
///   }
///   return image;
/// })
/// ..getImage();
/// 
/// typedef FilterFunction = Image Function(Image image);
void filter(FilterFunction filter);
```

### Transform Commands

```dart
void bakeOrientation();

void copyCropCircle({ int? radius, int? centerX, int? centerY });

void copyCrop({ required int x, required int y, required int width,
  required int height, num radius = 0 });

void copyExpandCanvas({ int? newWidth, int? newHeight, int? padding,
  ExpandCanvasPosition position = ExpandCanvasPosition.center,
  Color? backgroundColor, 
  Image? toImage });

void copyFlip({ required FlipDirection direction });

void copyRectify({ required Point topLeft,
  required Point topRight,
  required Point bottomLeft,
  required Point bottomRight,
  Interpolation interpolation = Interpolation.nearest });

void copyResize({ int? width, int? height,
  Interpolation interpolation = Interpolation.nearest });

void copyResizeCropSquare({ required int size,
  Interpolation interpolation = Interpolation.nearest,
  num radius = 0});

void copyRotate({ required num angle,
  Interpolation interpolation = Interpolation.nearest });

void flip({ required FlipDirection direction });

void trim({ TrimMode mode = TrimMode.transparent, Trim sides = Trim.all });
```
