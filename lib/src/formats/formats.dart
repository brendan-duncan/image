import 'dart:typed_data';

import '../animation.dart';
import '../image.dart';

import 'decoder.dart';
import 'exr_decoder.dart';
import 'gif_decoder.dart';
import 'gif_encoder.dart';
import 'jpeg_decoder.dart';
import 'jpeg_encoder.dart';
import 'png_decoder.dart';
import 'png_encoder.dart';
import 'psd_decoder.dart';
import 'tga_decoder.dart';
import 'tga_encoder.dart';
import 'tiff_decoder.dart';
import 'webp_decoder.dart';

/// Find a [Decoder] that is able to decode the given image [data].
/// Use this is you don't know the type of image it is.
Decoder findDecoderForData(List<int> data) {
  // The various decoders will be creating a Uint8List for their InputStream
  // if the data isn't already that type, so do it once here to avoid having to
  // do it multiple times.
  Uint8List bytes = Uint8List.fromList(data);

  JpegDecoder jpg = JpegDecoder();
  if (jpg.isValidFile(bytes)) {
    return jpg;
  }

  PngDecoder png = PngDecoder();
  if (png.isValidFile(bytes)) {
    return png;
  }

  GifDecoder gif = GifDecoder();
  if (gif.isValidFile(bytes)) {
    return gif;
  }

  WebPDecoder webp = WebPDecoder();
  if (webp.isValidFile(bytes)) {
    return webp;
  }

  TiffDecoder tiff = TiffDecoder();
  if (tiff.isValidFile(bytes)) {
    return tiff;
  }

  PsdDecoder psd = PsdDecoder();
  if (psd.isValidFile(bytes)) {
    return psd;
  }

  ExrDecoder exr = ExrDecoder();
  if (exr.isValidFile(bytes)) {
    return exr;
  }

  return null;
}

/// Decode the given image file bytes by first identifying the format of the
/// file and using that decoder to decode the file into a single frame [Image].
Image decodeImage(List<int> data) {
  Decoder decoder = findDecoderForData(data);
  if (decoder == null) {
    return null;
  }
  return decoder.decodeImage(data);
}

/// Decode the given image file bytes by first identifying the format of the
/// file and using that decoder to decode the file into an [Animation]
/// containing one or more [Image] frames.
Animation decodeAnimation(List<int> data) {
  Decoder decoder = findDecoderForData(data);
  if (decoder == null) {
    return null;
  }
  return decoder.decodeAnimation(data);
}

/// Return the [Decoder] that can decode image with the given [name],
/// by looking at the file extension. See also [findDecoderForData] to
/// determine the decoder to use given the bytes of the file.
Decoder getDecoderForNamedImage(String name) {
  String n = name.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) {
    return new JpegDecoder();
  }
  if (n.endsWith('.png')) {
    return new PngDecoder();
  }
  if (n.endsWith('.tga')) {
    return new TgaDecoder();
  }
  if (n.endsWith('.webp')) {
    return new WebPDecoder();
  }
  if (n.endsWith('.gif')) {
    return new GifDecoder();
  }
  if (n.endsWith('.tif') || n.endsWith('.tiff')) {
    return new TiffDecoder();
  }
  if (n.endsWith('.psd')) {
    return new PsdDecoder();
  }
  if (n.endsWith('.exr')) {
    return new ExrDecoder();
  }
  return null;
}

/// Identify the format of the image using the file extension of the given
/// [name], and decode the given file [bytes] to an [Animation] with one or more
/// [Image] frames. See also [decodeAnimation].
Animation decodeNamedAnimation(List<int> bytes, String name) {
  Decoder decoder = getDecoderForNamedImage(name);
  if (decoder == null) {
    return null;
  }
  return decoder.decodeAnimation(bytes);
}

/// Identify the format of the image using the file extension of the given
/// [name], and decode the given file [bytes] to a single frame [Image]. See
/// also [decodeImage].
Image decodeNamedImage(List<int> bytes, String name) {
  Decoder decoder = getDecoderForNamedImage(name);
  if (decoder == null) {
    return null;
  }
  return decoder.decodeImage(bytes);
}

/// Identify the format of the image and encode it with the appropriate
/// [Encoder].
List<int> encodeNamedImage(Image image, String name) {
  String n = name.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) {
    return encodeJpg(image);
  }
  if (n.endsWith('.png')) {
    return encodePng(image);
  }
  if (n.endsWith('.tga')) {
    return encodeTga(image);
  }
  if (n.endsWith('.gif')) {
    return encodeGif(image);
  }
  return null;
}

/// Decode a JPG formatted image.
Image decodeJpg(List<int> bytes) {
  return new JpegDecoder().decodeImage(bytes);
}

/// Renamed to [decodeJpg], left for backward compatibility.
Image readJpg(List<int> bytes) => decodeJpg(bytes);

