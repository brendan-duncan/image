import '../../util/_internal.dart';

/// Arithmetic right shift of a signed 32-bit value.
///
/// Under dart2js a Dart `int` is a double and the bitwise operators work on a
/// 32-bit two's complement view, returning the result *unsigned*: the SDK
/// implements `>>` as `(a >> b) >>> 0`, so `-5 >> 1` is 4294967293 rather than
/// -3. Every transform in the encoder shifts signed intermediates, so without
/// this the whole lossy path produces a valid but meaningless bitstream, about
/// 8 dB where it should be 34.
///
/// Converting back to signed costs about a third of the shift's own time,
/// which is why the backends that do not need it get a plain `>>` through the
/// conditional export rather than paying for a correction for nothing.
@internal
@pragma('dart2js:tryInline')
int sar(int value, int shift) => (value >> shift).toSigned(32);

/// |v|.
///
/// The VM backend derives a sign mask by shifting to avoid a branch. That
/// trick relies on `>>` of a negative value staying negative, which is exactly
/// what dart2js does not do, so the web build keeps the comparison.
@internal
@pragma('dart2js:tryInline')
int absBranchless(int v) => v < 0 ? -v : v;

/// -1 for a negative value, 1 otherwise.
@internal
@pragma('dart2js:tryInline')
int signOf(int v) => v < 0 ? -1 : 1;

/// 1 for a non-zero value, 0 for zero.
@internal
@pragma('dart2js:tryInline')
int nonZero(int v) => v != 0 ? 1 : 0;

/// `min(v, 2)`.
@internal
@pragma('dart2js:tryInline')
int min2(int v) => v >= 2 ? 2 : v;
