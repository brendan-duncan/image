import 'dart:typed_data';

import 'half.dart';
import 'hdr_image.dart';

/// A slice is the data for an image framebuffer for a single channel.
class HdrSlice {
  final String name;
  final int width;
  final int height;

  /// Indicates the type of data stored by the slice, either [HdrImage.HALF],
  /// [HdrImage.FLOAT], or [HdrImage.UINT].
  final int type;

  /// [data] will be either Uint16List, Float32List, or Uint32List depending
  /// on the type being HALF, FLOAT or UINT respectively.
  final dynamic data;

  HdrSlice(this.name, int width, int height, int type)
      : width = width,
        height = height,
        type = type,
        data = type == HdrImage.HALF
            ? Uint16List(width * height)
            : type == HdrImage.FLOAT64
                ? Float64List(width * height)
                : type == HdrImage.FLOAT
                    ? Float32List(width * height)
                    : Uint32List(width * height);

  /// Create a copy of the [other] HdrSlice.
  HdrSlice.from(HdrSlice other)
      : name = other.name,
        width = other.width,
        height = other.height,
        type = other.type,
        data = other.type == HdrImage.HALF
            ? (other.data as Uint16List).sublist(0)
            : other.type == HdrImage.FLOAT64
                ? (other.data as Float64List).sublist(0)
                : other.type == HdrImage.FLOAT
                    ? (other.data as Float32List).sublist(0)
                    : (other.data as Uint32List).sublist(0);

  /// Get the raw bytes of the data buffer.
  Uint8List getBytes() => Uint8List.view(data.buffer as ByteBuffer);

  /// Does this channel store floating-point data?
  bool get isFloat =>
      type == HdrImage.FLOAT ||
      type == HdrImage.FLOAT64 ||
      type == HdrImage.HALF;

  /// Get the float value of the sample at the coordinates [x],[y].
  /// [Half] samples are converted to double.
  /// An exception will occur if the slice stores UINT data.
  double getFloat(int x, int y) {
    final pi = y * width + x;
    var s = (type == HdrImage.HALF)
        ? Half.HalfToDouble(data[pi] as int)
        : data[pi] as double;
    return s;
  }

  /// Set the float value of the sample at the coordinates [x],[y] for
  ///[FLOAT] or [HALF] slices.
  void setFloat(int x, int y, num v) {
    final pi = y * width + x;
    if (type == HdrImage.FLOAT || type == HdrImage.FLOAT64) {
      data[pi] = v;
    } else if (type == HdrImage.HALF) {
      data[pi] = Half.DoubleToHalf(v);
    }
  }

  /// Get the int value of the sample at the coordinates [x],[y].
  ///An exception will occur if the slice stores FLOAT or HALF data.
  int getInt(int x, int y) {
    final pi = y * width + x;
    return data[pi] as int;
  }

  /// Set the int value of the sample at the coordinates [x],[y] for [UINT]
  /// slices.
  void setInt(int x, int y, int v) {
    final pi = y * width + x;
    data[pi] = v;
  }
}
