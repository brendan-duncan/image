import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readFile(String path) => File(path).readAsBytes();

Future<void> writeFile(String path, Uint8List bytes) async {
  final fp = File(path);
  await fp.create(recursive: true);
  await fp.writeAsBytes(bytes);
}
