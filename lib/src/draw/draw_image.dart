import '../image.dart';
import 'draw_pixel.dart';

/// Draw the image [src] onto the image [dst].
///
/// In other words, drawImage will take an rectangular area from src of
/// width [src_w] and height [src_h] at position ([src_x],[src_y]) and place it
/// in a rectangular area of [dst] of width [dst_w] and height [dst_h] at
/// position ([dst_x],[dst_y]).
///
/// If the source and destination coordinates and width and heights differ,
/// appropriate stretching or shrinking of the image fragment will be performed.
/// The coordinates refer to the upper left corner. This function can be used to
/// copy regions within the same image (if [dst] is the same as [src])
/// but if the regions overlap the results will be unpredictable.
Image drawImage(Image dst, Image src,
    {int dstX,
    int dstY,
    int dstW,
    int dstH,
    int srcX,
    int srcY,
    int srcW,
    int srcH,
    bool blend = true}) {
  if (dstX == null) {
    dstX = 0;
  }
  if (dstY == null) {
    dstY = 0;
  }
  if (srcX == null) {
    srcX = 0;
  }
  if (srcY == null) {
    srcY = 0;
  }
  if (srcW == null) {
    srcW = src.width;
  }
  if (srcH == null) {
    srcH = src.height;
  }
  if (dstW == null) {
    if (dst.width < src.width) {
      dstW = dst.width;
    } else {
      dstW = src.width;
    }
  }
  if (dstH == null) {
    if (dst.height < dst.height) {
      dstH = dst.height;
    } else {
      dstH = src.height;
    }
  }

  for (int y = 0; y < dstH; ++y) {
    for (int x = 0; x < dstW; ++x) {
      int stepX = (x * (srcW / dstW)).toInt();
      int stepY = (y * (srcH / dstH)).toInt();

      final srcPixel = src.getPixel(srcX + stepX, srcY + stepY);
      if (blend) {
        drawPixel(dst, dstX + x, dstY + y, srcPixel);
      } else {
        dst.setPixel(dstX + x, dstY + y, srcPixel);
      }
    }
  }

  return dst;
}
