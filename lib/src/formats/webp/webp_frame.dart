part of image;

/**
 * Decodes a frame from a WebP animation.
 */
class WebPFrame {
  Arc.InputStream input;
  WebPData webp;

  WebPFrame(Arc.InputStream input, this.webp) :
    this.input = input;

  Image decode() {
    Image image = new Image(webp.width, webp.height);
    return image;
  }
}
