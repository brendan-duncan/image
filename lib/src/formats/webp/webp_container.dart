/// Building the RIFF container a WebP file is wrapped in.
///
/// A single still frame with no metadata needs nothing but a RIFF header and
/// the bitstream. Animation, an ICC profile, EXIF or XMP all force the
/// extended format, which announces what is present in a VP8X chunk and then
/// carries each part as its own chunk
library;

import 'dart:typed_data';

import '../../util/_internal.dart';
import '../../util/output_buffer.dart';

/// A chunk of a WebP file: a four character tag and its payload.
@internal
class WebPChunk {
  WebPChunk(this.tag, this.data);

  final String tag;
  final Uint8List data;

  /// Chunks are padded to an even length, and the pad byte is not counted in
  /// the size field.
  int get diskSize => 8 + data.length + (data.length.isOdd ? 1 : 0);

  void writeTo(OutputBuffer out) {
    out
      ..writeBytes(webPTag(tag))
      ..writeUint32(data.length)
      ..writeBytes(data);
    if (data.length.isOdd) {
      out.writeByte(0);
    }
  }
}

/// The four bytes of a chunk tag.
@internal
Uint8List webPTag(String s) {
  final bytes = Uint8List(s.length);
  for (var i = 0; i < s.length; i++) {
    bytes[i] = s.codeUnitAt(i);
  }
  return bytes;
}

/// The flags byte of a VP8X chunk.
@internal
int vp8xFlags(
        {required bool hasIcc,
        required bool hasAlpha,
        required bool hasExif,
        required bool hasXmp,
        required bool hasAnimation}) =>
    (hasIcc ? 1 << 5 : 0) |
    (hasAlpha ? 1 << 4 : 0) |
    (hasExif ? 1 << 3 : 0) |
    (hasXmp ? 1 << 2 : 0) |
    (hasAnimation ? 1 << 1 : 0);

/// The VP8X chunk payload: the flags and the canvas size.
@internal
Uint8List vp8xChunkData(int flags, int width, int height) {
  final out = OutputBuffer()
    ..writeByte(flags)
    ..writeByte(0) // reserved, 24 bits
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24(out, width - 1);
  _writeUint24(out, height - 1);
  return out.getBytes();
}

/// The ANIM chunk payload: the canvas background color and the loop count.
///
/// [loopCount] is clamped, since wrapping its sixteen bit field turns 70000
/// loops into 4464
@internal
Uint8List animChunkData(int r, int g, int b, int a, int loopCount) {
  // The chunk holds blue, green, red, alpha in that byte order, and the buffer
  // is little endian, so the packed value runs the other way.
  final out = OutputBuffer()
    ..writeUint32((a << 24) | (r << 16) | (g << 8) | b)
    ..writeUint16(loopCount.clamp(0, 0xffff));
  return out.getBytes();
}

/// One ANMF chunk: the frame's placement and timing, then its bitstream.
///
/// [duration] is clamped, since wrapping its twenty four bit field turns a
/// negative duration into a pause of over four hours
@internal
Uint8List anmfChunkData(
    {required int x,
    required int y,
    required int width,
    required int height,
    required int duration,
    required bool clearToBackground,
    required bool blend,
    required List<WebPChunk> frame}) {
  final out = OutputBuffer();
  // The offsets are stored halved, so they are always even.
  _writeUint24(out, x >> 1);
  _writeUint24(out, y >> 1);
  _writeUint24(out, width - 1);
  _writeUint24(out, height - 1);
  _writeUint24(out, duration.clamp(0, 0xffffff));
  // Bit 0 disposes to the background after the frame is shown, bit 1 is set
  // when the frame must not be blended
  out.writeByte((clearToBackground ? 1 : 0) | (blend ? 0 : 2));
  // The frame's own chunks follow: its bitstream, preceded by the alpha plane
  // when the bitstream is lossy and carries none of its own.
  for (final chunk in frame) {
    chunk.writeTo(out);
  }
  return out.getBytes();
}

/// Wraps [chunks] in the RIFF/WEBP header.
@internal
Uint8List buildRiff(List<WebPChunk> chunks) {
  var payload = 4; // the 'WEBP' tag
  for (final c in chunks) {
    payload += c.diskSize;
  }

  final out = OutputBuffer()
    ..writeBytes(webPTag('RIFF'))
    ..writeUint32(payload)
    ..writeBytes(webPTag('WEBP'));
  for (final c in chunks) {
    c.writeTo(out);
  }
  return out.getBytes();
}

void _writeUint24(OutputBuffer out, int v) {
  out
    ..writeByte(v & 0xff)
    ..writeByte((v >> 8) & 0xff)
    ..writeByte((v >> 16) & 0xff);
}
