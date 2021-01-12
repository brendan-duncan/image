/// An exception thrown when there was a problem in the image library.
// @dart=2.11
class ImageException implements Exception {
  /// A message describing the error.
  final String message;

  ImageException(this.message);

  @override
  String toString() => 'ImageException: $message';
}
