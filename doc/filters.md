# Filtering, Transforming, and Drawing

The Dart Image Library provides a number of functions for modifying images, by applying
color filters, transformations into other images (resize, crop), or basic drawing.

## Filter Functions

* **[adjustColor](https://brendan-duncan.github.io/image/doc/api/image/adjustColor.html)**

![adjustColor](images/filter/adjustColor.png)

* **[billboard](https://brendan-duncan.github.io/image/doc/api/image/billboard.html)**

![billboard](images/filter/billboard.png)

* **[bleachBypass](https://brendan-duncan.github.io/image/doc/api/image/bleachBypass.html)**

![bleachBypass](images/filter/bleachBypass.png)

* **[bulgeDistortion](https://brendan-duncan.github.io/image/doc/api/image/bulgeDistortion.html)**

![bulgeDistortion](images/filter/bulgeDistortion.png)
  
* **[bumpToNormal](https://brendan-duncan.github.io/image/doc/api/image/bumpToNormal.html)**

![bumpToNormal](images/filter/bumpToNormal.png)

* **[chromaticAberration](https://brendan-duncan.github.io/image/doc/api/image/chromaticAberration.html)**

![chromaticAberration](images/filter/chromaticAberration.png)

* **[colorHalftone](https://brendan-duncan.github.io/image/doc/api/image/colorHalftone.html)**

![colorHalftone](images/filter/colorHalftone.png)

* **[colorOffset](https://brendan-duncan.github.io/image/doc/api/image/colorOffset.html)**

![colorOffset](images/filter/colorOffset.png)

* **[contrast](https://brendan-duncan.github.io/image/doc/api/image/contrast.html)**

![contrast](images/filter/contrast.png)

* **[convolution](https://brendan-duncan.github.io/image/doc/api/image/convolution.html)**

![convolution](images/filter/convolution.png)

* **[ditherImage](https://brendan-duncan.github.io/image/doc/api/image/ditherImage.html)**

![ditherImage](images/filter/ditherImage.png)

* **[dropShadow](https://brendan-duncan.github.io/image/doc/api/image/dropShadow.html)**

![dropShadow](images/filter/dropShadow.png)

* **[emboss](https://brendan-duncan.github.io/image/doc/api/image/emboss.html)**

![emboss](images/filter/emboss.png)

* **[gamma](https://brendan-duncan.github.io/image/doc/api/image/gamma.html)**
 
![gamma](images/filter/gamma.png)

* **[gaussianBlur](https://brendan-duncan.github.io/image/doc/api/image/gaussianBlur.html)**

![gaussianBlur](images/filter/gaussianBlur.png)

* **[grayscale](https://brendan-duncan.github.io/image/doc/api/image/grayscale.html)**

![grayscale](images/filter/grayscale.png)

* **[imageMask](https://brendan-duncan.github.io/image/doc/api/image/imageMask.html)**

![imageMask](images/filter/imageMask.png)

* **[invert](https://brendan-duncan.github.io/image/doc/api/image/invert.html)**

![invert](images/filter/invert.png)

* **[luminanceThreshold](https://brendan-duncan.github.io/image/doc/api/image/luminanceThreshold.html)**

![luminanceThreshold](images/filter/luminanceThreshold.png)

* **[noise](https://brendan-duncan.github.io/image/doc/api/image/noise.html)**

![noise](images/filter/noise.png)

* **[normalize](https://brendan-duncan.github.io/image/doc/api/image/normalize.html)**

![normalize](images/filter/normalize.png)

* **[pixelate](https://brendan-duncan.github.io/image/doc/api/image/pixelate.html)**

![pixelate](images/filter/pixelate_upperLeft.png)

* **[quantize](https://brendan-duncan.github.io/image/doc/api/image/quantize.html)**

![quantize](images/filter/quantize.png)

* **[remapColors](https://brendan-duncan.github.io/image/doc/api/image/remapColors.html)**

![remapColors](images/filter/remapColors.png)

* **[scaleRgba](https://brendan-duncan.github.io/image/doc/api/image/scaleRgba.html)**

![scaleRgba](images/filter/scaleRgba.png)

* **[separableConvolution](https://brendan-duncan.github.io/image/doc/api/image/separableConvolution.html)**

![separableConvolution](images/filter/separableConvolution.png)

* **[sepia](https://brendan-duncan.github.io/image/doc/api/image/sepia.html)**

![sepia](images/filter/sepia.png)

* **[sketch](https://brendan-duncan.github.io/image/doc/api/image/sketch.html)**

![sketch](images/filter/sketch.png)

* **[smooth](https://brendan-duncan.github.io/image/doc/api/image/smooth.html)**

![smooth](images/filter/smooth.png)

* **[sobel](https://brendan-duncan.github.io/image/doc/api/image/sobel.html)**

![sobel](images/filter/sobel.png)

* **[stretchDistortion](https://brendan-duncan.github.io/image/doc/api/image/stretchDistortion.html)**

![stretchDistortion](images/filter/stretchDistortion.png)

* **[vignette](https://brendan-duncan.github.io/image/doc/api/image/vignette.html)**

![vignette](images/filter/vignette.png)

## Transform Functions

* **[bakeOrientation](https://brendan-duncan.github.io/image/doc/api/image/bakeOrientation.html)**

If the image has orientation EXIF data, flip the image so its pixels are oriented and remove
the EXIF orientation. Returns a new Image.

* **[copyCrop](https://brendan-duncan.github.io/image/doc/api/image/copyCrop.html)**
Returns a new Image.

![copyCrop](images/transform/copyCrop.png)

* **[copyCropCircle](https://brendan-duncan.github.io/image/doc/api/image/copyCropCircle.html)**
Returns a new Image.

![copyCropCircle](images/transform/copyCropCircle.png)

* **[copyFlip](https://brendan-duncan.github.io/image/doc/api/image/copyFlip.html)**
Returns a new Image.

![copyFlip](images/transform/copyFlip_b.png)

* **[copyRectify](https://brendan-duncan.github.io/image/doc/api/image/copyRectify.html)**
Returns a new Image.

![copyRectify](images/transform/copyRectify_orig.jpg) ![copyRectify](images/transform/copyRectify.png)

* **[copyResize](https://brendan-duncan.github.io/image/doc/api/image/copyResize.html)**
Returns a new Image.

![copyResize](images/transform/copyResize.png)

* **[copyResizeCropSquare](https://brendan-duncan.github.io/image/doc/api/image/copyResizeCropSquare.html)**
Returns a new Image.

![copyResizeCropSquare](images/transform/copyResizeCropSquare.png)

* **[copyRotate](https://brendan-duncan.github.io/image/doc/api/image/copyRotate.html)**
Returns a new Image.

![copyRotate](images/transform/copyRotate_45.png)

* **[flip](https://brendan-duncan.github.io/image/doc/api/image/flip.html)**
Flips the image in-place.

![flip](images/transform/flip_v.png)

* **[trim](https://brendan-duncan.github.io/image/doc/api/image/trim.html)**
Returns a new Image.

![trim orig](images/transform/trim_orig.png) ![trim](images/transform/trim.png)

## Draw Functions

* **[fill](https://brendan-duncan.github.io/image/doc/api/image/fill.html)**

![fill](images/draw/fill.png)

* **[fillCircle](https://brendan-duncan.github.io/image/doc/api/image/fillCircle.html)**

![fillCircle](images/draw/fill_circle.png)

* **[fillRect](https://brendan-duncan.github.io/image/doc/api/image/fillRect.html)**

![fillRect](images/draw/fill_rect.png)

* **[fillFlood](https://brendan-duncan.github.io/image/doc/api/image/fillFlood.html)**

![fillFlood](images/draw/fill_flood.png)

* **[drawChar](https://brendan-duncan.github.io/image/doc/api/image/drawChar.html)**

![drawChar](images/draw/draw_char.png)

* **[drawCircle](https://brendan-duncan.github.io/image/doc/api/image/drawCircle.html)**

![drawCircle](images/draw/draw_circle.png)

* **[drawLine](https://brendan-duncan.github.io/image/doc/api/image/drawLine.html)**

![drawLine](images/draw/draw_line.png)

* **[drawPixel](https://brendan-duncan.github.io/image/doc/api/image/drawPixel.html)**

![drawPixel](images/draw/draw_pixel.png)

* **[drawRect](https://brendan-duncan.github.io/image/doc/api/image/drawRect.html)**

![drawRect](images/draw/draw_rect.png)

* **[drawString](https://brendan-duncan.github.io/image/doc/api/image/drawString.html)**

![drawString](images/draw/draw_string.png)

* **[drawImage](https://brendan-duncan.github.io/image/doc/api/image/drawImage.html)**

![drawImage](images/draw/draw_image.png)
