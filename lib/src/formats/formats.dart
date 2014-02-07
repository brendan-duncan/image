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
  if (n.endsWith('.gif')) {
    return decodeGif(bytes);
  }
  return null;
}

/**
 * Identify the format of the image and encode it with the appropriate
 * encoder.
 */
List<int> encodeNamedImage(Image image, String name) {
  String n = name.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) {
    return encodeJpg(image);
  }
  if (n.endsWith('.png')) {
    return encodePng(image);
  }
  if (n.endsWith('.tga')) {
    return encodeTga(image);
  }
  /*if (n.endsWith('.webp')) {
    return encodeWebP(image);
  }*/
  if (n.endsWith('.gif')) {
    return encodeGif(image);
  }
  return null;
}

/**
 * Decode a JPG formatted image.
 */
Image decodeJpg(List<int> bytes)  {
  return new JpegDecoder().decodeImage(bytes);
}

/**
 * Renamed to [decodeJpg], left for backward compatibility.
 */
Image readJpg(List<int> bytes) => decodeJpg(bytes);


/**
 * Encode an image to the JPEG format.
 */
List<int> encodeJpg(Image image, {int quality: 100}) {
  return new JpegEncoder(quality: quality).encodeImage(image);
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
  return new PngDecoder().decodeImage(bytes);
}

/**
 * Renamed to [decodePng], left for backward compatibility.
 */
Image readPng(List<int> bytes) => decodePng(bytes);

/**
 * Encode an image to the PNG format.
 */
List<int> encodePng(Image image, {int level: 6}) {
  return new PngEncoder(level: level).encodeImage(image);
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
  return new TgaDecoder().decodeImage(bytes);
}

/**
 * Renamed to [decodeTga], left for backward compatibility.
 */
Image readTga(List<int> bytes) => decodeTga(bytes);

/**
 * Encode an image to the Targa format.
 */
List<int> encodeTga(Image image) {
  return new TgaEncoder().encodeImage(image);
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
 * Decode an animated WebP file.  If the webp isn't animated, the animation
 * will contain a single frame with the webp's image.
 */
Animation decodeWebPAnimation(List<int> bytes) {
  return new WebPDecoder().decodeAnimation(bytes);
}

/**
 * Decode a GIF formatted image (first frame for animations).
 */
Image decodeGif(List<int> bytes) {
  return new GifDecoder().decodeImage(bytes);
}

/**
 * Decode an animated GIF file.  If the gif isn't animated, the animation
 * will contain a single frame with the gif's image.
 */
Animation decodeGifAnimation(List<int> bytes) {
  return new GifDecoder().decodeAnimation(bytes);
}

/**
 * Encode an image to the GIF format.
 */
List<int> encodeGif(Image image) {
  return new GifEncoder().encodeImage(image);
}

/**
 * Encode an animation to the GIF format.
 */
List<int> encodeGifAnimation(Animation anim) {
  return new GifEncoder().encodeAnimation(anim);
}
