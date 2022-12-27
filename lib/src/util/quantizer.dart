import '../color/color.dart';
import '../image/image.dart';
import '../image/palette.dart';

enum QuantizerType {
  octree,
  neural
}

abstract class Quantizer {
  Palette get palette;

  /// Find the index of the closest color to [c] in the colorMap.
  Color getQuantizedColor(Color c);

  int getColorIndex(Color c);

  int getColorIndexRgb(int r, int g, int b);

  /// Convert the [image] to a palette image.
  Image getIndexImage(Image image) {
    final target = Image(width: image.width, height: image.height,
        numChannels: 1, palette: palette);

    final ti = target.iterator..moveNext();

    for (var p in image) {
      final t = ti.current;
      t[0] = getColorIndex(p);
      ti.moveNext();
    }

    return target;
  }
}
