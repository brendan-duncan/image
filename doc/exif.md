# EXIF Data

EXIF data is metadata stored in an image file: the camera make and model, the date a photo was taken,
exposure settings, the orientation of the camera, GPS location, and so on. When you decode an image, any
EXIF data the decoder finds is stored in `Image.exif`, and encoders that support EXIF write it back out.

| Format | Reads EXIF | Writes EXIF |
|---|---|---|
| JPEG | Yes | Yes |
| TIFF | Yes (the TIFF tags are EXIF tags) | `imageIfd` and its sub-IFDs |
| WebP | Yes | Yes |
| PNG, GIF, BMP, TGA, others | No | No |

```dart
final image = await img.decodeJpgFile('photo.jpg');
if (image != null) {
  final ifd0 = image.exif.imageIfd;
  print('Camera: ${ifd0.make} ${ifd0.model}');
  print('Taken: ${image.exif.exifIfd['DateTimeOriginal']}');
}
```

`image.exif` creates an empty `ExifData` the first time you read it if the image has none, so use
`image.hasExif` to check whether an image has EXIF data without adding it. Assigning
`image.exif = ExifData()` replaces all of it.

## How EXIF data is organized

EXIF data is a set of directories (IFDs) of tags. Each tag has a numeric ID, a name, and a typed value.

| `ExifData` member | Directory | Contents |
|---|---|---|
| `imageIfd` | `ifd0` | The main image: make, model, orientation, resolution, software, date/time, … |
| `exifIfd` | sub-IFD `exif` of ifd0 | Photo details: exposure, f-number, ISO, `DateTimeOriginal`, lens, … |
| `gpsIfd` | sub-IFD `gps` of ifd0 | GPS location, altitude, time stamp. |
| `interopIfd` | sub-IFD `interop` of ifd0 | Interoperability information. |
| `thumbnailIfd` | `ifd1` | Tags describing the embedded thumbnail. |
| `thumbnailData` | | The embedded JPEG thumbnail bytes, if there is one. |
| `directories` | | All top-level directories by name (`ifd0`, `ifd1`, …). |

The getters create the directory if it doesn't exist yet, and an empty sub-IFD that you created is still
written to the file. To test whether a directory exists, use `exif.containsKey('ifd1')`, or
`exif.imageIfd.sub.containsKey('gps')` for the sub-IFDs.

## Reading tags

