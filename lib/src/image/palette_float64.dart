import 'dart:typed_data';

import '../color/format.dart';
import 'palette.dart';

class PaletteFloat64 extends Palette {
  final Float64List data;

  PaletteFloat64(int numColors, int numChannels)
      : data = Float64List(numColors * numChannels)
      , super(numColors, numChannels);

  PaletteFloat64.from(PaletteFloat64 other)
      : data = Float64List.fromList(other.data)
      , super(other.numColors, other.numChannels);

  PaletteFloat64 clone() => PaletteFloat64.from(this);

  int get lengthInBytes => data.lengthInBytes;
  ByteBuffer get buffer => data.buffer;
  Format get format => Format.float64;
  num get maxChannelValue => 1.0;

  void set(int index, int channel, num value) {
    if (channel < numChannels) {
      index *= numChannels;
      data[index + channel] = value.toDouble();
    }
  }

  void setColor(int index, num r, [num g = 0, num b = 0, num a = 0]) {
    index *= numChannels;
    data[index] = r.toDouble();
    if (numChannels > 1) {
      data[index + 1] = g.toDouble();
      if (numChannels > 2) {
        data[index + 2] = b.toDouble();
        if (numChannels > 3) {
          data[index + 3] = a.toDouble();
        }
      }
    }
  }

  num get(int index, int channel) =>
      channel < numChannels ?
      data[index * numChannels + channel] :
      0;

  num getRed(int index) {
    index *= numChannels;
    return data[index];
  }

  num getGreen(int index) {
    if (numChannels < 2) {
      return 0.0;
    }
    index *= numChannels;
    return data[index + 1];
  }

  num getBlue(int index) {
    if (numChannels < 3) {
      return 0.0;
    }
    index *= numChannels;
    return data[index + 2];
  }

  num getAlpha(int index) {
    if (numChannels < 4) {
      return 0.0;
    }
    index *= numChannels;
    return data[index + 3];
  }

  void setRed(int index, num value) => set(index, 0, value);
  void setGreen(int index, num value) => set(index, 1, value);
  void setBlue(int index, num value) => set(index, 2, value);
  void setAlpha(int index, num value) => set(index, 3, value);
}
