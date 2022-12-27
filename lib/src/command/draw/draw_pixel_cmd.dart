import '../../color/color.dart';
import '../../draw/blend_mode.dart';
import '../../draw/draw_pixel.dart';
import '../command.dart';

class DrawPixelCmd extends Command {
  int x;
  int y;
  Color color;
  final Color? _filter;
  double? alpha;
  BlendMode blend;

  DrawPixelCmd(Command? input, this.x, this.y, this.color, { Color? filter,
      this.alpha, this.blend = BlendMode.alpha })
      : this._filter = filter
      , super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? drawPixel(img, x, y, color, filter: _filter,
        alpha: alpha, blend: blend) : null;
  }
}