/// Encode an image to the JPEG format.
List<int> encodeJpg(Image image, {int quality = 100}) {
  return new JpegEncoder(quality: quality).encodeImage(image);
}

/// Renamed to [encodeJpg], left for backward compatibility.
List<int> writeJpg(Image image, {int quality = 100}) =>
    encodeJpg(image, quality: quality);

/// Decode a PNG formatted image.
Image decodePng(List<int> bytes) {
  return new PngDecoder().decodeImage(bytes);
}

/// Decode a PNG formatted animation.
Animation decodePngAnimation(List<int> bytes) {
  return new PngDecoder().decodeAnimation(bytes);
}

/// Renamed to [decodePng], left for backward compatibility.
Image readPng(List<int> bytes) => decodePng(bytes);

/// Encode an image to the PNG format.
List<int> encodePng(Image image, {int level = 6}) {
  return new PngEncoder(level: level).encodeImage(image);
}

/// Encode an animation to the PNG format.
List<int> encodePngAnimation(Animation anim, {int level = 6}) {
  return new PngEncoder(level: level).encodeAnimation(anim);
}

/// Renamed to [encodePng], left for backward compatibility.
List<int> writePng(Image image, {int level = 6}) =>
    encodePng(image, level: level);

/// Decode a Targa formatted image.
Image decodeTga(List<int> bytes) {
  return new TgaDecoder().decodeImage(bytes);
}

/// Renamed to [decodeTga], left for backward compatibility.
Image readTga(List<int> bytes) => decodeTga(bytes);

/// Encode an image to the Targa format.
List<int> encodeTga(Image image) {
  return new TgaEncoder().encodeImage(image);
}

/// Renamed to [encodeTga], left for backward compatibility.
List<int> writeTga(Image image) => encodeTga(image);

/// Decode a WebP formatted image (first frame for animations).
Image decodeWebP(List<int> bytes) {
  return new WebPDecoder().decodeImage(bytes);
}

/// Decode an animated WebP file. If the webp isn't animated, the animation
/// will contain a single frame with the webp's image.
Animation decodeWebPAnimation(List<int> bytes) {
  return new WebPDecoder().decodeAnimation(bytes);
}

/// Decode a GIF formatted image (first frame for animations).
Image decodeGif(List<int> bytes) {
  return new GifDecoder().decodeImage(bytes);
}

/// Decode an animated GIF file. If the GIF isn't animated, the animation
/// will contain a single frame with the GIF's image.
Animation decodeGifAnimation(List<int> bytes) {
  return new GifDecoder().decodeAnimation(bytes);
}

/// Encode an image to the GIF format.
///
/// The [samplingFactor] specifies the sampling factor for
/// NeuQuant image quantization. It is responsible for reducing
/// the amount of unique colors in your images to 256.
/// According to https://scientificgems.wordpress.com/stuff/neuquant-fast-high-quality-image-quantization/,
/// a sampling factor 10 gives you a reasonable trade-off between image quality
/// and quantization speed.
/// If you know that you have less than 256 colors in your frames
/// anyway, you should supply a very large [samplingFactor] for maximum performance.
List<int> encodeGif(Image image, {int samplingFactor = 30}) {
  return GifEncoder(samplingFactor: samplingFactor).encodeImage(image);
}

/// Encode an animation to the GIF format.
///
/// The [samplingFactor] specifies the sampling factor for
/// NeuQuant image quantization. It is responsible for reducing
/// the amount of unique colors in your images to 256.
/// According to https://scientificgems.wordpress.com/stuff/neuquant-fast-high-quality-image-quantization/,
/// a sampling factor 10 gives you a reasonable trade-off between image quality
/// and quantization speed.
/// If you know that you have less than 256 colors in your frames
/// anyway, you should supply a very large [samplingFactor] for maximum performance.
List<int> encodeGifAnimation(Animation anim, {int samplingFactor = 30}) {
  return GifEncoder(samplingFactor: samplingFactor).encodeAnimation(anim);
}

/// Decode a TIFF formatted image.
Image decodeTiff(List<int> bytes) {
  return new TiffDecoder().decodeImage(bytes);
}

/// Decode an multi-image (animated) TIFF file. If the tiff doesn't have
/// multiple images, the animation will contain a single frame with the tiff's
/// image.
Animation decodeTiffAnimation(List<int> bytes) {
  return new TiffDecoder().decodeAnimation(bytes);
}

/// Decode a Photoshop PSD formatted image.
Image decodePsd(List<int> bytes) {
  return new PsdDecoder().decodeImage(bytes);
}

/// Decode an OpenEXR formatted image, tone-mapped using the
/// given [exposure] to a low-dynamic-range [Image].
Image decodeExr(List<int> bytes, {double exposure = 1.0}) {
  return new ExrDecoder(exposure: exposure).decodeImage(bytes);
}
