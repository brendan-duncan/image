import 'dart:typed_data';

import '../color/channel.dart';
import '../color/format.dart';
import '../image/image.dart';
import '_reflect_index.dart';
import 'separable_kernel.dart';

/// Apply a generic separable convolution filter the [src] image, using the
/// given [kernel].
///
/// gaussianBlur is an example of such a filter.
Image separableConvolution(Image src,
    {required SeparableKernel kernel,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }
  for (final frame in src.frames) {
    if (mask == null && _convolveUint8(frame, kernel)) {
      continue;
    }
    final tmp = Image.from(frame, noAnimation: true);
    // Apply the filter horizontally
    kernel
      ..apply(frame, tmp, mask: mask, maskChannel: maskChannel)
      // Apply the filter vertically, applying back to the original image.
      ..apply(tmp, frame,
          horizontal: false, mask: mask, maskChannel: maskChannel);
  }

  return src;
}

// A fast path for uint8 images, giving the same result as
// SeparableKernel.apply: each channel is filtered horizontally and stored as
// uint8, then filtered vertically, summing the taps in the same order.
//
// The vertical pass writes each row in place, so instead of a whole image of
// horizontal results it keeps a ring of the 2 * size + 1 rows it needs. The
// rows it reads (including reflected ones) are always within that window, and
// the source rows still to be filtered horizontally are below the row being
// written.
//
// Returns false if the frame isn't uint8, or is a single row or column, which
// SeparableKernel.apply leaves unchanged.
bool _convolveUint8(Image frame, SeparableKernel kernel) {
  final size = kernel.size;
  final w = frame.width;
  final h = frame.height;
  if (frame.format != Format.uint8 || w < 2 || h < 2) {
    return false;
  }

  final data = frame.data!.toUint8List();
  final nc = frame.data!.numChannels;
  final stride = frame.data!.rowStride;
  final taps = 2 * size + 1;
  final k = Float64List(taps);
  for (var i = 0; i < taps; ++i) {
    k[i] = kernel[i].toDouble();
  }

  // The source pixel of each position of a row padded by size pixels on each
  // side, reflecting past the edges.
  final padSource = Int32List(w + 2 * size);
  for (var x = -size; x < w + size; ++x) {
    padSource[x + size] = reflectIndex(w, x) * nc;
  }
  final padded = Uint8List((w + 2 * size) * nc);

  final ring = Uint8List(taps * stride);
  final acc = Float64List(stride);
  final rowOffsets = Int32List(taps);
  var nextRow = 0;

  for (var y = 0; y < h; ++y) {
    // Filter the source rows the window needs horizontally.
    final last = y + size < h ? y + size : h - 1;
    for (; nextRow <= last; ++nextRow) {
      _padRow(data, nextRow * stride, padded, padSource, nc);
      _filterRow(padded, ring, (nextRow % taps) * stride, stride, nc, k, acc);
    }

    for (var j = 0; j < taps; ++j) {
      rowOffsets[j] = (reflectIndex(h, y + j - size) % taps) * stride;
    }
    _filterColumn(ring, rowOffsets, data, y * stride, stride, k, acc);
  }

  return true;
}

// Copies the row at srcOffset in src to padded, with its reflected edges.
void _padRow(Uint8List src, int srcOffset, Uint8List padded,
    Int32List padSource, int nc) {
  for (var x = 0, i = 0; x < padSource.length; ++x) {
    final s = srcOffset + padSource[x];
    for (var ch = 0; ch < nc; ++ch) {
      padded[i++] = src[s + ch];
    }
  }
}

// Filters a padded row horizontally, to the n bytes at dstOffset in dst.
void _filterRow(Uint8List padded, Uint8List dst, int dstOffset, int n, int nc,
    Float64List k, Float64List acc) {
  acc.fillRange(0, n, 0.0);
  for (var j = 0; j < k.length; ++j) {
    final c = k[j];
    final o = j * nc;
    for (var i = 0; i < n; ++i) {
      acc[i] += c * padded[o + i];
    }
  }
  for (var i = 0; i < n; ++i) {
    dst[dstOffset + i] = acc[i].toInt();
  }
}

// Filters one row vertically, from the ring rows at rowOffsets to dst at
// dstOffset.
void _filterColumn(Uint8List ring, Int32List rowOffsets, Uint8List dst,
    int dstOffset, int n, Float64List k, Float64List acc) {
  acc.fillRange(0, n, 0.0);
  for (var j = 0; j < k.length; ++j) {
    final c = k[j];
    final o = rowOffsets[j];
    for (var i = 0; i < n; ++i) {
      acc[i] += c * ring[o + i];
    }
  }
  for (var i = 0; i < n; ++i) {
    dst[dstOffset + i] = acc[i].toInt();
  }
}
