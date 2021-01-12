// @dart=2.11
import '../../internal/internal.dart';
import '../../util/input_buffer.dart';
import 'gif_color_map.dart';

class GifImageDesc {
  int x;
  int y;
  int width;
  int height;
  bool interlaced;
  GifColorMap colorMap;
  int duration = 80;
  bool clearFrame = true;

  GifImageDesc(InputBuffer input) {
    x = input.readUint16();
    y = input.readUint16();
    width = input.readUint16();
    height = input.readUint16();

    var b = input.readByte();

    var bitsPerPixel = (b & 0x07) + 1;

    interlaced = (b & 0x40) != 0;

    if (b & 0x80 != 0) {
      colorMap = GifColorMap(1 << bitsPerPixel);

      for (var i = 0; i < colorMap.numColors; ++i) {
        colorMap.setColor(
            i, input.readByte(), input.readByte(), input.readByte());
      }
    }

    _inputPosition = input.position;
  }

  /// The position in the file after the ImageDesc for this frame.
  int _inputPosition;
}

@internal
class InternalGifImageDesc extends GifImageDesc {
  InternalGifImageDesc(InputBuffer input) : super(input);

  int get inputPosition => _inputPosition;
}
