import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a WebP Image from byte [data].
class DecodeWebPCmd extends Command {
  Uint8List data;

  DecodeWebPCmd(Command? input, this.data) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = decodeWebP(data);
  }
}

// Decode a WebP from a file at the given [path].
class DecodeWebPFileCmd extends Command {
  String path;

  DecodeWebPFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = await decodeWebPFile(path);
  }
}

// Encode an Image to the WebP format.
class EncodeWebPCmd extends Command {
  EncodeWebPCmd(Command? input) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeWebP(outputImage!);
    }
  }
}

// Encode an Image to the WebP format and write it to a file at the given
// [path].
class EncodeWebPFileCmd extends Command {
  String path;

  EncodeWebPFileCmd(Command? input, this.path) : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      await encodeWebPFile(path, outputImage!);
    }
  }
}
