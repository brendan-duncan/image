import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

// Decode a WebP Image from byte [data].
class DecodeWebPCmd extends Command {
  Uint8List data;

  DecodeWebPCmd(this.data);

  @override
  Future<void> executeCommand() async {
    outputImage = decodeWebP(data);
  }
}

// Decode a WebP from a file at the given [path].
class DecodeWebPFileCmd extends Command {
  String path;

  DecodeWebPFileCmd(this.path);

  @override
  Future<void> executeCommand() async {
    outputImage = await decodeWebPFile(path);
  }
}
