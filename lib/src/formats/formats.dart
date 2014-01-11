part of image;


Image readJpg(List<int> bytes) {
  return new JpegDecoder().decode(bytes);
}

List<int> writeJpg(Image image, {int quality: 100}) {
  return new JpegEncoder(quality: quality).encode(image);
}


Image readPng(List<int> bytes) {
  return new PngDecoder().decode(bytes);
}

List<int> writePng(Image image, {int level: 6}) {
  return new PngEncoder(level: level).encode(image);
}


Image readTga(List<int> bytes) {
  return new TgaDecoder().decode(bytes);
}

List<int> writeTga(Image image) {
  return new TgaEncoder().encode(image);
}

