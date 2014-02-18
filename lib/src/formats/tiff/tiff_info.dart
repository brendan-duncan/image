part of image;

class TiffInfo extends DecodeInfo {
  int byteOrder;
  int signature;

  int ifdOffset;
  List<TiffImage> images = [];

  int get numFrames => images.length;
}
