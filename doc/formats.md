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

### Write Only
* CUR

## Decoding Images

Sometimes you don't know what the format of an image file is.
```dart
Image? decodeImage(Uint8List data);
```
Will guess the format by trying to parse it with the supported decoders. It won't do a full decode to determine if the
data is valid for a decoder, but it is still slower than using an explicit decode function as listed below.

## Decoding and Encoding Specific Formats

### JPEG: decoding, encoding
```dart
Image? decodeJpg(Uint8List bytes);

Uint8List encodeJpg(Image image, { int quality = 100 });
```
### PNG: decoding, encoding
```dart
Image? decodePng(Uint8List bytes);

Uint8List encodePng(Image image, { int level = 6, PngFilter filter = PngFilter.paeth });
```
### GIF: decoding, encoding
```dart
Image? decodeGif(Uint8List bytes);

Uint8List encodeGif(Image image, {
    int repeat = 0,
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false });
```
### WebP: decoding only
```dart
Image? decodeWebP(Uint8List bytes);
```
### BMP: decoding, encoding
```dart
Image? decodeBmp(Uint8List bytes);

Uint8List encodeBmp(Image image);
```
### TGA: decoding, encoding
```dart
Image? decodeTga(Uint8List bytes);

Uint8List encodeTga(Image image);
```
### TIFF: decoding, encoding
```dart
Image? decodeTiff(Uint8List bytes);

Uint8List encodeTiff(Image image);
```
### OpenEXR: decoding only
```dart
Image? decodeExr(Uint8List bytes);
```
### PSD: decoding only
```dart
Image? decodePsd(Uint8List bytes);
```
### ICO: decoding, encoding
```dart
Image? decodeIco(Uint8List bytes);

Uint8List encodeIco(Image image);
```
### CUR: encoding only
```dart
Uint8List encodeCur(Image image);
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
Decoder? getDecoderForNamedImage(String filename);
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
Encoder? getEncoderForNamedImage(String filename);
```