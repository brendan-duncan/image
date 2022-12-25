import 'dart:typed_data';

import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../util/color_util.dart';
import '../color/format.dart';
import 'image.dart';
import 'image_data_uint8.dart';
import 'palette.dart';
import 'pixel.dart';

class PixelUint8 extends Iterable<num> implements Pixel {
  int x;
  int y;
  int _index;
  final ImageDataUint8 image;

  PixelUint8.imageData(this.image)
      : x = -1
      , y = 0
      , _index = -image.numChannels;

  PixelUint8.image(Image image)
      : x = -1
      , y = 0
      , _index = -image.numChannels
      , image = image.data is ImageDataUint8 ? image.data as ImageDataUint8
          : ImageDataUint8(0, 0, 0);

  PixelUint8.from(PixelUint8 other)
      : x = other.x
      , y = other.y
      , _index = other._index
      , image = other.image;

  PixelUint8 clone() => PixelUint8.from(this);

  int get length => palette?.numChannels ?? image.numChannels;
  int get numChannels => palette?.numChannels ?? image.numChannels;
  bool get hasPalette => image.hasPalette;
  Palette? get palette => image.palette;
  int get width => image.width;
  int get height => image.height;
  Uint8List get data => image.data;
  num get maxChannelValue => image.maxChannelValue;
  Format get format => Format.uint8;
  bool get isLdrFormat => image.isLdrFormat;
  bool get isHdrFormat => image.isHdrFormat;

  void setPosition(int x, int y) {
    this.x = x;
    this.y = y;
    _index = y * image.width * image.numChannels + (x * image.numChannels);
  }

  Pixel get current => this;

  bool moveNext() {
    x++;
    if (x == width) {
      x = 0;
      y++;
    }
    _index += palette == null ? numChannels : 1;
    return _index < image.data.length;
  }

  void updateCache() {}

  num get(int ci) => palette != null ?
      palette!.get(data[_index], ci) :
      ci < numChannels ? data[_index + ci] : 0;

  num operator[](int ci) => get(ci);

  void operator[]=(int ci, num value) {
    if (ci < numChannels) {
      data[_index + ci] = value.clamp(0, 255).toInt();
    }
  }

  num get index => data[_index];
  void set index(num i) => data[_index] = i.clamp(0, 255).toInt();

  num get r => palette == null ? numChannels > 0 ? data[_index] : 0
      : palette!.getRed(data[_index]);

  void set r(num r) {
    if (image.numChannels > 0) {
      data[_index] = r.clamp(0, 255).toInt();
    }
  }

  num get g => palette == null ? numChannels > 1 ? data[_index + 1]  : 0
      : palette!.getGreen(data[_index]);

  void set g(num g) {
    if (image.numChannels > 1) {
      data[_index + 1] = g.clamp(0, 255).toInt();
    }
  }

  num get b => palette == null ? numChannels > 2 ? data[_index + 2]  : 0
      : palette!.getBlue(data[_index]);

  void set b(num b) {
    if (image.numChannels > 2) {
      data[_index + 2] = b.clamp(0, 255).toInt();
    }
  }

  num get a => palette == null ? numChannels > 3 ? data[_index + 3]  : 255
      : palette!.getAlpha(data[_index]);

  void set a(num a) {
    if (image.numChannels > 3) {
      data[_index + 3] = a.clamp(0, 255).toInt();
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
    if (image.hasPalette) {
      index = c.index;
    } else {
      r = c.r;
      g = c.g;
      b = c.b;
      a = c.a;
    }
  }

  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {
    final nc = image.numChannels;
    if (nc > 0) {
      data[_index] = r.clamp(0, 255).toInt();
      if (nc > 1) {
        data[_index + 1] = g.clamp(0, 255).toInt();
        if (nc > 2) {
          data[_index + 2] = b.clamp(0, 255).toInt();
          if (nc > 3) {
            data[_index + 3] = a.clamp(0, 255).toInt();
          }
        }
      }
    }
  }

  ChannelIterator get iterator => ChannelIterator(this);

  bool operator==(Object? other) {
    if (other is PixelUint8) {
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
