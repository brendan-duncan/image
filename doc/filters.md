# Image Processing

The Dart Image Library provides a number of functions for modifying images, by applying
color filters, transformations into other images (resize, crop), or basic drawing.

## Filter Functions

* Image [ **adjustColor**](https://brendan-duncan.github.io/image/doc/api/image/adjustColor.html)
(Image src, { Color? blacks, Color? whites, Color? mids, num? contrast, num? saturation,
* num? brightness, num? gamma, num? exposure, num? hue, num? amount })

![adjustColor](images/filter/adjustColor.png)

* Image **[billboard](https://brendan-duncan.github.io/image/doc/api/image/billboard.html)**
(Image src, { num grid = 10, num amount = 1 })

![billboard](images/filter/billboard.png)

* Image **[bleachBypass](https://brendan-duncan.github.io/image/doc/api/image/bleachBypass.html)**
(Image src, { num amount = 1 })

![bleachBypass](images/filter/bleachBypass.png)

* Image **[bulgeDistortion](https://brendan-duncan.github.io/image/doc/api/image/bulgeDistortion.html)**
(Image src, { int? centerX, int? centerY,
  num? radius, num scale = 0.5,
  Interpolation interpolation = Interpolation.nearest })

![bulgeDistortion](images/filter/bulgeDistortion.png)
  
* Image **[bumpToNormal](https://brendan-duncan.github.io/image/doc/api/image/bumpToNormal.html)**
(Image src, { num strength = 2.0 })

![bumpToNormal](images/filter/bumpToNormal.png)

* Image **[chromaticAberration](https://brendan-duncan.github.io/image/doc/api/image/chromaticAberration.html)**
(Image src, { int shift = 5 })

![chromaticAberration](images/filter/chromaticAberration.png)

* Image **[colorHalftone](https://brendan-duncan.github.io/image/doc/api/image/colorHalftone.html)**
(Image src, { num amount = 1, int? centerX, int? centerY,
  num angle = 180, num size = 5 })
 
![colorHalftone](images/filter/colorHalftone.png)

* Image **[colorOffset](https://brendan-duncan.github.io/image/doc/api/image/colorOffset.html)**
(Image src, { num red = 0, num green = 0, num blue = 0, num alpha = 0 })

![colorOffset](images/filter/colorOffset.png)

* Image **[contrast](https://brendan-duncan.github.io/image/doc/api/image/contrast.html)**
(Image src, num contrast)

![contrast](images/filter/contrast.png)

* Image **[convolution](https://brendan-duncan.github.io/image/doc/api/image/convolution.html)**
(Image src, List<num> filter, { num div = 1.0, num offset = 0.0, num amount = 1 })

![convolution](images/filter/convolution.png)

* Image **[ditherImage](https://brendan-duncan.github.io/image/doc/api/image/ditherImage.html)**
(Image image, { Quantizer? quantizer,
  DitherKernel kernel = DitherKernel.floydSteinberg,
  bool serpentine = false })

![ditherImage](images/filter/ditherImage.png)

* Image **[dotScreen](https://brendan-duncan.github.io/image/doc/api/image/dotScreen.html)**
(Image src, { num angle = 180, num size = 5.75, int? centerX,
  int? centerY, num amount = 1 })

![dotScreen](images/filter/dotScreen.png)

* Image **[dropShadow](https://brendan-duncan.github.io/image/doc/api/image/dropShadow.html)**
(Image src, int hShadow, int vShadow, int blur,
  { Color? shadowColor })

![dropShadow](images/filter/dropShadow.png)

* Image **[edgeGlow](https://brendan-duncan.github.io/image/doc/api/image/edgeGlow.html)**
(Image src, { num amount = 1.0 })

![edgeGlow](images/filter/edgeGlow.png)

* Image **[emboss](https://brendan-duncan.github.io/image/doc/api/image/emboss.html)**
(Image src, { num amount = 1 })

![emboss](images/filter/emboss.png)

* Image **[gamma](https://brendan-duncan.github.io/image/doc/api/image/gamma.html)**
(Image src, { num gamma = 2.2 })
 
![gamma](images/filter/gamma.png)

* Image **[gaussianBlur](https://brendan-duncan.github.io/image/doc/api/image/gaussianBlur.html)**
(Image src, int radius)

![gaussianBlur](images/filter/gaussianBlur.png)

* Image **[grayscale](https://brendan-duncan.github.io/image/doc/api/image/grayscale.html)**
(Image src, { num amount = 1 })

![grayscale](images/filter/grayscale.png)

* Image **[hexagonPixelate](https://brendan-duncan.github.io/image/doc/api/image/hexagonPixelate.html)**
(Image src, { int? centerX, int? centerY, int size = 5,
  num amount = 1 })

![hexagonPixelate](images/filter/hexagonPixelate.png)

* Image **[imageMask](https://brendan-duncan.github.io/image/doc/api/image/imageMask.html)**
(Image src, Image mask,
  { Channel maskChannel = Channel.luminance, bool scaleMask = false })

![imageMask](images/filter/imageMask.png)

* Image **[invert](https://brendan-duncan.github.io/image/doc/api/image/invert.html)**
(Image src)

![invert](images/filter/invert.png)

* Image **[luminanceThreshold](https://brendan-duncan.github.io/image/doc/api/image/luminanceThreshold.html)**
(Image src, { num threshold = 0.5,
  bool outputColor = false, num amount = 1 })

![luminanceThreshold](images/filter/luminanceThreshold.png)

* Image **[monochrome](https://brendan-duncan.github.io/image/doc/api/image/monochrome.html)**
(Image src, { Color? color, num amount = 1 })

![monochrome](images/filter/monochrome.png)

* Image **[noise](https://brendan-duncan.github.io/image/doc/api/image/noise.html)**
(Image image, num sigma,
  { NoiseType type = NoiseType.gaussian, Random? random })

![noise](images/filter/noise.png)

* Image **[normalize](https://brendan-duncan.github.io/image/doc/api/image/normalize.html)**
(Image src, num minValue, num maxValue)

![normalize](images/filter/normalize.png)

* Image **[pixelate](https://brendan-duncan.github.io/image/doc/api/image/pixelate.html)**
(Image src, int blockSize, { PixelateMode mode = PixelateMode.upperLeft })

![pixelate](images/filter/pixelate_upperLeft.png)

* Image **[quantize](https://brendan-duncan.github.io/image/doc/api/image/quantize.html)**
(Image src, { int numberOfColors = 256, QuantizeMethod method = QuantizeMethod.neuralNet,
  DitherKernel dither = DitherKernel.none, bool ditherSerpentine = false })

![quantize](images/filter/quantize.png)

* Image **[remapColors](https://brendan-duncan.github.io/image/doc/api/image/remapColors.html)**
(Image src, { Channel red = Channel.red, Channel green = Channel.green,
  Channel blue = Channel.blue, Channel alpha = Channel.alpha })

![remapColors](images/filter/remapColors.png)

* Image **[scaleRgba](https://brendan-duncan.github.io/image/doc/api/image/scaleRgba.html)**
(Image src, Color s)

![scaleRgba](images/filter/scaleRgba.png)

* Image **[separableConvolution](https://brendan-duncan.github.io/image/doc/api/image/separableConvolution.html)**
(Image src, SeparableKernel kernel)

![separableConvolution](images/filter/separableConvolution.png)

* Image **[sepia](https://brendan-duncan.github.io/image/doc/api/image/sepia.html)**
(Image src, { num amount = 1.0 })

![sepia](images/filter/sepia.png)

* Image **[sketch](https://brendan-duncan.github.io/image/doc/api/image/sketch.html)**
(Image src, { num amount = 1 })

![sketch](images/filter/sketch.png)

* Image **[smooth](https://brendan-duncan.github.io/image/doc/api/image/smooth.html)**
(Image src, num w)

![smooth](images/filter/smooth.png)

* Image **[sobel](https://brendan-duncan.github.io/image/doc/api/image/sobel.html)**
(Image src, { num amount = 1.0 })

![sobel](images/filter/sobel.png)

* Image **[stretchDistortion](https://brendan-duncan.github.io/image/doc/api/image/stretchDistortion.html)**
(Image src, { int? centerX, int? centerY,
  Interpolation interpolation = Interpolation.nearest })

![stretchDistortion](images/filter/stretchDistortion.png)

* Image **[vignette](https://brendan-duncan.github.io/image/doc/api/image/vignette.html)**
(Image src, { num start = 0.3, num end = 0.75, Color? color, num amount = 0.8 })

![vignette](images/filter/vignette.png)

## Transform Functions

* Image **[bakeOrientation](https://brendan-duncan.github.io/image/doc/api/image/bakeOrientation.html)**
(Image image)

If the image has orientation EXIF data, flip the image so its pixels are oriented and remove
the EXIF orientation. **Returns a new Image.**

* Image **[copyCrop](https://brendan-duncan.github.io/image/doc/api/image/copyCrop.html)**
(Image src, int x, int y, int w, int h)
 
**Returns a new Image.**

![copyCrop](images/transform/copyCrop.png)

* Image **[copyCropCircle](https://brendan-duncan.github.io/image/doc/api/image/copyCropCircle.html)**
(Image src, { int? radius, int? centerX, int? centerY })

**Returns a new Image.**

![copyCropCircle](images/transform/copyCropCircle.png)

* Image **[copyFlip](https://brendan-duncan.github.io/image/doc/api/image/copyFlip.html)**
(Image src, FlipDirection direction)

**Returns a new Image.**

![copyFlip](images/transform/copyFlip_b.png)

* Image **[copyRectify](https://brendan-duncan.github.io/image/doc/api/image/copyRectify.html)**
(Image src,
  { required Point topLeft,
  required Point topRight,
  required Point bottomLeft,
  required Point bottomRight,
  Interpolation interpolation = Interpolation.nearest,
  Image? toImage })

**Returns a new Image.**

![copyRectify](images/transform/copyRectify_orig.jpg) ![copyRectify](images/transform/copyRectify.png)

* Image **[copyResize](https://brendan-duncan.github.io/image/doc/api/image/copyResize.html)**
(Image src, { int? width, int? height, Interpolation interpolation = Interpolation.nearest })

**Returns a new Image.**

![copyResize](images/transform/copyResize.png)

* Image **[copyResizeCropSquare](https://brendan-duncan.github.io/image/doc/api/image/copyResizeCropSquare.html)**
(Image src, int size, { Interpolation interpolation = Interpolation.nearest })

**Returns a new Image.**

![copyResizeCropSquare](images/transform/copyResizeCropSquare.png)

* Image **[copyRotate](https://brendan-duncan.github.io/image/doc/api/image/copyRotate.html)**
(Image src, num angle, { Interpolation interpolation = Interpolation.nearest })

**Returns a new Image.**

![copyRotate](images/transform/copyRotate_45.png)

* Image **[flip](https://brendan-duncan.github.io/image/doc/api/image/flip.html)**
(Image src, FlipDirection direction)
 
Flips the image in-place.

![flip](images/transform/flip_v.png)

* Image **[trim](https://brendan-duncan.github.io/image/doc/api/image/trim.html)**
(Image src,
  { TrimMode mode = TrimMode.topLeftColor, Trim sides = Trim.all })

**Returns a new Image.**

![trim orig](images/transform/trim_orig.png) ![trim](images/transform/trim.png)

* List\<int\> [findTrim](https://brendan-duncan.github.io/image/doc/api/image/findTrim.html)
(Image src, { TrimMode mode = TrimMode.transparent, Trim sides = Trim.all })


## Draw Functions

* Image **[fill](https://brendan-duncan.github.io/image/doc/api/image/fill.html)**
(Image image, Color color)

![fill](images/draw/fill.png)

* Image **[fillCircle](https://brendan-duncan.github.io/image/doc/api/image/fillCircle.html)**
(Image image, int x, int y, int radius, Color color)

![fillCircle](images/draw/fill_circle.png)

* Image **[fillRect](https://brendan-duncan.github.io/image/doc/api/image/fillRect.html)**
(Image src, int x1, int y1, int x2, int y2, Color color)

![fillRect](images/draw/fill_rect.png)

* Image **[fillFlood](https://brendan-duncan.github.io/image/doc/api/image/fillFlood.html)**
(Image src, int x, int y, Color color,
  { num threshold = 0.0, bool compareAlpha = false })

![fillFlood](images/draw/fill_flood.png)

* Image **[drawChar](https://brendan-duncan.github.io/image/doc/api/image/drawChar.html)**
(Image image, BitmapFont font, int x, int y, String char, { Color? color })

![drawChar](images/draw/draw_char.png)

* Image **[drawCircle](https://brendan-duncan.github.io/image/doc/api/image/drawCircle.html)**
(Image image, int x, int y, int radius, Color color)

![drawCircle](images/draw/draw_circle.png)

* Image **[drawLine](https://brendan-duncan.github.io/image/doc/api/image/drawLine.html)**
(Image image, int x1, int y1, int x2, int y2, Color c,
  { bool antialias = false, num thickness = 1 })

![drawLine](images/draw/draw_line.png)

* Image **[drawPixel](https://brendan-duncan.github.io/image/doc/api/image/drawPixel.html)**
(Image image, int x, int y, Color c, { Color? filter,
  num? alpha, BlendMode blend = BlendMode.alpha })

![drawPixel](images/draw/drawPixel.png)

* Image **[drawRect](https://brendan-duncan.github.io/image/doc/api/image/drawRect.html)**
(Image dst, int x1, int y1, int x2, int y2, Color color,
  { num thickness = 1 })
 
![drawRect](images/draw/draw_rect.png)

* Image **[drawString](https://brendan-duncan.github.io/image/doc/api/image/drawString.html)**
(Image image, BitmapFont font, int x, int y, String string,
  { Color? color, bool rightJustify = false })

![drawString](images/draw/draw_string.png)

* Image **[compositeImage](https://brendan-duncan.github.io/image/doc/api/image/compositeImage.html)**
(Image dst, Image src, { int? dstX, int? dstY, int? dstW, int? dstH,
int? srcX, int? srcY, int? srcW, int? srcH, BlendMode blend = BlendMode.alpha, bool center = false })

![drawImage](images/draw/compositeImage.png)
