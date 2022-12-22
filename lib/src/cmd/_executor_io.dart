import 'dart:isolate';
import 'dart:typed_data';

import '../image/image.dart';
import 'command.dart';
import 'execute_result.dart';

class _Params {
  final SendPort port;
  final Command? command;
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

Future<ExecuteResult> executeCommandAsync(Command? command) async {
  final port = ReceivePort();
  await Isolate.spawn(_getResult, _Params(port.sendPort, command));
  return await port.first as ExecuteResult;
}

Image? executeCommandImage(Command? command) {
  command?.execute();
  return command?.image;
}

Future<Image?> executeCommandImageAsync(Command? command) async {
  final port = ReceivePort();
  await Isolate.spawn(_getImage, _Params(port.sendPort, command));
  return await port.first as Image?;
}

Uint8List? executeCommandBytes(Command? command) {
  command?.execute();
  return command?.bytes;
}

Future<Uint8List?> executeCommandBytesAsync(Command? command) async {
  final port = ReceivePort();
  await Isolate.spawn(_getBytes, _Params(port.sendPort, command));
  return await port.first as Uint8List?;
}
