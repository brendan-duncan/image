import 'dart:typed_data';

import '../color/format.dart';
import 'palette.dart';

class PaletteInt16 extends Palette {
  final Int16List data;

  PaletteInt16(int numColors, int numChannels)
      : data = Int16List(numColors * numChannels)
      , super(numColors, numChannels);

  PaletteInt16.from(PaletteInt16 other)
      : data = Int16List.fromList(other.data)
  , super(other.numColors, other.numChannels);

  PaletteInt16 clone() => PaletteInt16.from(this);

  int get lengthInBytes => data.lengthInBytes;
  ByteBuffer get buffer => data.buffer;
  Format get format => Format.int16;

  void set(int index, int channel, num value) {
    if (channel < numChannels) {
      index *= numChannels;
      data[index + channel] = value.toInt();
    }
  }

  void setColor(int index, num r, [num g = 0, num b = 0, num a = 0]) {
    index *= numChannels;
    data[index] = r.toInt();
    if (numChannels > 1) {
      data[index + 1] = g.toInt();
      if (numChannels > 2) {
        data[index + 2] = b.toInt();
        if (numChannels > 3) {
          data[index + 3] = a.toInt();
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
      return 0;
    }
    index *= numChannels;
    return data[index + 1];
  }

  num getBlue(int index) {
    if (numChannels < 3) {
      return 0;
    }
    index *= numChannels;
    return data[index + 2];
  }

  num getAlpha(int index) {
    if (numChannels < 4) {
      return 0;
    }
    index *= numChannels;
    return data[index + 3];
  }

  void setRed(int index, num value) => set(index, 0, value);
  void setGreen(int index, num value) => set(index, 1, value);
  void setBlue(int index, num value) => set(index, 2, value);
  void setAlpha(int index, num value) => set(index, 3, value);
}
