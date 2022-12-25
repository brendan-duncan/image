import '../../filter/luminance_threshold.dart';
import '../command.dart';

class LuminanceThresholdCmd extends Command {
  final num threshold;
  final bool outputColor;
  final num amount;
  LuminanceThresholdCmd(Command? input, { this.threshold = 0.5,
      this.outputColor = false, this.amount = 1 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    final img = input?.outputImage;
    outputImage = img != null ?
        luminanceThreshold(img, threshold: threshold, outputColor: outputColor,
            amount: amount)
        : null;
  }
}
