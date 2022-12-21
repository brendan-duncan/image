import '../../formats/formats.dart';
import '../image_command.dart';
import '_file_access.dart'
    if (dart.library.io) '_file_access_io.dart'
    if (dart.library.js) '_file_access_html.dart';

class DecodeImageFileCmd extends ImageCommand {
  String path;

  DecodeImageFileCmd(this.path);

  @override
  void executeCommand() {
    final bytes = readFile(path);
    image = bytes != null ? decodeImage(bytes) : null;
  }
}
