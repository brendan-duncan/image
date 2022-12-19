import 'channel_iterator.dart';
import 'color.dart';
import 'color_util.dart';
import 'format.dart';

/// A 2-bit color value.
class ColorUint2 extends Iterable<num> implements Color {
  final int length;
  late int data;

  ColorUint2(this.length)
      : data = 0;

  ColorUint2.from(ColorUint2 other)
      : length = other.length
      , data = other.data;

  ColorUint2.fromList(List<int> color)
      : length = color.length
      , data = 0 {
    setColor(length > 0 ? color[0] : 0,
        length > 1 ? color[1] : 0,
        length > 2 ? color[2] : 0,
        length > 3 ? color[3] : 0);
  }

  ColorUint2.rgb(int r, int g, int b)
      : length = 3
      , data = 0 {
    setColor(r, g, b);
  }

  ColorUint2.rgba(int r, int g, int b, int a)
      : length = 4
      , data = 0 {
    setColor(r, g, b, a);
  }

  ColorUint2 clone() => ColorUint2.from(this);

  Format get format => Format.uint2;
  num get maxChannelValue => 255;
  bool get isLdrFormat => true;
  bool get isHdrFormat => false;

  int getChannel(int ci) => (data >> (6 - (ci << 1))) & 0x3;

  void setChannel(int ci, num value) {
    if (ci >= length) {
      return;
    }

    const _mask = [~(0x3 << (6 - (0 << 1))) & 0xff,
      ~(0x3 << (6 - (1 << 1))) & 0xff,
      ~(0x3 << (6 - (2 << 1))) & 0xff,
      ~(0x3 << (6 - (3 << 1))) & 0xff];

    final mask = _mask[ci];
    final x = value.toInt() & 0x3;
    data = (data & mask) | (x << (6 - (ci << 1)));
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
    final ri = r.toInt().clamp(0, 3);
    final gi = g.toInt().clamp(0, 3);
    final bi = b.toInt().clamp(0, 3);
    final ai = a.toInt().clamp(0, 3);
    data = ri << 6 | gi << 4 | bi << 2 | ai;
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