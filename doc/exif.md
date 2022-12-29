# EXIF Data

Some image files can contain EXIF data, which is additional metadata about the image. When you decode an image,
any EXIF data decoded will be stored in the Image.exif property.

```dart
// Load a jpeg image file
final image = decodeJpgFile('big_buck_bunny.jpg');
if (image != null) {
  // Modify the exif data of the image, setting its XResolution and YResolution EXIF properties to 300:1.
  image.exif.imageIfd['XResolution'] = [300,1];
  image.exif.imageIfd['YResolution'] = [300, 1];
  // Save the jpeg with the modified EXIF data.
  encodeJpgFile('big_buck_bunny_modified.jpg', image);
}
```
