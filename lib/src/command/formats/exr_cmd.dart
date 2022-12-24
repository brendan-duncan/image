import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a Exr Image from byte [data].
class DecodeExrCmd extends Command {
  Uint8List data;

  DecodeExrCmd(this.data);

  @override
  Future<void> executeCommand() async {
    outputImage = decodeExr(data);
  }
}

// Decode a Exr from a file at the given [path].
class DecodeExrFileCmd extends Command {
  String path;

  DecodeExrFileCmd(this.path);

  @override
  Future<void> executeCommand() async {
    outputImage = await decodeExrFile(path);
  }
}
