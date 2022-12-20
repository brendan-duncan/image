import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../filter/dither_image.dart';
import '../formats/bmp_decoder.dart';
import '../formats/bmp_encoder.dart';
import '../formats/cur_encoder.dart';
import '../formats/decoder.dart';
import '../formats/encoder.dart';
import '../formats/exr_decoder.dart';
import '../formats/formats.dart';
import '../formats/gif_decoder.dart';
import '../formats/gif_encoder.dart';
import '../formats/ico_decoder.dart';
import '../formats/ico_encoder.dart';
import '../formats/jpeg_decoder.dart';
import '../formats/jpeg_encoder.dart';
import '../formats/png_decoder.dart';
import '../formats/png_encoder.dart';
import '../formats/psd_decoder.dart';
import '../formats/tga_decoder.dart';
import '../formats/tga_encoder.dart';
import '../formats/tiff_decoder.dart';
import '../formats/tiff_encoder.dart';
import '../formats/webp_decoder.dart';
import '../image/animation.dart';
import '../image/image.dart';

class _DecodeParam {
  final SendPort port;
  final Decoder decoder;
  final String? path;
  final Uint8List? bytes;
  _DecodeParam.bytes(this.port, this.decoder, this.bytes)
      : path = null;
  _DecodeParam.file(this.port, this.decoder, this.path)
      : bytes = null;
}

Future<void> _decode(_DecodeParam param) async {
  final bytes = param.bytes ?? File(param.path!).readAsBytesSync();
  final image = param.decoder.decodeImage(bytes);
  Isolate.exit(param.port, image);
}

Future<void> _decodeAnim(_DecodeParam param) async {
  final bytes = param.bytes ?? File(param.path!).readAsBytesSync();
  final anim = param.decoder.decodeAnimation(bytes);
  Isolate.exit(param.port, anim);
}

class _EncodeParam {
  final SendPort port;
  final Encoder encoder;
  final Image? image;
  final Animation? anim;
  _EncodeParam.image(this.port, this.encoder, this.image)
      : anim = null;
  _EncodeParam.anim(this.port, this.encoder, this.anim)
      : image = null;
}

Future<void> _encode(_EncodeParam param) async {
  if (param.anim != null) {
    final bytes = param.encoder.encodeAnimation(param.anim!);
    Isolate.exit(param.port, bytes);
  }
  final bytes = param.encoder.encodeImage(param.image!);
  Isolate.exit(param.port, bytes);
}

class _DecodeImage {
  final SendPort port;
  final String? path;
  final Uint8List? bytes;
  _DecodeImage.file(this.port, this.path)
      : bytes = null;
  _DecodeImage.bytes(this.port, this.bytes)
      : path = null;
}

Future<void> _decodeImage(_DecodeImage param) async {
  final bytes = param.bytes ?? await File(param.path!).readAsBytes();
  final image = decodeImage(bytes);
  Isolate.exit(param.port, image);
}

Future<void> _decodeAnimation(_DecodeImage param) async {
  final bytes = param.bytes ?? await File(param.path!).readAsBytes();
  final image = decodeAnimation(bytes);
  Isolate.exit(param.port, image);
}

/// Asynchronously decode the given image file by first identifying the format
/// of the file and using that decoder to decode the file into a single frame
/// [Image].
/// **WARNING** Since this will check the image data against all known decoders,
/// it is much slower than using an explicit decoder.
Future<Image?> decodeImageFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeImage,
      _DecodeImage.file(port.sendPort, path));
  return await port.first as Image?;
}

/// Asynchronously decode the given image file bytes by first identifying the
/// format of the file and using that decoder to decode the file into a single
/// frame [Image].
/// **WARNING** Since this will check the image data against all known decoders,
/// it is much slower than using an explicit decoder.
Future<Image?> decodeImageAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeImage,
      _DecodeImage.bytes(port.sendPort, data));
  return await port.first as Image?;
}

/// Asynchronously decode the given image file by first identifying the
/// format of the file and using that decoder to decode the file into an
/// [Animation] containing one or more [Image] frames.
/// **WARNING** Since this will check the image data against all known decoders,
/// it is much slower than using an explicit decoder.
Future<Animation?> decodeAnimationFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnimation,
      _DecodeImage.file(port.sendPort, path));
  return await port.first as Animation?;
}

/// Asynchronously decode the given image file bytes by first identifying the
/// format of the file and using that decoder to decode the file into an
/// [Animation] containing one or more [Image] frames.
/// **WARNING** Since this will check the image data against all known decoders,
/// it is much slower than using an explicit decoder.
Future<Animation?> decodeAnimationAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnimation,
      _DecodeImage.bytes(port.sendPort, data));
  return await port.first as Animation?;
}

/// Asynchronously decode an [Image] from JPEG [data].
Future<Image?> decodeJpgAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.bytes(port.sendPort, JpegDecoder(), data));
  return await port.first as Image?;
}

/// Asynchronously decode an [Image] from a JPEG file at the given [path].
Future<Image?> decodeJpgFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.file(port.sendPort, JpegDecoder(), path));
  return await port.first as Image?;
}

