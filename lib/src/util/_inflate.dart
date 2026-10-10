import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Inflates the zlib stream [data], stopping after [maxLength] bytes, so a
/// small stream can't inflate to an unbounded size.
Uint8List inflate(List<int> data, int maxLength) {
  final input = const ZLibDecoder().decodeLazy(InputMemoryStream(data));
  try {
    return input.readBytes(maxLength).toUint8List();
  } finally {
    input.closeSync();
  }
}
