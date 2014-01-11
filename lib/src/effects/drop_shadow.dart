part of image;

Image dropShadow(Image src, int hshadow, int vshadow, int blur,
                 {int shadowColor: 0x000000a0}) {
  int dw = src.width + hshadow + (blur + 5);
  int dh = src.height + vshadow + (blur + 5);

  Image dst = new Image(dw, dh, Image.RGBA);

  fill(dst, 0xffffff00);

  fillRect(dst, hshadow, vshadow,
           src.width + hshadow,
           src.height + vshadow,
           shadowColor);

  dst = copyGaussianBlur(dst, blur ~/ 2);

  copyInto(dst, src);

  return dst;
}
