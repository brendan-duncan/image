# Filtering, Transforming, and Drawing

The Dart Image Library provides a number of functions for modifying images, by applying
color filters, transformations into other images (resize, crop), or basic drawing.

## Filter Functions

* **[adjustColor](api/image/adjustColor.html)**
![adjustColor](images/filter/adjustColor.png)
  
* **[bumpToNormal](api/image/bumpToNormal.html)**
![bumpToNormal](images/filter/bumpToNormal.png)

* **[colorOffset](api/image/colorOffset.html)**
![colorOffset](images/filter/colorOffset.png)

* **[contrast](api/image/contrast.html)**
![contrast](images/filter/contrast.png)

* **[convolution](api/image/convolution.html)**
![convolution](images/filter/convolution.png)

* **[ditherImage](api/image/ditherImage.html)**
![ditherImage](images/filter/ditherImage.png)

* **[dropShadow](api/image/dropShadow.html)**
![dropShadow](images/filter/dropShadow.png)

* **[emboss](api/image/emboss.html)**
![emboss](images/filter/emboss.png)

* **[gamma](api/image/gamma.html)**
![gamma](images/filter/gamma.png)

* **[gaussianBlur](api/image/gaussianBlur.html)**
![gaussianBlur](images/filter/gaussianBlur.png)

* **[grayscale](api/image/grayscale.html)**
![grayscale](images/filter/grayscale.png)

* **[invert](api/image/invert.html)**
![invert](images/filter/invert.png)

* **[noise](api/image/noise.html)**
![noise](images/filter/noise.png)

* **[normalize](api/image/normalize.html)**
![normalize](images/filter/normalize.png)

* **[pixelate](api/image/pixelate.html)**
![pixelate](images/filter/pixelate_upperLeft.png)

* **[quantize](api/image/quantize.html)**
![quantize](images/filter/quantize.png)

* **[remapColors](api/image/remapColors.html)**
![remapColors](images/filter/remapColors.png)

* **[scaleRgba](api/image/scaleRgba.html)**
![scaleRgba](images/filter/scaleRgba.png)

* **[separableConvolution](api/image/separableConvolution.html)**
![separableConvolution](images/filter/separableConvolution.png)

* **[sepia](api/image/sepia.html)**
![sepia](images/filter/sepia.png)

* **[smooth](api/image/smooth.html)**
![smooth](images/filter/smooth.png)

* **[sobel](api/image/sobel.html)**
![sobel](images/filter/sobel.png)

* **[vignette](api/image/vignette.html)**
![vignette](images/filter/vignette.png)

## Transform Functions

* **[bakeOrientation](api/image/bakeOrientation.html)**
If the image has orientation EXIF data, flip the image so its pixels are oriented and remove
the EXIF orientation. Returns a new Image.

* **[copyCrop](api/image/copyCrop.html)**
Returns a new Image.
![copyCrop](images/transform/copyCrop.png)

* **[copyCropCircle](api/image/copyCropCircle.html)**
Returns a new Image.
![copyCropCircle](images/transform/copyCropCircle.png)

* **[copyFlip](api/image/copyFlip.html)**
Returns a new Image.
![copyFlip](images/transform/copyFlip_b.png)

* **[copyRectify](api/image/copyRectify.html)**
Returns a new Image.
![copyRectify](images/transform/copyRectify_orig.jpg) ![copyRectify](images/transform/copyRectify.png)

* **[copyResize](api/image/copyResize.html)**
Returns a new Image.
![copyResize](images/transform/copyResize.png)

* **[copyResizeCropSquare](api/image/copyResizeCropSquare.html)**
Returns a new Image.
![copyResizeCropSquare](images/transform/copyResizeCropSquare.png)

* **[copyRotate](api/image/copyRotate.html)**
Returns a new Image.
![copyRotate](images/transform/copyRotate_45.png)

* **[flip](api/image/flip.html)**
Flips the image in-place.
![flip](images/transform/flip_v.png)

* **[trim](api/image/trim.html)**
Returns a new Image.
![trim orig](images/transform/trim_orig.png) ![trim](images/transform/trim.png)

## Draw Functions

* **[fill](api/image/fill.html)**
![fill](images/draw/fill.png)

* **[fillCircle](api/image/fillCircle.html)**
![fillCircle](images/draw/fill_circle.png)

* **[fillRect](api/image/fillRect.html)**
![fillRect](images/draw/fill_rect.png)

* **[fillFlood](api/image/fillFlood.html)**
![fillFlood](images/draw/fill_flood.png)

* **[drawChar](api/image/drawChar.html)**
![drawChar](images/draw/draw_char.png)

* **[drawCircle](api/image/drawCircle.html)**
![drawCircle](images/draw/draw_circle.png)

* **[drawLine](api/image/drawLine.html)**
![drawLine](images/draw/draw_line.png)

* **[drawPixel](api/image/drawPixel.html)**
![drawPixel](images/draw/draw_pixel.png)

* **[drawRect](api/image/drawRect.html)**
![drawRect](images/draw/draw_rect.png)

* **[drawString](api/image/drawString.html)**
![drawString](images/draw/draw_string.png)

* **[drawImage](api/image/drawImage.html)**
![drawImage](images/draw/draw_image.png)
