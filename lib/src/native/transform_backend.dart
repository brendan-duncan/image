import 'dart:typed_data';

import '../color/channel_order.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import 'transform_backend_stub.dart'
    if (dart.library.ffi) 'transform_backend_ffi.dart' as backend;

enum ImageBackendMode { auto, nativeOnly, dartOnly }

ImageBackendMode _imageBackendMode = ImageBackendMode.auto;

ImageBackendMode get imageBackendMode => _imageBackendMode;

set imageBackendMode(ImageBackendMode mode) {
  _imageBackendMode = mode;
}

bool get nativeImageBackendAvailable => backend.nativeImageBackendAvailable;

Image? tryNativeCopyResize(
  Image src, {
  required int width,
  required int height,
  required Interpolation interpolation,
}) {
  if (_imageBackendMode == ImageBackendMode.dartOnly) {
    return null;
  }
  final image = backend.tryNativeCopyResize(
    src,
    width: width,
    height: height,
    interpolation: interpolation,
  );
  if (image == null && _imageBackendMode == ImageBackendMode.nativeOnly) {
    throw UnsupportedError('Native backend could not execute copyResize.');
  }
  return image;
}

Image? tryNativeCopyCrop(
  Image src, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  if (_imageBackendMode == ImageBackendMode.dartOnly) {
    return null;
  }
  final image = backend.tryNativeCopyCrop(
    src,
    x: x,
    y: y,
    width: width,
    height: height,
  );
  if (image == null && _imageBackendMode == ImageBackendMode.nativeOnly) {
    throw UnsupportedError('Native backend could not execute copyCrop.');
  }
  return image;
}

Image createNativeImageFromRgba({
  required Image template,
  required Uint8List bytes,
  required int width,
  required int height,
}) {
  return Image.fromBytes(
    width: width,
    height: height,
    bytes: bytes.buffer,
    bytesOffset: bytes.offsetInBytes,
    numChannels: 4,
    order: ChannelOrder.rgba,
    exif: template.hasExif ? template.exif.clone() : null,
    iccp: template.iccProfile?.clone(),
    textData: template.textData != null
        ? Map<String, String>.from(template.textData!)
        : null,
    loopCount: template.loopCount,
    frameType: template.frameType,
    backgroundColor: template.backgroundColor?.clone(),
    frameDuration: template.frameDuration,
    frameIndex: template.frameIndex,
  );
}
