# Image File Formats

Dart Image Library supports a wide range of image file formats for both decoding and encoding.

Sometimes you don't know what the format of an image file is.
```dart
Image? decodeImage(Uint8List data, { int? frame });
```
Will guess the format by trying to parse it with the supported decoders. It won't do a full decode to determine if the
data is valid for a decoder, but it is still slower than using an explicit decode function as listed below. 

## JPEG: decoding, encoding
```dart
Image? decodeJpg(Uint8List bytes);

Uint8List encodeJpg(Image image, { int quality = 100 });
```
## PNG: decoding, encoding
```dart
Image? decodePng(Uint8List bytes, { int? frame });

Uint8List encodePng(Image image, { bool singleFrame = false, int level = 6,
PngFilter filter = PngFilter.paeth });
```
## GIF: decoding, encoding
```dart
Image? decodeGif(Uint8List bytes, { int? frame });

Uint8List encodeGif(Image image, {
    bool singleFrame = false,
    int repeat = 0,
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false });
```
## WebP: decoding only
```dart
Image? decodeWebP(Uint8List bytes, { int? frame });
```
## BMP: decoding, encoding
```dart
Image? decodeBmp(Uint8List bytes, { int? frame });

Uint8List encodeBmp(Image image);
```
## TGA: decoding, encoding
```dart
Image? decodeTga(Uint8List bytes);

Uint8List encodeTga(Image image);
```
## TIFF: decoding, encoding
```dart
Image? decodeTiff(Uint8List bytes, { int? frame });

Uint8List encodeTiff(Image image, { bool singleFrame = false });
```
## OpenEXR: decoding only
```dart
Image? decodeExr(Uint8List bytes, { int? frame });
```
## PSD: decoding only
```dart
Image? decodePsd(Uint8List bytes, { int? frame });
```
## ICO: decoding, encoding
```dart
Image? decodeIco(Uint8List bytes, { int? frame });

Uint8List encodeIco(Image image, { bool singleFrame = false });
```
## CUR: encoding only
```dart
Uint8List encodeCur(Image image, { bool singleFrame = false });
```
