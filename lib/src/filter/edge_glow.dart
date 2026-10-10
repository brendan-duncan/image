import 'dart:math';
import 'dart:typed_data';

import '../color/channel.dart';
import '../color/format.dart';
import '../image/image.dart';
import '../util/math_util.dart';
import '_frame_copy.dart';

/// Apply the edge glow filter to the [src] Image.
Image edgeGlow(Image src,
    {num amount = 1, Image? mask, Channel maskChannel = Channel.luminance}) {
  if (amount == 0.0) {
    return src;
  }
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }
  Image? scratch;
  for (final frame in src.frames) {
    scratch = copyFrameReusing(frame, scratch);
    final orig = scratch;
    final width = frame.width;
    final height = frame.height;
    if (mask == null &&
        frame.format == Format.uint8 &&
        frame.numChannels >= 3) {
      _edgeGlowUint8(orig.toUint8List(), frame.toUint8List(), width, height,
          frame.numChannels, amount);
      continue;
    }
    for (final p in frame) {
      final ny = (p.y - 1).clamp(0, height - 1);
      final py = (p.y + 1).clamp(0, height - 1);
      final nx = (p.x - 1).clamp(0, width - 1);
      final px = (p.x + 1).clamp(0, width - 1);

      final t1 = orig.getPixel(nx, ny);
      final t2 = orig.getPixel(p.x, ny);
      final t3 = orig.getPixel(px, ny);
      final t4 = orig.getPixel(nx, p.y);
      final t5 = p;
      final t6 = orig.getPixel(px, p.y);
      final t7 = orig.getPixel(nx, py);
      final t8 = orig.getPixel(p.x, py);
      final t9 = orig.getPixel(px, py);

      final xxR = t1.rNormalized +
          2 * t2.rNormalized +
          t3.rNormalized -
          t7.rNormalized -
          2 * t8.rNormalized -
          t9.rNormalized;
      final xxG = t1.gNormalized +
          2 * t2.gNormalized +
          t3.gNormalized -
          t7.gNormalized -
          2 * t8.gNormalized -
          t9.gNormalized;
      final xxB = t1.bNormalized +
          2 * t2.bNormalized +
          t3.bNormalized -
          t7.bNormalized -
          2 * t8.bNormalized -
          t9.bNormalized;

      final yyR = t1.rNormalized -
          t3.rNormalized +
          2 * t4.rNormalized -
          2 * t6.rNormalized +
          t7.rNormalized -
          t9.rNormalized;
      final yyG = t1.gNormalized -
          t3.gNormalized +
          2 * t4.gNormalized -
          2 * t6.gNormalized +
          t7.gNormalized -
          t9.gNormalized;
      final yyB = t1.bNormalized -
          t3.bNormalized +
          2 * t4.bNormalized -
          2 * t6.bNormalized +
          t7.bNormalized -
          t9.bNormalized;

      final rrR = sqrt(xxR * xxR + yyR * yyR);
      final rrG = sqrt(xxG * xxG + yyG * yyG);
      final rrB = sqrt(xxB * xxB + yyB * yyB);

      final r = (rrR * 2 * t5.rNormalized) * p.maxChannelValue;
      final g = (rrG * 2 * t5.gNormalized) * p.maxChannelValue;
      final b = (rrB * 2 * t5.bNormalized) * p.maxChannelValue;

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      final mx = (msk ?? 1) * amount;

      p
        ..r = mix(p.r, r, mx)
        ..g = mix(p.g, g, mx)
        ..b = mix(p.b, b, mx);
    }
  }

  return src;
}

// The normalized value of each uint8 channel value, as rNormalized gives it.
final _normalized =
    Float64List.fromList([for (var v = 0; v < 256; ++v) v / 255]);

// A fast path for RGB(A) uint8 images, computing the same values as the
// general path from the original pixels in [src].
void _edgeGlowUint8(
    Uint8List src, Uint8List out, int width, int height, int nc, num amount) {
  final n = _normalized;
  final mx = (1 * amount).toDouble();
  final invMx = 1 - mx;
  final stride = width * nc;
  for (var y = 0; y < height; ++y) {
    final ny = (y > 0 ? y - 1 : 0) * stride;
    final cy = y * stride;
    final py = (y + 1 < height ? y + 1 : height - 1) * stride;
    for (var x = 0; x < width; ++x) {
      final nx = (x > 0 ? x - 1 : 0) * nc;
      final cx = x * nc;
      final px = (x + 1 < width ? x + 1 : width - 1) * nc;
      for (var c = 0; c < 3; ++c) {
        final t1 = n[src[ny + nx + c]];
        final t2 = n[src[ny + cx + c]];
        final t3 = n[src[ny + px + c]];
        final t4 = n[src[cy + nx + c]];
        final t5 = n[src[cy + cx + c]];
        final t6 = n[src[cy + px + c]];
        final t7 = n[src[py + nx + c]];
        final t8 = n[src[py + cx + c]];
        final t9 = n[src[py + px + c]];
        final xx = t1 + 2 * t2 + t3 - t7 - 2 * t8 - t9;
        final yy = t1 - t3 + 2 * t4 - 2 * t6 + t7 - t9;
        final rr = sqrt(xx * xx + yy * yy);
        final v = (rr * 2 * t5) * 255;
        final i = cy + cx + c;
        final m = src[i] * invMx + v * mx;
        out[i] = m < 0
            ? 0
            : m > 255
                ? 255
                : m.toInt();
      }
    }
  }
}
