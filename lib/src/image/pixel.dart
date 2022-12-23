import '../color/color.dart';
import 'image_data.dart';
import 'pixel_undefined.dart';

abstract class Pixel extends Iterator<Pixel> implements Color {
  /// [undefined] is used to represent an invalid pixel.
  static Pixel get undefined => PixelUndefined();

  ImageData get image;

  int get width;
  int get height;

  int get x;
  void set x(int value);

  int get y;
  void set y(int value);

  void setPosition(int x, int y);

  bool moveNext();

  Pixel get current;

  bool operator==(Object? other);
  int get hashCode;
}
