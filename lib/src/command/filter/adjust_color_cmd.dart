import '../../color/color.dart';
import '../../filter/adjust_color.dart' as g;
import '../command.dart';

class AdjustColorCmd extends Command {
  final Color? blacks;
  final Color? whites;
  final Color? mids;
  final num? _contrast;
  final num? saturation;
  final num? brightness;
  final num? _gamma;
  final num? exposure;
  final num? hue;
  final num? amount;

  AdjustColorCmd(Command? input, { this.blacks,
      this.whites,
      this.mids,
      num? contrast,
      this.saturation,
      this.brightness,
      num? gamma,
      this.exposure,
      this.hue,
      this.amount })
      : _contrast = contrast
      , _gamma = gamma
      , super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ? g.adjustColor(img, blacks: blacks,
        whites: whites, mids: mids, contrast: _contrast, saturation: saturation,
        brightness: brightness, gamma: _gamma, exposure: exposure,
        hue: hue, amount: amount) : null;
  }
}
