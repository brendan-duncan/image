part of webp;

/**
 * Main object storing the configuration for advanced decoding.
 */
class WebPDecoderConfig {
  /// Immutable bitstream features (optional)
  WebPBitstreamFeatures input;
  /// Decoding options
  WebPDecoderOptions options;

  WebPDecoderConfig() :
    input = new WebPBitstreamFeatures(),
    options = new WebPDecoderOptions();
}

/**
 * Features gathered from the bitstream
 */
class WebPBitstreamFeatures {
  /// Width in pixels, as read from the bitstream.
  int width = 0;
  /// Height in pixels, as read from the bitstream.
  int height = 0;
  /// True if the bitstream contains an alpha channel.
  int has_alpha = 0;
  /// True if the bitstream is an animation.
  int has_animation = 0;
  /// 0 = undefined (/mixed), 1 = lossy, 2 = lossless
  int format = 0;

  // Unused for now:
  /// if true, using incremental decoding is not recommended.
  int no_incremental_decoding = 0;
  int rotate = 0;
  int uv_sampling = 0;
}

/**
 * Decoding options.
 */
class WebPDecoderOptions {
  /// if true, skip the in-loop filtering
  int bypass_filtering = 0;
  /// if true, use faster pointwise upsampler
  int no_fancy_upsampling = 0;
  /// if true, cropping is applied _first_
  int use_cropping = 0;
  /// top-left position for cropping. Will be snapped to even values.
  int crop_left = 0;
  int crop_top = 0;
  /// dimension of the cropping area
  int crop_width = 0;
  int crop_height = 0;
  /// if true, scaling is applied _afterward_
  int use_scaling = 0;
  /// final resolution
  int scaled_width = 0;
  int scaled_height = 0;
  /// dithering strength (0=Off, 100=full)
  int dithering_strength = 0;

  // Unused for now:
  /// forced rotation (to be applied _last_)
  int force_rotation = 0;
  /// if true, discard enhancement layer
  int no_enhancement = 0;
}
