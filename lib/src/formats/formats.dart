part of image;

/**
 * Identify the format of the image and decode it with the appropriate
 * decoder.
 */
Image decodeNamedImage(List<int> bytes, String name) {
  String n = name.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) {
    return decodeJpg(bytes);
  }
  if (n.endsWith('.png')) {
    return decodePng(bytes);
  }
  if (n.endsWith('.tga')) {
    return decodeTga(bytes);
  }
  if (n.endsWith('.webp')) {
    return decodeWebP(bytes);
  }
  return null;
}


/**
 * Decode a JPG formatted image.
 */
Image decodeJpg(List<int> bytes)  {
  return new JpegDecoder().decode(bytes);
}

/**
 * Renamed to [decodeJpg], left for backward compatibility.
 */
Image readJpg(List<int> bytes) => decodeJpg(bytes);


/**
 * Encode an image to the JPEG format.
 */
List<int> encodeJpg(Image image, {int quality: 100}) {
  return new JpegEncoder(quality: quality).encode(image);
}

/**
 * Renamed to [encodeJpg], left for backward compatibility.
 */
List<int> writeJpg(Image image, {int quality: 100}) =>
  encodeJpg(image, quality: quality);


/**
 * Decode a PNG formatted image.
 */
Image decodePng(List<int> bytes) {
  return new PngDecoder().decode(bytes);
}

/**
 * Renamed to [decodePng], left for backward compatibility.
 */
Image readPng(List<int> bytes) => decodePng(bytes);

/**
 * Encode an image to the PNG format.
 */
List<int> encodePng(Image image, {int level: 6}) {
  return new PngEncoder(level: level).encode(image);
}

/**
 * Renamed to [encodePng], left for backward compatibility.
 */
List<int> writePng(Image image, {int level: 6}) =>
    encodePng(image, level: level);

/**
 * Decode a Targa formatted image.
 */
Image decodeTga(List<int> bytes) {
  return new TgaDecoder().decode(bytes);
}

/**
 * Renamed to [decodeTga], left for backward compatibility.
 */
Image readTga(List<int> bytes) => decodeTga(bytes);

/**
 * Encode an image to the Targa format.
 */
List<int> encodeTga(Image image) {
  return new TgaEncoder().encode(image);
}

/**
 * Renamed to [encodeTga], left for backward compatibility.
 */
List<int> writeTga(Image image) => encodeTga(image);

/**
 * Decode a WebP formatted image (first frame for animations).
 */
Image decodeWebP(List<int> bytes) {
  return new WebPDecoder().decodeImage(bytes);
}

/**
 * Renamed to [decodeWebP], left for backward compatibility.
 */
Image readWebP(List<int> bytes) => decodeWebP(bytes);
