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
