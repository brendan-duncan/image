import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart';

List<File> listBuckPngFiles() {
  final dir = Directory('benchmark/_data');
  if (!dir.existsSync()) {
    return const [];
  }
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.png') && f.path.contains('buck_'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

Image loadSampleImage() {
  final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
  final img = decodePng(bytes);
  if (img == null) {
    throw StateError('Failed to decode sample image');
  }
  return img;
}

Uint8List loadBytes(String relPath) => File(relPath).readAsBytesSync();

Image makeSolidImage(int w, int h, {int numChannels = 4, Color? color}) =>
    Image(width: w, height: h, numChannels: numChannels)
      ..clear(color ?? ColorRgba8(128, 64, 32, 255));
