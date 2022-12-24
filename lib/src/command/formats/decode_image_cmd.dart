import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';
import '_file_access.dart'
if (dart.library.io) '_file_access_io.dart'
if (dart.library.js) '_file_access_html.dart';

class DecodeImageCmd extends Command {
  Uint8List data;

  DecodeImageCmd(this.data);

  @override
  void executeCommand() {
    outputImage = decodeImage(data);
  }
}

class DecodeImageFileCmd extends Command {
  String path;

  DecodeImageFileCmd(this.path);

  @override
  void executeCommand() {
    final bytes = readFile(path);
    outputImage = bytes != null ? decodeImage(bytes) : null;
  }
}
