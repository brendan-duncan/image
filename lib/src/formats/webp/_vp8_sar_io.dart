import '../../util/_internal.dart';

/// Arithmetic right shift of a signed 32-bit value.
///
/// On a backend with real 64-bit integers, which is the VM and dart2wasm
/// alike, `>>` already has this meaning, so this is the operator itself. See
/// `_vp8_sar_html.dart` for the backend that needs a correction.
@internal
@pragma('vm:prefer-inline')
int sar(int value, int shift) => value >> shift;