Index an [`IfdDirectory`](https://pub.dev/documentation/image/latest/image/IfdDirectory-class.html) by tag
name or by tag ID. The result is an `IfdValue`, or null if the tag isn't there:

```dart
final ifd0 = image.exif.imageIfd;
final make = ifd0['Make']; // By name.
final orientation = ifd0[0x0112]; // By ID.
print('${make?.toString()} ${orientation?.toInt()}');
```

`IfdValue` converts to the type you need. A tag can hold several values; pass an index to read the others.

| `IfdValue` member | Description |
|---|---|
| `toInt([int index = 0])` | The value as an int. |
| `toDouble([int index = 0])` | The value as a double (rationals are divided out). |
| `toRational([int index = 0])` | A rational value, with `numerator` and `denominator`. |
| `toString()` | Text tags as a string; other tags as a readable value. |
| `toData()` | The raw bytes. |
| `length` | The number of values. |
| `type` | The `IfdValueType`. |

Tag names come from the tables `exifImageTags` (ifd0 and the exif sub-IFD), `exifGpsTags` and
`exifInteropTags`, each mapping a tag ID to an `ExifTag` with its `name` and `type`. `exifTagNameToID` maps
names to IDs. To list every tag of an image:

```dart
void printExif(img.ExifData exif) {
  for (final name in exif.keys) {
    final ifd = exif[name];
    for (final tag in ifd.keys) {
      print('$name ${exif.getTagName(tag)}: ${ifd[tag]}');
    }
    for (final subName in ifd.sub.keys) {
      final sub = ifd.sub[subName];
      final names = subName == 'gps' ? img.exifGpsTags : img.exifImageTags;
      for (final tag in sub.keys) {
        print('$subName ${names[tag]?.name ?? tag}: ${sub[tag]}');
      }
    }
  }
}
```

`exif.toString()` also prints all tags. Both it and `getTagName` look names up in `exifImageTags` only, so
the names they give for GPS and interop tags aren't correct.

### Named properties

`IfdDirectory` has properties for common tags. Each has a `hasXxx` test, and setting it to null removes the
tag.

| Property | Tag | Type |
|---|---|---|
| `make`, `model`, `software`, `copyright`, `imageDescription` | `Make`, `Model`, `Software`, `Copyright`, `ImageDescription` | `String?` |
| `userComment` | `UserComment` (exif sub-IFD) | `String?` |
| `orientation` | `Orientation` | `int?` |
| `xResolution`, `yResolution` | `XResolution`, `YResolution` | rational (set with `[numerator, denominator]`) |
| `resolutionUnit` | `ResolutionUnit` | `int?` (2 = inch, 3 = centimeter) |
| `imageWidth`, `imageHeight` | `ImageWidth`, `ImageLength` | `int?` |
| `gpsLatitude`, `gpsLongitude`, `gpsLatitudeRef`, `gpsLongitudeRef`, `gpsDate` | GPS tags (gps sub-IFD) | see [GPS](#gps-location) |

```dart
final ifd0 = image.exif.imageIfd;
if (ifd0.hasXResolution) {
  final res = ifd0.xResolution!;
  print('${res.numerator / res.denominator} pixels per unit');
}
ifd0.software = 'My App';
ifd0.copyright = null; // Remove the tag.
```

## Writing tags

Assign a value to a tag by name or ID. Set a tag to null to remove it.

```dart
final ifd0 = image.exif.imageIfd;
ifd0['XResolution'] = [300, 1]; // A rational: [numerator, denominator].
ifd0['YResolution'] = [300, 1];
ifd0['ResolutionUnit'] = 2; // Inches.
ifd0['Artist'] = 'Jane Doe';
image.exif.exifIfd['DateTimeOriginal'] = '2024:06:01 12:00:00';
ifd0['ImageDescription'] = null; // Remove the tag.
```

A plain value (`int`, `double`, `String`, `List<int>`, or `[numerator, denominator]` for rationals) is
converted to the tag's type from `exifImageTags`. That only works for tags in that table. For other tags,
including the GPS tags, and to choose the type yourself, assign an `IfdValue`; a plain value assigned to a
tag the table doesn't know is silently ignored.

| `IfdValue` class | EXIF type | Constructors |
|---|---|---|
| `IfdByteValue` | BYTE (uint8) | `IfdByteValue(int)`, `.list(Uint8List)` |
| `IfdValueAscii` | ASCII | `IfdValueAscii(String)` |
| `IfdValueShort` | SHORT (uint16) | `IfdValueShort(int)`, `.list(List<int>)` |
| `IfdValueLong` | LONG (uint32) | `IfdValueLong(int)`, `.list(List<int>)` |
| `IfdValueRational` | RATIONAL | `IfdValueRational(numerator, denominator)`, `.list(...)` |
| `IfdValueSByte` | SBYTE (int8) | `IfdValueSByte(int)`, `.list(List<int>)` |
| `IfdValueUndefined` | UNDEFINED (raw bytes) | `IfdValueUndefined.list(List<int>)` |
| `IfdValueSShort` | SSHORT (int16) | `IfdValueSShort(int)`, `.list(List<int>)` |
| `IfdValueSLong` | SLONG (int32) | `IfdValueSLong(int)`, `.list(List<int>)` |
| `IfdValueSRational` | SRATIONAL | `IfdValueSRational(numerator, denominator)`, `.list(...)` |
| `IfdValueSingle` | FLOAT | `IfdValueSingle(double)`, `.list(List<double>)` |
| `IfdValueDouble` | DOUBLE | `IfdValueDouble(double)`, `.list(List<double>)` |

```dart
image.exif.exifIfd[0x8827] = img.IfdValueShort(400); // ISO sensitivity
image.exif.imageIfd[0x9c9b] = img.IfdByteValue.list(Uint8List.fromList([0x41, 0, 0, 0])); // XPTitle
```

The changes are saved when you encode the image to a format that writes EXIF:

```dart
final bytes = img.encodeJpg(image);
```

## GPS location

GPS tags live in `exif.gpsIfd`. In standard EXIF files, `GPSLatitude` and `GPSLongitude` are three
rationals (degrees, minutes, seconds), and `GPSLatitudeRef` / `GPSLongitudeRef` are `N`/`S` and `E`/`W`.
To read them:

```dart
double? readCoordinate(img.IfdDirectory gps, String tag, String refTag) {
  final value = gps[tag];
  if (value == null || value.length < 3) {
    return null;
  }
  final degrees = value.toDouble(0) + value.toDouble(1) / 60 + value.toDouble(2) / 3600;
  final ref = gps[refTag]?.toString();
  return (ref == 'S' || ref == 'W') ? -degrees : degrees;
}

void printLocation(img.Image image) {
  if (image.hasExif && image.exif.imageIfd.sub.containsKey('gps')) {
    final gps = image.exif.gpsIfd;
    final lat = readCoordinate(gps, 'GPSLatitude', 'GPSLatitudeRef');
    final lon = readCoordinate(gps, 'GPSLongitude', 'GPSLongitudeRef');
    print('$lat, $lon');
  }
}
```

To write them in the standard form, assign `IfdValue`s (plain values aren't converted for GPS tags):

```dart
void setLocation(img.Image image, double latitude, double longitude) {
  // Degrees, minutes and seconds as rationals; seconds to 1/100.
  img.IfdValue dms(double value) {
    final v = value.abs();
    final d = v.floor();
    final m = ((v - d) * 60).floor();
    final s = ((v - d - m / 60) * 3600 * 100).round();
    return img.IfdValueRational.list([
      img.IfdValueRational(d, 1).toRational(),
      img.IfdValueRational(m, 1).toRational(),
      img.IfdValueRational(s, 100).toRational(),
    ]);
  }

  final gps = image.exif.gpsIfd;
  gps['GPSVersionID'] = img.IfdByteValue.list(Uint8List.fromList([2, 3, 0, 0]));
  gps['GPSLatitudeRef'] = img.IfdValueAscii(latitude < 0 ? 'S' : 'N');
  gps['GPSLatitude'] = dms(latitude);
  gps['GPSLongitudeRef'] = img.IfdValueAscii(longitude < 0 ? 'W' : 'E');
  gps['GPSLongitude'] = dms(longitude);
}
```

`IfdDirectory` also has `setGpsLocation(latitude: ..., longitude: ...)` and the `gpsLatitude`,
`gpsLongitude`, `gpsLatitudeRef` and `gpsLongitudeRef` properties. Be aware that these store each coordinate
as a single DOUBLE value rather than the three RATIONAL values the EXIF standard specifies, so other
software may not read them, and the `gpsLatitude`/`gpsLongitude` getters read only the first value, which
for camera files is the whole degrees without the minutes and seconds.

To remove the location, for example before sharing a photo:

```dart
image.exif.imageIfd.sub.directories.remove('gps');
```

## Orientation

Cameras often store photos in the sensor's orientation and record how to rotate them in the `Orientation`
tag:

| Value | Meaning |
|---|---|
| 1 | Normal |
| 2 | Flipped horizontally |
| 3 | Rotated 180° |
| 4 | Flipped vertically |
| 5 | Transposed (flipped horizontally, then rotated 90° counter-clockwise) |
| 6 | Needs a 90° clockwise rotation to display |
| 7 | Transverse (flipped horizontally, then rotated 90° clockwise) |
| 8 | Needs a 90° counter-clockwise rotation to display |

The JPEG decoder applies the orientation while decoding, so a decoded JPEG is already upright, and its
`Orientation` tag is removed. For images from other formats, or images where you set the tag yourself,
[`bakeOrientation`](transform.md#bakeorientation) returns a copy rotated and flipped to match the tag, with
the tag removed and the rest of the EXIF data kept:

```dart
final tiff = img.decodeTiff(bytes)!;
final upright = img.bakeOrientation(tiff);
```

## Reading and writing EXIF without decoding pixels

For JPEG files, you can read or replace the EXIF data without decoding or re-encoding the image. This is
fast and doesn't lose any quality.

```dart
ExifData? decodeJpgExif(Uint8List jpeg);

Uint8List? injectJpgExif(Uint8List jpeg, ExifData exif);
```

`decodeJpgExif` returns null if the data isn't a JPEG or has no EXIF data. `injectJpgExif` returns new JPEG
bytes with the EXIF block replaced (or added, if there wasn't one), or null if the data isn't a JPEG.
Passing an empty `ExifData` removes the EXIF block.

```dart
Future<void> stripLocation(String path) async {
  final bytes = await File(path).readAsBytes();
  final exif = img.decodeJpgExif(bytes);
  if (exif == null) {
    return;
  }
  exif.imageIfd.sub.directories.remove('gps');
  final output = img.injectJpgExif(bytes, exif);
  if (output != null) {
    await File(path).writeAsBytes(output);
  }
}

// Remove all EXIF data from a JPEG.
Uint8List? stripExif(Uint8List jpeg) => img.injectJpgExif(jpeg, img.ExifData());
```

## Copying EXIF between images

`ExifData.from(other)` and `exif.clone()` make deep copies. Functions that make a modified copy of an
image, such as `copyResize`, `copyCrop` and `Image.from`, copy its EXIF data too. An image you create
yourself starts without EXIF data, so copy it explicitly:

```dart
final canvas = img.Image(width: photo.width, height: photo.height);
img.compositeImage(canvas, photo);
canvas.exif = img.ExifData.from(photo.exif);
```
