import 'dart:typed_data';

import 'channel_iterator.dart';
import 'color.dart';
import 'color_util.dart';
import 'format.dart';

class ColorUint32 extends Iterable<num> implements Color {
  final Uint32List data;

  ColorUint32(int numChannels)
      : data = Uint32List(numChannels);

  ColorUint32.from(ColorUint32 other)
      : data = Uint32List.fromList(other.data);

  ColorUint32.fromList(List<int> color)
      : data = Uint32List.fromList(color);

  ColorUint32.rgb(int r, int g, int b)
      : data = Uint32List(3) {
    data[0] = r;
    data[1] = g;
    data[2] = b;
  }

  ColorUint32.rgba(int r, int g, int b, int a)
      : data = Uint32List(4) {
    data[0] = r;
    data[1] = g;
    data[2] = b;
    data[3] = a;
  }

  ColorUint32 clone() => ColorUint32.from(this);

  Format get format => Format.uint32;
  int get length => data.length;
  num get maxChannelValue => 255;
  bool get isLdrFormat => false;
  bool get isHdrFormat => true;

  num operator[](int index) => index < data.length ? data[index] : 0;
  void operator[]=(int index, num value) {
    if (index < data.length) {
      data[index] = value.toInt();
    }
  }

  num get index => r;
  void set index(num i) => r = i;

  num get r => data.isNotEmpty ? data[0] : 0;
  void set r(num r) => data.isNotEmpty ? data[0] = r.toInt() : 0;

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

  num get a => data.length > 3 ? data[3] : 0;
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
