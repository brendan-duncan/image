part of image;

/**
 * WebP lossy format.
 */
class Vp8 {
  Arc.InputStream input;
  WebPData webp;

  Vp8(Arc.InputStream input, this.webp) :
    this.input = input;

  bool decodeHeader() {
    return true;
  }

  Image decode() {
    Image image = new Image(webp.width, webp.height);
    return image;
  }
}
