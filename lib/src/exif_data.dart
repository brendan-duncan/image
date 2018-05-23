import 'dart:typed_data';

/**
 * Exif data stored with an image.
 */
class ExifData {
  static const int CAMERA_MAKE = 0x010F; // string
  static const int CAMERA_MODEL = 0x0110; // string
  static const int DATE_TIME = 0x0132; // string
  static const int ORIENTATION = 0x0112; // int

  Uint8List rawData;
  Map<int, dynamic> data;

  ExifData()
    : data = new Map<int, dynamic>()
    , rawData = null;

  ExifData.from(ExifData other)
    : data = (other == null) ?
              new Map<int, dynamic>() :
              new Map<int, dynamic>.from(other.data)
    , rawData = (other == null || other.rawData == null) ?
                null : new Uint8List.fromList(other.rawData);

  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;

  bool get hasRawData => rawData != null;

  bool get hasOrientation => data.containsKey(ORIENTATION);
  int get orientation => data[ORIENTATION];
  set orientation(int value) => data[ORIENTATION] = value;
}
