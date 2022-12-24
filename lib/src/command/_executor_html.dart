import 'dart:typed_data';

import '../image/image.dart';
import 'command.dart';
import 'execute_result.dart';

Future<ExecuteResult> executeCommandAsync(Command? command) async {
  command?.execute();
  return ExecuteResult(command?.outputImage, command?.outputBytes);
}

Image? executeCommandImage(Command? command) {
  command?.execute();
  return command?.outputImage;
}

Future<Image?> executeCommandImageAsync(Command? command) async {
  command?.execute();
  return command?.outputImage;
}

Uint8List? executeCommandBytes(Command? command) {
  command?.execute();
  return command?.outputBytes;
}

Future<Uint8List?> executeCommandBytesAsync(Command? command) async {
  command?.execute();
  return command?.outputBytes;
}
