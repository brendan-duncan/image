import 'dart:typed_data';

import '../color/format.dart';
import '../util/float16.dart';
import 'palette.dart';

class PaletteFloat16 extends Palette {
  final Uint16List data;

  PaletteFloat16(int numColors, int numChannels)
      : data = Uint16List(numColors * numChannels)
      , super(numColors, numChannels);

  PaletteFloat16.from(PaletteFloat16 other)
      : data = Uint16List.fromList(other.data)
      , super(other.numColors, other.numChannels);

  PaletteFloat16 clone() => PaletteFloat16.from(this);

  int get lengthInBytes => data.lengthInBytes;
  ByteBuffer get buffer => data.buffer;
  Format get format => Format.float16;

  void set(int index, int channel, num value) {
    if (channel < numChannels) {
      index *= numChannels;
      data[index + channel] = Float16.doubleToFloat16(value.toDouble());
    }
  }

  void setColor(int index, num r, [num g = 0, num b = 0, num a = 0]) {
    index *= numChannels;
    data[index] = Float16.doubleToFloat16(r.toDouble());
    if (numChannels > 1) {
      data[index + 1] = Float16.doubleToFloat16(g.toDouble());
      if (numChannels > 2) {
        data[index + 2] = Float16.doubleToFloat16(b.toDouble());
        if (numChannels > 3) {
          data[index + 3] = Float16.doubleToFloat16(a.toDouble());
        }
      }
    }
  }

  num get(int index, int channel) =>
      channel < numChannels ?
      Float16.float16ToDouble(data[index * numChannels + channel]) :
      0.0;

  num getRed(int index) {
    index *= numChannels;
    return Float16.float16ToDouble(data[index]);
  }

  num getGreen(int index) {
    if (numChannels < 2) {
      return 0.0;
    }
    index *= numChannels;
    return Float16.float16ToDouble(data[index + 1]);
  }

  num getBlue(int index) {
    if (numChannels < 3) {
      return 0.0;
    }
    index *= numChannels;
    return Float16.float16ToDouble(data[index + 2]);
  }

  num getAlpha(int index) {
    if (numChannels < 4) {
      return 0.0;
    }
    index *= numChannels;
    return Float16.float16ToDouble(data[index + 3]);
  }

  void setRed(int index, num value) => set(index, 0, value);
  void setGreen(int index, num value) => set(index, 1, value);
  void setBlue(int index, num value) => set(index, 2, value);
  void setAlpha(int index, num value) => set(index, 3, value);
}
