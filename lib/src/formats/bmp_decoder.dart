import 'dart:typed_data';

import '../color/format.dart';
import '../image/animation.dart';
import '../image/image.dart';
import '../util/input_buffer.dart';
import 'bmp/bmp_info.dart';
import 'decoder.dart';

class BmpDecoder extends Decoder {
  late InputBuffer _input;
  BmpInfo? info;
  bool forceRgba;

  BmpDecoder({ this.forceRgba = false });

  /// Is the given file a valid BMP image?
  @override
  bool isValidFile(Uint8List data) =>
      BmpFileHeader.isValidFile(InputBuffer(data));

  @override
  int numFrames() => info != null ? info!.numFrames : 0;

  @override
  BmpInfo? startDecode(Uint8List bytes) {
    if (!isValidFile(bytes)) {
      return null;
    }
    _input = InputBuffer(bytes);
    return info = BmpInfo(_input);
  }

  /// Decode a single frame from the data stat was set with [startDecode].
  /// If [frame] is out of the range of available frames, null is returned.
  /// Non animated image files will only have [frame] 0. An [AnimationFrame]
  /// is returned, which provides the image, and top-left coordinates of the
  /// image, as animated frames may only occupy a subset of the canvas.
  @override
  Image decodeFrame(int frame) {
    if (info == null) {
      return Image(0, 0);
    }

    final _info = info!;

    _input.offset = _info.header.imageOffset;

    final bpp = _info.bitsPerPixel;
    final rowStride = ((_info.width * bpp + 31) ~/ 32) * 4;
    final nc = forceRgba ? 4
        : bpp == 1 || bpp == 4 || bpp == 8 ? 1 : bpp == 32 ? 3 : 3;
    final format = forceRgba ? Format.uint8
        : bpp == 1 ? Format.uint1
        : bpp == 2 ? Format.uint2
        : bpp == 4 ? Format.uint4
        : bpp == 8 ? Format.uint8
        // BMP allows > 4 bit per channel for 16bpp, so we have to scale it
        // up to 8-bit
        : bpp == 16 ? Format.uint8
        : bpp == 24 ? Format.uint8
        : Format.uint8;
    final palette = forceRgba ? null : _info.palette;

    final image = Image(_info.width, _info.height, format: format,
        numChannels: nc, palette: palette);

    for (var y = image.height - 1; y >= 0; --y) {
      final line = _info.readBottomUp ? y : image.height - 1 - y;
      final row = _input.readBytes(rowStride);
      final w = image.width;
      var x = 0;
      final p = image.getPixel(0, line);
      while (x < w) {
        _info.decodePixel(row, (r, g, b, a) {
          if (x < w) {
            if (forceRgba && _info.palette != null) {
              final pi = r as int;
              final pr = _info.palette!.getRed(pi);
              final pg = _info.palette!.getGreen(pi);
              final pb = _info.palette!.getBlue(pi);
              final pa = _info.palette!.getAlpha(pi);
              p.setColor(pr, pg, pb, pa);
            } else {
              p.setColor(r, g, b, a);
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
  Image? decodeImage(Uint8List data, {int frame = 0}) {
    if (!isValidFile(data)) {
      return null;
    }
    startDecode(data);
    return decodeFrame(frame);
  }

  /// Decode all of the frames from an animation. If the file is not an
  /// animation, a single frame animation is returned. If there was a problem
  /// decoding the file, null is returned.
  @override
  Animation? decodeAnimation(Uint8List data) {
    if (!isValidFile(data)) {
      return null;
    }
    final image = decodeImage(data)!;

    final anim = Animation();
    anim.width = image.width;
    anim.height = image.height;
    anim.addFrame(image);

    return anim;
  }
}

class DibDecoder extends BmpDecoder {
  DibDecoder(InputBuffer input, BmpInfo info, { bool forceRgba = false })
      : super(forceRgba: forceRgba) {
    _input = input;
    this.info = info;
  }
}
