import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';
import '_file_access.dart'
if (dart.library.io) '_file_access_io.dart'
if (dart.library.js) '_file_access_html.dart';

// Decode a TGA Image from byte [data].
class DecodeTgaCmd extends Command {
  Uint8List data;

  DecodeTgaCmd(this.data);

  @override
  Future<void> executeCommand() async {
    outputImage = decodeTga(data);
  }
}

// Decode a TGA from a file at the given [path].
class DecodeTgaFileCmd extends Command {
  String path;

  DecodeTgaFileCmd(this.path);

  @override
  Future<void> executeCommand() async {
    final bytes = await readFile(path);
    outputImage = bytes != null ? decodeTga(bytes) : null;
  }
}

// Encode an Image to the TGA format.
class EncodeTgaCmd extends Command {
  EncodeTgaCmd(Command? input)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeTga(outputImage!);
    }
  }
}

// Encode an Image to the TGA format and write it to a file at the given
// [path].
class EncodeTgaFileCmd extends EncodeTgaCmd {
  String path;

  EncodeTgaFileCmd(Command? input, this.path)
      : super(input);

  @override
  Future<void> executeCommand() async {
    await super.executeCommand();
    if (outputBytes != null) {
      await writeFile(path, outputBytes!);
    }
  }
}
