import '../../formats/formats.dart';
import '../command.dart';
import '_file_access.dart'
if (dart.library.io) '_file_access_io.dart'
if (dart.library.js) '_file_access_html.dart';

// Encode an Image to the Cur format.
class EncodeCurCmd extends Command {
  EncodeCurCmd(Command? input)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    image = input?.image;
    if (image != null) {
      bytes = encodeCur(image!);
    }
  }
}

// Encode an Image to the Cur format and write it to a file at the given
// [path].
class EncodeCurFileCmd extends EncodeCurCmd {
  String path;

  EncodeCurFileCmd(Command? input, this.path)
      : super(input);

  @override
  void executeCommand() {
    super.executeCommand();
    if (bytes != null) {
      writeFile(path, bytes!);
    }
  }
}