/// Asynchronously encode an [Image] to the JPEG format.
Future<Uint8List> encodeJpgAsync(Image image, {int quality = 100}) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.image(port.sendPort, JpegEncoder(quality: quality), image));
  return await port.first as Uint8List;
}

/// Asynchronously decode an [Image] from PNG [data].
Future<Image?> decodePngAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.bytes(port.sendPort, PngDecoder(), data));
  return await port.first as Image?;
}

/// Asynchronously decode an [Image] from a PNG file at the given [path].
Future<Image?> decodePngFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.file(port.sendPort, PngDecoder(), path));
  return await port.first as Image?;
}

/// Asynchronously decode an [Animation] from PNG [data]. If the PNG does
/// not have animation, it will return an [Animation] with a single frame.
Future<Animation?> decodePngAnimationAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnim,
      _DecodeParam.bytes(port.sendPort, PngDecoder(), data));
  return await port.first as Animation?;
}

/// Asynchronously decode an [Image] from a PNG file at the given [path].
Future<Animation?> decodePngAnimationFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnim,
      _DecodeParam.file(port.sendPort, PngDecoder(), path));
  return await port.first as Animation?;
}

/// Asynchronously encode an [Image] to the PNG format.
Future<Uint8List> encodePngAsync(Image image,
    { int level = 6, PngFilter filter = PngFilter.paeth }) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.image(port.sendPort,
          PngEncoder(level: level, filter: filter), image));
  return await port.first as Uint8List;
}

/// Asynchronously encode an [Animation] to the APNG format.
Future<Uint8List> encodePngAnimationAsync(Animation anim,
    { int level = 6, PngFilter filter = PngFilter.paeth }) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.anim(port.sendPort,
          PngEncoder(level: level, filter: filter), anim));
  return await port.first as Uint8List;
}

/// Asynchronously decode an [Image] from GIF [data].
Future<Image?> decodeGifAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.bytes(port.sendPort, GifDecoder(), data));
  return await port.first as Image?;
}

/// Asynchronously decode an [Image] from a GIF file at the given [path].
Future<Image?> decodeGifFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.file(port.sendPort, GifDecoder(), path));
  return await port.first as Image?;
}

/// Asynchronously decode an [Animation] from GIF [data]. If the GIF does not
/// have animation, it will return an [Animation] with a single frame.
Future<Animation?> decodeGifAnimationAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnim,
      _DecodeParam.bytes(port.sendPort, GifDecoder(), data));
  return await port.first as Animation?;
}

/// Asynchronously decode an [Animation] from a GIF file at the given [path].
/// If the GIF does not have animation, it will return an [Animation] with a
/// single frame.
Future<Animation?> decodeGifAnimationFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnim,
      _DecodeParam.file(port.sendPort, GifDecoder(), path));
  return await port.first as Animation?;
}

/// Asynchronously encode an [Image] to the GIF format.
Future<Uint8List> encodeGifAsync(Image image, {
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false }) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.image(port.sendPort, GifEncoder(
        samplingFactor: samplingFactor, dither: dither,
          ditherSerpentine: ditherSerpentine), image));
  return await port.first as Uint8List;
}

/// Asynchronously encode an [Animation] to the GIF format.
Future<Uint8List> encodeGifAnimationAsync(Animation anim, { int delay = 80,
    int repeat = 0,
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false }) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.anim(port.sendPort, GifEncoder(
          samplingFactor: samplingFactor, dither: dither,
          ditherSerpentine: ditherSerpentine,
          delay: delay, repeat: repeat), anim));
  return await port.first as Uint8List;
}

/// Asynchronously decode an [Image] from TGA [data].
Future<Image?> decodeTgaAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.bytes(port.sendPort, TgaDecoder(), data));
  return await port.first as Image?;
}

/// Asynchronously decode an [Image] from a TGA file at the given [path].
Future<Image?> decodeTgaFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.file(port.sendPort, TgaDecoder(), path));
  return await port.first as Image?;
}

/// Asynchronously encode an [Image] to the TGA format.
Future<Uint8List> encodeTgaAsync(Image image, {int quality = 100}) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.image(port.sendPort, TgaEncoder(), image));
  return await port.first as Uint8List;
}

/// Asynchronously decode an [Image] from WebP [data].
Future<Image?> decodeWebPAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.bytes(port.sendPort, WebPDecoder(), data));
  return await port.first as Image?;
}

/// Asynchronously decode an [Image] from a WebP file at the given [path].
Future<Image?> decodeWebPFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.file(port.sendPort, WebPDecoder(), path));
  return await port.first as Image?;
}

/// Asynchronously decode an [Animation] from WebP [data]. If the WebP does not
/// have animation, it will return an [Animation] with a single frame.
Future<Animation?> decodeWebPAnimationAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnim,
      _DecodeParam.bytes(port.sendPort, WebPDecoder(), data));
  return await port.first as Animation?;
}

/// Asynchronously decode an [Animation] from a WebP file at the given [path].
/// If the WebP does not have animation, it will return an [Animation] with a
/// single frame.
Future<Animation?> decodeWebPAnimationFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnim,
      _DecodeParam.file(port.sendPort, WebPDecoder(), path));
  return await port.first as Animation?;
}

