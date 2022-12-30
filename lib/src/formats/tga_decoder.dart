import 'dart:typed_data';

import '../image/image.dart';
import '../util/input_buffer.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'tga/tga_info.dart';

/// Decode a TGA image. This only supports the 24-bit and 32-bit uncompressed
/// format.
class TgaDecoder extends Decoder {
  TgaInfo? info;
  late InputBuffer input;

  /// Is the given file a valid TGA image?
  @override
  bool isValidFile(Uint8List data) {
    final input = InputBuffer(data, bigEndian: true);

    final header = input.readBytes(18);
    if (header[2] != 2) {
      return false;
    }
    if (header[16] != 24 && header[16] != 32) {
      return false;
    }

    return true;
  }

  @override
  DecodeInfo? startDecode(Uint8List bytes) {
    info = TgaInfo();
    input = InputBuffer(bytes, bigEndian: true);

    final header = input.readBytes(18);
    if (header[2] != 2) {
      return null;
    }
    if (header[16] != 24 && header[16] != 32) {
      return null;
    }

    info!.width = (header[12] & 0xff) | ((header[13] & 0xff) << 8);
    info!.height = (header[14] & 0xff) | ((header[15] & 0xff) << 8);
    info!.imageOffset = input.offset;
    info!.bpp = header[16];

    return info;
  }

  @override
  int numFrames() => info != null ? 1 : 0;

  @override
  Image? decodeFrame(int frame) {
    if (info == null) {
      return null;
    }

    input.offset = info!.imageOffset!;
    final image = Image(width: info!.width, height: info!.height,
        numChannels: info!.bpp == 32 ? 4 : 3);
    for (var y = image.height - 1; y >= 0; --y) {
      for (var x = 0; x < image.width; ++x) {
        final b = input.readByte();
        final g = input.readByte();
        final r = input.readByte();
        final a = info!.bpp == 32 ? input.readByte() : 255;
        image.setPixelColor(x, y, r, g, b, a);
      }
    }

    return image;
  }

  @override
  Image? decode(Uint8List bytes, { int? frame }) {
    if (startDecode(bytes) == null) {
      return null;
    }

    return decodeFrame(frame ?? 0);
  }
}
