part of image;

/**
 * Set all of the pixels of an [image] to the given [color].
 */
Image fill(Image image, int color) {
  image.buffer.fillRange(0, image.buffer.length, color);
  return image;
}
