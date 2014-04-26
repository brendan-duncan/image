part of image;

/**
 * A slice is the data for an image framebuffer for a single channel.
 */
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

  HdrSlice(this.name, int width, int height, int type) :
    this.width = width,
    this.height = height,
    this.type = type,
    data = type == HdrImage.HALF ? new Uint16List(width * height) :
           type == HdrImage.FLOAT ? new Float32List(width * height) :
           new Uint32List(width * height);

  /**
   * Create a copy of the [other] HdrSlice.
   */
  HdrSlice.from(HdrSlice other) :
    name = other.name ,
    width = other.width,
    height = other.height,
    type = other.type,
    data = other.type == HdrImage.HALF ? new Uint16List.fromList(other.data) :
      other.type == HdrImage.FLOAT ? new Float32List.fromList(other.data) :
      new Uint32List.fromList(other.data);

  /**
   * Get the raw bytes of the data buffer.
   */
  Uint8List getBytes() => new Uint8List.view(data.buffer);

  /**
   * Does this channel store floating-point data?
   */
  bool get isFloat => type != HdrImage.UINT;

  /**
   * Get the float value of the sample at the coordinates [x],[y].
   * [Half] samples are converted to double.
   * An exception will occur if the slice stores UINT data.
   */
  double getFloat(int x, int y) {
    int pi = y * width + x;
    double s = (type == HdrImage.HALF) ?
               Half.HalfToDouble(data[pi]) : data[pi];
    return s;
  }

  /**
   * Set the float value of the sample at the coordinates [x],[y] for
   * [FLOAT] or [HALF] slices.
   */
  void setFloat(int x, int y, double v) {
    int pi = y * width + x;
    if (type == HdrImage.FLOAT) {
      data[pi] = v;
    } else if (type == HdrImage.HALF) {
      data[pi] = Half.DoubleToHalf(v);
    }
  }

  /**
   * Get the int value of the sample at the coordinates [x],[y].
   * An exception will occur if the slice stores FLOAT or HALF data.
   */
  int getInt(int x, int y) {
    int pi = y * width + x;
    return data[pi];
  }

  /**
   * Set the int value of the sample at the coordinates [x],[y] for [UINT]
   * slices.
   */
  void setInt(int x, int y, int v) {
    int pi = y * width + x;
    data[pi] = v;
  }
}
