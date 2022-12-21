import '../../formats/formats.dart';
import '../image_command.dart';
import '_file_access.dart'
    if (dart.library.io) '_file_access_io.dart'
    if (dart.library.js) '_file_access_html.dart';

class WriteToFileCmd extends ImageCommand {
  ImageCommand? input;
  String path;

  WriteToFileCmd(this.input, this.path);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    image = input?.image;
    bytes = input?.bytes;

    if (bytes == null && image != null) {
      final ext = path.split('.').last.toLowerCase();
      if (ext == 'png') {
        bytes = encodePng(image!);
      } else if (ext == 'jpg' || ext == 'jpeg') {
        bytes = encodeJpg(image!);
      } else if (ext == 'gif') {
        bytes = encodeGif(image!);
      } else if (ext == 'tga') {
        bytes = encodeTga(image!);
      } else if (ext == 'bmp') {
        bytes = encodeBmp(image!);
      } else if (ext == 'tif' || ext == 'tiff') {
        bytes = encodeBmp(image!);
      } else if (ext == 'cur') {
        bytes = encodeCur(image!);
      } else if (ext == 'ico') {
        bytes = encodeIco(image!);
      }
    }

    if (bytes != null) {
      writeFile(path, bytes!);
    }
  }
}
