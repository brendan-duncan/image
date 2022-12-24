import '../../formats/formats.dart';
import '../command.dart';
import '_file_access.dart'
if (dart.library.io) '_file_access_io.dart'
if (dart.library.js) '_file_access_html.dart';

class DecodeImageFileCmd extends Command {
  String path;

  DecodeImageFileCmd(this.path);

  @override
  Future<void> executeCommand() async {
    final bytes = await readFile(path);
    if (bytes != null) {
      final decoder = findDecoderForNamedImage(path);
      if (decoder != null) {
        outputImage = decoder.decode(bytes);
      }
    }
  }
}
