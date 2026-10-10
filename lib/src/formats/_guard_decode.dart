import '../util/image_exception.dart';

/// Runs [decode], converting any error other than an [ImageException] into
/// one, so malformed data only ever throws an [ImageException].
T guardDecode<T>(T Function() decode) {
  try {
    return decode();
  } catch (e) {
    if (e is ImageException) {
      rethrow;
    }
    throw ImageException('Invalid image data: $e');
  }
}
