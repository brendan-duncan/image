import 'dart:typed_data';

import '../color/format.dart';
import '../image/image.dart';
import '../util/image_exception.dart';
import '../util/input_buffer.dart';
import '_guard_decode.dart';
import '_max_pixels.dart';
import 'bmp/bmp_info.dart';
import 'decoder.dart';
import 'image_format.dart';

class BmpDecoder extends Decoder {
  late InputBuffer _input;
  BmpInfo? info;
  bool forceRgba;

  /// The maximum number of pixels (width * height) of the image. Larger
  /// images throw an [ImageException]. A value <= 0 disables the limit.
  final int maxPixels;

  BmpDecoder({this.forceRgba = false, int? maxPixels})
      : maxPixels = maxPixels ?? Decoder.defaultMaxPixels;

  @override
  ImageFormat get format => ImageFormat.bmp;

  /// Is the given file a valid BMP image?
  @override
  bool isValidFile(Uint8List data) {
    if (!BmpFileHeader.isValidFile(InputBuffer(data)) || data.length < 18) {
      return false;
    }
    // Validate the DIB header size to avoid misdetecting non-BMP files that
    // merely start with the 'BM' signature.
    final dibHeaderSize = (InputBuffer(data)..skip(14)).readUint32();
    return dibHeaderSize >= 12 && dibHeaderSize <= 124;
  }

  @override
  int numFrames() => info != null ? info!.numFrames : 0;

  @override
  BmpInfo? startDecode(Uint8List bytes) =>
      guardDecode(() => _startDecode(bytes));

  BmpInfo? _startDecode(Uint8List bytes) {
    if (!isValidFile(bytes)) {
      return null;
    }
    _input = InputBuffer(bytes);
    return info = BmpInfo(_input);
  }

  /// Decode a single frame from the data stat was set with [startDecode].
  /// If [frame] is out of the range of available frames, null is returned.
  /// Non animated image files will only have [frame] 0. An AnimationFrame
  /// is returned, which provides the image, and top-left coordinates of the
  /// image, as animated frames may only occupy a subset of the canvas.
  @override
  Image decodeFrame(int frame) => guardDecode(() => _decodeFrame(frame));

  Image _decodeFrame(int frame) {
    if (info == null) {
      return Image.empty();
    }

    final inf = info!;

    _input.offset = inf.header.imageOffset;

    checkPixels(inf.width, inf.height, maxPixels);
    final bpp = inf.bitsPerPixel;
    final rowStride = ((inf.width * bpp + 31) ~/ 32) * 4;
    if (rowStride * inf.height > _input.length) {
      throw ImageException('Truncated BMP data');
    }
    final nc = forceRgba
        ? 4
        : bpp == 1 || bpp == 4 || bpp == 8
            ? 1
            : bpp == 32
                ? 4
                : 3;
    final format = forceRgba
        ? Format.uint8
        : bpp == 1
            ? Format.uint1
            : bpp == 2
                ? Format.uint2
                : bpp == 4
                    ? Format.uint4
                    : bpp == 8
                        ? Format.uint8
                        // BMP allows > 4 bit per channel for 16bpp, so we have
                        // to scale it up to 8-bit
                        : bpp == 16
                            ? Format.uint8
                            : bpp == 24
                                ? Format.uint8
                                : bpp == 32
                                    ? Format.uint8
                                    : Format.uint8;
    final palette = forceRgba ? null : inf.palette;

    final image = Image(
        width: inf.width,
        height: inf.height,
        format: format,
        numChannels: nc,
        palette: palette);

    for (var y = image.height - 1; y >= 0; --y) {
      final line = inf.readBottomUp ? y : image.height - 1 - y;
      final row = _input.readBytes(rowStride);
      final w = image.width;
      var x = 0;
      final p = image.getPixel(0, line);
      while (x < w) {
        inf.decodePixel(row, (r, g, b, a) {
          if (x < w) {
            if (forceRgba && inf.palette != null) {
              final pi = r as int;
              final pr = inf.palette!.getRed(pi);
              final pg = inf.palette!.getGreen(pi);
              final pb = inf.palette!.getBlue(pi);
              final pa = inf.palette!.getAlpha(pi);
              p.setRgba(pr, pg, pb, pa);
            } else {
              p.setRgba(r, g, b, a);
            }
            p.moveNext();
            x++;
          }
        });
      }
    }

    return image;
  }

  /// Decode the file and extract a single image from it. If the file is
  /// animated, the specified [frame] will be decoded. If there was a problem
  /// decoding the file, null is returned.
  @override
  Image? decode(Uint8List data, {int? frame}) =>
      guardDecode(() => _decode(data, frame: frame));

  Image? _decode(Uint8List data, {int? frame}) {
    final info = startDecode(data);
    if (info == null || info.width < 1 || info.height < 1) {
      return null;
    }
    return decodeFrame(frame ?? 0);
  }
}

class DibDecoder extends BmpDecoder {
  DibDecoder(InputBuffer input, BmpInfo info,
      {bool forceRgba = false, int? maxPixels})
      : super(forceRgba: forceRgba, maxPixels: maxPixels) {
    _input = input;
    this.info = info;
  }
}
