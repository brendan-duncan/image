import 'dart:math';

import '../image/image.dart';
import '../util/neural_quantizer.dart';
import '../util/quantizer.dart';

/// The pattern to use for dithering
enum DitherKernel {
  none,
  floydSteinberg,
  falseFloydSteinberg,
  jarvisJudiceNinke,
  stucki,
  burkes,
  atkinson,
  bayer2x2,
  bayer4x4,
  bayer8x8,
}

/// The order in which pixels are visited by the error-diffusion kernels.
enum DitherScanOrder {
  /// Standard raster scan: every row is traversed left to right, top to
  /// bottom.
  raster,

  /// Boustrophedon (snake) scan: the horizontal direction is reversed on
  /// every other row, which reduces directional artifacts.
  serpentine,

  /// Diagonal zigzag scan (the JPEG-style ordering): pixels are visited along
  /// anti-diagonals (`x + y == d`), alternating the direction of each
  /// diagonal. It spreads the error along both axes, which softens the
  /// horizontal worm patterns typical of raster scanning.
  zigzag,

  /// Hilbert space-filling curve scan: pixels are visited following the
  /// fractal Hilbert curve order, which maximizes spatial locality. Every
  /// pair of consecutive pixels is adjacent on the grid. This gives the best
  /// reduction of directional artifacts among deterministic scan orders and
  /// closely approximates random-walk error diffusion without sacrificing
  /// determinism.
  hilbert,
}

/// Error-diffusion dither kernels keyed by [DitherKernel].
///
/// Each kernel is a list of taps, where every tap is `[weight, offsetX,
/// offsetY]`: the weight (fraction of the quantization error) is propagated
/// to the neighbor at `(x + offsetX, y + offsetY)`.
///
/// The Bayer are not error-diffusion kernels and
/// live in [_bayerMatrices] instead.
const Map<DitherKernel, List<List<num>>> _errorDiffusionKernels = {
  // Placeholder for [DitherKernel.none]; it is never actually used because
  // [ditherImage] short-circuits before reaching the diffusion loop.
  DitherKernel.none: [
    [0, 0, 0],
    [0, 0, 0],
    [0, 0, 0],
  ],
  // Floyd-Steinberg
  DitherKernel.floydSteinberg: [
    [7 / 16, 1, 0],
    [3 / 16, -1, 1],
    [5 / 16, 0, 1],
    [1 / 16, 1, 1],
  ],
  // False Floyd-Steinberg (Heckbert)
  DitherKernel.falseFloydSteinberg: [
    [3 / 8, 1, 0],
    [3 / 8, 0, 1],
    [2 / 8, 1, 1],
  ],
  // Jarvis-Judice-Ninke
  DitherKernel.jarvisJudiceNinke: [
    [7 / 48, 1, 0],
    [5 / 48, 2, 0],
    [3 / 48, -2, 1],
    [5 / 48, -1, 1],
    [7 / 48, 0, 1],
    [5 / 48, 1, 1],
    [3 / 48, 2, 1],
    [1 / 48, -2, 2],
    [3 / 48, -1, 2],
    [5 / 48, 0, 2],
    [3 / 48, 1, 2],
    [1 / 48, 2, 2],
  ],
  // Stucki
  DitherKernel.stucki: [
    [8 / 42, 1, 0],
    [4 / 42, 2, 0],
    [2 / 42, -2, 1],
    [4 / 42, -1, 1],
    [8 / 42, 0, 1],
    [4 / 42, 1, 1],
    [2 / 42, 2, 1],
    [1 / 42, -2, 2],
    [2 / 42, -1, 2],
    [4 / 42, 0, 2],
    [2 / 42, 1, 2],
    [1 / 42, 2, 2],
  ],
  // Burkes
  DitherKernel.burkes: [
    [8 / 32, 1, 0],
    [4 / 32, 2, 0],
    [2 / 32, -2, 1],
    [4 / 32, -1, 1],
    [8 / 32, 0, 1],
    [4 / 32, 1, 1],
    [2 / 32, 2, 1],
  ],
  // Atkinson
  DitherKernel.atkinson: [
    [1 / 8, 1, 0],
    [1 / 8, 2, 0],
    [1 / 8, -1, 1],
    [1 / 8, 0, 1],
    [1 / 8, 1, 1],
    [1 / 8, 0, 2],
  ],
};

