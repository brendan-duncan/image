part of image;

class ImageException {
  String reason;

  ImageException(this.reason);

  String toString() => reason;
}
