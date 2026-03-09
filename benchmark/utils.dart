import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart';

List<File> listBuckPngFiles() {
  final dir = Directory('benchmark/_data');
  if (!dir.existsSync()) {
    return const [];
  }
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.png') && f.path.contains('buck_'))
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

Image loadSampleImage() {
  final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
  final img = decodePng(bytes);
  if (img == null) {
    throw StateError('Failed to decode sample image');
  }
  return img;
}

Uint8List loadBytes(String relPath) {
  return File(relPath).readAsBytesSync();
}

Image makeSolidImage(int w, int h, {int numChannels = 4, Color? color}) {
  final c = color ?? ColorRgba8(128, 64, 32, 255);
  return Image(width: w, height: h, numChannels: numChannels)..clear(c);
}
