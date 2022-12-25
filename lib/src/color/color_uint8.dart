import 'dart:typed_data';

import '../util/color_util.dart';
import 'channel_iterator.dart';
import 'color.dart';
import 'format.dart';

class ColorUint8 extends Iterable<num> implements Color {
  final Uint8List data;

  ColorUint8(int numChannels)
      : data = Uint8List(numChannels);

  ColorUint8.from(ColorUint8 other)
      : data = Uint8List.fromList(other.data);

  ColorUint8.fromList(List<int> color)
      : data = Uint8List.fromList(color);

  ColorUint8.rgb(int r, int g, int b)
      : data = Uint8List(3) {
    data[0] = r;
    data[1] = g;
    data[2] = b;
  }

  ColorUint8.rgba(int r, int g, int b, int a)
      : data = Uint8List(4) {
    data[0] = r;
    data[1] = g;
    data[2] = b;
    data[3] = a;
  }

  ColorUint8 clone() => ColorUint8.from(this);

  Format get format => Format.uint8;
  int get length => data.length;
  num get maxChannelValue => 255;
  bool get isLdrFormat => true;
  bool get isHdrFormat => false;

  num operator[](int index) => index < data.length ? data[index] : 0;
  void operator[]=(int index, num value) {
    if (index < data.length) {
      data[index] = value.toInt();
    }
  }

  num get index => r;
  void set index(num i) => r = i;

  num get r => data.isNotEmpty ? data[0] : 0;
  void set r(num r) {
    if (data.isNotEmpty) {
      data[0] = r.toInt();
    }
  }

  num get g => data.length > 1 ? data[1] : 0;
  void set g(num g) {
    if (data.length > 1) {
      data[1] = g.toInt();
    }
  }

  num get b => data.length > 2 ? data[2] : 0;
  void set b(num b) {
    if (data.length > 2) {
      data[2] = b.toInt();
    }
  }

  num get a => data.length > 3 ? data[3] : 255;
  void set a(num a) {
    if (data.length > 3) {
      data[3] = a.toInt();
    }
  }

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
    r = c.r;
    g = c.g;
    b = c.b;
    a = c.a;
  }

  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {
    data[0] = r.toInt();
    final nc = data.length;
    if (nc > 1) {
      data[1] = g.toInt();
      if (nc > 2) {
        data[2] = b.toInt();
        if (nc > 3) {
          data[3] = a.toInt();
        }
      }
    }
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

class ColorRgb8 extends ColorUint8 {
  ColorRgb8([int r = 0, int g = 0, int b = 0])
      : super.rgb(r, g, b);

  ColorRgb8.from(ColorUint8 other)
      : super(3) {
    data[0] = other[0] as int;
    data[1] = other[1] as int;
    data[2] = other[2] as int;
  }
}

class ColorRgba8 extends ColorUint8 {
  ColorRgba8([int r = 0, int g = 0, int b = 0, int a = 255])
    : super.rgba(r, g, b, a);

  ColorRgba8.from(ColorUint8 other)
      : super(4) {
    data[0] = other[0] as int;
    data[1] = other[1] as int;
    data[2] = other[2] as int;
    data[3] = other[3] as int;
  }
}
