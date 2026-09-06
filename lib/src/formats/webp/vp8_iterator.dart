/// Walks the picture macroblock by macroblock, keeping the neighbouring
/// samples and contexts each one needs.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8_state.dart';
import 'vp8_tables.dart';

/// Where the top sample of each 4x4 block sits inside the boundary array.
///
/// The boundary of a 4x4 block is kept in one snaking array that is updated as
/// the sixteen blocks are reconstructed in turn, so that each block sees the
/// samples of the ones already coded.
const _topLeftI4 = [
  17, 21, 25, 29, //
  13, 17, 21, 25,
  9, 13, 17, 21,
  5, 9, 13, 17
];

/// The current macroblock, its neighbours, and the scratch buffers the search
/// works in.
@internal
class VP8EncIterator {
  VP8EncIterator(this.enc) {
    reset();
  }

  final VP8EncState enc;

  /// Position of the current macroblock.
  int x = 0;
  int y = 0;

  /// Source samples of the current macroblock.
  final yuvIn = Uint8List(yuvSizeEnc);

  /// Reconstructed samples. Swapped with [yuvOut2] as better modes are found.
  Uint8List yuvOut = Uint8List(yuvSizeEnc);
  Uint8List yuvOut2 = Uint8List(yuvSizeEnc);

  /// Every candidate prediction, built once per macroblock.
  final yuvP = Uint8List(predSizeEnc);

  /// Index of the current macroblock in the per-macroblock arrays.
  int mbPos = 0;

  /// Index of the current macroblock's first 4x4 mode in `enc.preds`.
  int predsPos = 0;

  /// Index of the current macroblock's entry in `enc.nz`.
  int nzPos = 1;

  /// Index of the current macroblock's top samples.
  int yTopPos = 0;
  int uvTopPos = 0;

  /// Whether the top samples come from a scratch buffer rather than from the
  /// running reconstruction. The analysis pass works on the source instead.
  late Uint8List yTop;
  late Uint8List uvTop;

  /// Left samples, addressable from index -1 through the offsets below.
  final yLeft = Uint8List(17);
  final uvLeft = Uint8List(32);

  static const yLeftOff = 1;
  static const uLeftOff = 1;
  static const vLeftOff = 17;

  /// Scratch used when the boundary must come from the source picture.
  final boundaryScratch = Uint8List(32);

  /// The 4x4 boundary samples, in the snaking order [_topLeftI4] indexes.
  final i4Boundary = Uint8List(40);

  /// Index in [i4Boundary] of the current 4x4 block's top samples.
  int i4Top = 0;

  /// Which 4x4 block the intra-4 search is on.
  int i4 = 0;

  /// Non-zero flags of the blocks above and to the left, one per 4x4 column
  /// and row, plus the luma DC block at index 8.
  final topNz = Int32List(9);
  final leftNz = Int32List(9);

  /// Whether the coefficient trellis is in use for this macroblock.
  bool doTrellis = false;

  int countDown = 0;

  void reset() {
    yTop = enc.yTop;
    uvTop = enc.uvTop;
    setRow(0);
    countDown = enc.mbW * enc.mbH;
    // The picture's top border acts as a row of mid-grey samples.
    enc.yTop.fillRange(0, enc.yTop.length, 127);
    enc.uvTop.fillRange(0, enc.uvTop.length, 127);
    enc.nz.fillRange(0, enc.nz.length, 0);
    enc.topDerr?.fillRange(0, enc.topDerr!.length, 0);
    doTrellis = false;
  }

  /// Chroma DC error carried in from the block to the left, two values per
  /// channel. Reset at the start of every macroblock row, since there is no
  /// left neighbour there.
  final leftDerr = Int8List(4);

  void setRow(int row) {
    x = 0;
    y = row;
    predsPos = enc.predsOrigin + row * 4 * enc.predsW;
    nzPos = 1;
    mbPos = row * enc.mbW;
    yTop = enc.yTop;
    uvTop = enc.uvTop;
    yTopPos = 0;
    uvTopPos = 0;
    _initLeft();
  }

