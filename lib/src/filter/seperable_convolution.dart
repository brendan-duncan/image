part of image;

/**
 * Apply a generic seperable convolution filter the [src] image, using the
 * given [kernel].
 *
 * [gaussianBlur] is an example of such a filter.
 */
Image seperableConvolution(Image src, SeperableKernel kernel) {
  // Apply the filter horizontally
  Image tmp = new Image.from(src);
  kernel.apply(src, tmp, horizontal: true);

  // Apply the filter vertically, applying back to the original image.
  kernel.apply(tmp, src, horizontal: false);

  return src;
}
