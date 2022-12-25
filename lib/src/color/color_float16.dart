import 'dart:typed_data';

import '../util/float16.dart';
import 'channel_iterator.dart';
import 'color.dart';
import 'color_util.dart';
import 'format.dart';

class ColorFloat16 extends Iterable<num> implements Color {
  final Uint16List data;

  ColorFloat16(int numChannels)
      : data = Uint16List(numChannels);

  ColorFloat16.from(ColorFloat16 other)
      : data = Uint16List.fromList(other.data);

  ColorFloat16.fromList(List<double> color)
      : data = Uint16List(color.length) {
    final l = color.length;
    for (var i = 0; i < l; ++i) {
      data[i] = Float16.doubleToFloat16(color[i]);
    }
  }

  ColorFloat16.rgb(num r, num g, num b)
      : data = Uint16List(3) {
    data[0] = Float16.doubleToFloat16(r.toDouble());
    data[1] = Float16.doubleToFloat16(g.toDouble());
    data[2] = Float16.doubleToFloat16(b.toDouble());
  }

  ColorFloat16.rgba(num r, num g, num b, num a)
      : data = Uint16List(4) {
    data[0] = Float16.doubleToFloat16(r.toDouble());
    data[1] = Float16.doubleToFloat16(g.toDouble());
    data[2] = Float16.doubleToFloat16(b.toDouble());
    data[3] = Float16.doubleToFloat16(a.toDouble());
  }

  ColorFloat16 clone() => ColorFloat16.from(this);

  Format get format => Format.float16;
  int get length => data.length;
  num get maxChannelValue => 1.0;
  bool get isLdrFormat => false;
  bool get isHdrFormat => true;

  num operator[](int index) => index < data.length ?
      Float16.float16ToDouble(data[index]) : 0;

  void operator[]=(int index, num value) {
    if (index < data.length) {
      data[index] = Float16.doubleToFloat16(value.toDouble());
    }
  }

  num get index => r;
  void set index(num i) => r = i;

  num get r => data.isNotEmpty ? Float16.float16ToDouble(data[0]) : 0;
  void set r(num v) {
    if (data.isNotEmpty) {
      data[0] = Float16.doubleToFloat16(v.toDouble());
    }
  }

  num get g => data.length > 1 ? Float16.float16ToDouble(data[1]) : 0;
  void set g(num v) {
    if (data.length > 1) {
      data[1] = Float16.doubleToFloat16(v.toDouble());
    }
  }

  num get b => data.length > 2 ? Float16.float16ToDouble(data[2]) : 0;
  void set b(num v) {
    if (data.length > 2) {
      data[2] = Float16.doubleToFloat16(v.toDouble());
    }
  }

  num get a => data.length > 3 ? Float16.float16ToDouble(data[3]) : 0;
  void set a(num v) {
    if (data.length > 3) {
      data[3] = Float16.doubleToFloat16(v.toDouble());
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
    data[0] = Float16.doubleToFloat16(r.toDouble());
    final nc = data.length;
    if (nc > 1) {
      data[1] = Float16.doubleToFloat16(g.toDouble());
      if (nc > 2) {
        data[2] = Float16.doubleToFloat16(b.toDouble());
        if (nc > 3) {
          data[3] = Float16.doubleToFloat16(a.toDouble());
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
