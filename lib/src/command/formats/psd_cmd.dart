import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';
import '_file_access.dart'
if (dart.library.io) '_file_access_io.dart'
if (dart.library.js) '_file_access_html.dart';

// Decode a Psd Image from byte [data].
class DecodePsdCmd extends Command {
  Uint8List data;

  DecodePsdCmd(this.data);

  @override
  void executeCommand() {
    image = decodePsd(data);
  }
}

// Decode a Psd from a file at the given [path].
class DecodePsdFileCmd extends Command {
  String path;

  DecodePsdFileCmd(this.path);

  @override
  void executeCommand() {
    final bytes = readFile(path);
    image = bytes != null ? decodePsd(bytes) : null;
  }
}