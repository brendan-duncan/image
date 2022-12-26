import 'dart:typed_data';

import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/format.dart';
import '../util/color_util.dart';
import 'image.dart';
import 'image_data_uint2.dart';
import 'palette.dart';
import 'pixel.dart';

class PixelUint2 extends Iterable<num> implements Pixel {
  int _x;
  int _y;
  int _index;
  int _bitIndex;
  int _rowOffset;
  final ImageDataUint2 image;

  PixelUint2.imageData(this.image)
      : _x = -1
      , _y = 0
      , _index = 0
      , _bitIndex = -2
      , _rowOffset = 0;

  PixelUint2.image(Image image)
      : _x = -1
      , _y = 0
      , _index = 0
      , _bitIndex = -2
      , _rowOffset = 0
      , image = image.data is ImageDataUint2 ? image.data as ImageDataUint2
          : ImageDataUint2(0, 0, 0);

  PixelUint2.from(PixelUint2 other)
      : _x = other._x
      , _y = other._y
      , _index = other._index
      , _bitIndex = other._bitIndex
      , _rowOffset = other._rowOffset
      , image = other.image;

  PixelUint2 clone() => PixelUint2.from(this);

  int get length => palette?.numChannels ?? image.numChannels;
  int get numChannels => palette?.numChannels ?? image.numChannels;
  bool get hasPalette => image.hasPalette;
  Palette? get palette => image.palette;
  int get width => image.width;
  int get height => image.height;
  Uint8List get data => image.data;
  num get maxChannelValue => image.maxChannelValue;
  Format get format => Format.uint2;
  bool get isLdrFormat => image.isLdrFormat;
  bool get isHdrFormat => image.isHdrFormat;

  bool get isValid => x >= 0 && x < (image.width - 1) &&
      y >= 0 && y < (image.height - 1);

  int get bitsPerPixel => image.palette != null ? 2 : image.numChannels << 1;

  int get x => _x;
  int get y => _y;

  /// The normalized x coordinate of the pixel, in the range \[0, 1\].
  num get xNormalized => width > 1 ? _x / (width - 1) : 0;

  /// The normalized y coordinate of the pixel, in the range \[0, 1\].
  num get yNormalized => height > 1 ? _y / (height - 1) : 0;

  /// Set the normalized coordinates of the pixel, in the range \[0, 1\].
  void setPositionNormalized(num x, num y) =>
      setPosition((x * (width - 1)).floor(), (y * (height - 1)).floor());

  void setPosition(int x, int y) {
    this._x = x;
    this._y = y;
    final bpp = bitsPerPixel;
    _rowOffset = _y * image.rowStride;
    _index = _rowOffset + ((_x * bpp) >> 3);
    _bitIndex = (_x * bpp) & 0x7;
  }

  Pixel get current => this;

  bool moveNext() {
    _x++;
    if (x == width) {
      _x = 0;
      _y++;
      _bitIndex = 0;
      _index++;
      _rowOffset += image.rowStride;
      return _y < height;
    }

    final nc = numChannels;
    if (palette != null || nc == 1) {
      _bitIndex += 2;
      if (_bitIndex > 7) {
        _bitIndex = 0;
        _index++;
      }
    } else {
      final bpp = bitsPerPixel;
      _bitIndex = (x * bpp) & 0x7;
      _index = _rowOffset + ((x * bpp) >> 3);
    }

    return _index < image.data.length;
  }

  int _get(int ci) {
    var i = _index;
    var bi = 6 - (_bitIndex + (ci << 1));
    if (bi < 0) {
      bi += 8;
      i++;
    }
    return (image.data[i] >> bi) & 0x3;
  }

  num get(int ci) => palette == null ? numChannels > ci ? _get(ci)  : 0
      : palette!.get(_get(0), ci);

  void setChannel(int ci, num value) {
    if (ci >= image.numChannels) {
      return;
    }

    var i = _index;
    var bi = 6 - (_bitIndex + (ci << 1));
    if (bi < 0) {
      i++;
      bi += 8;
    }

    var v = data[i];
    final vi = value.toInt().clamp(0, 3);
    const _mask = [ 0xfc, 0xf3, 0xcf, 0x3f ];
    final mask = _mask[bi >> 1];
    v = (v & mask) | (vi << bi);
    data[i] = v;
  }

  num operator[](int i) => get(i);

  void operator[]=(int i, num value) => setChannel(i, value);

  num get index => _get(0);
  void set index(num i) => setChannel(0, i);

  num get r => get(0);

  void set r(num r) => setChannel(0, r);

  num get g => get(1);

  void set g(num g) => setChannel(1, g);

  num get b => get(2);

  void set b(num b) => setChannel(2, b);

  num get a => get(3);

  void set a(num a) => setChannel(3, a);

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
    final nc = image.numChannels;
    if (nc > 0) {
      setChannel(0, r);
      if (nc > 1) {
        setChannel(1, g);
        if (nc > 2) {
          setChannel(2, b);
          if (nc > 3) {
            setChannel(3, a);
          }
        }
      }
    }
  }

  ChannelIterator get iterator => ChannelIterator(this);

  bool operator==(Object? other) {
    if (other is PixelUint2) {
      return hashCode == other.hashCode;
    }
    if (other is List<int>) {
      final nc = palette != null ? palette!.numChannels : numChannels;
      if (other.length != nc) {
        return false;
      }
      if (get(0) != other[0]) {
        return false;
      }
      if (nc > 1) {
        if (get(1) != other[1]) {
          return false;
        }
        if (nc > 2) {
          if (get(2) != other[2]) {
            return false;
          }
          if (nc > 3) {
            if (get(3) != other[3]) {
              return false;
            }
          }
        }
      }
      return true;
    }
    return false;
  }

  int get hashCode => Object.hashAll(toList());

  Color convert({ Format? format, int? numChannels, num? alpha }) =>
      convertColor(this, format: format, numChannels: numChannels,
          alpha: alpha);
}