/// Ordered (Bayer) dither matrices with values normalized to [0, 1).
const _bayerMatrices = <DitherKernel, List<List<double>>>{
  DitherKernel.bayer2x2: [
    [0 / 4, 2 / 4],
    [3 / 4, 1 / 4]
  ],
  DitherKernel.bayer4x4: [
    [0 / 16, 8 / 16, 2 / 16, 10 / 16],
    [12 / 16, 4 / 16, 14 / 16, 6 / 16],
    [3 / 16, 11 / 16, 1 / 16, 9 / 16],
    [15 / 16, 7 / 16, 13 / 16, 5 / 16]
  ],
  DitherKernel.bayer8x8: [
    [0 / 64, 32 / 64, 8 / 64, 40 / 64, 2 / 64, 34 / 64, 10 / 64, 42 / 64],
    [48 / 64, 16 / 64, 56 / 64, 24 / 64, 50 / 64, 18 / 64, 58 / 64, 26 / 64],
    [12 / 64, 44 / 64, 4 / 64, 36 / 64, 14 / 64, 46 / 64, 6 / 64, 38 / 64],
    [60 / 64, 28 / 64, 52 / 64, 20 / 64, 62 / 64, 30 / 64, 54 / 64, 22 / 64],
    [3 / 64, 35 / 64, 11 / 64, 43 / 64, 1 / 64, 33 / 64, 9 / 64, 41 / 64],
    [51 / 64, 19 / 64, 59 / 64, 27 / 64, 49 / 64, 17 / 64, 57 / 64, 25 / 64],
    [15 / 64, 47 / 64, 7 / 64, 39 / 64, 13 / 64, 45 / 64, 5 / 64, 37 / 64],
    [63 / 64, 31 / 64, 55 / 64, 23 / 64, 61 / 64, 29 / 64, 53 / 64, 21 / 64]
  ]
};

/// Dither an image to reduce banding patterns when reducing the number of
/// colors.
/// Derived from http://jsbin.com/iXofIji/2/edit
///
/// [quantizer] is the color reducer used to map each pixel to the palette;
/// if `null` a [NeuralQuantizer] is built from [image].
///
/// [kernel] selects the dithering algorithm: error-diffusion kernels
/// (e.g. [DitherKernel.floydSteinberg]) propagate quantization error to
/// neighbors, while the ordered Bayer kernels ([DitherKernel.bayer2x2],
/// [DitherKernel.bayer4x4], [DitherKernel.bayer8x8]) use a fixed
/// position-based threshold matrix.
///
/// [scanOrder] selects the order in which pixels are visited by the
/// error-diffusion kernels ([DitherScanOrder.raster],
/// [DitherScanOrder.serpentine], the diagonal [DitherScanOrder.zigzag], or
/// the space-filling [DitherScanOrder.hilbert] curve).
/// It has no effect on the Bayer kernels.
///
/// [intensity] scales the dither offset and is only used for the Bayer
/// kernels; it is ignored by the error-diffusion kernels.
Image ditherImage(
  Image image, {
  Quantizer? quantizer,
  DitherKernel kernel = DitherKernel.floydSteinberg,
  // Use scanOrder: DitherScanOrder.serpentine instead.
  bool serpentine = false,
  DitherScanOrder scanOrder = DitherScanOrder.zigzag,
  double intensity = 1.0,
}) {
  quantizer ??= NeuralQuantizer(image);

  if (kernel == DitherKernel.none) {
    return quantizer.getIndexImage(image);
  }

  if (_bayerMatrices.containsKey(kernel)) {
    return ditherImageBayer(image, quantizer, kernel, intensity);
  }

  final order = serpentine ? DitherScanOrder.serpentine : scanOrder;

  final q = quantizer;
  final ds = _errorDiffusionKernels[kernel]!;
  final height = image.height;
  final width = image.width;

  final palette = quantizer.palette;
  final indexedImage = Image(
    width: width,
    height: height,
    numChannels: 1,
    palette: palette,
  );

  final imageCopy = image.clone();

  // Quantizes the pixel at [x],[y] and diffuses its error to the neighbors.
  // [direction] is the horizontal scan direction (1 or -1) and controls the
  // order in which the kernel taps are applied.
  void diffusePixel(int x, int y, int direction) {
    // Get original color
    final pc = imageCopy.getPixel(x, y);
    final r1 = pc[0].toInt();
    final g1 = pc[1].toInt();
    final b1 = pc[2].toInt();

    // Get converted color
    final idx = q.getColorIndexRgb(r1, g1, b1);
    indexedImage.setPixelIndex(x, y, idx);

    final r2 = palette.get(idx, 0);
    final g2 = palette.get(idx, 1);
    final b2 = palette.get(idx, 2);

    final er = r1 - r2;
    final eg = g1 - g2;
    final eb = b1 - b2;

    if (er == 0 && eg == 0 && eb == 0) {
      return;
    }

    final i0 = direction == 1 ? 0 : ds.length - 1;
    final i1 = direction == 1 ? ds.length : 0;
    for (var i = i0; i != i1; i += direction) {
      final x1 = ds[i][1].toInt();
      final y1 = ds[i][2].toInt();
      if ((x1 + x) >= 0 &&
          (x1 + x) < width &&
          (y1 + y) >= 0 &&
          (y1 + y) < height) {
        final d = ds[i][0];
        final nx = x + x1;
        final ny = y + y1;
        final p2 = imageCopy.getPixel(nx, ny);
        p2
          ..r = p2.r + er * d
          ..g = p2.g + eg * d
          ..b = p2.b + eb * d;
      }
    }
  }

  if (order == DitherScanOrder.zigzag) {
    // Walk the anti-diagonals x + y == d, alternating their direction.
    final numDiagonals = width + height - 1;
    for (var d = 0; d < numDiagonals; d++) {
      final xMin = d < height ? 0 : d - height + 1;
      final xMax = d < width ? d : width - 1;
      if (d.isEven) {
        for (var x = xMin; x <= xMax; x++) {
          diffusePixel(x, d - x, 1);
        }
      } else {
        for (var x = xMax; x >= xMin; x--) {
          diffusePixel(x, d - x, 1);
        }
      }
    }
    return indexedImage;
  }

  if (order == DitherScanOrder.hilbert) {
    // Walk pixels in Hilbert space-filling curve order.
    // The curve is defined on a power-of-2 square; pixels outside the image
    // bounds are simply skipped.
    final maxDim = max(width, height);
    var n = 1;
    while (n < maxDim) {
      n <<= 1;
    }
    final xy = [0, 0];
    final total = n * n;
    for (var d = 0; d < total; d++) {
      _hilbertDtoXY(n, d, xy);
      if (xy[0] < width && xy[1] < height) {
        diffusePixel(xy[0], xy[1], 1);
      }
    }
    return indexedImage;
  }

  final isSerpentine = order == DitherScanOrder.serpentine;
  var direction = isSerpentine ? -1 : 1;

  for (var y = 0; y < height; y++) {
    if (isSerpentine) {
      direction = direction * -1;
    }

    final x0 = direction == 1 ? 0 : width - 1;
    final x1 = direction == 1 ? width : 0;
    for (var x = x0; x != x1; x += direction) {
      diffusePixel(x, y, direction);
    }
  }

  return indexedImage;
}

