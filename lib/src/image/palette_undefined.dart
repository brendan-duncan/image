import 'dart:typed_data';

import '../color/format.dart';
import 'palette.dart';

class PaletteUndefined extends Palette {
  PaletteUndefined()
      : super(0, 0);
  PaletteUndefined.from(PaletteUndefined other)
      : super(0, 0);
  PaletteUndefined clone() => PaletteUndefined.from(this);
  int get lengthInBytes => 0;
  Format get format => Format.uint8;
  ByteBuffer get buffer => Uint8List(0).buffer;
  void set(int index, int channel, num value) {}
  void setColor(int index, num r, [num g = 0, num b = 0, num a = 0]) {}
  num get(int index, int channel) => 0;
  num getRed(int index) => 0;
  num getGreen(int index) => 0;
  num getBlue(int index) => 0;
  num getAlpha(int index) => 0;
}
