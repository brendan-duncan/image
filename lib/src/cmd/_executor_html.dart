import 'dart:typed_data';

import '../image/image.dart';
import 'execute_result.dart';
import 'image_command.dart';

Future<ExecuteResult> executeCommandAsync(ImageCommand? command) async {
  command?.execute();
  return ExecuteResult(command?.image, command?.bytes);
}

Image? executeCommandImage(ImageCommand? command) {
  command?.execute();
  return command?.image;
}

Future<Image?> executeCommandImageAsync(ImageCommand? command) async {
  command?.execute();
  return command?.image;
}

Uint8List? executeCommandBytes(ImageCommand? command) {
  command?.execute();
  return command?.bytes;
}

Future<Uint8List?> executeCommandBytesAsync(ImageCommand? command) async {
  command?.execute();
  return command?.bytes;
}
