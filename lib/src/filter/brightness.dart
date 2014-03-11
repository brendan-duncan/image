part of image;

/**
 * Set the [brightness] level for the image [src].
 *
 * [brightness] is an offset that is added to the red, green, and blue channels
 * of every pixel.
 */
Image brightness(Image src, int brightness) {
  if (src == null || brightness == 0) {
    return src;
  }

  var pixels = src.getBytes();
  for (int i = 0, len = pixels.length; i < len; i += 4) {
    pixels[i] = _clamp255(pixels[i] + brightness);
    pixels[i + 1] = _clamp255(pixels[i + 1] + brightness);
    pixels[i + 2] = _clamp255(pixels[i + 2] + brightness);
  }

  return src;
}
