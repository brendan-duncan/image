import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Compresses PNG image data that is added in pieces, passing the compressed
/// zlib stream to [onData] as it becomes available, so neither the whole
/// uncompressed nor compressed data has to be held in memory.
class PngDeflater {
  final void Function(Uint8List bytes) onData;
  late final ByteConversionSink _sink;

  /// [sizeHint] is the expected total size of the uncompressed data, which
  /// isn't needed here.
  // ignore: avoid_unused_constructor_parameters
  PngDeflater(int? level, int sizeHint, this.onData) {
    _sink = ZLibCodec(level: level ?? 6)
        .encoder
        .startChunkedConversion(_CallbackSink(onData));
  }

  /// Adds [bytes] to the data to compress. [bytes] can be reused by the caller
  /// once this returns: the platform's zlib copies the data it's given.
  void add(Uint8List bytes) => _sink.add(bytes);

  /// Finishes compressing the data.
  void close() => _sink.close();
}

class _CallbackSink implements Sink<List<int>> {
  final void Function(Uint8List bytes) onData;

  _CallbackSink(this.onData);

  @override
  void add(List<int> data) =>
      onData(data is Uint8List ? data : Uint8List.fromList(data));

  @override
  void close() {}
}
