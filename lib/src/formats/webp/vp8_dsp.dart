/// The sample-level kernels of the lossy encoder: transforms, intra
/// predictions and distortion metrics.
///
/// Every function here works on the macroblock cache, a flat byte buffer whose
/// rows are [kBps] apart, and is addressed by an offset into it. Keeping one
/// layout for the source, the predictions and the reconstruction is what lets
/// the prediction of a 4x4 block be four fixed-distance reads.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8_sar.dart';
import 'vp8_tables.dart';

/// Whether [rows] rows of [width] samples starting at [off] fit in [list].
///
/// The kernels below are compiled without bounds checks, which is safe only
/// because every offset they are given is computed from the fixed geometry of
/// the macroblock cache rather than from anything in the image. These
/// assertions state that invariant so that a mistake in the geometry fails
/// loudly in tests instead of silently reading past the buffer in a release
/// build, where the checks are gone.
bool _inRange(List<int> list, int off, int rows, [int width = 4]) =>
    off >= 0 && off + (rows - 1) * kBps + width <= list.length;

/// Clips a value to a byte.
@pragma('vm:prefer-inline')
int _clip8(int v) => v < 0
    ? 0
    : v > 255
        ? 255
        : v;

@pragma('vm:prefer-inline')
int _avg3(int a, int b, int c) => (a + 2 * b + c + 2) >> 2;

@pragma('vm:prefer-inline')
int _avg2(int a, int b) => (a + b + 1) >> 1;

// The two multiplies of the inverse transform, as RFC 6386 14.3 spells them.
// The first constant is 20091/65536 ~= sqrt(2) - 1, so the factor it stands
// for is 1 + that, hence the added term; the second is
// 35468/65536 ~= sqrt(2) * cos(pi/8) - 1 and is used as it is.
@pragma('vm:prefer-inline')
int _mul1(int a) => sar(a * 20091, 16) + a;

@pragma('vm:prefer-inline')
int _mul2(int a) => sar(a * 35468, 16);

/// The forward 4x4 DCT of `src - ref`, written to [out] at [outOff].
///
/// Both passes are unrolled: the sixteen intermediates stay in locals, which
/// is worth doing because this is the single most-executed routine of the
/// encoder.
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void fTransform(Uint8List src, int srcOff, Uint8List ref, int refOff,
    Int16List out, int outOff) {
  assert(_inRange(src, srcOff, 4) && _inRange(ref, refOff, 4));
  assert(outOff >= 0 && outOff + 16 <= out.length);
  // Rows.
  var d0 = src[srcOff] - ref[refOff];
  var d1 = src[srcOff + 1] - ref[refOff + 1];
  var d2 = src[srcOff + 2] - ref[refOff + 2];
  var d3 = src[srcOff + 3] - ref[refOff + 3];
  var a0 = d0 + d3;
  var a1 = d1 + d2;
  var a2 = d1 - d2;
  var a3 = d0 - d3;
  final t0 = (a0 + a1) * 8;
  final t1 = sar(a2 * 2217 + a3 * 5352 + 1812, 9);
  final t2 = (a0 - a1) * 8;
  final t3 = sar(a3 * 2217 - a2 * 5352 + 937, 9);

  srcOff += kBps;
  refOff += kBps;
  d0 = src[srcOff] - ref[refOff];
  d1 = src[srcOff + 1] - ref[refOff + 1];
  d2 = src[srcOff + 2] - ref[refOff + 2];
  d3 = src[srcOff + 3] - ref[refOff + 3];
  a0 = d0 + d3;
  a1 = d1 + d2;
  a2 = d1 - d2;
  a3 = d0 - d3;
  final t4 = (a0 + a1) * 8;
  final t5 = sar(a2 * 2217 + a3 * 5352 + 1812, 9);
  final t6 = (a0 - a1) * 8;
  final t7 = sar(a3 * 2217 - a2 * 5352 + 937, 9);

  srcOff += kBps;
  refOff += kBps;
  d0 = src[srcOff] - ref[refOff];
  d1 = src[srcOff + 1] - ref[refOff + 1];
  d2 = src[srcOff + 2] - ref[refOff + 2];
  d3 = src[srcOff + 3] - ref[refOff + 3];
  a0 = d0 + d3;
  a1 = d1 + d2;
  a2 = d1 - d2;
  a3 = d0 - d3;
  final t8 = (a0 + a1) * 8;
  final t9 = sar(a2 * 2217 + a3 * 5352 + 1812, 9);
  final t10 = (a0 - a1) * 8;
  final t11 = sar(a3 * 2217 - a2 * 5352 + 937, 9);

  srcOff += kBps;
  refOff += kBps;
  d0 = src[srcOff] - ref[refOff];
  d1 = src[srcOff + 1] - ref[refOff + 1];
  d2 = src[srcOff + 2] - ref[refOff + 2];
  d3 = src[srcOff + 3] - ref[refOff + 3];
  a0 = d0 + d3;
  a1 = d1 + d2;
  a2 = d1 - d2;
  a3 = d0 - d3;
  final t12 = (a0 + a1) * 8;
  final t13 = sar(a2 * 2217 + a3 * 5352 + 1812, 9);
  final t14 = (a0 - a1) * 8;
  final t15 = sar(a3 * 2217 - a2 * 5352 + 937, 9);

  // Columns.
  _fTransformColumn(t0, t4, t8, t12, out, outOff);
  _fTransformColumn(t1, t5, t9, t13, out, outOff + 1);
  _fTransformColumn(t2, t6, t10, t14, out, outOff + 2);
  _fTransformColumn(t3, t7, t11, t15, out, outOff + 3);
}

