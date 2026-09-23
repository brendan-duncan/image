import '../../util/_internal.dart';

/// Arithmetic right shift of a signed 32-bit value.
///
/// On a backend with real 64-bit integers, which is the VM and dart2wasm
/// alike, `>>` already has this meaning, so this is the operator itself. See
/// `_vp8_sar_html.dart` for the backend that needs a correction.
@internal
@pragma('vm:prefer-inline')
int sar(int value, int shift) => value >> shift;

/// |v| without a branch.
///
/// Dart AOT compiles `v < 0 ? -v : v` to a branch, which mispredicts on
/// transform coefficients because their sign is close to random. Deriving a
/// sign mask by shifting removes the branch: 87 animation frames encode in
/// 2230 ms, in 2552 ms without this and in 2844 ms without [signOf] as well.
///
/// The shift has to cover the whole 64-bit integer. A shift by 31 looks the
/// same on the Int16 coefficients that reach here today and silently breaks on
/// anything wider.
@internal
@pragma('vm:prefer-inline')
int absBranchless(int v) {
  final s = v >> 63;
  return (v + s) ^ s;
}

/// -1 for a negative value, 1 otherwise, without a branch.
@internal
@pragma('vm:prefer-inline')
int signOf(int v) => 2 * (v >> 63) + 1;

/// 1 for a non-zero value, 0 for zero, without a branch.
@internal
@pragma('vm:prefer-inline')
int nonZero(int v) => (v | -v) >>> 63;

/// `min(v, 2)` without a branch.
@internal
@pragma('vm:prefer-inline')
int min2(int v) => 2 + ((v - 2) & ((v - 2) >> 63));
