/// A right shift that means the same thing on every backend.
///
/// Only needed where the value being shifted can be negative. Where it cannot,
/// the plain operator is correct everywhere and is what the code should use.
///
/// The split is by integer width, not by platform: only dart2js gives `int` a
/// 32-bit view, while the VM and dart2wasm both have real 64-bit integers.
/// `dart:isolate` draws that line. `dart.library.io` is the more usual
/// condition and the wrong one here: it is absent on dart2wasm, which would
/// then pay for a correction it does not need.
library;

export '_vp8_sar_html.dart' if (dart.library.isolate) '_vp8_sar_io.dart';
