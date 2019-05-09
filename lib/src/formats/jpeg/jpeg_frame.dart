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
  final Map<int, JpegComponent> components = {};
  final List<int> componentsOrder = List<int>();

  void prepare() {
    for (int componentId in components.keys) {
      JpegComponent component = components[componentId];
      maxHSamples = max(maxHSamples, component.hSamples);
      maxVSamples = max(maxVSamples, component.vSamples);
    }

    mcusPerLine = (samplesPerLine / 8 / maxHSamples).ceil();
    mcusPerColumn = (scanLines / 8 / maxVSamples).ceil();

    for (int componentId in components.keys) {
      JpegComponent component = components[componentId];
      int blocksPerLine =
          ((samplesPerLine / 8).ceil() * component.hSamples / maxHSamples)
              .ceil();
      int blocksPerColumn =
          ((scanLines / 8).ceil() * component.vSamples / maxVSamples).ceil();
      int blocksPerLineForMcu = mcusPerLine * component.hSamples;
      int blocksPerColumnForMcu = mcusPerColumn * component.vSamples;

      List blocks = List(blocksPerColumnForMcu);
      for (int i = 0; i < blocksPerColumnForMcu; i++) {
        List row = List(blocksPerLineForMcu);
        for (int j = 0; j < blocksPerLineForMcu; j++) {
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
