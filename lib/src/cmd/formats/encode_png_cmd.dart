import '../../formats/formats.dart';
import '../../formats/png_encoder.dart';
import '../image_command.dart';

class EncodePngCmd extends ImageCommand {
  ImageCommand? input;
  int level;
  PngFilter filter;

  EncodePngCmd(this.input, { this.level = 6, this.filter = PngFilter.paeth });

  @override
  void executeCommand() {
    input?.executeIfDirty();
    image = input?.image;
    if (image != null) {
      bytes = encodePng(image!, level: level, filter: filter);
    }
  }
}
