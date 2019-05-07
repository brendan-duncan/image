import 'package:image/src/util/octree_quantizer.dart';

import '../image.dart';
import '../util/neural_quantizer.dart';

/**
 * Quantize the number of colors in image to 256.
 */
Image quantize(Image src, {int numberOfColors=256}) {
  /*if (numberOfColors < 4) {
    OctreeQuantizer oct = OctreeQuantizer(src, numberOfColors: numberOfColors);
    for (int i = 0, len = src.length; i < len; ++i) {
      src[i] = oct.getQuantizedColor(src[i]);
    }
  }*/
  NeuralQuantizer quant = NeuralQuantizer(src, numberOfColors: numberOfColors);
  for (int i = 0, len = src.length; i < len; ++i) {
    src[i] = quant.getQuantizedColor(src[i]);
  }
  return src;
}
