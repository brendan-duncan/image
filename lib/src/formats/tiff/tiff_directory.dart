part of image;

class TiffDirectory {
  List<TiffEntity> entities = [];
}

class TiffEntity {
  int tag;
  int type;
  int numValues;
  int valueOffset;
}