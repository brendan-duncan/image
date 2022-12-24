import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';
import '_file_access.dart'
if (dart.library.io) '_file_access_io.dart'
if (dart.library.js) '_file_access_html.dart';

// Decode a TIFF Image from byte [data].
class DecodeTiffCmd extends Command {
  Uint8List data;

  DecodeTiffCmd(this.data);

  @override
  Future<void> executeCommand() async {
    outputImage = decodeTiff(data);
  }
}

// Decode a TIFF from a file at the given [path].
class DecodeTiffFileCmd extends Command {
  String path;

  DecodeTiffFileCmd(this.path);

  @override
  Future<void> executeCommand() async {
    final bytes = await readFile(path);
    outputImage = bytes != null ? decodeTiff(bytes) : null;
  }
}

// Encode an Image to the TIFF format.
class EncodeTiffCmd extends Command {
  EncodeTiffCmd(Command? input)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeTiff(outputImage!);
    }
  }
}

// Encode an Image to the TIFF format and write it to a file at the given
// [path].
class EncodeTiffFileCmd extends EncodeTiffCmd {
  String path;

  EncodeTiffFileCmd(Command? input, this.path)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await super.executeCommand();
    if (outputBytes != null) {
      await writeFile(path, outputBytes!);
    }
  }
}
