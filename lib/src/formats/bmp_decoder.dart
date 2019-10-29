import 'dart:typed_data';

import '../animation.dart';
import '../color.dart';
import '../image.dart';

import '../util/input_buffer.dart';
import 'decoder.dart';
import 'bmp/bmp_info.dart';

class BmpDecoder extends Decoder {
  InputBuffer _input;
  BmpInfo info;

  @override

  /// Is the given file a valid BMP image?
  bool isValidFile(List<int> data) {
    return BitmapFileHeader.isValidFile(InputBuffer(data));
  }

  int numFrames() => info != null ? info.numFrames : 0;

  @override
  BmpInfo startDecode(List<int> bytes) {
    if (!isValidFile(bytes)) return null;
    _input = InputBuffer(Uint8List.fromList(bytes));
    info = BmpInfo(_input);
    print(info);

    return info;
  }

  /// Decode a single frame from the data stat was set with [startDecode].
  /// If [frame] is out of the range of available frames, null is returned.
  /// Non animated image files will only have [frame] 0. An [AnimationFrame]
  /// is returned, which provides the image, and top-left coordinates of the
  /// image, as animated frames may only occupy a subset of the canvas.
  Image decodeFrame(int frame) {
    _input.offset =
        info.compression == BitmapCompression.BI_BITFIELDS && info.bpp == 16
            ? info.file.offset + 16
            : info.file.offset;

    Image image = Image(info.width, info.height, channels: Channels.rgb);
    for (int y = image.height - 1; y >= 0; --y) {
      for (int x = 0; x < image.width; ++x) {
        final colors = info.decodeRgba(_input);
        image.setPixel(
            x, y, getColor(colors[0], colors[1], colors[2], colors[3]));
      }
    }

    return image;
  }

  /// Decode the file and extract a single image from it. If the file is
  /// animated, the specified [frame] will be decoded. If there was a problem
  /// decoding the file, null is returned.
  Image decodeImage(List<int> data, {int frame = 0}) {
    if (!isValidFile(data)) return null;
    startDecode(data);
    return decodeFrame(frame);
  }

  /// Decode all of the frames from an animation. If the file is not an
  /// animation, a single frame animation is returned. If there was a problem
  /// decoding the file, null is returned.
  Animation decodeAnimation(List<int> data) {
    if (!isValidFile(data)) return null;
    Image image = decodeImage(data);

    Animation anim = Animation();
    anim.width = image.width;
    anim.height = image.height;
    anim.addFrame(image);

    return anim;
  }
}
