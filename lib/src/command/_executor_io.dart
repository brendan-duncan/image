import 'dart:isolate';
import 'dart:typed_data';

import '../image/image.dart';
import 'command.dart';
import 'execute_result.dart';

// Isolate.run sends the result back without copying it, and rethrows an
// error from the command here, so the returned future always completes.

Future<ExecuteResult> _getResult(Command? command) async {
  Object? exception;
  try {
    await command?.execute();
  } catch (e) {
    exception = e;
  }
  return ExecuteResult(
      command?.outputImage, command?.outputBytes, command?.outputObject,
      exception: exception);
}

Future<ExecuteResult> executeCommandAsync(Command? command) async {
  final result = await Isolate.run(() => _getResult(command));
  // Don't throw instances of classes that don't extend either 'Exception' or
  // 'Error'.
  if (result.exception is Error) {
    throw result.exception as Error;
  } else if (result.exception is Exception) {
    throw result.exception as Exception;
  }
  return result;
}

Future<Image?> executeCommandImage(Command? command) async {
  await command?.execute();
  return command?.outputImage;
}

Future<Image?> executeCommandImageAsync(Command? command) =>
    Isolate.run(() async {
      await command?.execute();
      return command?.outputImage;
    });

Future<Uint8List?> executeCommandBytes(Command? command) async {
  await command?.execute();
  return command?.outputBytes;
}

Future<Uint8List?> executeCommandBytesAsync(Command? command) =>
    Isolate.run(() async {
      await command?.execute();
      return command?.outputBytes;
    });
