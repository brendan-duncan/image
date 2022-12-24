import '../../formats/formats.dart';
import '../command.dart';
import '_file_access.dart'
if (dart.library.io) '_file_access_io.dart'
if (dart.library.js) '_file_access_html.dart';

class WriteToFileCmd extends Command {
  String path;

  WriteToFileCmd(Command? input, this.path)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    outputBytes = input?.outputBytes;

    if (outputBytes == null && outputImage != null) {
      final ext = path.split('.').last.toLowerCase();
      if (ext == 'png') {
        outputBytes = encodePng(outputImage!);
      } else if (ext == 'jpg' || ext == 'jpeg') {
        outputBytes = encodeJpg(outputImage!);
      } else if (ext == 'gif') {
        outputBytes = encodeGif(outputImage!);
      } else if (ext == 'tga') {
        outputBytes = encodeTga(outputImage!);
      } else if (ext == 'bmp') {
        outputBytes = encodeBmp(outputImage!);
      } else if (ext == 'tif' || ext == 'tiff') {
        outputBytes = encodeBmp(outputImage!);
      } else if (ext == 'cur') {
        outputBytes = encodeCur(outputImage!);
      } else if (ext == 'ico') {
        outputBytes = encodeIco(outputImage!);
      }
    }

    if (outputBytes != null) {
      await writeFile(path, outputBytes!);
    }
  }
}
