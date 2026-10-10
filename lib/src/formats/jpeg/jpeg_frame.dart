import 'dart:math';
import 'dart:typed_data';

import '../../util/_internal.dart';
import 'jpeg_component.dart';

@internal
class JpegFrame {
  bool? extended;
  bool? progressive;
  int? precision;
  int? scanLines;
  int? samplesPerLine;
  int maxHSamples = 0;
  int maxVSamples = 0;
  late int mcusPerLine;
  late int mcusPerColumn;
  final components = <int, JpegComponent>{};
  final List<int> componentsOrder = <int>[];

  /// Allocates the coefficients of the components. With [dcOnly], only the
  /// DC coefficient of each block is kept. With [band], only one row of MCUs
  /// is kept, for decoding a row at a time.
  void prepare({bool dcOnly = false, bool band = false}) {
    for (var componentId in components.keys) {
      final component = components[componentId]!;
      maxHSamples = max(maxHSamples, component.hSamples);
      maxVSamples = max(maxVSamples, component.vSamples);
    }

    mcusPerLine = (samplesPerLine! / 8 / maxHSamples).ceil();
    mcusPerColumn = (scanLines! / 8 / maxVSamples).ceil();

    for (var componentId in components.keys) {
      final component = components[componentId]!;
      final blocksPerLine =
          ((samplesPerLine! / 8).ceil() * component.hSamples / maxHSamples)
              .ceil();
      final blocksPerColumn =
          ((scanLines! / 8).ceil() * component.vSamples / maxVSamples).ceil();
      final blocksPerLineForMcu = mcusPerLine * component.hSamples;
      final blocksPerColumnForMcu = mcusPerColumn * component.vSamples;

      component
        ..blocksPerLine = blocksPerLine
        ..blocksPerColumn = blocksPerColumn
        ..blocksPerLineForMcu = blocksPerLineForMcu
        ..blocksPerColumnForMcu = blocksPerColumnForMcu
        ..dcOnly = dcOnly
        ..bandBlockRows = band ? component.vSamples : 0
        ..coefficients = Int16List(blocksPerLineForMcu *
            (band ? component.vSamples : blocksPerColumnForMcu) *
            (dcOnly ? 1 : 64));
    }
  }
}
