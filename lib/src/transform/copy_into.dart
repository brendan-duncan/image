import '../image.dart';
import '../draw/draw_pixel.dart';

/// Copies a rectangular portion of one image to another image. [dst] is the
/// destination image, [src] is the source image identifier.
///
/// In other words, copyInto will take an rectangular area from src of
/// width [src_w] and height [src_h] at position ([src_x],[src_y]) and place it
/// in a rectangular area of [dst] of width [dst_w] and height [dst_h] at
/// position ([dst_x],[dst_y]).
///
/// If the source and destination coordinates and width and heights differ,
/// appropriate stretching or shrinking of the image fragment will be performed.
/// The coordinates refer to the upper left corner. This function can be used to
/// copy regions within the same image (if [dst] is the same as [src])
/// but if the regions overlap the results will be unpredictable.
Image copyInto(Image dst, Image src,
    {int? dstX,
    int? dstY,
    int? srcX,
    int? srcY,
    int? srcW,
    int? srcH,
    bool blend = true}) {
  dstX ??= 0;
  dstY ??= 0;
  srcX ??= 0;
  srcY ??= 0;
  srcW ??= src.width;
  srcH ??= src.height;

  for (var y = 0; y < srcH; ++y) {
    for (var x = 0; x < srcW; ++x) {
      if (blend) {
        drawPixel(dst, dstX + x, dstY + y, src.getPixel(srcX + x, srcY + y));
      } else {
        dst.setPixel(dstX + x, dstY + y, src.getPixel(srcX + x, srcY + y));
      }
    }
  }

  return dst;
}
