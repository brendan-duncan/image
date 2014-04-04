part of image;

class ExrFrameBuffer {
  Map<String, ExrSlice> slices = {};
  // cached slices for quick access
  ExrSlice red;
  ExrSlice green;
  ExrSlice blue;
  ExrSlice alpha;

  bool contains(String channel) => slices.containsKey(channel);

  ExrSlice operator[](String ch) => slices[ch];

  operator[]=(String ch, ExrSlice sl) {
    slices[ch] = sl;
    switch (sl.channel.name) {
      case ExrChannel.R:
        red = sl;
        break;
      case ExrChannel.G:
        green = sl;
        break;
      case ExrChannel.B:
        blue = sl;
        break;
      case ExrChannel.A:
        alpha = sl;
        break;
    }
  }

  int get width => slices.isEmpty ? 0 : slices.values.first.width;

  int get height => slices.isEmpty ? 0 : slices.values.first.height;
}
