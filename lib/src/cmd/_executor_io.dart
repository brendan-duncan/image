import 'dart:isolate';
import 'dart:typed_data';

import '../image/image.dart';
import 'execute_result.dart';
import 'image_command.dart';

class _Params {
  final SendPort port;
  final ImageCommand? command;
  _Params(this.port, this.command);
}

Future<Image?> _getImage(_Params p) {
  p.command?.execute();
  final res = p.command?.image;
  Isolate.exit(p.port, res);
}

Future<Uint8List?> _getBytes(_Params p) {
  p.command?.execute();
  final res = p.command?.bytes;
  Isolate.exit(p.port, res);
}

Future<ExecuteResult> _getResult(_Params p) {
  p.command?.execute();
  Isolate.exit(p.port, ExecuteResult(p.command?.image, p.command?.bytes));
}

Future<ExecuteResult> executeCommandAsync(ImageCommand? command) async {
  final port = ReceivePort();
  await Isolate.spawn(_getResult, _Params(port.sendPort, command));
  return await port.first as ExecuteResult;
}

Image? executeCommandImage(ImageCommand? command) {
  command?.execute();
  return command?.image;
}

Future<Image?> executeCommandImageAsync(ImageCommand? command) async {
  final port = ReceivePort();
  await Isolate.spawn(_getImage, _Params(port.sendPort, command));
  return await port.first as Image?;
}

Uint8List? executeCommandBytes(ImageCommand? command) {
  command?.execute();
  return command?.bytes;
}

Future<Uint8List?> executeCommandBytesAsync(ImageCommand? command) async {
  final port = ReceivePort();
  await Isolate.spawn(_getBytes, _Params(port.sendPort, command));
  return await port.first as Uint8List?;
}
