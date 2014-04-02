part of image;

class PsdLayerData {
  String tag;

  factory PsdLayerData(String tag, InputBuffer data) {
    switch (tag) {
      case PsdLayerSectionDivider.TAG:
        return new PsdLayerSectionDivider(tag, data);
      default:
        return new PsdLayerAdditionalData(tag, data);
    }
  }

  PsdLayerData.type(this.tag);
}