@pragma('vm:prefer-inline')
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void _fTransformColumn(
    int r0, int r1, int r2, int r3, Int16List out, int outOff) {
  final a0 = r0 + r3;
  final a1 = r1 + r2;
  final a2 = r1 - r2;
  final a3 = r0 - r3;
  out[outOff] = sar(a0 + a1 + 7, 4);
  out[outOff + 4] = sar(a2 * 2217 + a3 * 5352 + 12000, 16) + (a3 != 0 ? 1 : 0);
  out[outOff + 8] = sar(a0 - a1 + 7, 4);
  out[outOff + 12] = sar(a3 * 2217 - a2 * 5352 + 51000, 16);
}

/// The forward DCT of the two 4x4 blocks starting at [srcOff].
@internal
void fTransform2(Uint8List src, int srcOff, Uint8List ref, int refOff,
    Int16List out, int outOff) {
  fTransform(src, srcOff, ref, refOff, out, outOff);
  fTransform(src, srcOff + 4, ref, refOff + 4, out, outOff + 16);
}

/// The Walsh-Hadamard transform of the sixteen luma DC values.
///
/// [inp] holds the sixteen 4x4 coefficient blocks back to back, so the DC of
/// block `n` is at `16 * n`.
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void fTransformWHT(Int16List inp, int inOff, Int16List out, int outOff) {
  final tmp = Int32List(16);
  for (var i = 0; i < 4; i++, inOff += 64) {
    final a0 = inp[inOff] + inp[inOff + 2 * 16];
    final a1 = inp[inOff + 16] + inp[inOff + 3 * 16];
    final a2 = inp[inOff + 16] - inp[inOff + 3 * 16];
    final a3 = inp[inOff] - inp[inOff + 2 * 16];
    tmp[0 + i * 4] = a0 + a1;
    tmp[1 + i * 4] = a3 + a2;
    tmp[2 + i * 4] = a3 - a2;
    tmp[3 + i * 4] = a0 - a1;
  }
  for (var i = 0; i < 4; i++) {
    final a0 = tmp[0 + i] + tmp[8 + i];
    final a1 = tmp[4 + i] + tmp[12 + i];
    final a2 = tmp[4 + i] - tmp[12 + i];
    final a3 = tmp[0 + i] - tmp[8 + i];
    out[outOff + i] = sar(a0 + a1, 1);
    out[outOff + 4 + i] = sar(a3 + a2, 1);
    out[outOff + 8 + i] = sar(a3 - a2, 1);
    out[outOff + 12 + i] = sar(a0 - a1, 1);
  }
}

/// The inverse Walsh-Hadamard transform, scattering the sixteen luma DC
/// values back into the DC slot of each 4x4 block.
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void transformWHT(Int16List inp, int inOff, Int16List out, int outOff) {
  final tmp = Int32List(16);
  for (var i = 0; i < 4; i++) {
    final a0 = inp[inOff + i] + inp[inOff + 12 + i];
    final a1 = inp[inOff + 4 + i] + inp[inOff + 8 + i];
    final a2 = inp[inOff + 4 + i] - inp[inOff + 8 + i];
    final a3 = inp[inOff + i] - inp[inOff + 12 + i];
    tmp[i] = a0 + a1;
    tmp[8 + i] = a0 - a1;
    tmp[4 + i] = a3 + a2;
    tmp[12 + i] = a3 - a2;
  }
  for (var i = 0; i < 4; i++) {
    final dc = tmp[i * 4] + 3; // with rounder
    final a0 = dc + tmp[3 + i * 4];
    final a1 = tmp[1 + i * 4] + tmp[2 + i * 4];
    final a2 = tmp[1 + i * 4] - tmp[2 + i * 4];
    final a3 = dc - tmp[3 + i * 4];
    out[outOff] = sar(a0 + a1, 3);
    out[outOff + 16] = sar(a3 + a2, 3);
    out[outOff + 32] = sar(a0 - a1, 3);
    out[outOff + 48] = sar(a3 - a2, 3);
    outOff += 64;
  }
}

