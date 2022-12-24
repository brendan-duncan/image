import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';
import '_file_access.dart'
if (dart.library.io) '_file_access_io.dart'
if (dart.library.js) '_file_access_html.dart';

// Decode a BMP Image from byte [data].
class DecodeBmpCmd extends Command {
  Uint8List data;

  DecodeBmpCmd(this.data);

  @override
  void executeCommand() {
    outputImage = decodeBmp(data);
  }
}

// Decode a BMP from a file at the given [path].
class DecodeBmpFileCmd extends Command {
  String path;

  DecodeBmpFileCmd(this.path);

  @override
  void executeCommand() {
    final bytes = readFile(path);
    outputImage = bytes != null ? decodeBmp(bytes) : null;
  }
}

// Encode an Image to the BMP format.
class EncodeBmpCmd extends Command {
  EncodeBmpCmd(Command? input)
      : super(input);

  @override
  void executeCommand() {
    input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeBmp(outputImage!);
    }
  }
}

// Encode an Image to the BMP format and write it to a file at the given
// [path].
class EncodeBmpFileCmd extends EncodeBmpCmd {
  String path;

  EncodeBmpFileCmd(Command? input, this.path)
      : super(input);

  @override
  void executeCommand() {
    super.executeCommand();
    if (outputBytes != null) {
      writeFile(path, outputBytes!);
    }
  }
}
