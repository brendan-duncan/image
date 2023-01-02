# Image Processing

The Dart Image Library provides a number of functions for applying color filters to images. These
functions will be applied to the image itself rather than create a new image.

## Masking Filter Functions

Most of the drawing and filter functions can take a mask parameter. A mask is an image that controls
the blending of the filter per pixel. You can specify which channel of the mask, or its luminance, to use for
the blending value. Where the mask channel is full intensity, the filter has full effect, and where
the mask channel is 0, it has no effect; and values in between will blend the filter with the original
image.

Using a mask image to blend the [sketch](https://brendan-duncan.github.io/image/doc/api/image/sketch.html) filter:

![mask](images/filter/mask.png) 
![sketchMask](images/filter/sketch_mask.png)

## Filter Functions

### [adjustColor](https://brendan-duncan.github.io/image/doc/api/image/adjustColor.html)

```dart
Image adjustColor(Image src,
{ Color? blacks, Color? whites, Color? mids, num? contrast, num? saturation, num? brightness, num? gamma, num? exposure,
num? hue, num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![adjustColor](images/filter/adjustColor.png)

### [billboard](https://brendan-duncan.github.io/image/doc/api/image/billboard.html)

```dart
Image billboard(Image src, { num grid = 10, num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![billboard](images/filter/billboard.png)

### [bleachBypass](https://brendan-duncan.github.io/image/doc/api/image/bleachBypass.html)

```dart
Image bleachBypass(Image src, { num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![bleachBypass](images/filter/bleachBypass.png)

### [bulgeDistortion](https://brendan-duncan.github.io/image/doc/api/image/bulgeDistortion.html)

```dart
Image bulgeDistortion(Image src, { int? centerX, int? centerY, num? radius, num scale = 0.5,
    Interpolation interpolation = Interpolation.nearest, Image? mask, Channel maskChannel = Channel.luminance })
```

![bulgeDistortion](images/filter/bulgeDistortion.png)
  
### [bumpToNormal](https://brendan-duncan.github.io/image/doc/api/image/bumpToNormal.html)

```dart
Image bumpToNormal(Image src, { num strength = 2 })
```

![bumpToNormal](images/filter/bumpToNormal.png)

### [chromaticAberration](https://brendan-duncan.github.io/image/doc/api/image/chromaticAberration.html)

```dart
Image chromaticAberration(Image src, { int shift = 5, Image? mask, Channel maskChannel = Channel.luminance })
```

![chromaticAberration](images/filter/chromaticAberration.png)

### [colorHalftone](https://brendan-duncan.github.io/image/doc/api/image/colorHalftone.html)

```dart
Image colorHalftone(Image src, { num amount = 1, int? centerX, int? centerY,
    num angle = 180, num size = 5, Image? mask, Channel maskChannel = Channel.luminance })
```

![colorHalftone](images/filter/colorHalftone.png)

### [colorOffset](https://brendan-duncan.github.io/image/doc/api/image/colorOffset.html)

```dart
Image colorOffset(Image src, { num red = 0, num green = 0, num blue = 0, num alpha = 0,
    Image? mask, Channel maskChannel = Channel.luminance })
```

![colorOffset](images/filter/colorOffset.png)

### [contrast](https://brendan-duncan.github.io/image/doc/api/image/contrast.html)

```dart
Image contrast(Image src, { required num contrast, Image? mask, Channel maskChannel = Channel.luminance })
```

![contrast](images/filter/contrast.png)

### [convolution](https://brendan-duncan.github.io/image/doc/api/image/convolution.html)

```dart
Image convolution(Image src, { required List<num> filter,
    num div = 1.0, num offset = 0.0, num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![convolution](images/filter/convolution.png)

### [copyImageChannels](https://brendan-duncan.github.io/image/doc/api/image/copyImageChannels.html)

```dart
Image copyImageChannels(Image src, { required Image from, bool scaled = false,
    Channel? red, Channel? green, Channel? blue, Channel? alpha,
    Image? mask, Channel maskChannel = Channel.luminance })
```

![copyImageChannels](images/filter/copyImageChannels.png)

### [ditherImage](https://brendan-duncan.github.io/image/doc/api/image/ditherImage.html)

```dart
Image ditherImage(Image image, { Quantizer? quantizer,
  DitherKernel kernel = DitherKernel.floydSteinberg,
  bool serpentine = false })
```

![ditherImage](images/filter/ditherImage.png)

### [dotScreen](https://brendan-duncan.github.io/image/doc/api/image/dotScreen.html)

```dart
Image dotScreen(Image src, { num angle = 180, num size = 5.75, int? centerX,
    int? centerY, num amount = 1, Image? mask,
    Channel maskChannel = Channel.luminance })
```

![dotScreen](images/filter/dotScreen.png)

### [dropShadow](https://brendan-duncan.github.io/image/doc/api/image/dropShadow.html)

```dart
Image dropShadow(Image src, int hShadow, int vShadow, int blur, { Color? shadowColor })
```

![dropShadow](images/filter/dropShadow.png)

### [edgeGlow](https://brendan-duncan.github.io/image/doc/api/image/edgeGlow.html)

```dart
Image edgeGlow(Image src, { num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![edgeGlow](images/filter/edgeGlow.png)

### [emboss](https://brendan-duncan.github.io/image/doc/api/image/emboss.html)

```dart
Image emboss(Image src, { num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![emboss](images/filter/emboss.png)

### [gamma](https://brendan-duncan.github.io/image/doc/api/image/gamma.html)

```dart
Image gamma(Image src, { required num gamma, Image? mask, Channel maskChannel = Channel.luminance })
```

![gamma](images/filter/gamma.png)

### [gaussianBlur](https://brendan-duncan.github.io/image/doc/api/image/gaussianBlur.html)

```dart
Image gaussianBlur(Image src, { required int radius, Image? mask, Channel maskChannel = Channel.luminance })
```

![gaussianBlur](images/filter/gaussianBlur.png)

### [grayscale](https://brendan-duncan.github.io/image/doc/api/image/grayscale.html)

```dart
Image grayscale(Image src, { num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![grayscale](images/filter/grayscale.png)

### [hdrToLdr](https://brendan-duncan.github.io/image/doc/api/image/hdrToLdr.html)

```dart
Image hdrToLdr(Image hdr, { num? exposure })
```

![hdrToLdr](images/filter/hdrToLdr.png)

### [hexagonPixelate](https://brendan-duncan.github.io/image/doc/api/image/hexagonPixelate.html)

```dart
Image hexagonPixelate(Image src, { int? centerX, int? centerY, int size = 5,
    num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![hexagonPixelate](images/filter/hexagonPixelate.png)

### [invert](https://brendan-duncan.github.io/image/doc/api/image/invert.html)

```dart
Image invert(Image src, { Image? mask, Channel maskChannel = Channel.luminance })
```

![invert](images/filter/invert.png)

### [luminanceThreshold](https://brendan-duncan.github.io/image/doc/api/image/luminanceThreshold.html)

```dart
Image luminanceThreshold(Image src, { num threshold = 0.5,
    bool outputColor = false, num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![luminanceThreshold](images/filter/luminanceThreshold.png)

### [monochrome](https://brendan-duncan.github.io/image/doc/api/image/monochrome.html)

```dart
Image monochrome(Image src, { Color? color, num amount = 1,
    Image? mask, Channel maskChannel = Channel.luminance })
```

![monochrome](images/filter/monochrome.png)

### [noise](https://brendan-duncan.github.io/image/doc/api/image/noise.html)

```dart
Image noise(Image image, num sigma, { NoiseType type = NoiseType.gaussian, Random? random,
    Image? mask, Channel maskChannel = Channel.luminance })
```

![noise](images/filter/noise.png)

### [normalize](https://brendan-duncan.github.io/image/doc/api/image/normalize.html)

```dart
Image normalize(Image src, { required num min, required num max,
    Image? mask, Channel maskChannel = Channel.luminance })
```

![normalize](images/filter/normalize.png)

### [pixelate](https://brendan-duncan.github.io/image/doc/api/image/pixelate.html)

```dart
Image pixelate(Image src, { required int size,
    PixelateMode mode = PixelateMode.upperLeft, num amount = 1, Image? mask,
    Channel maskChannel = Channel.luminance })
```

![pixelate](images/filter/pixelate_upperLeft.png)

### [quantize](https://brendan-duncan.github.io/image/doc/api/image/quantize.html)

```dart
Image quantize(Image src, { int numberOfColors = 256, QuantizeMethod method = QuantizeMethod.neuralNet,
  DitherKernel dither = DitherKernel.none, bool ditherSerpentine = false })
```

![quantize](images/filter/quantize.png)

### [reinhardTonemap](https://brendan-duncan.github.io/image/doc/api/image/reinhardTonemap.html)

```dart
Image reinhardTonemap(Image hdr, { Image? mask, Channel maskChannel = Channel.luminance })
```

![reinhardTonemap](images/filter/reinhardTonemap.png)

### [remapColors](https://brendan-duncan.github.io/image/doc/api/image/remapColors.html)

```dart
Image remapColors(Image src, { Channel red = Channel.red, Channel green = Channel.green,
  Channel blue = Channel.blue, Channel alpha = Channel.alpha })
```

![remapColors](images/filter/remapColors.png)

### [scaleRgba](https://brendan-duncan.github.io/image/doc/api/image/scaleRgba.html)

```dart
Image scaleRgba(Image src, { required Color scale, Image? mask, Channel maskChannel = Channel.luminance })
```

![scaleRgba](images/filter/scaleRgba.png)

### [separableConvolution](https://brendan-duncan.github.io/image/doc/api/image/separableConvolution.html)

```dart
Image separableConvolution(Image src, { required SeparableKernel kernel,
    Image? mask, Channel maskChannel = Channel.luminance })
```

![separableConvolution](images/filter/separableConvolution.png)

### [sepia](https://brendan-duncan.github.io/image/doc/api/image/sepia.html)

```dart
Image sepia(Image src, { num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![sepia](images/filter/sepia.png)

### [sketch](https://brendan-duncan.github.io/image/doc/api/image/sketch.html)

```dart
Image sketch(Image src, { num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![sketch](images/filter/sketch.png)

### [smooth](https://brendan-duncan.github.io/image/doc/api/image/smooth.html)

```dart
Image smooth(Image src, { required num weight, Image? mask, Channel maskChannel = Channel.luminance })
```

![smooth](images/filter/smooth.png)

### [sobel](https://brendan-duncan.github.io/image/doc/api/image/sobel.html)

```dart
Image sobel(Image src, { num amount = 1, Image? mask, Channel maskChannel = Channel.luminance })
```

![sobel](images/filter/sobel.png)

### [stretchDistortion](https://brendan-duncan.github.io/image/doc/api/image/stretchDistortion.html)

```dart
Image stretchDistortion(Image src, { int? centerX, int? centerY,
    Interpolation interpolation = Interpolation.nearest, Image? mask, Channel maskChannel = Channel.luminance })
```

![stretchDistortion](images/filter/stretchDistortion.png)

### [vignette](https://brendan-duncan.github.io/image/doc/api/image/vignette.html)

```dart
Image vignette(Image src, { num start = 0.3, num end = 0.85,
    num amount = 0.9, Color? color, Image? mask, Channel maskChannel = Channel.luminance })
```

![vignette](images/filter/vignette.png)