/// Whether a macroblock's source is a single flat colour.
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
bool isFlatSource16(Uint8List src, int off) {
  final v = src[off];
  for (var j = 0; j < 16; j++) {
    for (var i = 0; i < 16; i++) {
      if (src[off + i] != v) {
        return false;
      }
    }
    off += kBps;
  }
  return true;
}

/// Whether [numBlocks] blocks of levels carry at most [thresh] non-zero AC
/// coefficients between them.
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
bool isFlat(Int16List levels, int off, int numBlocks, int thresh) {
  var score = 0;
  for (var b = 0; b < numBlocks; b++) {
    for (var i = 1; i < 16; i++) {
      if (levels[off + i] != 0) {
        score++;
        if (score > thresh) {
          return false;
        }
      }
    }
    off += 16;
  }
  return true;
}

/// Reconstructs one 4x4 block: adds the inverse transform of [inp] to the
/// prediction at [refOff] and stores it at [dstOff].
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void iTransform(Uint8List ref, int refOff, Int16List inp, int inOff,
    Uint8List dst, int dstOff) {
  assert(_inRange(ref, refOff, 4) && _inRange(dst, dstOff, 4));
  assert(inOff >= 0 && inOff + 16 <= inp.length);
  // Vertical pass, keeping the sixteen intermediates in locals.
  var a = inp[inOff] + inp[inOff + 8];
  var b = inp[inOff] - inp[inOff + 8];
  var c = _mul2(inp[inOff + 4]) - _mul1(inp[inOff + 12]);
  var d = _mul1(inp[inOff + 4]) + _mul2(inp[inOff + 12]);
  final c0 = a + d;
  final c1 = b + c;
  final c2 = b - c;
  final c3 = a - d;

  a = inp[inOff + 1] + inp[inOff + 9];
  b = inp[inOff + 1] - inp[inOff + 9];
  c = _mul2(inp[inOff + 5]) - _mul1(inp[inOff + 13]);
  d = _mul1(inp[inOff + 5]) + _mul2(inp[inOff + 13]);
  final c4 = a + d;
  final c5 = b + c;
  final c6 = b - c;
  final c7 = a - d;

  a = inp[inOff + 2] + inp[inOff + 10];
  b = inp[inOff + 2] - inp[inOff + 10];
  c = _mul2(inp[inOff + 6]) - _mul1(inp[inOff + 14]);
  d = _mul1(inp[inOff + 6]) + _mul2(inp[inOff + 14]);
  final c8 = a + d;
  final c9 = b + c;
  final c10 = b - c;
  final c11 = a - d;

  a = inp[inOff + 3] + inp[inOff + 11];
  b = inp[inOff + 3] - inp[inOff + 11];
  c = _mul2(inp[inOff + 7]) - _mul1(inp[inOff + 15]);
  d = _mul1(inp[inOff + 7]) + _mul2(inp[inOff + 15]);
  final c12 = a + d;
  final c13 = b + c;
  final c14 = b - c;
  final c15 = a - d;

  _iTransformRow(c0, c4, c8, c12, ref, refOff, dst, dstOff);
  _iTransformRow(c1, c5, c9, c13, ref, refOff + kBps, dst, dstOff + kBps);
  _iTransformRow(
      c2, c6, c10, c14, ref, refOff + 2 * kBps, dst, dstOff + 2 * kBps);
  _iTransformRow(
      c3, c7, c11, c15, ref, refOff + 3 * kBps, dst, dstOff + 3 * kBps);
}

@pragma('vm:prefer-inline')
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void _iTransformRow(int t0, int t1, int t2, int t3, Uint8List ref, int refOff,
    Uint8List dst, int dstOff) {
  final dc = t0 + 4;
  final a = dc + t2;
  final b = dc - t2;
  final c = _mul2(t1) - _mul1(t3);
  final d = _mul1(t1) + _mul2(t3);
  dst[dstOff] = _clip8(ref[refOff] + sar(a + d, 3));
  dst[dstOff + 1] = _clip8(ref[refOff + 1] + sar(b + c, 3));
  dst[dstOff + 2] = _clip8(ref[refOff + 2] + sar(b - c, 3));
  dst[dstOff + 3] = _clip8(ref[refOff + 3] + sar(a - d, 3));
}

