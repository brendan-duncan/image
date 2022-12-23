import 'dart:typed_data';

Uint8List? readFile(String path) =>
    throw UnsupportedError('File access is only supported by dart:io');

void writeFile(String path, Uint8List bytes) =>
  throw UnsupportedError('File access is only supported by dart:io');
