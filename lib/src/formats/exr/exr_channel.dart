import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';

enum ExrChannelType {
  uint,
  half,
  float
}

// Standard channel names are:
// A: Alpha/Opacity
// R: Red value of a sample
// G: Green value of a sample
// B: Blue value of a sample
// Y: Luminance
// RY: Chroma RY
// BY: Chroma BY
// AR: Red for colored mattes
// GR: Green for colored mattes
// BR: Blue for colored mattes
// Z: Distance of the front of a sample from the viewer
// ZBack: Distance of the back of a sample from the viewer
// id: A numerical identifier for the object represented by a sample.
class ExrChannel {
  late String name;
  late ExrChannelType type;
  late int size;
  late bool pLinear;
  late int xSampling;
  late int ySampling;

  ExrChannel(InputBuffer input) {
    name = input.readString();
    if (name.isEmpty) {
      return;
    }
    type = ExrChannelType.values[input.readUint32()];
    final i = input.readByte();
    assert(i == 0 || i == 1);
    pLinear = i == 1;
    input.skip(3);
    xSampling = input.readUint32();
    ySampling = input.readUint32();

    switch (type) {
      case ExrChannelType.uint:
        size = 4;
        break;
      case ExrChannelType.half:
        size = 2;
        break;
      case ExrChannelType.float:
        size = 4;
        break;
      default:
        throw ImageException('EXR Invalid pixel type: $type');
    }
  }

  bool get isValid => name.isNotEmpty;
}
