import 'dart:typed_data';

import '../filter/dither_image.dart';
import '../image/animation.dart';
import '../image/image.dart';
import 'bmp_decoder.dart';
import 'bmp_encoder.dart';
import 'cur_encoder.dart';
import 'decoder.dart';
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
Image? decodeImage(Uint8List data) {
    final decoder = findDecoderForData(data);
    return decoder?.decodeImage(data);
}

/// Decode the given image file bytes by first identifying the format of the
/// file and using that decoder to decode the file into an [Animation]
/// containing one or more [Image] frames.
/// **WARNING** Since this will check the image data against all known decoders,
/// it is much slower than using an explicit decoder.
Animation? decodeAnimation(Uint8List data) {
    final decoder = findDecoderForData(data);
    return decoder?.decodeAnimation(data);
}

/// Decode a JPG formatted image.
Image? decodeJpg(Uint8List bytes) => JpegDecoder().decodeImage(bytes);

/// Encode an image to the JPEG format.
Uint8List encodeJpg(Image image, {int quality = 100}) =>
    JpegEncoder(quality: quality).encodeImage(image);

/// Decode a PNG formatted image.
Image? decodePng(Uint8List bytes) => PngDecoder().decodeImage(bytes);

/// Decode a PNG formatted animation.
Animation? decodePngAnimation(Uint8List bytes) =>
    PngDecoder().decodeAnimation(bytes);

/// Encode an image to the PNG format.
Uint8List encodePng(Image image,
    { int level = 6, PngFilter filter = PngFilter.paeth }) =>
    PngEncoder(filter: filter, level: level).encodeImage(image);

/// Encode an animation to the PNG format.
Uint8List encodePngAnimation(Animation anim,
    {int level = 6, PngFilter filter = PngFilter.paeth}) =>
    PngEncoder(level: level, filter: filter).encodeAnimation(anim);

/// Decode a Targa formatted image.
Image? decodeTga(Uint8List bytes) => TgaDecoder().decodeImage(bytes);

/// Encode an image to the Targa format.
Uint8List encodeTga(Image image) => TgaEncoder().encodeImage(image);

/// Decode a WebP formatted image (first frame for animations).
Image? decodeWebP(Uint8List bytes) => WebPDecoder().decodeImage(bytes);

/// Decode an animated WebP file. If the webp isn't animated, the animation
/// will contain a single frame with the webp's image.
Animation? decodeWebPAnimation(Uint8List bytes) =>
    WebPDecoder().decodeAnimation(bytes);

/// Decode a GIF formatted image (first frame for animations).
Image? decodeGif(Uint8List bytes) => GifDecoder().decodeImage(bytes);

/// Decode an animated GIF file. If the GIF isn't animated, the animation
/// will contain a single frame with the GIF's image.
Animation? decodeGifAnimation(Uint8List bytes) =>
    GifDecoder().decodeAnimation(bytes);

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
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false }) =>
    GifEncoder(samplingFactor: samplingFactor, dither: dither,
        ditherSerpentine: ditherSerpentine).encodeImage(image);

/// Encode an animation to the GIF format.
///
/// The [samplingFactor] specifies the sampling factor for
/// NeuQuant image quantization. It is responsible for reducing
/// the amount of unique colors in your images to 256.
/// According to
/// https://scientificgems.wordpress.com/stuff/neuquant-fast-high-quality-image-quantization/,
/// a sampling factor of 10 gives you a reasonable trade-off between
/// image quality and quantization speed.
/// If you know that you have less than 256 colors in your frames
/// anyway, you should supply a large [samplingFactor] for maximum
/// performance.
Uint8List encodeGifAnimation(Animation anim, { int delay = 80,
    int repeat = 0,
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false }) =>
    GifEncoder(samplingFactor: samplingFactor).encodeAnimation(anim);

/// Decode a TIFF formatted image.
Image? decodeTiff(Uint8List bytes) => TiffDecoder().decodeImage(bytes);

/// Decode an multi-image (animated) TIFF file. If the tiff doesn't have
/// multiple images, the animation will contain a single frame with the tiff's
/// image.
Animation? decodeTiffAnimation(Uint8List bytes) =>
    TiffDecoder().decodeAnimation(bytes);

Uint8List encodeTiff(Image image) =>
    TiffEncoder().encodeImage(image);

Uint8List encodeTiffAnimation(Animation anim) =>
    TiffEncoder().encodeAnimation(anim);

/// Decode a Photoshop PSD formatted image.
Image? decodePsd(Uint8List bytes) => PsdDecoder().decodeImage(bytes);

/// Decode an OpenEXR formatted image. EXR is a high dynamic range format.
Image? decodeExr(Uint8List bytes) =>
    ExrDecoder().decodeImage(bytes);

/// Decode a BMP formatted image.
Image? decodeBmp(Uint8List bytes) => BmpDecoder().decodeImage(bytes);

/// Encode an [Image] to the BMP format.
Uint8List encodeBmp(Image image) => BmpEncoder().encodeImage(image);

/// Encode an [Image] to the CUR format.
Uint8List encodeCur(Image image) => CurEncoder().encodeImage(image);

/// Encode an [Animation] (list of images) to the CUR format.
Uint8List encodeCurAnimation(Animation anim) =>
    CurEncoder().encodeAnimation(anim);

/// Encode an image to the ICO format.
Uint8List encodeIco(Image image) => IcoEncoder().encodeImage(image);

/// Encode an [Animation] (list of images) to the ICO format.
Uint8List encodeIcoAnimation(Animation anim) =>
    IcoEncoder().encodeAnimation(anim);

/// Decode an ICO image.
Image? decodeIco(Uint8List bytes) => IcoDecoder().decodeImage(bytes);
