import 'dart:io';
import 'dart:typed_data';

Uint8List? readFile(String path) =>
    File(path).readAsBytesSync();

void writeFile(String path, Uint8List bytes) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
}
