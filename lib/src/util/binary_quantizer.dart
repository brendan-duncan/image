import '../color/color.dart';
import '../color/color_uint8.dart';
import '../image/palette.dart';
import '../image/palette_uint8.dart';
import '../util/color_util.dart';
import 'quantizer.dart';

class BinaryQuantizer extends Quantizer {
  final Palette _palette;
  final num threshold;

  BinaryQuantizer({this.threshold = 0.5}) : _palette = PaletteUint8(2, 3) {
    _palette.setRgb(1, 255, 255, 255);
  }

  @override
  Palette get palette => _palette;

  @override
  Color getQuantizedColor(Color c) => c.luminanceNormalized < threshold
      ? ColorRgb8(_palette.getRed(0) as int, _palette.getGreen(0) as int,
          _palette.getBlue(0) as int)
      : ColorRgb8(_palette.getRed(1) as int, _palette.getGreen(1) as int,
          _palette.getBlue(1) as int);

  @override
  int getColorIndex(Color c) => c.luminanceNormalized < threshold ? 0 : 1;

  @override
  int getColorIndexRgb(int r, int g, int b) =>
      getLuminanceRgb(r, g, b) < threshold ? 0 : 1;
}
