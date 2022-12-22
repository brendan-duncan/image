import 'dart:typed_data';

import '../filter/dither_image.dart';
import '../image/image.dart';
import 'bmp_decoder.dart';
import 'bmp_encoder.dart';
import 'cur_encoder.dart';
import 'decoder.dart';
import 'encoder.dart';
import 'exr_decoder.dart';
import 'gif_decoder.dart';
import 'gif_encoder.dart';
import 'ico_decoder.dart';
import 'ico_encoder.dart';
import 'jpeg_decoder.dart';
import 'jpeg_encoder.dart';
import 'png_decoder.dart';
import 'png_encoder.dart';
import 'psd_decoder.dart';
import 'tga_decoder.dart';
import 'tga_encoder.dart';
import 'tiff_decoder.dart';
import 'tiff_encoder.dart';
import 'webp_decoder.dart';

/// Return the [Decoder] that can decode image with the given [name],
/// by looking at the file extension.
Decoder? getDecoderForNamedImage(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) {
    return JpegDecoder();
  }
  if (n.endsWith('.png')) {
    return PngDecoder();
  }
  if (n.endsWith('.tga')) {
    return TgaDecoder();
  }
  if (n.endsWith('.webp')) {
    return WebPDecoder();
  }
  if (n.endsWith('.gif')) {
    return GifDecoder();
  }
  if (n.endsWith('.tif') || n.endsWith('.tiff')) {
    return TiffDecoder();
  }
  if (n.endsWith('.psd')) {
    return PsdDecoder();
  }
  if (n.endsWith('.exr')) {
    return ExrDecoder();
  }
  if (n.endsWith('.bmp')) {
    return BmpDecoder();
  }
  if (n.endsWith('.ico')) {
    return IcoDecoder();
  }
  return null;
}

/// Return the [Encoder] that can decode image with the given [name],
/// by looking at the file extension.
Encoder? getEncoderForNamedImage(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) {
    return JpegEncoder();
  }
  if (n.endsWith('.png')) {
    return PngEncoder();
  }
  if (n.endsWith('.tga')) {
    return TgaEncoder();
  }
  if (n.endsWith('.gif')) {
    return GifEncoder();
  }
  if (n.endsWith('.tif') || n.endsWith('.tiff')) {
    return TiffEncoder();
  }
  if (n.endsWith('.bmp')) {
    return BmpEncoder();
  }
  if (n.endsWith('.ico')) {
    return IcoEncoder();
  }
  if (n.endsWith('.cur')) {
    return IcoEncoder();
  }
  return null;
}

/// Find a [Decoder] that is able to decode the given image [data].
/// Use this is you don't know the type of image it is.
/// **WARNING** Since this will check the image data against all known decoders,
/// it is much slower than using an explicit decoder.
Decoder? findDecoderForData(List<int> data) {
  // The various decoders will be creating a Uint8List for their InputStream
  // if the data isn't already that type, so do it once here to avoid having
  // to do it multiple times.
  final bytes = data is Uint8List ? data : Uint8List.fromList(data);

  final jpg = JpegDecoder();
  if (jpg.isValidFile(bytes)) {
    return jpg;
  }

  final png = PngDecoder();
  if (png.isValidFile(bytes)) {
    return png;
  }

  final gif = GifDecoder();
  if (gif.isValidFile(bytes)) {
    return gif;
  }

  final webp = WebPDecoder();
  if (webp.isValidFile(bytes)) {
    return webp;
  }

  final tiff = TiffDecoder();
  if (tiff.isValidFile(bytes)) {
    return tiff;
  }

  final psd = PsdDecoder();
  if (psd.isValidFile(bytes)) {
    return psd;
  }

  final exr = ExrDecoder();
  if (exr.isValidFile(bytes)) {
    return exr;
  }

  final bmp = BmpDecoder();
  if (bmp.isValidFile(bytes)) {
    return bmp;
  }

  final tga = TgaDecoder();
  if (tga.isValidFile(bytes)) {
    return tga;
  }

  final ico = IcoDecoder();
  if (ico.isValidFile(bytes)) {
    return ico;
  }

  return null;
}

