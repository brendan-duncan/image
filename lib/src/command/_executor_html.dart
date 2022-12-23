import 'dart:typed_data';

import '../image/image.dart';
import 'command.dart';
import 'execute_result.dart';

Future<ExecuteResult> executeCommandAsync(Command? command) async {
  command?.execute();
  return ExecuteResult(command?.image, command?.bytes);
}

Image? executeCommandImage(Command? command) {
  command?.execute();
  return command?.image;
}

Future<Image?> executeCommandImageAsync(Command? command) async {
  command?.execute();
  return command?.image;
}

Uint8List? executeCommandBytes(Command? command) {
  command?.execute();
  return command?.bytes;
}

Future<Uint8List?> executeCommandBytesAsync(Command? command) async {
  command?.execute();
  return command?.bytes;
}