  void setCountDown(int count) {
    countDown = count;
  }

  bool get isDone => countDown <= 0;

  @pragma('vm:unsafe:no-bounds-checks')
  void _initLeft() {
    // Left of the first column: the standard's fixed values, which differ
    // above and below the first row.
    yLeft[0] = uvLeft[uLeftOff - 1] = uvLeft[vLeftOff - 1] = y > 0 ? 129 : 127;
    yLeft.fillRange(yLeftOff, yLeftOff + 16, 129);
    uvLeft.fillRange(uLeftOff, uLeftOff + 8, 129);
    uvLeft.fillRange(vLeftOff, vLeftOff + 8, 129);
    leftNz[8] = 0;
    if (enc.topDerr != null) {
      leftDerr.fillRange(0, 4, 0);
    }
  }

  /// Copies the current macroblock out of the picture, replicating the edge
  /// where the macroblock hangs over the right or bottom border.
  ///
  /// When [sourceBoundary] is set the neighbouring samples are taken from the
  /// source rather than from the reconstruction, which is what the analysis
  /// pass wants: it measures the picture, not the coding so far.
  @pragma('vm:unsafe:no-bounds-checks')
  void import({bool sourceBoundary = false}) {
    final pic = enc.pic;
    final yStride = pic.width;
    final uvStride = pic.uvWidth;
    final ySrc = (y * yStride + x) * 16;
    final uvSrc = (y * uvStride + x) * 8;
    final w = _min(pic.width - x * 16, 16);
    final h = _min(pic.height - y * 16, 16);
    final uvW = (w + 1) >> 1;
    final uvH = (h + 1) >> 1;

    _importBlock(pic.y, ySrc, yStride, yuvIn, yOffEnc, w, h, 16);
    _importBlock(pic.u, uvSrc, uvStride, yuvIn, uOffEnc, uvW, uvH, 8);
    _importBlock(pic.v, uvSrc, uvStride, yuvIn, vOffEnc, uvW, uvH, 8);

    if (!sourceBoundary) {
      return;
    }

    if (x == 0) {
      _initLeft();
    } else {
      if (y == 0) {
        yLeft[0] = uvLeft[uLeftOff - 1] = uvLeft[vLeftOff - 1] = 127;
      } else {
        yLeft[0] = pic.y[ySrc - 1 - yStride];
        uvLeft[uLeftOff - 1] = pic.u[uvSrc - 1 - uvStride];
        uvLeft[vLeftOff - 1] = pic.v[uvSrc - 1 - uvStride];
      }
      _importLine(pic.y, ySrc - 1, yStride, yLeft, yLeftOff, h, 16);
      _importLine(pic.u, uvSrc - 1, uvStride, uvLeft, uLeftOff, uvH, 8);
      _importLine(pic.v, uvSrc - 1, uvStride, uvLeft, vLeftOff, uvH, 8);
    }

    yTop = boundaryScratch;
    uvTop = boundaryScratch;
    yTopPos = 0;
    uvTopPos = 16;
    if (y == 0) {
      boundaryScratch.fillRange(0, 32, 127);
    } else {
      _importLine(pic.y, ySrc - yStride, 1, boundaryScratch, 0, w, 16);
      _importLine(pic.u, uvSrc - uvStride, 1, boundaryScratch, 16, uvW, 8);
      _importLine(pic.v, uvSrc - uvStride, 1, boundaryScratch, 24, uvW, 8);
    }
  }

  static void _importBlock(Uint8List src, int srcOff, int srcStride,
      Uint8List dst, int dstOff, int w, int h, int size) {
    for (var i = 0; i < h; i++) {
      dst.setRange(dstOff, dstOff + w, src, srcOff);
      if (w < size) {
        dst.fillRange(dstOff + w, dstOff + size, dst[dstOff + w - 1]);
      }
      dstOff += kBps;
      srcOff += srcStride;
    }
    for (var i = h; i < size; i++) {
      dst.setRange(dstOff, dstOff + size, dst, dstOff - kBps);
      dstOff += kBps;
    }
  }