/// Decode the given image file bytes by first identifying the format of the
/// file and using that decoder to decode the file into a single frame [Image].
/// **WARNING** Since this will check the image data against all known decoders,
/// it is much slower than using an explicit decoder.
Image? decodeImage(Uint8List data, { int? frame }) {
  final decoder = findDecoderForData(data);
  return decoder?.decode(data, frame: frame);
}

/// Decode a JPG formatted image.
Image? decodeJpg(Uint8List bytes) => JpegDecoder().decode(bytes);

/// Encode an image to the JPEG format.
Uint8List encodeJpg(Image image, { int quality = 100 }) =>
    JpegEncoder(quality: quality).encode(image);

/// Decode a PNG formatted image.
Image? decodePng(Uint8List bytes, { int? frame }) =>
    PngDecoder().decode(bytes, frame: frame);

/// Encode an image to the PNG format.
Uint8List encodePng(Image image, { bool singleFrame = false, int level = 6,
    PngFilter filter = PngFilter.paeth }) =>
    PngEncoder(filter: filter, level: level)
        .encode(image, singleFrame: singleFrame);

/// Decode a Targa formatted image.
Image? decodeTga(Uint8List bytes, { int? frame }) =>
    TgaDecoder().decode(bytes, frame: frame);

/// Encode an image to the Targa format.
Uint8List encodeTga(Image image) => TgaEncoder().encode(image);

/// Decode a WebP formatted image
Image? decodeWebP(Uint8List bytes, { int? frame }) =>
    WebPDecoder().decode(bytes, frame: frame);

/// Decode a GIF formatted image.
Image? decodeGif(Uint8List bytes, { int? frame }) =>
    GifDecoder().decode(bytes, frame: frame);

/// Encode an image to the GIF format.
///
/// The [samplingFactor] specifies the sampling factor for
/// NeuQuant image quantization. It is responsible for reducing
/// the amount of unique colors in your images to 256.
/// A sampling factor of 10 gives you a reasonable trade-off between
/// image quality and quantization speed.
/// If you know that you have less than 256 colors in your frames
/// anyway, you should supply a very large [samplingFactor] for maximum
/// performance.
Uint8List encodeGif(Image image, {
    bool singleFrame = false,
    int repeat = 0,
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false }) =>
    GifEncoder(samplingFactor: samplingFactor, dither: dither,
        ditherSerpentine: ditherSerpentine).encode(image,
            singleFrame: singleFrame);

/// Decode a TIFF formatted image.
Image? decodeTiff(Uint8List bytes, { int? frame }) =>
    TiffDecoder().decode(bytes, frame: frame);

Uint8List encodeTiff(Image image, { bool singleFrame = false }) =>
    TiffEncoder().encode(image, singleFrame: singleFrame);

/// Decode a Photoshop PSD formatted image.
Image? decodePsd(Uint8List bytes, { int? frame }) =>
    PsdDecoder().decode(bytes, frame: frame);

/// Decode an OpenEXR formatted image. EXR is a high dynamic range format.
Image? decodeExr(Uint8List bytes, { int? frame }) =>
    ExrDecoder().decode(bytes, frame: frame);

/// Decode a BMP formatted image.
Image? decodeBmp(Uint8List bytes, { int? frame }) =>
    BmpDecoder().decode(bytes, frame: frame);

/// Encode an [Image] to the BMP format.
Uint8List encodeBmp(Image image) => BmpEncoder().encode(image);

/// Encode an [Image] to the CUR format.
Uint8List encodeCur(Image image, { bool singleFrame = false }) =>
    CurEncoder().encode(image, singleFrame: singleFrame);

/// Encode an image to the ICO format.
Uint8List encodeIco(Image image, { bool singleFrame = false }) =>
    IcoEncoder().encode(image, singleFrame: singleFrame);

/// Decode an ICO image.
Image? decodeIco(Uint8List bytes, { int? frame }) =>
    IcoDecoder().decode(bytes, frame: frame);