/// Reconstructs the two 4x4 blocks starting at [dstOff].
@internal
void iTransform2(Uint8List ref, int refOff, Int16List inp, int inOff,
    Uint8List dst, int dstOff) {
  iTransform(ref, refOff, inp, inOff, dst, dstOff);
  iTransform(ref, refOff + 4, inp, inOff + 16, dst, dstOff + 4);
}

//------------------------------------------------------------------------------
// Intra predictions.
//
// A prediction is built for every mode at once, into the scratch area, so the
// mode search is a series of comparisons against blocks that are already there.

/// Clips `[-255, 510]` to a byte; indexed by `value + 255`.
final _clipTable = () {
  final table = Uint8List(255 + 510 + 1);
  for (var i = -255; i <= 255 + 255; i++) {
    table[255 + i] = _clip8(i);
  }
  return table;
}();

@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void _fill(Uint8List dst, int dstOff, int value, int size) {
  if (size == 4) {
    // The 4x4 case runs ten times per block and a range fill costs more in
    // call overhead than the sixteen stores it saves.
    for (var j = 0; j < 4; j++) {
      final o = dstOff + j * kBps;
      dst[o] = value;
      dst[o + 1] = value;
      dst[o + 2] = value;
      dst[o + 3] = value;
    }
    return;
  }
  for (var j = 0; j < size; j++) {
    dst.fillRange(dstOff + j * kBps, dstOff + j * kBps + size, value);
  }
}

@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void _verticalPred(
    Uint8List dst, int dstOff, Uint8List? top, int topOff, int size) {
  if (top == null) {
    _fill(dst, dstOff, 127, size);
    return;
  }
  for (var j = 0; j < size; j++) {
    dst.setRange(dstOff + j * kBps, dstOff + j * kBps + size, top, topOff);
  }
}

@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void _horizontalPred(
    Uint8List dst, int dstOff, Uint8List? left, int leftOff, int size) {
  if (left == null) {
    _fill(dst, dstOff, 129, size);
    return;
  }
  for (var j = 0; j < size; j++) {
    dst.fillRange(
        dstOff + j * kBps, dstOff + j * kBps + size, left[leftOff + j]);
  }
}

@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void _trueMotion(Uint8List dst, int dstOff, Uint8List? left, int leftOff,
    Uint8List? top, int topOff, int size) {
  if (left == null) {
    // Without left samples true motion degenerates to copying the top row,
    // and with no top row either to the flat 129 the left would have supplied.
    if (top != null) {
      _verticalPred(dst, dstOff, top, topOff, size);
    } else {
      _fill(dst, dstOff, 129, size);
    }
    return;
  }
  if (top == null) {
    _horizontalPred(dst, dstOff, left, leftOff, size);
    return;
  }
  final clip = _clipTable;
  final base = 255 - left[leftOff - 1];
  for (var y = 0; y < size; y++) {
    final row = base + left[leftOff + y];
    for (var x = 0; x < size; x++) {
      dst[dstOff + x] = clip[row + top[topOff + x]];
    }
    dstOff += kBps;
  }
}

@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void _dcMode(Uint8List dst, int dstOff, Uint8List? left, int leftOff,
    Uint8List? top, int topOff, int size, int round, int shift) {
  var dc = 0;
  if (top != null) {
    for (var j = 0; j < size; j++) {
      dc += top[topOff + j];
    }
    if (left != null) {
      for (var j = 0; j < size; j++) {
        dc += left[leftOff + j];
      }
    } else {
      dc += dc;
    }
    dc = (dc + round) >> shift;
  } else if (left != null) {
    for (var j = 0; j < size; j++) {
      dc += left[leftOff + j];
    }
    dc += dc;
    dc = (dc + round) >> shift;
  } else {
    dc = 0x80;
  }
  _fill(dst, dstOff, dc, size);
}

/// Builds the four 16x16 luma predictions into the prediction cache [dst].
///
/// [left] and [top] are null at the picture border, where the standard
/// prescribes fixed replacement values rather than the missing neighbours.
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void predLuma16(
    Uint8List dst, Uint8List? left, int leftOff, Uint8List? top, int topOff) {
  _dcMode(dst, i16DC16, left, leftOff, top, topOff, 16, 16, 5);
  _verticalPred(dst, i16VE16, top, topOff, 16);
  _horizontalPred(dst, i16HE16, left, leftOff, 16);
  _trueMotion(dst, i16TM16, left, leftOff, top, topOff, 16);
}

