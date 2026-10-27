import 'dart:math';
import 'dart:typed_data';

import '../../util/input_buffer.dart';
import '../../util/output_buffer.dart';
import 'jpeg_marker.dart';

// An ICC profile is stored in APP2 segments, each with 'ICC_PROFILE\0', its
// 1-based sequence number, the number of segments and a part of the profile.

const _signature = [
  0x49,
  0x43,
  0x43,
  0x5F,
  0x50,
  0x52,
  0x4F,
  0x46,
  0x49,
  0x4C,
  0x45,
  0x00
]; // "ICC_PROFILE\0"

// The size of a segment before its part of the profile: the length, the
// signature, the sequence number and the count.
const _headerSize = 2 + 12 + 2;

// The segment length is 16 bits.
const _maxPartSize = 65535 - _headerSize;

/// Writes [profile] as APP2 segments.
void writeJpegIccProfile(OutputBuffer out, Uint8List profile) {
  final numParts = (profile.length + _maxPartSize - 1) ~/ _maxPartSize;
  for (var i = 0; i < numParts; ++i) {
    final start = i * _maxPartSize;
    final end = min(start + _maxPartSize, profile.length);
    out
      ..writeByte(0xff)
      ..writeByte(JpegMarker.app2)
      ..writeUint16(_headerSize + end - start)
      ..writeBytes(_signature)
      ..writeByte(i + 1)
      ..writeByte(numParts)
      ..writeBytes(Uint8List.sublistView(profile, start, end));
  }
}

/// Joins the parts of an ICC profile read from APP2 segments.
class JpegIccProfileReader {
  final _parts = <int, Uint8List>{};

  /// Reads the APP2 [block]. Returns the profile when all of its parts are
  /// read, or null.
  Uint8List? read(InputBuffer block) {
    if (block.length < _signature.length + 2) {
      return null;
    }
    for (final b in _signature) {
      if (block.readByte() != b) {
        return null;
      }
    }
    final sequence = block.readByte();
    final numParts = block.readByte();
    if (sequence == 0 || sequence > numParts) {
      return null;
    }
    _parts[sequence] = block.toUint8List();
    return _join(numParts);
  }

  Uint8List? _join(int numParts) {
    final parts = <Uint8List>[];
    for (var i = 1; i <= numParts; ++i) {
      final part = _parts[i];
      if (part == null) {
        return null;
      }
      parts.add(part);
    }
    final profile =
        Uint8List(parts.fold(0, (size, part) => size + part.length));
    var offset = 0;
    for (final part in parts) {
      profile.setAll(offset, part);
      offset += part.length;
    }
    return profile;
  }
}