  static void _importLine(Uint8List src, int srcOff, int srcStride,
      Uint8List dst, int dstOff, int len, int totalLen) {
    var i = 0;
    for (; i < len; i++, srcOff += srcStride) {
      dst[dstOff + i] = src[srcOff];
    }
    for (; i < totalLen; i++) {
      dst[dstOff + i] = dst[dstOff + len - 1];
    }
  }

  /// Keeps the reconstructed edges of this macroblock for its neighbours.
  @pragma('vm:unsafe:no-bounds-checks')
  void saveBoundary() {
    const ySrc = yOffEnc;
    const uvSrc = uOffEnc;
    if (x < enc.mbW - 1) {
      for (var i = 0; i < 16; i++) {
        yLeft[yLeftOff + i] = yuvOut[ySrc + 15 + i * kBps];
      }
      for (var i = 0; i < 8; i++) {
        uvLeft[uLeftOff + i] = yuvOut[uvSrc + 7 + i * kBps];
        uvLeft[vLeftOff + i] = yuvOut[uvSrc + 15 + i * kBps];
      }
      // The top-left corner has to be taken before 'top' is overwritten.
      yLeft[0] = yTop[yTopPos + 15];
      uvLeft[uLeftOff - 1] = uvTop[uvTopPos + 7];
      uvLeft[vLeftOff - 1] = uvTop[uvTopPos + 8 + 7];
    }
    if (y < enc.mbH - 1) {
      yTop.setRange(yTopPos, yTopPos + 16, yuvOut, ySrc + 15 * kBps);
      uvTop.setRange(uvTopPos, uvTopPos + 16, yuvOut, uvSrc + 7 * kBps);
    }
  }

  /// Advances to the next macroblock. Returns false when the picture is done.
  @pragma('vm:unsafe:no-bounds-checks')
  bool next() {
    if (++x == enc.mbW) {
      setRow(++y);
    } else {
      predsPos += 4;
      mbPos += 1;
      nzPos += 1;
      yTopPos += 16;
      uvTopPos += 16;
    }
    return --countDown > 0;
  }

  //----------------------------------------------------------------------------
  // Non-zero context.
  //
  // The pattern of a macroblock packs one bit per 4x4 block:
  //
  //    0  1  2  3   Y
  //    4  5  6  7
  //    8  9 10 11
  //   12 13 14 15
  //   16 17         U
  //   18 19
  //   20 21         V
  //   22 23
  //   24            the luma DC block of an intra 16x16 macroblock

  /// Unpacks the neighbouring patterns into [topNz] and [leftNz].
  @pragma('vm:unsafe:no-bounds-checks')
  void nzToBytes() {
    final tnz = enc.nz[nzPos];
    final lnz = enc.nz[nzPos - 1];
    topNz[0] = (tnz >> 12) & 1;
    topNz[1] = (tnz >> 13) & 1;
    topNz[2] = (tnz >> 14) & 1;
    topNz[3] = (tnz >> 15) & 1;
    topNz[4] = (tnz >> 18) & 1;
    topNz[5] = (tnz >> 19) & 1;
    topNz[6] = (tnz >> 22) & 1;
    topNz[7] = (tnz >> 23) & 1;
    topNz[8] = (tnz >> 24) & 1;

    leftNz[0] = (lnz >> 3) & 1;
    leftNz[1] = (lnz >> 7) & 1;
    leftNz[2] = (lnz >> 11) & 1;
    leftNz[3] = (lnz >> 15) & 1;
    leftNz[4] = (lnz >> 17) & 1;
    leftNz[5] = (lnz >> 19) & 1;
    leftNz[6] = (lnz >> 21) & 1;
    leftNz[7] = (lnz >> 23) & 1;
    // The left DC flag lives in leftNz[8] and is carried separately.
  }

