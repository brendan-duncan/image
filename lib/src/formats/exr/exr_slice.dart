part of image;

/**
 * A slice contains channel data for an [ExrFrameBuffer].
 */
class ExrSlice {
  /// The channel stored by this slice.
  final ExrChannel channel;
  /// The raw data of the slice.
  final Uint8List bytes;
  /// The width of the slice.
  int width;
  /// The height of the slice.
  int height;
  /// The channel-specific data view.
  var data;

  ExrSlice(ExrChannel ch, int width, int height) :
    channel = ch,
    this.width = width,
    this.height = height,
    bytes = new Uint8List(width * height * ch.size) {
    data = (ch.type == ExrChannel.TYPE_FLOAT) ?
           new Float32List.view(bytes.buffer) :
           (ch.type == ExrChannel.TYPE_HALF) ?
           new Uint16List.view(bytes.buffer) :
           new Uint32List.view(bytes.buffer);
  }

  /**
   * Does this channel store floating-point data?
   */
  bool get isFloat => channel.type != ExrChannel.TYPE_UINT;

  /**
   * Get the float value of the sample at the coordinates [x],[y].
   * [Half] samples are converted to double.
   * An exception will occur if the slice stores UINT data.
   */
  double getFloatSample(int x, int y) {
    int pi = y * width + x;
    double s = (channel.type == ExrChannel.TYPE_HALF) ?
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
