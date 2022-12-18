import 'dart:typed_data';

import '../color/format.dart';

abstract class Palette {
  int get lengthInBytes;
  ByteBuffer get buffer;
  final int numColors;
  final int numChannels;

  Palette(this.numColors, this.numChannels);

  Palette clone();

  Format get format;

  Uint8List toUint8List() => Uint8List.view(buffer);

  void setColor(int index, num r, [num g = 0, num b = 0, num a = 0]);
  void set(int index, int channel, num value);
  num get(int index, int channel);
  num getRed(int index);
  num getGreen(int index);
  num getBlue(int index);
  num getAlpha(int index);
}
