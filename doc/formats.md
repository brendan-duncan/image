# Image File Formats

Dart Image Library supports a wide range of image file formats for both decoding and encoding.

## Supported Formats

### Read/Write
* JPEG
* PNG + Animated APNG
* GIF + Animated GIF
* TIFF
* BMP
* TGA
* ICO
* PVRTC

### Read Only
* WebP + Animated WebP
* Photoshop PSD
* OpenEXR
* PNM (PBM, PGM, PPM)

### Write Only
* CUR

## Decoding Images

Sometimes you don't know what the format of an image file is.
```dart
Image? decodeImage(Uint8List data, { int? frame });
```
Will guess the format by trying to parse it with the supported decoders. It won't do a full decode to determine if the
data is valid for a decoder, but it is still slower than using an explicit decode function as listed below.

If you know the image file name, you can use the filename extension to determine the decoder to use.
```dart
Image? decodeNamedImage(String path, Uint8List data, { int? frame });
```

You can also load an image directly from a file given its path, on platforms that support dart:io.
```dart
Future<Image?> decodeImageFile(String path, { int? frame }) async;
```

## Encoding Images

You can encode an image to a file format using a format specific encode function, or the general:
```dart
Uint8List? encodeNamedImage(String path, Image image);

Future<bool> encodeImageFile(String path, Image image) async;
```

## Decoding and Encoding Specific Formats

### JPEG: decoding, encoding
```dart
Image? decodeJpg(Uint8List bytes);

// Decode an image file directly from the file on platforms that support dart:io.
Future<Image?> decodeJpgFile(String path) async;

Uint8List encodeJpg(Image image, { int quality = 100, chroma: JpegChroma.yuv444 });

Future<bool> encodeJpgFile(String path, Image image, { int quality = 100, chroma: JpegChroma.yuv444 }) async;
```
### PNG: decoding, encoding
```dart
Image? decodePng(Uint8List bytes);

Future<Image?> decodePngFile(String path) async;

Uint8List encodePng(Image image, { int level = 6, PngFilter filter = PngFilter.paeth });

Future<bool> encodePngFile(String path, Image image,
    { bool singleFrame = false, int level = 6, PngFilter filter = PngFilter.paeth }) async;
```
### GIF: decoding, encoding
```dart
Image? decodeGif(Uint8List bytes);

Future<Image?> decodeGifFile(String path, { int? frame }) async;

Uint8List encodeGif(Image image, {
    int repeat = 0,
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false });

Future<bool> encodeGifFile(String path, Image image, {
    bool singleFrame = false,
    int repeat = 0,
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false });
```
### WebP: decoding only
```dart
Image? decodeWebP(Uint8List bytes);

Future<Image?> decodeWebPFile(String path, { int? frame }) async;
```
### BMP: decoding, encoding
```dart
Image? decodeBmp(Uint8List bytes);

Future<Image?> decodeBmpFile(String path) async;

Uint8List encodeBmp(Image image);

Future<bool> encodeBmpFile(String path, Image image) async;
```
### TGA: decoding, encoding
```dart
Image? decodeTga(Uint8List bytes);

Future<Image?> decodeTgaFile(String path) async;

Uint8List encodeTga(Image image);

Future<bool> encodeTgaFile(String path, Image image) async;
```
### TIFF: decoding, encoding
```dart
Image? decodeTiff(Uint8List bytes);

Future<Image?> decodeTiffFile(String path, { int? frame }) async;

Uint8List encodeTiff(Image image);

Uint8List encodeTiff(Image image, { bool singleFrame = false });
```
### OpenEXR: decoding only
```dart
Image? decodeExr(Uint8List bytes);

Future<Image?> decodeExrFile(String path) async;
```
### Photoshop PSD: decoding only
```dart
Image? decodePsd(Uint8List bytes);

Future<Image?> decodePsdFile(String path) async;
```
### ICO: decoding, encoding
```dart
Image? decodeIco(Uint8List bytes);

Future<Image?> decodeIcoFile(String path, { int? frame }) async;

Uint8List encodeIco(Image image);

Future<bool> encodeIcoFile(String path, Image image,
    { bool singleFrame = false }) async;
```
### CUR: encoding only
```dart
Uint8List encodeCur(Image image);

Future<bool> encodeCurFile(String path, Image image,
    { bool singleFrame = false }) async;
```

### PVR: decoding, encoding
```dart
Image? decodePvr(Uint8List bytes, { int? frame });

Future<Image?> decodePvrFile(String path, { int? frame }) async;

Uint8List encodePvr(Image image, { bool singleFrame = false });

Future<bool> encodePvrFile(String path, Image image,
    { bool singleFrame = false }) async;
```
### PNM: decoding
```dart
Image? decodePnm(Uint8List bytes);

Future<Image?> decodePnmFile(String path) async;
```

## Decoder Classes

Sometimes Decoders for the various formats include more information about the image than you get from an Image.
You can use the Decoder classes directly to decode images, and access their additional information.

```dart
final decoder = PngDecoder();
// Returns true if the file is a valid PNG image.
decoder.isValidFile(fileBytes);
// Decodes the PNG image, returning null if the file is not a PNG.
Image? image = decoder.decode(fileBytes);

// startDecode will decode just the information from the image file without decoding the image data. 
DecodeInfo? info = decoder.startDecode(fileBytes);
if (info != null) {
  int width = info.width; // The width of the PNG image.
  int height = info.height; // The height of the PNG image.
  int numFrames = info.numFrames; // The number of frames, if it's an animated image, otherwise 1.
  final pngInfo = info as PngInfo; // The actual class of the info, in the case of PngDecoder.
  double? gamma = pngInfo.gamma; // The display gamma of the PNG
  int bits = pngInfo.bits; // How many bits per pixel for the PNG image data.
}
int numFrames = decoder.numFrames; // How many frames can be decoded.
Image? frame0 = decoder.decodeFrame(0); // Decode the 1st frame if it's animated, otherwise the image itself.
```
Each format has its own DecodeInfo derived class for specific data from that format.

```dart
// Determine the format of the given file and return its Decoder. This will need to attempt to decode the image
// with the known decoders, returning with the first decoder it finds that seems to support the data, so it is
// preferable to use a specific format decoder if you know what the format is.
Decoder? findDecoderForData(Uint8List fileBytes);

// Return the decoder based on the file name extension.
Decoder? findDecoderForNamedImage(String filename);

// Find the [ImageFormat] for the given file data.
ImageFormat findFormatForData(List<int> data);

// Create a [Decoder] for the given [format] type.
Decoder? createDecoderForFormat(ImageFormat format);
```

## Encoder Classes

Like Decoders, each format that supports encoding has an Encoder class.
```dart
final encoder = PngEncoder();
// Encode the image to the PNG format.
Uint8List fileBytes = encoder.encode(image);
// Does the encoder support encoding multi-frame images?
bool supportsAnimation = encoder.supportsAnimation;
```
You can also find the encoder for the format that uses a particular file extension.
```dart
// Return the encoder based on the file name extension.
Encoder? findEncoderForNamedImage(String filename);
```
