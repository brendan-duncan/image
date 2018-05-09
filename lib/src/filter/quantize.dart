import '../image.dart';
import '../util/neural_quantizer.dart';

/**
 * Quantize the number of colors in image to 256.
 */
Image quantize(Image src) {
  NeuralQuantizer quant = new NeuralQuantizer(src);
  for (int i = 0, len = src.length; i < len; ++i) {
    src[i] = quant.getQuantizedColor(src[i]);
  }
  return src;
}
