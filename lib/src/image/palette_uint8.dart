import 'dart:typed_data';

import '../color/format.dart';
import 'palette.dart';

class PaletteUint8 extends Palette {
  final Uint8List data;

  PaletteUint8(int numColors, int numChannels)
      : data = Uint8List(numColors * numChannels)
      , super(numColors, numChannels);

  PaletteUint8.from(PaletteUint8 other)
      : data = Uint8List.fromList(other.data)
      , super(other.numColors, other.numChannels);

  PaletteUint8 clone() => PaletteUint8.from(this);

  int get lengthInBytes => data.lengthInBytes;
  ByteBuffer get buffer => data.buffer;
  Format get format => Format.uint8;

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
      return 255;
    }
    index *= numChannels;
    return data[index + 3];
  }
}
