import '../image/palette.dart';
import '../util/color_util.dart';
import 'channel.dart';
import 'channel_iterator.dart';
import 'color.dart';
import 'format.dart';

/// An 8-bit unsigned int color with channel values in the range \[0, 255].
class ConstColorUint8 extends Iterable<num> implements Color {
  final int data;

  const ConstColorUint8.data(this.data);

  ConstColorUint8.from(ConstColorUint8 c) : data = c.data;

  @override
  ConstColorUint8 clone() => ConstColorUint8.from(this);

  @override
  Format get format => Format.uint8;
  @override
  int get length => 4;
  @override
  num get maxChannelValue => 255;
  @override
  num get maxIndexValue => 255;
  @override
  bool get isLdrFormat => true;
  @override
  bool get isHdrFormat => false;
  @override
  bool get hasPalette => false;
  @override
  Palette? get palette => null;

  @override
  num operator [](int index) => index >= 0 && index < 4
      ? (data & (0xff << (index << 3))) >> (index << 3)
      : 0;

  @override
  void operator []=(int index, num value) {}

  @override
  void set(Color c) {}

  @override
  void setRgb(num r, num g, num b) {}

  @override
  void setRgba(num r, num g, num b, num a) {}

  @override
  num get index => r;

  @override
  set index(num v) {}

  @override
  num get r => this[0];

  @override
  set r(num v) {}

  @override
  num get g => this[1];

  @override
  set g(num v) {}

  @override
  num get b => this[2];

  @override
  set b(num v) {}

  @override
  num get a => this[3];

  @override
  set a(num v) {}

  @override
  num get rNormalized => r / maxChannelValue;

  @override
  set rNormalized(num v) {}

  @override
  num get gNormalized => g / maxChannelValue;

  @override
  set gNormalized(num v) {}

  @override
  num get bNormalized => b / maxChannelValue;

  @override
  set bNormalized(num v) {}

  @override
  num get aNormalized => a / maxChannelValue;

  @override
  set aNormalized(num v) {}

  @override
  num get luminance => getLuminance(this);

  @override
  num get luminanceNormalized => getLuminanceNormalized(this);

  @override
  num getChannel(Channel channel) =>
      channel == Channel.luminance ? luminance : this[channel.index];

  @override
  num getChannelNormalized(Channel channel) =>
      getChannel(channel) / maxChannelValue;

  @override
  ChannelIterator get iterator => ChannelIterator(this);

  @override
  bool operator ==(Object other) =>
      other is Color && other.length == length && other.hashCode == hashCode;

  @override
  int get hashCode => Object.hashAll(toList());

  @override
  Color convert({Format? format, int? numChannels, num? alpha}) =>
      convertColor(this,
          format: format, numChannels: numChannels, alpha: alpha);
}

class ConstColorR8 extends ConstColorUint8 {
  const ConstColorR8(int r) : super.data((255 << 24) | (r & 0xff));

  @override
  num get g => 0;

  @override
  num get gNormalized => 0;

  @override
  num get b => 0;

  @override
  num get bNormalized => 0;

  @override
  num get a => 255;

  @override
  num get aNormalized => 1;

  @override
  num getChannel(Channel channel) => channel == Channel.luminance
      ? luminance
      : channel == Channel.green
          ? 0
          : channel == Channel.blue
              ? 0
              : channel == Channel.alpha
                  ? 255
                  : this[channel.index];

  @override
  int get length => 1;
}

class ConstColorRg8 extends ConstColorUint8 {
  const ConstColorRg8(int r, int g)
      : super.data((255 << 24) | ((g & 0xff) << 8) | (r & 0xff));

  @override
  num get b => 0;

  @override
  num get bNormalized => 0;

  @override
  num get a => 255;

  @override
  num get aNormalized => 1;

  @override
  num getChannel(Channel channel) => channel == Channel.luminance
      ? luminance
      : channel == Channel.blue
          ? 0
          : channel == Channel.alpha
              ? 255
              : this[channel.index];

  @override
  int get length => 2;
}

class ConstColorRgb8 extends ConstColorUint8 {
  const ConstColorRgb8(int r, int g, int b)
      : super.data(
            (255 << 24) | ((b & 0xff) << 16) | ((g & 0xff) << 8) | (r & 0xff));

  @override
  num get a => 255;

  @override
  num get aNormalized => 1;

  @override
  num getChannel(Channel channel) => channel == Channel.luminance
      ? luminance
      : channel == Channel.alpha
          ? 255
          : this[channel.index];

  @override
  int get length => 3;
}

class ConstColorRgba8 extends ConstColorUint8 {
  const ConstColorRgba8(int r, int g, int b, int a)
      : super.data(((a & 0xff) << 24) |
            ((b & 0xff) << 16) |
            ((g & 0xff) << 8) |
            (r & 0xff));
}
