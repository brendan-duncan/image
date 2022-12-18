import '../color/color.dart';
import '../image/image.dart';
import '../image/palette.dart';

enum QuantizerType {
  Octree,
  Neural
}

abstract class Quantizer {
  Palette get palette;

  /// Find the index of the closest color to [c] in the [colorMap].
  Color getQuantizedColor(Color c);

  int getColorIndex(Color c);

  int getColorIndexRgb(int r, int g, int b);

  /// Convert the [image] to a palette image.
  Image getIndexImage(Image image) {
    final target = Image(image.width, image.height, numChannels: 1,
        palette: palette);

    final ti = target.iterator;
    ti.moveNext();

    for (var p in image) {
      var t = ti.current;
      t[0] = getColorIndex(p);
      ti.moveNext();
    }

    return target;
  }
}
