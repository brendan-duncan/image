/// Interpolation method to use when resizing images.
enum Interpolation {
  /// Select the closest pixel. Fastest, lowest quality.
  nearest,

  /// Linearly blend between the neighboring pixels.
  linear,

  /// Cubic blend between the neighboring pixels. Slow, high Quality.
  cubic,

  /// Average the colors of the neighboring pixels.
  average,

  /// Computationally heavy and extremely slow algorithm with good results.
  /// Slowest, provides highest quality for downscaling.
  lanczos,
  ;
}
