#ifndef IMAGE_FFI_H_
#define IMAGE_FFI_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ImageBuffer {
  uint8_t* data;
  void* release_handle;
  int32_t width;
  int32_t height;
  int32_t channels;
  int32_t stride;
} ImageBuffer;

typedef struct ImageResult {
  int32_t code;
  ImageBuffer buffer;
} ImageResult;

ImageResult image_resize_rgba8(const uint8_t* data,
                               int32_t width,
                               int32_t height,
                               int32_t channels,
                               int32_t target_width,
                               int32_t target_height,
                               int32_t interpolation);

ImageResult image_crop_rgba8(const uint8_t* data,
                             int32_t width,
                             int32_t height,
                             int32_t channels,
                             int32_t x,
                             int32_t y,
                             int32_t crop_width,
                             int32_t crop_height);

void image_free_buffer(void* release_handle);

const char* image_last_error_message(void);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // IMAGE_FFI_H_
