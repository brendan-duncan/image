import '../animation.dart';
import '../color.dart';
import '../image.dart';
import '../util/input_buffer.dart';
import 'decoder.dart';
import 'decode_info.dart';
import 'tga/tga_info.dart';

/**
 * Decode a TGA image. This only supports the 24-bit uncompressed format.
 * TODO add more TGA support.
 */
class TgaDecoder extends Decoder {
  TgaInfo info;
  InputBuffer input;

  /**
   * Is the given file a valid TGA image?
   */
  bool isValidFile(List<int> data) {
    InputBuffer input = InputBuffer(data, bigEndian: true);

    InputBuffer header = input.readBytes(18);
    if (header[2] != 2) {
      return false;
    }
    if (header[16] != 24 && header[16] != 32) {
      return false;
    }

    return true;
  }

  DecodeInfo startDecode(List<int> data) {
    info = TgaInfo();
    input = InputBuffer(data, bigEndian: true);

    InputBuffer header = input.readBytes(18);
    if (header[2] != 2) {
      return null;
    }
    if (header[16] != 24 && header[16] != 32) {
      return null;
    }

    info.width = (header[12] & 0xff) | ((header[13] & 0xff) << 8);
    info.height = (header[14] & 0xff) | ((header[15] & 0xff) << 8);
    info.imageOffset = input.offset;
    info.bpp = header[16];

    return info;
  }

  int numFrames() => info != null ? 1 : 0;

  Image decodeFrame(int frame) {
    if (info == null) {
      return null;
    }

    input.offset = info.imageOffset;
    Image image = Image(info.width, info.height, Image.RGB);
    for (int y = image.height - 1; y >= 0; --y) {
      for (int x = 0; x < image.width; ++x) {
        int b = input.readByte();
        int g = input.readByte();
        int r = input.readByte();
        int a = info.bpp == 32 ? input.readByte() : 255;
        image.setPixel(x, y, getColor(r, g, b, a));
      }
    }

    return image;
  }

  Image decodeImage(List<int> data, {int frame = 0}) {
    if (startDecode(data) == null) {
      return null;
    }

    return decodeFrame(frame);
  }

  Animation decodeAnimation(List<int> data) {
    Image image = decodeImage(data);
    if (image == null) {
      return null;
    }

    Animation anim = Animation();
    anim.width = image.width;
    anim.height = image.height;
    anim.addFrame(image);

    return anim;
  }
}
