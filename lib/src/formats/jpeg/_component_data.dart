import 'dart:typed_data';

class ComponentData {
  int hSamples;
  int maxHSamples;
  int vSamples;
  int maxVSamples;
  List<Uint8List?> lines;
  int hScaleShift;
  int vScaleShift;
  ComponentData(this.hSamples, this.maxHSamples, this.vSamples,
      this.maxVSamples, this.lines)
      : hScaleShift = hSamples == maxHSamples
            ? 0
            : hSamples == 1 && maxHSamples == 4
                ? 2
                : 1,
        vScaleShift = vSamples == maxVSamples
            ? 0
            : vSamples == 1 && maxVSamples == 4
                ? 2
                : 1;
}
