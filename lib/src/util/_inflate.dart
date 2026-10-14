import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'image_exception.dart';

/// Inflates the zlib stream [data], stopping after [maxLength] bytes, so a
/// small stream can't inflate to an unbounded size.
Uint8List inflate(List<int> data, int maxLength) {
  final input =
      const ZLibDecoder().decodeLazy(InputMemoryStream(data), verify: true);
  try {
    final bytes = input.readBytes(maxLength).toUint8List();
    if (bytes.length == maxLength) {
      // Adler-32 is checked at stream end, which maxLength bytes may not reach
      input.readBytes(1).toUint8List();
    }
    return bytes;
  } on FormatException catch (e) {
    throw ImageException('Invalid compressed data: $e');
  } finally {
    input.closeSync();
  }
}