/// Builds the four 8x8 chroma predictions, U and V side by side, into [dst].
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void predChroma8(
    Uint8List dst, Uint8List? left, int leftOff, Uint8List? top, int topOff) {
  _dcMode(dst, c8DC8, left, leftOff, top, topOff, 8, 8, 4);
  _verticalPred(dst, c8VE8, top, topOff, 8);
  _horizontalPred(dst, c8HE8, left, leftOff, 8);
  _trueMotion(dst, c8TM8, left, leftOff, top, topOff, 8);
  // V sits eight columns to the right of U, and takes the second half of the
  // top row and of the left column.
  _dcMode(dst, c8DC8 + 8, left, leftOff + 16, top, topOff + 8, 8, 8, 4);
  _verticalPred(dst, c8VE8 + 8, top, topOff + 8, 8);
  _horizontalPred(dst, c8HE8 + 8, left, leftOff + 16, 8);
  _trueMotion(dst, c8TM8 + 8, left, leftOff + 16, top, topOff + 8, 8);
}

/// Builds all ten 4x4 luma predictions into [dst].
///
/// [top] points at the four samples above the block; the four left samples are
/// at `top[-5 .. -2]`, the top-left corner at `top[-1]`, and the four
/// above-right samples at `top[4 .. 7]`.
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void predLuma4(Uint8List dst, Uint8List top, int topOff) {
  final x = top[topOff - 1];
  final i = top[topOff - 2];
  final j = top[topOff - 3];
  final k = top[topOff - 4];
  final l = top[topOff - 5];
  final a = top[topOff];
  final b = top[topOff + 1];
  final c = top[topOff + 2];
  final d = top[topOff + 3];
  final e = top[topOff + 4];
  final f = top[topOff + 5];
  final g = top[topOff + 6];
  final h = top[topOff + 7];

  // DC
  _fill(dst, i4DC4, (4 + a + b + c + d + l + k + j + i) >> 3, 4);

  // TM
  final clip = _clipTable;
  final base = 255 - x;
  for (var y = 0; y < 4; y++) {
    final row = base + top[topOff - 2 - y];
    final at = i4TM4 + y * kBps;
    dst[at] = clip[row + a];
    dst[at + 1] = clip[row + b];
    dst[at + 2] = clip[row + c];
    dst[at + 3] = clip[row + d];
  }

  // VE
  _row4(dst, i4VE4, _avg3(x, a, b), _avg3(a, b, c), _avg3(b, c, d),
      _avg3(c, d, e), 4);

  // HE
  _fillRow4(dst, i4HE4, _avg3(x, i, j), _avg3(i, j, k), _avg3(j, k, l),
      _avg3(k, l, l));

  // RD
  _set4(dst, i4RD4, 0, 3, _avg3(j, k, l));
  _set4(dst, i4RD4, 0, 2, _avg3(i, j, k));
  _set4(dst, i4RD4, 1, 3, _avg3(i, j, k));
  final rd2 = _avg3(x, i, j);
  _set4(dst, i4RD4, 0, 1, rd2);
  _set4(dst, i4RD4, 1, 2, rd2);
  _set4(dst, i4RD4, 2, 3, rd2);
  final rd3 = _avg3(a, x, i);
  _set4(dst, i4RD4, 0, 0, rd3);
  _set4(dst, i4RD4, 1, 1, rd3);
  _set4(dst, i4RD4, 2, 2, rd3);
  _set4(dst, i4RD4, 3, 3, rd3);
  final rd4 = _avg3(b, a, x);
  _set4(dst, i4RD4, 1, 0, rd4);
  _set4(dst, i4RD4, 2, 1, rd4);
  _set4(dst, i4RD4, 3, 2, rd4);
  final rd5 = _avg3(c, b, a);
  _set4(dst, i4RD4, 2, 0, rd5);
  _set4(dst, i4RD4, 3, 1, rd5);
  _set4(dst, i4RD4, 3, 0, _avg3(d, c, b));

  // VR
  final vr0 = _avg2(x, a);
  _set4(dst, i4VR4, 0, 0, vr0);
  _set4(dst, i4VR4, 1, 2, vr0);
  final vr1 = _avg2(a, b);
  _set4(dst, i4VR4, 1, 0, vr1);
  _set4(dst, i4VR4, 2, 2, vr1);
  final vr2 = _avg2(b, c);
  _set4(dst, i4VR4, 2, 0, vr2);
  _set4(dst, i4VR4, 3, 2, vr2);
  _set4(dst, i4VR4, 3, 0, _avg2(c, d));
  _set4(dst, i4VR4, 0, 3, _avg3(k, j, i));
  _set4(dst, i4VR4, 0, 2, _avg3(j, i, x));
  final vr3 = _avg3(i, x, a);
  _set4(dst, i4VR4, 0, 1, vr3);
  _set4(dst, i4VR4, 1, 3, vr3);
  final vr4 = _avg3(x, a, b);
  _set4(dst, i4VR4, 1, 1, vr4);
  _set4(dst, i4VR4, 2, 3, vr4);
  final vr5 = _avg3(a, b, c);
  _set4(dst, i4VR4, 2, 1, vr5);
  _set4(dst, i4VR4, 3, 3, vr5);
  _set4(dst, i4VR4, 3, 1, _avg3(b, c, d));

  // LD
  _set4(dst, i4LD4, 0, 0, _avg3(a, b, c));
  final ld1 = _avg3(b, c, d);
  _set4(dst, i4LD4, 1, 0, ld1);
  _set4(dst, i4LD4, 0, 1, ld1);
  final ld2 = _avg3(c, d, e);
  _set4(dst, i4LD4, 2, 0, ld2);
  _set4(dst, i4LD4, 1, 1, ld2);
  _set4(dst, i4LD4, 0, 2, ld2);
  final ld3 = _avg3(d, e, f);
  _set4(dst, i4LD4, 3, 0, ld3);
  _set4(dst, i4LD4, 2, 1, ld3);
  _set4(dst, i4LD4, 1, 2, ld3);
  _set4(dst, i4LD4, 0, 3, ld3);
  final ld4 = _avg3(e, f, g);
  _set4(dst, i4LD4, 3, 1, ld4);
  _set4(dst, i4LD4, 2, 2, ld4);
  _set4(dst, i4LD4, 1, 3, ld4);
  final ld5 = _avg3(f, g, h);
  _set4(dst, i4LD4, 3, 2, ld5);
  _set4(dst, i4LD4, 2, 3, ld5);
  _set4(dst, i4LD4, 3, 3, _avg3(g, h, h));

  // VL
  _set4(dst, i4VL4, 0, 0, _avg2(a, b));
  final vl1 = _avg2(b, c);
  _set4(dst, i4VL4, 1, 0, vl1);
  _set4(dst, i4VL4, 0, 2, vl1);
  final vl2 = _avg2(c, d);
  _set4(dst, i4VL4, 2, 0, vl2);
  _set4(dst, i4VL4, 1, 2, vl2);
  final vl3 = _avg2(d, e);
  _set4(dst, i4VL4, 3, 0, vl3);
  _set4(dst, i4VL4, 2, 2, vl3);
  _set4(dst, i4VL4, 0, 1, _avg3(a, b, c));
  final vl4 = _avg3(b, c, d);
  _set4(dst, i4VL4, 1, 1, vl4);
  _set4(dst, i4VL4, 0, 3, vl4);
  final vl5 = _avg3(c, d, e);
  _set4(dst, i4VL4, 2, 1, vl5);
  _set4(dst, i4VL4, 1, 3, vl5);
  final vl6 = _avg3(d, e, f);
  _set4(dst, i4VL4, 3, 1, vl6);
  _set4(dst, i4VL4, 2, 3, vl6);
  _set4(dst, i4VL4, 3, 2, _avg3(e, f, g));
  _set4(dst, i4VL4, 3, 3, _avg3(f, g, h));

  // HD
  final hd0 = _avg2(i, x);
  _set4(dst, i4HD4, 0, 0, hd0);
  _set4(dst, i4HD4, 2, 1, hd0);
  final hd1 = _avg2(j, i);
  _set4(dst, i4HD4, 0, 1, hd1);
  _set4(dst, i4HD4, 2, 2, hd1);
  final hd2 = _avg2(k, j);
  _set4(dst, i4HD4, 0, 2, hd2);
  _set4(dst, i4HD4, 2, 3, hd2);
  _set4(dst, i4HD4, 0, 3, _avg2(l, k));
  _set4(dst, i4HD4, 3, 0, _avg3(a, b, c));
  _set4(dst, i4HD4, 2, 0, _avg3(x, a, b));
  final hd3 = _avg3(i, x, a);
  _set4(dst, i4HD4, 1, 0, hd3);
  _set4(dst, i4HD4, 3, 1, hd3);
  final hd4 = _avg3(j, i, x);
  _set4(dst, i4HD4, 1, 1, hd4);
  _set4(dst, i4HD4, 3, 2, hd4);
  final hd5 = _avg3(k, j, i);
  _set4(dst, i4HD4, 1, 2, hd5);
  _set4(dst, i4HD4, 3, 3, hd5);
  _set4(dst, i4HD4, 1, 3, _avg3(l, k, j));

  // HU
  _set4(dst, i4HU4, 0, 0, _avg2(i, j));
  final hu1 = _avg2(j, k);
  _set4(dst, i4HU4, 2, 0, hu1);
  _set4(dst, i4HU4, 0, 1, hu1);
  final hu2 = _avg2(k, l);
  _set4(dst, i4HU4, 2, 1, hu2);
  _set4(dst, i4HU4, 0, 2, hu2);
  _set4(dst, i4HU4, 1, 0, _avg3(i, j, k));
  final hu3 = _avg3(j, k, l);
  _set4(dst, i4HU4, 3, 0, hu3);
  _set4(dst, i4HU4, 1, 1, hu3);
  final hu4 = _avg3(k, l, l);
  _set4(dst, i4HU4, 3, 1, hu4);
  _set4(dst, i4HU4, 1, 2, hu4);
  _set4(dst, i4HU4, 3, 2, l);
  _set4(dst, i4HU4, 2, 2, l);
  _set4(dst, i4HU4, 0, 3, l);
  _set4(dst, i4HU4, 1, 3, l);
  _set4(dst, i4HU4, 2, 3, l);
  _set4(dst, i4HU4, 3, 3, l);
}

