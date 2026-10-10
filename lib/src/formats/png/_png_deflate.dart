import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../util/output_buffer.dart';

/// Compresses PNG image data that is added in pieces, passing the compressed
/// zlib stream to [onData] as it becomes available.
///
/// The pure Dart deflate can't compress a stream in pieces, so this collects
/// the data and compresses it when closed. The dart:io version
/// (`_png_deflate_io.dart`) streams it.
class PngDeflater {
  final int? level;
  final void Function(Uint8List bytes) onData;
  final OutputBuffer _data;

  /// [sizeHint] is the expected total size of the uncompressed data.
  PngDeflater(this.level, int sizeHint, this.onData)
      : _data = OutputBuffer(size: sizeHint);

  /// Adds [bytes] to the data to compress. [bytes] can be reused by the caller
  /// once this returns.
  void add(Uint8List bytes) => _data.writeBytes(bytes);

  /// Finishes compressing the data.
  void close() =>
      onData(const ZLibEncoder().encodeBytes(_data.getBytes(), level: level));
}
