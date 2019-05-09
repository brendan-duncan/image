import 'dart:typed_data';

/**
 * Exif data stored with an image.
 */
class ExifData {
  static const int CAMERA_MAKE = 0x010F; // string
  static const int CAMERA_MODEL = 0x0110; // string
  static const int DATE_TIME = 0x0132; // string
  static const int ORIENTATION = 0x0112; // int

  List<Uint8List> rawData;
  Map<int, dynamic> data;

  ExifData() : data = Map<int, dynamic>();

  ExifData.from(ExifData other)
      : data = (other == null)
            ? new Map<int, dynamic>()
            : new Map<int, dynamic>.from(other.data) {
    if (other != null && other.rawData != null) {
      rawData = List<Uint8List>(other.rawData.length);
      for (int i = 0; i < other.rawData.length; ++i) {
        rawData[i] = Uint8List.fromList(other.rawData[i]);
      }
    }
  }

  bool get hasRawData => rawData != null && rawData.isNotEmpty;

  bool get hasOrientation => data.containsKey(ORIENTATION);
  int get orientation => data[ORIENTATION];
  set orientation(int value) => data[ORIENTATION] = value;
}