  /// Packs [topNz] and [leftNz] back into this macroblock's pattern.
  @pragma('vm:unsafe:no-bounds-checks')
  void bytesToNz() {
    var nz = 0;
    nz |= (topNz[0] << 12) | (topNz[1] << 13);
    nz |= (topNz[2] << 14) | (topNz[3] << 15);
    nz |= (topNz[4] << 18) | (topNz[5] << 19);
    nz |= (topNz[6] << 22) | (topNz[7] << 23);
    // The DC flag is propagated downwards, which is what intra 4x4 needs.
    nz |= topNz[8] << 24;
    nz |= (leftNz[0] << 3) | (leftNz[1] << 7);
    nz |= leftNz[2] << 11;
    nz |= (leftNz[4] << 17) | (leftNz[6] << 21);
    enc.nz[nzPos] = nz;
  }

  //----------------------------------------------------------------------------
  // Mode bookkeeping.

  void setIntra16Mode(int mode) {
    var p = predsPos;
    for (var yy = 0; yy < 4; yy++) {
      enc.preds.fillRange(p, p + 4, mode);
      p += enc.predsW;
    }
    enc.mbType[mbPos] = 1;
  }

  void setIntra4Mode(Uint8List modes) {
    var p = predsPos;
    for (var yy = 0; yy < 4; yy++) {
      enc.preds.setRange(p, p + 4, modes, 4 * yy);
      p += enc.predsW;
    }
    enc.mbType[mbPos] = 0;
  }

  void setIntraUVMode(int mode) => enc.mbUvMode[mbPos] = mode;

  void setSkip(bool skip) => enc.mbSkip[mbPos] = skip ? 1 : 0;

  void setSegment(int segment) => enc.mbSegment[mbPos] = segment;

  int get segment => enc.mbSegment[mbPos];

  int get mbType => enc.mbType[mbPos];

  int get uvMode => enc.mbUvMode[mbPos];

  /// Exchanges the reconstruction buffer with the scratch one.
  @pragma('vm:unsafe:no-bounds-checks')
  void swapOut() {
    final tmp = yuvOut;
    yuvOut = yuvOut2;
    yuvOut2 = tmp;
  }

  //----------------------------------------------------------------------------
  // Intra 4x4 iteration.

  void startI4() {
    i4 = 0;
    i4Top = _topLeftI4[0];
    for (var i = 0; i < 17; i++) {
      i4Boundary[i] = yLeft[16 - i];
    }
    for (var i = 0; i < 16; i++) {
      i4Boundary[17 + i] = yTop[yTopPos + i];
    }
    if (x < enc.mbW - 1) {
      for (var i = 16; i < 16 + 4; i++) {
        i4Boundary[17 + i] = yTop[yTopPos + i];
      }
    } else {
      // At the right edge there is nothing above-right, so the standard says
      // to repeat the last valid sample.
      for (var i = 16; i < 16 + 4; i++) {
        i4Boundary[17 + i] = i4Boundary[17 + 15];
      }
    }
    nzToBytes();
  }

  /// Folds the block just reconstructed into the boundary and moves on.
  ///
  /// Returns false once all sixteen blocks are done.
  bool rotateI4(Uint8List yuvOut, int outOff) {
    final blk = outOff + kScan[i4];
    final top = i4Top;
    for (var i = 0; i <= 3; i++) {
      i4Boundary[top - 4 + i] = yuvOut[blk + i + 3 * kBps];
    }
    if (i4 & 3 != 3) {
      for (var i = 0; i <= 2; i++) {
        i4Boundary[top + i] = yuvOut[blk + 3 + (2 - i) * kBps];
      }
    } else {
      // On the right-hand blocks the samples above-right are not available;
      // the standard replicates the ones above instead.
      for (var i = 0; i <= 3; i++) {
        i4Boundary[top + i] = i4Boundary[top + i + 4];
      }
    }
    if (++i4 == 16) {
      return false;
    }
    i4Top = _topLeftI4[i4];
    return true;
  }
}

@pragma('vm:prefer-inline')
int _min(int a, int b) => a < b ? a : b;
