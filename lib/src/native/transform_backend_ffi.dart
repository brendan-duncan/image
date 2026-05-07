import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../color/format.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import 'bindings.dart';
import 'transform_backend.dart' show createNativeImageFromRgba;

const _imageOk = 0;

bool? _nativeBackendAvailable;
final Expando<Uint8List> _retainedNativeImageBytes = Expando<Uint8List>(
  'nativeImageBytes',
);

bool get nativeImageBackendAvailable {
  if (!_supportsNativePlatform) {
    return false;
  }
  try {
    return _nativeBackendAvailable ??= _probeNativeBackend();
  } catch (_) {
    return false;
  }
}

Image? tryNativeCopyResize(
  Image src, {
  required int width,
  required int height,
  required Interpolation interpolation,
}) {
  if (!nativeImageBackendAvailable ||
      width <= 0 ||
      height <= 0 ||
      src.hasPalette ||
      src.hasAnimation ||
      (src.hasExif && src.exif.imageIfd.hasOrientation) ||
      interpolation == Interpolation.average ||
      interpolation == Interpolation.cubic) {
    return null;
  }

  final prepared = _prepareImage(src);
  if (prepared == null) {
    return null;
  }

  final input = malloc<Uint8>(prepared.length);
  final sourceBytes = prepared.toUint8List();
  input.asTypedList(sourceBytes.length).setAll(0, sourceBytes);
  try {
    final result = imageResizeRgba8(
      input,
      prepared.width,
      prepared.height,
      prepared.numChannels,
      width,
      height,
      interpolation.index,
    );
    return _materializeImageResult(result, original: src);
  } finally {
    malloc.free(input);
  }
}

Image? tryNativeCopyCrop(
  Image src, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  if (!nativeImageBackendAvailable ||
      width <= 0 ||
      height <= 0 ||
      src.hasPalette ||
      src.hasAnimation) {
    return null;
  }

  final prepared = _prepareImage(src);
  if (prepared == null) {
    return null;
  }

  final clampedX = x.clamp(0, prepared.width - 1).toInt();
  final clampedY = y.clamp(0, prepared.height - 1).toInt();
  var clampedWidth = width;
  var clampedHeight = height;
  if (clampedX + clampedWidth > prepared.width) {
    clampedWidth = prepared.width - clampedX;
  }
  if (clampedY + clampedHeight > prepared.height) {
    clampedHeight = prepared.height - clampedY;
  }
  if (clampedWidth <= 0 || clampedHeight <= 0) {
    return null;
  }

  final input = malloc<Uint8>(prepared.length);
  final sourceBytes = prepared.toUint8List();
  input.asTypedList(sourceBytes.length).setAll(0, sourceBytes);
  try {
    final result = imageCropRgba8(
      input,
      prepared.width,
      prepared.height,
      prepared.numChannels,
      clampedX,
      clampedY,
      clampedWidth,
      clampedHeight,
    );
    return _materializeImageResult(result, original: src);
  } finally {
    malloc.free(input);
  }
}

_PreparedImage? _prepareImage(Image src) {
  if (src.numFrames != 1) {
    return null;
  }
  var prepared = src;
  if (prepared.format != Format.uint8 || prepared.numChannels != 4) {
    prepared = prepared.convert(format: Format.uint8, numChannels: 4);
  }
  if (prepared.hasPalette || prepared.numChannels != 4) {
    return null;
  }
  return _PreparedImage(prepared);
}

Image? _materializeImageResult(ImageResult result, {required Image original}) {
  if (result.code != _imageOk ||
      result.buffer.data == nullptr ||
      result.buffer.releaseHandle == nullptr) {
    return null;
  }

  final length = result.buffer.stride * result.buffer.height;
  if (length <= 0) {
    imageFreeBuffer(result.buffer.releaseHandle);
    return null;
  }

  if (original.format == Format.uint8 && original.numChannels == 4) {
    final bytes = result.buffer.data.asTypedList(
      length,
      finalizer: imageFreeBufferPointer,
      token: result.buffer.releaseHandle,
    );
    final image = createNativeImageFromRgba(
      template: original,
      bytes: bytes,
      width: result.buffer.width,
      height: result.buffer.height,
    );
    _retainedNativeImageBytes[image] = bytes;
    return image;
  }

  try {
    final bytes = result.buffer.data.asTypedList(length);
    final image = createNativeImageFromRgba(
      template: original,
      bytes: bytes,
      width: result.buffer.width,
      height: result.buffer.height,
    );
    return image.convert(
      format: original.format,
      numChannels: original.numChannels,
      noAnimation: true,
    );
  } finally {
    imageFreeBuffer(result.buffer.releaseHandle);
  }
}

bool get _supportsNativePlatform => Platform.isAndroid || Platform.isIOS;

bool _probeNativeBackend() {
  imageLastErrorMessage();
  return true;
}

final class _PreparedImage {
  _PreparedImage(this.image);

  final Image image;

  int get width => image.width;
  int get height => image.height;
  int get numChannels => image.numChannels;
  int get length => image.lengthInBytes;

  Uint8List toUint8List() => image.toUint8List();
}