@pragma('vm:prefer-inline')
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void _set4(Uint8List dst, int base, int x, int y, int value) {
  dst[base + x + y * kBps] = value;
}

/// Writes the same four values on every row of a 4x4 block.
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void _row4(Uint8List dst, int at, int v0, int v1, int v2, int v3, int rows) {
  for (var i = 0; i < rows; i++) {
    final o = at + i * kBps;
    dst[o] = v0;
    dst[o + 1] = v1;
    dst[o + 2] = v2;
    dst[o + 3] = v3;
  }
}

/// Fills each row of a 4x4 block with one value.
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void _fillRow4(Uint8List dst, int at, int v0, int v1, int v2, int v3) {
  _row4(dst, at, v0, v0, v0, v0, 1);
  _row4(dst, at + kBps, v1, v1, v1, v1, 1);
  _row4(dst, at + 2 * kBps, v2, v2, v2, v2, 1);
  _row4(dst, at + 3 * kBps, v3, v3, v3, v3, 1);
}

//------------------------------------------------------------------------------
// Metrics.

/// The sum of squared differences over a 4x4 block.
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
@pragma('vm:unsafe:no-interrupts')
int getSSE4x4(Uint8List a, int aOff, Uint8List b, int bOff) {
  assert(_inRange(a, aOff, 4) && _inRange(b, bOff, 4));
  var count = 0;
  for (var y = 0; y < 4; y++) {
    final d0 = a[aOff] - b[bOff];
    final d1 = a[aOff + 1] - b[bOff + 1];
    final d2 = a[aOff + 2] - b[bOff + 2];
    final d3 = a[aOff + 3] - b[bOff + 3];
    count += d0 * d0 + d1 * d1 + d2 * d2 + d3 * d3;
    aOff += kBps;
    bOff += kBps;
  }
  return count;
}