/// Asynchronously decode an [Image] from BMP [data].
Future<Image?> decodeBmpAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.bytes(port.sendPort, BmpDecoder(), data));
  return await port.first as Image?;
}

/// Asynchronously decode an [Image] from a BMP file at the given [path].
Future<Image?> decodeBmpFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.file(port.sendPort, BmpDecoder(), path));
  return await port.first as Image?;
}

/// Asynchronously encode an [Image] to the BMP format.
Future<Uint8List> encodeBmpAsync(Image image) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.image(port.sendPort, BmpEncoder(), image));
  return await port.first as Uint8List;
}

/// Asynchronously decode an [Image] from TIFF [data].
Future<Image?> decodeTiffAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.bytes(port.sendPort, TiffDecoder(), data));
  return await port.first as Image?;
}

/// Asynchronously decode an [Image] from a TIFF file at the given [path].
Future<Image?> decodeTiffFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.file(port.sendPort, TiffDecoder(), path));
  return await port.first as Image?;
}

/// Asynchronously decode an [Animation] from TIFF [data]. If the TIFF does not
/// have animation, it will return an [Animation] with a single frame.
Future<Animation?> decodeTiffAnimationAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnim,
      _DecodeParam.bytes(port.sendPort, TiffDecoder(), data));
  return await port.first as Animation?;
}

/// Asynchronously decode an [Animation] from a TIFF file at the given [path].
/// If the TIFF does not have animation, it will return an [Animation] with a
/// single frame.
Future<Animation?> decodeTiffAnimationFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnim,
      _DecodeParam.file(port.sendPort, TiffDecoder(), path));
  return await port.first as Animation?;
}

/// Asynchronously encode an [Image] to the TIFF format.
Future<Uint8List> encodeTiffAsync(Image image) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.image(port.sendPort, TiffEncoder(), image));
  return await port.first as Uint8List;
}

/// Asynchronously encode an [Animation] to the TIFF format.
Future<Uint8List> encodeTiffAnimationAsync(Animation anim) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.anim(port.sendPort, TiffEncoder(), anim));
  return await port.first as Uint8List;
}

/// Asynchronously decode an [Image] from PSD [data].
Future<Image?> decodePsdAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.bytes(port.sendPort, PsdDecoder(), data));
  return await port.first as Image?;
}

/// Asynchronously decode an [Image] from a PSD file at the given [path].
Future<Image?> decodePsdFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.file(port.sendPort, PsdDecoder(), path));
  return await port.first as Image?;
}

/// Asynchronously decode an [Image] from ICO [data].
Future<Image?> decodeIcoAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.bytes(port.sendPort, IcoDecoder(), data));
  return await port.first as Image?;
}

/// Asynchronously decode an [Image] from a ICO file at the given [path].
Future<Image?> decodeIcoFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.file(port.sendPort, IcoDecoder(), path));
  return await port.first as Image?;
}

/// Asynchronously decode an [Animation] from ICO [data]. If the ICO does not
/// have animation, it will return an [Animation] with a single frame.
Future<Animation?> decodeIcoAnimationAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnim,
      _DecodeParam.bytes(port.sendPort, IcoDecoder(), data));
  return await port.first as Animation?;
}

/// Asynchronously decode an [Animation] from a ICO file at the given [path].
/// If the ICO does not have animation, it will return an [Animation] with a
/// single frame.
Future<Animation?> decodeIcoAnimationFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decodeAnim,
      _DecodeParam.file(port.sendPort, IcoDecoder(), path));
  return await port.first as Animation?;
}

/// Asynchronously encode an [Image] to the ICO format.
Future<Uint8List> encodeIcoAsync(Image image) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.image(port.sendPort, IcoEncoder(), image));
  return await port.first as Uint8List;
}

/// Asynchronously encode an [Animation] to the ICO format.
Future<Uint8List> encodeIcoAnimationAsync(Animation anim) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.anim(port.sendPort, IcoEncoder(), anim));
  return await port.first as Uint8List;
}

/// Asynchronously encode an [Image] to the CUR format.
Future<Uint8List> encodeCurAsync(Image image) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.image(port.sendPort, CurEncoder(), image));
  return await port.first as Uint8List;
}

/// Asynchronously encode an [Animation] to the CUR format.
Future<Uint8List> encodeCurAnimationAsync(Animation anim) async {
  final port = ReceivePort();
  await Isolate.spawn(_encode,
      _EncodeParam.anim(port.sendPort, CurEncoder(), anim));
  return await port.first as Uint8List;
}

/// Asynchronously decode an [Image] from EXR [data].
Future<Image?> decodeExrAsync(Uint8List data) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.bytes(port.sendPort, ExrDecoder(), data));
  return await port.first as Image?;
}

/// Asynchronously decode an [Image] from a EXR file at the given [path].
Future<Image?> decodeExrFileAsync(String path) async {
  final port = ReceivePort();
  await Isolate.spawn(_decode,
      _DecodeParam.file(port.sendPort, ExrDecoder(), path));
  return await port.first as Image?;
}
