import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

class DecodeImageCmd extends Command {
  Uint8List data;

  DecodeImageCmd(this.data);

  @override
  Future<void> executeCommand() async {
    outputImage = decodeImage(data);
  }
}
