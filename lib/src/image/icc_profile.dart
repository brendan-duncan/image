import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../util/_inflate.dart';

enum IccProfileCompression { none, deflate }

/// ICC Profile data stored with an image.
class IccProfile {
  String name = '';
  IccProfileCompression compression;
  Uint8List data;

  IccProfile(this.name, this.compression, this.data);

  IccProfile.from(IccProfile other)
      : name = other.name,
        compression = other.compression,
        data = other.data.sublist(0);

  IccProfile clone() => IccProfile.from(this);

  /// Returns the compressed data of the ICC Profile, compressing the stored
  /// data as necessary.
  Uint8List compressed() {
    if (compression == IccProfileCompression.deflate) {
      return data;
    }
    data = const ZLibEncoder().encode(data) as Uint8List;
    compression = IccProfileCompression.deflate;
    return data;
  }

  // The largest decompressed profile, so malformed data can't inflate to an
  // unbounded size.
  static const _maxSize = 16 * 1024 * 1024;

  /// Returns the uncompressed data of the ICC Profile, decompressing the stored
  /// data as necessary. Profiles larger than 16 MB are truncated.
  Uint8List decompressed() {
    if (compression == IccProfileCompression.none) {
      return data;
    }
    data = inflate(data, _maxSize);
    compression = IccProfileCompression.none;
    return data;
  }
}
