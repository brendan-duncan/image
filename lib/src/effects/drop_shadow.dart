part of image;

/**
 * Create a drop-shadow effect for the image.
 *
 * TODO this is just doing a rectangle shadow; use the src image to crete the
 * shadow.
 *
 * TODO support different directions of shadows (0 or negative h/vshadow).
 */
Image dropShadow(Image src, int hshadow, int vshadow, int blur,
                 {int shadowColor: 0x000000a0}) {
  int dw = src.width + hshadow + (blur + 5);
  int dh = src.height + vshadow + (blur + 5);

  Image dst = new Image(dw, dh, Image.RGBA);

  fill(dst, 0xffffff00);

  fillRect(dst, hshadow, vshadow,
           src.width + hshadow * 2,
           src.height + vshadow * 2,
           shadowColor);

  gaussianBlur(dst, blur ~/ 2);

  copyInto(dst, src);

  return dst;
}
