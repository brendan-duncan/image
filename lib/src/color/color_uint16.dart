import 'dart:typed_data';

import 'channel_iterator.dart';
import 'color.dart';
import 'color_util.dart';
import 'format.dart';

class ColorUint16 extends Iterable<num> implements Color {
  final Uint16List data;

  ColorUint16(int numChannels)
      : data = Uint16List(numChannels);

  ColorUint16.from(ColorUint16 other)
      : data = Uint16List.fromList(other.data);

  ColorUint16.fromList(List<int> color)
      : data = Uint16List.fromList(color);

  ColorUint16.rgb(int r, int g, int b)
      : data = Uint16List(3) {
    data[0] = r;
    data[1] = g;
    data[2] = b;
  }

  ColorUint16.rgba(int r, int g, int b, int a)
      : data = Uint16List(4) {
    data[0] = r;
    data[1] = g;
    data[2] = b;
    data[3] = a;
  }

  ColorUint16 clone() => ColorUint16.from(this);

  Format get format => Format.uint16;
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