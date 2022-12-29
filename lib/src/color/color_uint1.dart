import '../image/palette.dart';
import '../util/color_util.dart';
import 'channel_iterator.dart';
import 'color.dart';
import 'format.dart';

/// A 1-bit color with channel values in the range \[0, 1\].
class ColorUint1 extends Iterable<num> implements Color {
  final int length;
  late int data;

  ColorUint1(this.length)
      : data = 0;

  ColorUint1.from(ColorUint1 other)
      : length = other.length
      , data = other.data;

  ColorUint1.fromList(List<int> color)
      : length = color.length {
    setColor(length > 0 ? color[0] : 0,
        length > 1 ? color[1] : 0,
        length > 2 ? color[2] : 0,
        length > 3 ? color[3] : 0);
  }

  ColorUint1.rgb(int r, int g, int b)
      : length = 3 {
    setColor(r, g, b);
  }

  ColorUint1.rgba(int r, int g, int b, int a)
      : length = 4 {
    setColor(r, g, b, a);
  }

  ColorUint1 clone() => ColorUint1.from(this);

  Format get format => Format.uint1;
  num get maxChannelValue => 1;
  num get maxIndexValue => 1;
  bool get isLdrFormat => true;
  bool get isHdrFormat => false;
  bool get hasPalette => false;
  Palette? get palette => null;

  int getChannel(int ci) => ci < length ? ((data >> (7 - ci)) & 0x1) : 0;

  void setChannel(int ci, num value) {
    if (ci >= length) {
      return;
    }
    ci = 7 - ci;
    var v = data;
    if (value != 0) {
      v |= 1 << ci;
    } else {
      v &= ~((1 << ci) & 0xff);
    }
    data = v;
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

  num get rNormalized => r / maxChannelValue;
  void set rNormalized(num v) => r = v * maxChannelValue;

  num get gNormalized => g / maxChannelValue;
  void set gNormalized(num v) => g = v * maxChannelValue;

  num get bNormalized => b / maxChannelValue;
  void set bNormalized(num v) => b = v * maxChannelValue;

  num get aNormalized => a / maxChannelValue;
  void set aNormalized(num v) => a = v * maxChannelValue;

  num get luminance => getLuminance(this);
  num get luminanceNormalized => getLuminanceNormalized(this);

  void set(Color c) {
    setColor(c.r, c.g, c.b, c.a);
  }

  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {
    data = (r.toInt().clamp(0, 1) << 7) |
        (g.toInt().clamp(0, 1) << 6) |
        (b.toInt().clamp(0, 1) << 5) |
        a.toInt().clamp(0, 1) << 4;
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
