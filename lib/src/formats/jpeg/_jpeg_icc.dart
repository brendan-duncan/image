import 'dart:math';
import 'dart:typed_data';

import '../../util/image_exception.dart';
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

// The sequence number and count are 8 bits.
const _maxParts = 255;

/// Writes [profile] as APP2 segments. Throws an [ImageException] if it doesn't
/// fit in them.
void writeJpegIccProfile(OutputBuffer out, Uint8List profile) {
  final numParts = (profile.length + _maxPartSize - 1) ~/ _maxPartSize;
  if (numParts > _maxParts) {
    throw ImageException('ICC profile is too large for a JPEG');
  }
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

/// Collects the parts of an ICC profile from APP2 segments.
class JpegIccProfileReader {
  final _parts = <int, Uint8List>{};
  var _numParts = 0;
  var _valid = true;

  /// Reads the APP2 [block], ignoring it if it isn't an ICC profile segment.
  void read(InputBuffer block) {
    if (block.length < _signature.length + 2) {
      return;
    }
    for (final b in _signature) {
      if (block.readByte() != b) {
        return;
      }
    }
    final data = block.toUint8List();
    if (_isUnsplit(data)) {
      _add(1, 1, data);
    } else {
      _add(data[0], data[1], Uint8List.sublistView(data, 2));
    }
  }

  /// The joined profile, or null if the segments read don't make a complete
  /// profile: like libjpeg, a count that differs between segments or a repeated
  /// sequence number invalidates all of them.
  Uint8List? get profile {
    if (!_valid || _parts.isEmpty || _parts.length != _numParts) {
      return null;
    }
    final profile = BytesBuilder(copy: false);
    for (var i = 1; i <= _numParts; ++i) {
      profile.add(_parts[i]!);
    }
    return profile.takeBytes();
  }

  // encodeJpg before 4.13.0 wrote the profile directly after the signature. The
  // profile starts with its big-endian size, so the byte that would be the
  // sequence number is 0, and the size is that of the segment data.
  bool _isUnsplit(Uint8List data) =>
      data.length >= 4 &&
      data[0] == 0 &&
      ByteData.sublistView(data).getUint32(0) == data.length;

  void _add(int sequence, int numParts, Uint8List part) {
    if (_numParts == 0) {
      _numParts = numParts;
    }
    if (sequence == 0 ||
        sequence > numParts ||
        numParts != _numParts ||
        _parts.containsKey(sequence)) {
      _valid = false;
      return;
    }
    _parts[sequence] = part;
  }
}
