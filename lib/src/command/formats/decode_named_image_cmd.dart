import 'dart:typed_data';

import '../../formats/formats.dart';
import '../command.dart';

class DecodeNamedImageCmd extends Command {
  String name;
  Uint8List data;

  DecodeNamedImageCmd(this.name, this.data);

  @override
  Future<void> executeCommand() async {
    final decoder = findDecoderForNamedImage(name);
    if (decoder != null) {
      outputImage = decoder.decode(data);
    } else {
      outputImage = decodeImage(data);
    }
  }
}

