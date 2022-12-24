import 'dart:typed_data';

Future<Uint8List?> readFile(String path) async =>
    throw UnsupportedError('File access is only supported by dart:io');

Future<void> writeFile(String path, Uint8List bytes) async =>
  throw UnsupportedError('File access is only supported by dart:io');
