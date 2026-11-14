import 'dart:typed_data';

import '_internal.dart';

/// Returns bilinear color of 4 taps weighted by alpha, since plain blend
/// mixes RGB of transparent taps into visible ones, as offset from reference
/// tap: dividing blended color by [alpha] gave 97.99999999999999 for 98
@internal
@pragma('vm:prefer-inline')
double alphaWeightedLinear(
    double center,
    double right,
    double below,
    double diagonal,
    double centerAlpha,
    double rightAlpha,
    double belowAlpha,
    double diagonalAlpha,
    double fractionX,
    double fractionY,
    double alpha) {
  final cross = fractionX * fractionY;
  final centerWeight = (1 - fractionX - fractionY + cross) * centerAlpha;
  final rightWeight = (fractionX - cross) * rightAlpha;
  final belowWeight = (fractionY - cross) * belowAlpha;
  final diagonalWeight = cross * diagonalAlpha;

  // Tap with largest weight is reference: where no other tap has weight,
  // result is exactly color of that tap, and reference with weight 0 gave
  // 204.99999999999997 for 205
  var reference = center;
  var largest = centerWeight;
  if (rightWeight > largest) {
    reference = right;
    largest = rightWeight;
  }
  if (belowWeight > largest) {
    reference = below;
    largest = belowWeight;
  }
  if (diagonalWeight > largest) {
    reference = diagonal;
  }

  final offset = centerWeight * (center - reference) +
      rightWeight * (right - reference) +
      belowWeight * (below - reference) +
      diagonalWeight * (diagonal - reference);

  return reference + offset / alpha;
}

/// Replaces alpha of 16 taps in row order in [weights] with bicubic weight
/// times alpha, and returns tap with largest weight, which is reference in
/// [alphaWeightedCubic]
@internal
int cubicAlphaWeights(Float64List weights, double fractionX, double fractionY) {
  final squareX = fractionX * fractionX;
  final cubeX = squareX * fractionX;
  final squareY = fractionY * fractionY;
  final cubeY = squareY * fractionY;
  final previousX = 0.5 * (-fractionX + 2 * squareX - cubeX);
  final currentX = 1 + 0.5 * (-5 * squareX + 3 * cubeX);
  final nextX = 0.5 * (fractionX + 4 * squareX - 3 * cubeX);
  final afterX = 0.5 * (-squareX + cubeX);

  for (var row = 0; row < 4; ++row) {
    final rowWeight = row == 0
        ? 0.5 * (-fractionY + 2 * squareY - cubeY)
        : row == 1
            ? 1 + 0.5 * (-5 * squareY + 3 * cubeY)
            : row == 2
                ? 0.5 * (fractionY + 4 * squareY - 3 * cubeY)
                : 0.5 * (-squareY + cubeY);
    final first = row * 4;

    weights[first] *= rowWeight * previousX;
    weights[first + 1] *= rowWeight * currentX;
    weights[first + 2] *= rowWeight * nextX;
    weights[first + 3] *= rowWeight * afterX;
  }

  var referenceTap = 0;
  for (var i = 1; i < 16; ++i) {
    if (weights[i] > weights[referenceTap]) {
      referenceTap = i;
    }
  }

  return referenceTap;
}

/// Returns bicubic color of 16 taps weighted by alpha as
/// [alphaWeightedLinear] does, with [weights] and [referenceTap] from
/// [cubicAlphaWeights]
@internal
@pragma('vm:prefer-inline')
double alphaWeightedCubic(
    Float64List colors, Float64List weights, int referenceTap, double alpha) {
  final reference = colors[referenceTap];
  var offset = 0.0;
  for (var i = 0; i < 16; ++i) {
    offset += weights[i] * (colors[i] - reference);
  }

  return reference + offset / alpha;
}
