part of image;

/**
 * Decodes a frame from a WebP animation.
 */
class WebPFrame {
  Image decode(Arc.InputStream input, WebPData data) {
    Image image = new Image(data.width, data.height);

    return image;
  }
}
