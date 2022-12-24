import '../../color/format.dart';
import '../command.dart';

class ConvertCmd extends Command {
  int? numChannels;
  Format? format;
  ConvertCmd(Command? input, { this.numChannels, this.format })
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    final img = input?.outputImage;
    outputImage = img?.convert(format: format, numChannels: numChannels);
  }
}
