part of image;

class JpegFrame {
  bool extended;
  bool progressive;
  int precision;
  int scanLines;
  int samplesPerLine;
  int maxH = 0;
  int maxV = 0;
  int mcusPerLine;
  int mcusPerColumn;
  final Map<int, JpegComponent> components = {};
  final List<int> componentsOrder = new List<int>();

  void prepare() {
    for (int componentId in components.keys) {
      JpegComponent component = components[componentId];
      if (maxH < component.h) {
        maxH = component.h;
      }
      if (maxV < component.v) {
        maxV = component.v;
      }
    }

    mcusPerLine = (samplesPerLine / 8 / maxH).ceil();
    mcusPerColumn = (scanLines / 8 / maxV).ceil();

    for (int componentId in components.keys) {
      JpegComponent component = components[componentId];
      int blocksPerLine = ((samplesPerLine / 8).ceil() *
                           component.h / maxH).ceil();
      int blocksPerColumn = ((scanLines / 8).ceil() *
                             component.v / maxV).ceil();
      int blocksPerLineForMcu = mcusPerLine * component.h;
      int blocksPerColumnForMcu = mcusPerColumn * component.v;

      List blocks = new List(blocksPerColumnForMcu);
      for (int i = 0; i < blocksPerColumnForMcu; i++) {
        List row = new List(blocksPerLineForMcu);
        for (int j = 0; j < blocksPerLineForMcu; j++) {
          row[j] = new Int32List(64);
        }
        blocks[i] = row;
      }

      component.blocksPerLine = blocksPerLine;
      component.blocksPerColumn = blocksPerColumn;
      component.blocks = blocks;
    }
  }
}
