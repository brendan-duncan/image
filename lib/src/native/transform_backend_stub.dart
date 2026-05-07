import '../image/image.dart';
import '../image/interpolation.dart';

bool get nativeImageBackendAvailable => false;

Image? tryNativeCopyResize(
  Image src, {
  required int width,
  required int height,
  required Interpolation interpolation,
}) =>
    null;

Image? tryNativeCopyCrop(
  Image src, {
  required int x,
  required int y,
  required int width,
  required int height,
}) =>
    null;
