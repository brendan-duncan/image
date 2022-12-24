import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';
import '_file_access.dart'
if (dart.library.io) '_file_access_io.dart'
if (dart.library.js) '_file_access_html.dart';

// Decode a JPEG Image from byte [data].
class DecodeJpgCmd extends Command {
  Uint8List data;

  DecodeJpgCmd(this.data);

  @override
  Future<void> executeCommand() async {
    outputImage = decodeJpg(data);
  }
}

// Decode a JPEG from a file at the given [path].
class DecodeJpgFileCmd extends Command {
  String path;

  DecodeJpgFileCmd(this.path);

  @override
  Future<void> executeCommand() async {
    final bytes = await readFile(path);
    outputImage = bytes != null ? decodeJpg(bytes) : null;
  }
}

// Encode an Image to the JPEG format.
class EncodeJpgCmd extends Command {
  int quality;

  EncodeJpgCmd(Command? input, { this.quality = 100 })
      : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeJpg(outputImage!, quality: quality);
    }
  }
}

// Encode an Image to the JPEG format and write it to a file at the given
// [path].
class EncodeJpgFileCmd extends EncodeJpgCmd {
  String path;

  EncodeJpgFileCmd(Command? input, this.path, { int quality = 100 })
      : super(input, quality: quality);

  @override
  Future<void> executeCommand() async {
    await super.executeCommand();
    if (outputBytes != null) {
      await writeFile(path, outputBytes!);
    }
  }
}
