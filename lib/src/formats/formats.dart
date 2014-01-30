part of image;


/**
 * Decode a JPG formatted image.
 */
Image readJpg(List<int> bytes) {
  return new JpegDecoder().decode(bytes);
}

/**
 * Encode an image to the JPEG format.
 */
List<int> writeJpg(Image image, {int quality: 100}) {
  return new JpegEncoder(quality: quality).encode(image);
}

/**
 * Decode a PNG formatted image.
 */
Image readPng(List<int> bytes) {
  return new PngDecoder().decode(bytes);
}

/**
 * Encode an image to the PNG format.
 */
List<int> writePng(Image image, {int level: 6}) {
  return new PngEncoder(level: level).encode(image);
}

/**
 * Decode a Targa formatted image.
 */
Image readTga(List<int> bytes) {
  return new TgaDecoder().decode(bytes);
}

/**
 * Encode an image to the Targa format.
 */
List<int> writeTga(Image image) {
  return new TgaEncoder().encode(image);
}

/**
 * Decode a WebP formatted image (first frame for animations).
 */
Image readWebP(List<int> bytes) {
  return new WebPDecoder().decodeImage(bytes);
}
