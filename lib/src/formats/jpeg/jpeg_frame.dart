import 'dart:math';
import 'dart:typed_data';
import 'jpeg_component.dart';

class JpegFrame {
  bool extended;
  bool progressive;
  int precision;
  int scanLines;
  int samplesPerLine;
  int maxHSamples = 0;
  int maxVSamples = 0;
  int mcusPerLine;
  int mcusPerColumn;
  final components = <int, JpegComponent>{};
  final List<int> componentsOrder = <int>[];

  void prepare() {
    for (var componentId in components.keys) {
      var component = components[componentId];
      maxHSamples = max(maxHSamples, component.hSamples);
      maxVSamples = max(maxVSamples, component.vSamples);
    }

    mcusPerLine = (samplesPerLine / 8 / maxHSamples).ceil();
    mcusPerColumn = (scanLines / 8 / maxVSamples).ceil();

    for (var componentId in components.keys) {
      var component = components[componentId];
      var blocksPerLine =
          ((samplesPerLine / 8).ceil() * component.hSamples / maxHSamples)
              .ceil();
      var blocksPerColumn =
          ((scanLines / 8).ceil() * component.vSamples / maxVSamples).ceil();
      var blocksPerLineForMcu = mcusPerLine * component.hSamples;
      var blocksPerColumnForMcu = mcusPerColumn * component.vSamples;

      final blocks = List<dynamic>(blocksPerColumnForMcu);
      for (var i = 0; i < blocksPerColumnForMcu; i++) {
        final row = List<dynamic>(blocksPerLineForMcu);
        for (var j = 0; j < blocksPerLineForMcu; j++) {
          row[j] = Int32List(64);
        }
        blocks[i] = row;
      }

      component.blocksPerLine = blocksPerLine;
      component.blocksPerColumn = blocksPerColumn;
      component.blocks = blocks;
    }
  }
}
