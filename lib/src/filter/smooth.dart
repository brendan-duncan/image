import '../color/channel.dart';
import '../image/image.dart';
import '../util/_linear_rgb.dart';
import 'convolution.dart';

/// Apply a smoothing convolution filter to the [src] image.
///
/// [weight] is the weight of the current pixel being filtered. If it's greater
/// than 1.0, it will make the image sharper.
///
/// If [linearBlend] is true, the colors, taken as sRGB, are averaged as linear
/// light, which is slower but keeps bright details from fading into darker
/// surroundings.
Image smooth(Image src,
    {required num weight,
    bool linearBlend = false,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (linearBlend) {
    return filterLinear(
        src,
        (linear) => smooth(linear,
            weight: weight, mask: mask, maskChannel: maskChannel));
  }
  final filter = [1.0, 1.0, 1.0, 1.0, weight.toDouble(), 1.0, 1.0, 1.0, 1.0];
  return convolution(src,
      filter: filter,
      div: weight + 8,
      offset: 0,
      mask: mask,
      maskChannel: maskChannel);
}
