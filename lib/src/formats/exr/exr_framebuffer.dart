part of image;

class ExrFrameBuffer {
  Map<String, ExrSlice> slices = {};

  bool contains(String channel) => slices.containsKey(channel);

  ExrSlice operator[](String ch) => slices[ch];

  operator[]=(String ch, ExrSlice sl) => slices[ch] = sl;

  int get width => slices.isEmpty ? 0 : slices.values.first.width;

  int get height => slices.isEmpty ? 0 : slices.values.first.height;
}
