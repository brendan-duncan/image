// Generated bindings for `native/include/image_ffi.h`.
// Regenerate with: `dart run ffigen --config ffigen.yaml`

import 'dart:ffi';

import 'package:ffi/ffi.dart';

const _assetId = 'package:image/src/native/bindings.dart';

final class ImageBuffer extends Struct {
  external Pointer<Uint8> data;

  external Pointer<Void> releaseHandle;

  @Int32()
  external int width;

  @Int32()
  external int height;

  @Int32()
  external int channels;

  @Int32()
  external int stride;
}

final class ImageResult extends Struct {
  @Int32()
  external int code;

  external ImageBuffer buffer;
}

@Native<
  ImageResult Function(
    Pointer<Uint8>,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
  )
>(assetId: _assetId, symbol: 'image_resize_rgba8')
external ImageResult imageResizeRgba8(
  Pointer<Uint8> data,
  int width,
  int height,
  int channels,
  int targetWidth,
  int targetHeight,
  int interpolation,
);

@Native<
  ImageResult Function(
    Pointer<Uint8>,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
  )
>(assetId: _assetId, symbol: 'image_crop_rgba8')
external ImageResult imageCropRgba8(
  Pointer<Uint8> data,
  int width,
  int height,
  int channels,
  int x,
  int y,
  int cropWidth,
  int cropHeight,
);

@Native<Void Function(Pointer<Void>)>(
  assetId: _assetId,
  symbol: 'image_free_buffer',
)
external void imageFreeBuffer(Pointer<Void> releaseHandle);

Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    get imageFreeBufferPointer => Native.addressOf(imageFreeBuffer);

@Native<Pointer<Utf8> Function()>(
  assetId: _assetId,
  symbol: 'image_last_error_message',
)
external Pointer<Utf8> imageLastErrorMessage();
