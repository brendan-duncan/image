import '../../formats/formats.dart';
import '../command.dart';

class DecodeImageFileCmd extends Command {
  String path;

  DecodeImageFileCmd(this.path);

  @override
  Future<void> executeCommand() async {
    outputImage = await decodeImageFile(path);
  }
}
