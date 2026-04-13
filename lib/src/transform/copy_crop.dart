import '../image/image.dart';
import '../native/transform_backend.dart';
import 'copy_crop_dart.dart';

/// Returns a cropped copy of [src].
Image copyCrop(Image src,
    {required int x,
    required int y,
    required int width,
    required int height,
    num radius = 0,
    bool antialias = true}) {
  if (radius == 0) {
    final native = tryNativeCopyCrop(
      src,
      x: x,
      y: y,
      width: width,
      height: height,
    );
    if (native != null) {
      return native;
    }
  }
  return copyCropDart(
    src,
    x: x,
    y: y,
    width: width,
    height: height,
    radius: radius,
    antialias: antialias,
  );
}
