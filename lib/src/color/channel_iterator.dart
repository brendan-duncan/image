import 'color.dart';

/// An iterator over the channels of a [Color].
class ChannelIterator extends Iterator<num> {
  int index = -1;
  Color color;

  ChannelIterator(this.color);

  bool moveNext() {
    index++;
    return index < color.length;
  }

  num get current => color[index];
}
