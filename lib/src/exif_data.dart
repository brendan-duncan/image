
class ExifData {
  ExifData()
    : _data = new Map<int, dynamic>();

  ExifData.from(ExifData other)
    : _data = (other == null) ?
              new Map<int, dynamic> :
              new Map<int, dynamic>.from(other._data);

  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;

  bool get hasCameraMake => _data.containsKey(_CAMERA_MAKE);
  String get cameraMake => _data[_CAMERA_MAKE];
  set cameraMake(String value) => _data[_CAMERA_MAKE] = value;

  bool get hasCameraModel => _data.containsKey(_CAMERA_MODEL);
  String get cameraModel => _data[_CAMERA_MODEL];
  set cameraModel(String value) => _data[_CAMERA_MODEL] = value;

  bool get hasDateTime => _data.containsKey(_DATE_TIME);
  String get dateTime => _data[_DATE_TIME];
  set dateTime(String value) => _data[_DATE_TIME] = value;

  bool get hasOrientation => _data.containsKey(_ORIENTATION);
  int get orientation => _data[_ORIENTATION];
  set orientation(int value) => _data[_ORIENTATION] = value;

  static const int _CAMERA_MAKE = 0; // string
  static const int _CAMERA_MODEL = 1; // string
  static const int _DATE_TIME = 2; // string
  static const int _ORIENTATION = 3; // int
  static const int _IS_COLOR = 4; // int
  static const int _PROCESS = 5; // int
  static const int _FLASH_USED = 6; // int
  static const int _FOCAL_LENGTH = 7; // float
  static const int _EXPOSURE_TIME = 8; // float
  static const int _APERTURE_FNUMBER = 9; // float
  static const int _DISTANCE = 10; // float
  static const int _CCD_WIDTH = 11; // float
  static const int _EPOSURE_BIAS = 12; // float
  static const int _DIGITAL_ZOOM_RATIO = 13; // float
  static const int _FOCAL_LENGTH_35MM_EQUIV = 14; // int
  static const int _WHITEBALANCE = 15; // int
  static const int _METERING_MODE = 16; // int
  static const int _EXPOSURE_PROGRAM = 17; // int
  static const int _EXPOSURE_MODE = 18; // int
  static const int _ISO_EQUIVALENT = 19; // int
  static const int _LIGHT_SOURCE = 20; // int
  static const int _DISTANCE_RANGE = 21; // int

  Map<int, dynamic> _data;
}