/// Dither an image using an ordered (Bayer) threshold matrix. Unlike the
/// error-diffusion kernels, the dither pattern is position-based and does not
/// propagate error to neighboring pixels, making it deterministic and fast.
///
/// [kernel] must be one of the Bayer variants ([DitherKernel.bayer2x2],
/// [DitherKernel.bayer4x4] or [DitherKernel.bayer8x8]); passing any other
/// [DitherKernel] will trigger an assertion failure.
///
/// [quantizer] is the color reducer used to map each pixel to the palette;
/// if `null` (the default) a [NeuralQuantizer] is built from [image].
///
/// [intensity] scales the dither offset (defaults to 1.0 for the classic
/// full-range Bayer look; smaller values give subtler banding reduction).
Image ditherImageBayer(
  Image image, [
  Quantizer? quantizer,
  DitherKernel kernel = DitherKernel.bayer4x4,
  double intensity = 1.0,
]) {
  quantizer ??= NeuralQuantizer(image);

  assert(_bayerMatrices.containsKey(kernel),
      'kernel must be a Bayer variant: bayer2x2, bayer4x4 or bayer8x8');

  final matrix = _bayerMatrices[kernel]!;
  final n = matrix.length;

  final height = image.height;
  final width = image.width;

  final palette = quantizer.palette;
  final indexedImage = Image(
    width: width,
    height: height,
    numChannels: 1,
    palette: palette,
  );

  for (var y = 0; y < height; y++) {
    final row = matrix[y % n];
    for (var x = 0; x < width; x++) {
      final pc = image.getPixel(x, y);
      // Centered threshold in the range [-0.5, 0.5).
      final t = row[x % n] - 0.5;
      final d = t * 255 * intensity;
      final r = _clampChannel(pc[0] + d);
      final g = _clampChannel(pc[1] + d);
      final b = _clampChannel(pc[2] + d);
      final idx = quantizer.getColorIndexRgb(r, g, b);
      indexedImage.setPixelIndex(x, y, idx);
    }
  }

  return indexedImage;
}

int _clampChannel(num v) => v.clamp(0, 255).round();

/// Converts a Hilbert curve index [d] to (x, y) coordinates for an [n]×[n]
/// grid, where [n] MUST be a power of 2. The result is written into [out]
/// in-place ([out][0] = x, [out][1] = y) to avoid per-pixel allocations.
void _hilbertDtoXY(int n, int d, List<int> out) {
  out[0] = 0;
  out[1] = 0;
  int t = d;
  for (var s = 1; s < n; s <<= 1) {
    final rx = (t >> 1) & 1;
    final ry = (t ^ rx) & 1;
    if (ry == 0) {
      if (rx == 1) {
        out[0] = s - 1 - out[0];
        out[1] = s - 1 - out[1];
      }
      final temp = out[0];
      out[0] = out[1];
      out[1] = temp;
    }
    out[0] += s * rx;
    out[1] += s * ry;
    t >>= 2;
  }
}
