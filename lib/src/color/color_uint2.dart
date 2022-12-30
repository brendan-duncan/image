import '../image/palette.dart';
import '../util/color_util.dart';
import 'channel.dart';
import 'channel_iterator.dart';
import 'color.dart';
import 'format.dart';

/// A 2-bit unsigned int color with channel values in the range \[0, 3].
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
  num get maxChannelValue => 3;
  num get maxIndexValue => 3;
  bool get isLdrFormat => true;
  bool get isHdrFormat => false;
  bool get hasPalette => false;
  Palette? get palette => null;


  int _getChannel(int ci) => ci < length ? (data >> (6 - (ci << 1))) & 0x3 : 0;

  void _setChannel(int ci, num value) {
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

  num operator[](int index) => _getChannel(index);
  void operator[]=(int index, num value) => _setChannel(index, value);

  num get index => r;
  void set index(num i) => r = i;

  num get r => _getChannel(0);
  void set r(num v) => _setChannel(0, v);

  num get g => _getChannel(1);
  void set g(num v) => _setChannel(1, v);

  num get b => _getChannel(2);
  void set b(num v) => _setChannel(2, v);

  num get a => _getChannel(3);
  void set a(num v) => _setChannel(3, v);

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

  num getChannel(Channel channel) => channel == Channel.luminance ?
      luminance : _getChannel(channel.index);

  num getChannelNormalized(Channel channel) =>
      getChannel(channel) / maxChannelValue;

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