import 'dart:typed_data';

import 'channel_iterator.dart';
import 'color.dart';
import 'color_util.dart';
import 'format.dart';

/// A 4-bit color value.
class ColorUint4 extends Iterable<num> implements Color {
  final int length;
  Uint8List data;

  ColorUint4(this.length)
      : data = Uint8List(length < 3 ? 1 : 2);

  ColorUint4.from(ColorUint4 other)
      : length = other.length
      , data = Uint8List.fromList(other.data);

  ColorUint4.fromList(List<int> color)
      : length = color.length
      , data = Uint8List(color.length < 3 ? 1 : 2) {
    setColor(length > 0 ? color[0] : 0,
        length > 1 ? color[1] : 0,
        length > 2 ? color[2] : 0,
        length > 3 ? color[3] : 0);
  }

  ColorUint4.rgb(int r, int g, int b)
      : length = 3
      , data = Uint8List(2) {
    setColor(r, g, b);
  }

  ColorUint4.rgba(int r, int g, int b, int a)
      : length = 4
      , data = Uint8List(2) {
    setColor(r, g, b, a);
  }

  ColorUint4 clone() => ColorUint4.from(this);

  Format get format => Format.uint4;
  num get maxChannelValue => 255;
  bool get isLdrFormat => true;
  bool get isHdrFormat => false;

  int getChannel(int ci) => ci < 0 || ci >= length ? 0
      : ci < 2 ? (data[0] >> (4 - (ci << 2))) & 0xf
      : (data[1] >> (4 - ((ci & 0x1) << 2)) & 0xf);

  void setChannel(int ci, num value) {
    if (ci >= length) {
      return;
    }
    final vi = value.toInt().clamp(0, 15);
    int i = 0;
    if (ci > 2) {
      ci &= 0x1;
      i = 1;
    }
    if (ci == 0) {
      data[i] = (data[i] & 0xf) | (vi << 4);
    } else if (ci == 1) {
      data[i] = (data[i] & 0xf0) | vi;
    }
  }

  num operator[](int index) => getChannel(index);
  void operator[]=(int index, num value) => setChannel(index, value);

  num get index => r;
  void set index(num i) => r = i;

  num get r => getChannel(0);
  void set r(num v) => setChannel(0, v);

  num get g => getChannel(1);
  void set g(num v) => setChannel(1, v);

  num get b => getChannel(2);
  void set b(num v) => setChannel(2, v);

  num get a => getChannel(3);
  void set a(num v) => setChannel(3, v);

  void set(Color c) {
    setColor(c.r, c.g, c.b, c.a);
  }

  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {
    final ri = r.toInt().clamp(0, 15) & 0xf;
    final gi = g.toInt().clamp(0, 15) & 0xf;
    final bi = b.toInt().clamp(0, 15) & 0xf;
    final ai = a.toInt().clamp(0, 15) & 0xf;
    data[0] = (ri << 4) | gi;
    data[1] = (bi << 4) | ai;
  }

  ChannelIterator get iterator => ChannelIterator(this);

  bool operator==(Object? other) =>
      other is Color &&
          other.length == length &&
          other.hashCode == hashCode;

  int get hashCode => Object.hashAll(toList());

  Color convert({ Format? format, int? numChannels, num? alpha }) =>
      convertColor(this, format: format, numChannels: numChannels,
          alpha: alpha);
}