/// The sum of squared differences over a [w] by [h] block.
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
@pragma('vm:unsafe:no-interrupts')
int getSSE(Uint8List a, int aOff, Uint8List b, int bOff, int w, int h) {
  assert(_inRange(a, aOff, h, w) && _inRange(b, bOff, h, w));
  var count = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final diff = a[aOff + x] - b[bOff + x];
      count += diff * diff;
    }
    aOff += kBps;
    bOff += kBps;
  }
  return count;
}

/// A weighted sum of the absolute Hadamard coefficients of one 4x4 block.
///
/// Fully unrolled: the sixteen intermediates stay in locals rather than in a
/// scratch array, because this runs for every candidate mode of every block
/// and an allocation here costs more than the arithmetic.
///
/// The weights of the spectral distortion - `{38, 32, 20, 9, 32, 28, 17, 7,
/// 20, 17, 10, 4, 9, 7, 4, 2}` in libwebp - are written into the columns as
/// literals rather than read from a table. A top-level table would be a `final`
/// and so carry a lazy-initialisation check on every one of the sixteen reads,
/// which is more than the multiplications cost.
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
int _tTransform(Uint8List src, int off) {
  assert(_inRange(src, off, 4));
  // Horizontal pass.
  var a0 = src[off] + src[off + 2];
  var a1 = src[off + 1] + src[off + 3];
  var a2 = src[off + 1] - src[off + 3];
  var a3 = src[off] - src[off + 2];
  final t0 = a0 + a1;
  final t1 = a3 + a2;
  final t2 = a3 - a2;
  final t3 = a0 - a1;

  off += kBps;
  a0 = src[off] + src[off + 2];
  a1 = src[off + 1] + src[off + 3];
  a2 = src[off + 1] - src[off + 3];
  a3 = src[off] - src[off + 2];
  final t4 = a0 + a1;
  final t5 = a3 + a2;
  final t6 = a3 - a2;
  final t7 = a0 - a1;

  off += kBps;
  a0 = src[off] + src[off + 2];
  a1 = src[off + 1] + src[off + 3];
  a2 = src[off + 1] - src[off + 3];
  a3 = src[off] - src[off + 2];
  final t8 = a0 + a1;
  final t9 = a3 + a2;
  final t10 = a3 - a2;
  final t11 = a0 - a1;

  off += kBps;
  a0 = src[off] + src[off + 2];
  a1 = src[off + 1] + src[off + 3];
  a2 = src[off + 1] - src[off + 3];
  a3 = src[off] - src[off + 2];
  final t12 = a0 + a1;
  final t13 = a3 + a2;
  final t14 = a3 - a2;
  final t15 = a0 - a1;

  // Vertical pass, accumulating the weighted magnitudes as it goes.
  return _tTransformColumn(t0, t4, t8, t12, 38, 32, 20, 9) +
      _tTransformColumn(t1, t5, t9, t13, 32, 28, 17, 7) +
      _tTransformColumn(t2, t6, t10, t14, 20, 17, 10, 4) +
      _tTransformColumn(t3, t7, t11, t15, 9, 7, 4, 2);
}

