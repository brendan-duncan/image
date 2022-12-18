import 'format.dart';

abstract class Color extends Iterable<num> {
  Color clone();

  int get length;
  num get maxChannelValue;
  Format get format;
  bool get isLdrFormat;
  bool get isHdrFormat;

  num operator[](int index);
  void operator[]=(int index, num value);

  num get index;
  void set index(num i);

  num get r;
  void set r(num r);
  num get g;
  void set g(num g);
  num get b;
  void set b(num b);
  num get a;
  void set a(num a);

  void set(Color c);
  void setColor(num r, [num g = 0, num b = 0, num a = 0]);

  Color convert({ Format? format, int? numChannels, num? alpha });

  bool operator==(Object? other);
  int get hashCode;
}
