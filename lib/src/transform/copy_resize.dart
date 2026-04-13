import '../color/color.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import '../native/transform_backend.dart';
import 'copy_resize_dart.dart';

/// Returns a resized copy of the [src] Image.
/// If [height] isn't specified, then it will be determined by the aspect
/// ratio of [src] and [width].
/// If [width] isn't specified, then it will be determined by the aspect ratio
/// of [src] and [height].
Image copyResize(Image src,
    {int? width,
    int? height,
    bool? maintainAspect,
    Color? backgroundColor,
    Interpolation interpolation = Interpolation.nearest}) {
  if (width != null &&
      height != null &&
      maintainAspect != true &&
      backgroundColor == null) {
    final native = tryNativeCopyResize(
      src,
      width: width,
      height: height,
      interpolation: interpolation,
    );
    if (native != null) {
      return native;
    }
  }
  return copyResizeDart(
    src,
    width: width,
    height: height,
    maintainAspect: maintainAspect,
    backgroundColor: backgroundColor,
    interpolation: interpolation,
  );
}
