part of image;

/**
 * A slice is the data for an image framebuffer for a single channel.
 */
class HdrSlice {
  final String name;
  final int width;
  final int height;
  final int type;
  final dynamic data;

  HdrSlice(this.name, int width, int height, int type) :
    this.width = width,
    this.height = height,
    this.type = type,
    data = type == HdrImage.HALF ? new Uint16List(width * height) :
           type == HdrImage.FLOAT ? new Float32List(width * height) :
           new Uint32List(width * height);

  /**
   * Get the raw bytes of the data buffer.
   */
  Uint8List getBytes() => new Uint8List.view(data);

  /**
   * Does this channel store floating-point data?
   */
  bool get isFloat => type != HdrImage.UINT;

  /**
   * Get the float value of the sample at the coordinates [x],[y].
   * [Half] samples are converted to double.
   * An exception will occur if the slice stores UINT data.
   */
  double getFloatSample(int x, int y) {
    int pi = y * width + x;
    double s = (type == HdrImage.HALF) ?
               Half.HalfToDouble(data[pi]) : data[pi];
    return s;
  }

  /**
   * Get the int value of the sample at the coordinates [x],[y].
   * An exception will occur if the slice stores FLOAT or HALF data.
   */
  int getIntSample(int x, int y) {
    int pi = y * width + x;
    return data[pi];
  }
}
