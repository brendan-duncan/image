import 'dart:typed_data';

import '../image/image.dart';

/// Maps the RGB channels of the RGB(A) uint8 [image] through the lookup
/// tables.
void applyRgbLut(Image image, Uint8List r, Uint8List g, Uint8List b) {
  final data = image.toUint8List();
  final nc = image.numChannels;
  for (var i = 0; i < data.length; i += nc) {
    data[i] = r[data[i]];
    data[i + 1] = g[data[i + 1]];
    data[i + 2] = b[data[i + 2]];
  }
}
