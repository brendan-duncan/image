# Image Transformations

The Dart Image Library provides a number of functions for modifying images by applying a transformation
that changes the image, such as resizing and cropping. Most of these functions will return a new Image.

## Transform Functions

### [bakeOrientation](https://brendan-duncan.github.io/image/doc/api/image/bakeOrientation.html)

```dart
Image bakeOrientation(Image image)
```

If the image has orientation EXIF data, flip the image so its pixels are oriented and remove
the EXIF orientation. Returns a new Image.

### [copyCrop](https://brendan-duncan.github.io/image/doc/api/image/copyCrop.html)

```dart
Image copyCrop(Image src, { required int x, required int y, required int width, required int height,
    num radius = 0})
 ```

The radius argument is used to round the corners of the crop. Returns a new Image.

![copyCrop](images/transform/copyCrop.png)
![copyCrop](images/transform/copyCrop_rounded.png)

### [copyCropCircle](https://brendan-duncan.github.io/image/doc/api/image/copyCropCircle.html)

```dart
Image copyCropCircle(Image src, { int? radius, int? centerX, int? centerY })
```

Returns a new Image.

![copyCropCircle](images/transform/copyCropCircle.png)

### [copyFlip](https://brendan-duncan.github.io/image/doc/api/image/copyFlip.html)

```dart
Image copyFlip(Image src, { required FlipDirection direction })
```

Returns a new Image.

![copyFlip](images/transform/copyFlip_b.png)

### [copyRectify](https://brendan-duncan.github.io/image/doc/api/image/copyRectify.html)

```dart
Image copyRectify(Image src,
  { required Point topLeft,
  required Point topRight,
  required Point bottomLeft,
  required Point bottomRight,
  Interpolation interpolation = Interpolation.nearest,
  Image? toImage })
```

Returns a new Image.

![copyRectify](images/transform/copyRectify_orig.jpg) ![copyRectify](images/transform/copyRectify.png)

### [copyResize](https://brendan-duncan.github.io/image/doc/api/image/copyResize.html)

```dart
Image copyResize(Image src, { int? width, int? height, Interpolation interpolation = Interpolation.nearest })
```

Returns a new Image.

![copyResize](images/transform/copyResize.png)

### [copyResizeCropSquare](https://brendan-duncan.github.io/image/doc/api/image/copyResizeCropSquare.html)

```dart
Image copyResizeCropSquare(Image src, { required int size, num radius = 1, Interpolation interpolation = Interpolation.nearest })
```

The radius argument is used to round the corners of the crop. Returns a new Image.

![copyResizeCropSquare](images/transform/copyResizeCropSquare.png)
![copyResizeCropSquare](images/transform/copyResizeCropSquare_rounded.png)

### [copyRotate](https://brendan-duncan.github.io/image/doc/api/image/copyRotate.html)

```dart
Image copyRotate(Image src, { required num angle, Interpolation interpolation = Interpolation.nearest })
```

Returns a new Image.

![copyRotate](images/transform/copyRotate_45.png)

### [flip](https://brendan-duncan.github.io/image/doc/api/image/flip.html)

```dart
Image flip(Image src, { required FlipDirection direction })
```

Flips the image in-place.

![flip](images/transform/flip_v.png)

### [trim](https://brendan-duncan.github.io/image/doc/api/image/trim.html)

```dart
Image trim(Image src, { TrimMode mode = TrimMode.topLeftColor, Trim sides = Trim.all })
```

Returns a new Image.

![trim orig](images/transform/trim_orig.png) ![trim](images/transform/trim.png)

### [findTrim](https://brendan-duncan.github.io/image/doc/api/image/findTrim.html)

```dart
List<int> findTrim(Image src, { TrimMode mode = TrimMode.transparent, Trim sides = Trim.all })
```
