import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'image_exception.dart';

/// Inflates the zlib stream [data], stopping after [maxLength] bytes, so a
/// small stream can't inflate to an unbounded size.
Uint8List inflate(List<int> data, int maxLength) {
  final input = inflateLazy(data);
  try {
    final bytes = input.readBytes(maxLength).toUint8List();
    if (bytes.length == maxLength) {
      // The Adler-32 is checked at the end of the stream, which reading
      // maxLength bytes may not reach.
      input.readBytes(1).toUint8List();
    }
    return bytes;
  } on FormatException catch (e) {
    throw ImageException('Invalid compressed data: ${e.message}');
  } finally {
    input.closeSync();
  }
}

/// A stream that inflates the zlib stream [data] as it is read.
///
/// The compressed data is handed to zlib in steps of [_inflateStep] bytes,
/// as each step is inflated whole: zlib expands up to about 1032 times, so a
/// step of 64 KB of crafted data would otherwise inflate to 64 MB at once.
InputStream inflateLazy(List<int> data) =>
    const ZLibDecoder().decodeLazy(_SteppedInput(data), verify: true);

const _inflateStep = 8192;

/// Gives at most [_inflateStep] bytes from each [readBytes].
class _SteppedInput extends InputMemoryStream {
  _SteppedInput(super.bytes);

  @override
  InputStream readBytes(int count) =>
      super.readBytes(count < _inflateStep ? count : _inflateStep);
}