@pragma('vm:prefer-inline')
int _tTransformColumn(
    int r0, int r1, int r2, int r3, int w0, int w1, int w2, int w3) {
  final a0 = r0 + r2;
  final a1 = r1 + r3;
  final a2 = r1 - r3;
  final a3 = r0 - r2;
  final b0 = a0 + a1;
  final b1 = a3 + a2;
  final b2 = a3 - a2;
  final b3 = a0 - a1;
  // Written out rather than calling abs(), which the compiler leaves as a
  // call: it showed up as its own entry in the profile.
  return w0 * (b0 < 0 ? -b0 : b0) +
      w1 * (b1 < 0 ? -b1 : b1) +
      w2 * (b2 < 0 ? -b2 : b2) +
      w3 * (b3 < 0 ? -b3 : b3);
}

/// The weighted spectrum of one 4x4 block, which [distoFrom] compares.
///
/// Exposed on its own because the source block of a mode search does not
/// change while the candidates do, so its spectrum is worth computing once
/// instead of once per candidate.
@internal
int spectrum4x4(Uint8List src, int off) => _tTransform(src, off);

/// How far a block is from a spectrum already measured by [spectrum4x4].
///
/// Squared error alone rates a blurred block the same as a block whose detail
/// merely moved; comparing weighted spectra instead is what keeps texture from
/// being quantised away.
@internal
int distoFrom(int reference, Uint8List b, int bOff) {
  final d = _tTransform(b, bOff) - reference;
  return (d < 0 ? -d : d) >> 5;
}

/// The sum of each of the four 4x4 blocks of a 16x4 strip, written to [dc]
/// starting at [dcOff].
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void mean16x4(Uint8List ref, int off, Uint32List dc, int dcOff) {
  for (var k = 0; k < 4; k++) {
    var avg = 0;
    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < 4; x++) {
        avg += ref[off + x + y * kBps];
      }
    }
    dc[dcOff + k] = avg;
    off += 4;
  }
}

//------------------------------------------------------------------------------
// Block copies.

@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void copy4x4(Uint8List src, int srcOff, Uint8List dst, int dstOff) {
  for (var y = 0; y < 4; y++) {
    dst[dstOff] = src[srcOff];
    dst[dstOff + 1] = src[srcOff + 1];
    dst[dstOff + 2] = src[srcOff + 2];
    dst[dstOff + 3] = src[srcOff + 3];
    srcOff += kBps;
    dstOff += kBps;
  }
}

@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void copy16x8(Uint8List src, int srcOff, Uint8List dst, int dstOff) {
  for (var y = 0; y < 8; y++) {
    dst.setRange(dstOff, dstOff + 16, src, srcOff);
    srcOff += kBps;
    dstOff += kBps;
  }
}
