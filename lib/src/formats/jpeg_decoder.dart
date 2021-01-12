// @dart=2.11
import '../animation.dart';
import '../image.dart';
import '../image_exception.dart';
import '../util/input_buffer.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'jpeg/jpeg_data.dart';
import 'jpeg/jpeg_info.dart';

/// Decode a jpeg encoded image.
class JpegDecoder extends Decoder {
  JpegInfo info;
  InputBuffer input;

  /// Is the given file a valid JPEG image?
  @override
  bool isValidFile(List<int> data) {
    return JpegData().validate(data);
  }

  @override
  DecodeInfo startDecode(List<int> data) {
    input = InputBuffer(data, bigEndian: true);
    info = JpegData().readInfo(data);
    return info;
  }

  @override
  int numFrames() => info == null ? 0 : info.numFrames;

  @override
  Image decodeFrame(int frame) {
    if (input == null) {
      return null;
    }
    var jpeg = JpegData();
    jpeg.read(input.buffer);
    if (jpeg.frames.length != 1) {
      throw ImageException('only single frame JPEGs supported');
    }

    return jpeg.getImage();
  }

  @override
  Image decodeImage(List<int> data, {int frame = 0}) {
    var jpeg = JpegData();
    jpeg.read(data);

    if (jpeg.frames.length != 1) {
      throw ImageException('only single frame JPEGs supported');
    }

    return jpeg.getImage();
  }

  @override
  Animation decodeAnimation(List<int> data) {
    var image = decodeImage(data);
    if (image == null) {
      return null;
    }

    var anim = Animation();
    anim.width = image.width;
    anim.height = image.height;
    anim.addFrame(image);

    return anim;
  }
}
