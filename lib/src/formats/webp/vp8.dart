part of image;

/**
 * WebP lossy format.
 */
class Vp8 {
  Image decode(Arc.InputStream input, WebPData data) {
    Image image = new Image(data.width, data.height);

    return image;
  }
}
