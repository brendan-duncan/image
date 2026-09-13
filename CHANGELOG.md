# 4.10.0

* Add lossy WebP encoding with `encodeWebP(lossless: false)` and the `quality`,
  `method` and `alphaQuality` options.
* Improve lossless WebP compression, with file sizes now close to `cwebp`.
* Add the `exact` and `singleFrame` options to `encodeWebP`.
* `WebPEncoder.exact` now defaults to `true`, preserving the color under fully
  transparent pixels at the cost of larger files.
* Fix WebP encoding of 16-bit and grayscale+alpha images.
* Read ICC profiles when decoding WebP files.
* Fix animated WebP frame durations, partial-frame disposal, and the
  background color byte order.
* Fix lossless WebP decoding on the web, where the color cache hash lost
  precision.
* Fix JPEG decoding failing with "Unknown JPEG marker" when a restart marker
  precedes the end of the image (#805).

# 4.9.2

* Add the `DitherKernel.burkes` and `DitherKernel.jarvisJudiceNinke`
  error-diffusion kernels.
* Add ordered (Bayer) matrix dithering via `ditherImageBayer` and the
  `DitherKernel.bayer2x2`, `DitherKernel.bayer4x4`, `DitherKernel.bayer8x8`
  kernels. Unlike the error-diffusion kernels, the pattern is position-based
  and uses a fixed threshold matrix, so it is deterministic and fast.
* Add `DitherScanOrder` (`raster`, `serpentine`, `zigzag`, `hilbert`) and the
  `ditherImage(scanOrder:)` / `quantize(ditherScanOrder:)` /
  `encodeGif(ditherScanOrder:)` / `GifEncoder(ditherScanOrder:)` parameters.
  `zigzag` visits pixels along the anti-diagonals, which breaks up the
  horizontal worm artifacts of raster scanning.
* Fix binary PNM files being misdetected as TGA, by probing PNM before TGA in
  `findDecoderForData`.
* Fix `injectJpgExif` dropping any segment (such as the JFIF APP0 header) that
  precedes the EXIF APP1 block, and losing the embedded EXIF thumbnail.
* Remove xml dependency, replacing it with a minimal built-in parser for the
  bitmap font (.fnt) format.
* Fix `OctreeQuantizer` mapping colors to palette index 0 when their octree
  path hit a folded-away branch, which turned bright pixels near-black once an
  image had more distinct colors than the requested palette size. Palettes
  built from partially-folded internal nodes now include those nodes' entries,
  so the palette also no longer comes up short of `numberOfColors`.

# 4.9.1

* Remove meta dependency.

# 4.9.0

* Fix `minMax` returning incorrect values when the minimum or maximum was in
  the first pixel of a multi-channel image.
* Fix `copyResizeCropSquare` ignoring the crop offset when using non-nearest
  interpolation, which off-centered the resized result.
* Improve the precision of the RGB/XYZ/CIE-Lab color conversions, and round
  rather than truncate the final RGB values, making the conversions lossless.
* Fix `copyResizeCropSquare` throwing a range error when a non-zero radius was
  used with a non-square image.
* Fix non-antialiased `drawLine` drawing diagonal lines offset by ~1 pixel.
* Preserve EXIF metadata when expanding an image with `copyExpandCanvas`.
* `Image.convert` now applies an explicitly provided `alpha` value even when
  the format and channel count are unchanged.
* Fix a range error in `Image.fromBytes` when the source row stride is smaller
  than the image's row stride.
* Fix a `RangeError` when decoding images with corrupt EXIF data.
* Reject non-BMP files that merely start with the `BM` signature instead of
  crashing the decoder.
* Fix `noise` with `NoiseType.saltAndPepper` producing colored pixels instead
  of black/white ones.
* `colorOffset` now scales its offsets to the bit depth of the image, so the
  effect is consistent regardless of the image's format.
* Add `fuzzy` and `padding` options to `trim` and `findTrim`.
* Add `findEncoderForData`, which returns an `Encoder` for a buffer of image
  data, complementing `findDecoderForData`.
* Add a `dispose` option to `GifEncoder` to control the frame disposal method.
* `PsdImage.layers` no longer throws a `LateInitializationError` when accessed
  before `decode` has been called.

# 4.8.0

* Fix JPEG decoding issue with Adobe RGB color transformations.
* Feature: Histogram equalize and stretch 

# 4.7.1

* Fix issue decoding the last row of lossless webp images.

# 4.7.0

* Major update to the WebP decoder to resolve errors decoding some files.
* Fixed issue where App1 marker would not be written when Exif data is injected into jpegs without exif block. Also fixed wrong IFD1 pointer.
* Improved robustness of EXIF injection and reading:
* Skips malformed EXIF sub-IFDs (e.g., bad GPSInfo pointers) during reading and injection, preventing RangeErrors and crashes.
* Allows injecting new EXIF (including GPS) data into files with broken EXIF blocks.

# 4.6.0

* Fix issues with injectJpegExif corrupting jpeg files.
* Clean up validation errors causing Wasm builds to fail.
* Fix issue with Jpeg subsampling causing some images to fail to load.
* Fix rgbToHsv function
* Fix jpeg RGB-to-YUV conversion and background blending logic.
* Decode and encode ICC profile data for JPEG
* Added export for ICO encoder
* Fix error adding frame to an empty image
* Fix GIF decoder animation frame clear color
* GIF animation frame background transparency.
* Fixes for TIFF decoding

# 4.5.4

* Fix for fillRect for images that that have alpha.
* Fix copyExpandCanvas for images with alpha.
* Improved performance for copyResize.
* Improved performance for gaussianBlur.

# 4.5.3

* Improve fillPolygon to better handle concave polygons.
* Update conditional imports to be compatible with WASM.
* Fix TIFF 5-channel CMYK decoding
* Fix adjustColor color corruption
* Improve adjustColor saturation calculations
* Fix alpha color handling in JPEG encoder
* Change the default background color to white instead of black

# 4.5.2

* Reduce Min SDK version to 3.0.

# 4.5.1

* Make image library compatible with archive 3.x

# 4.5.0

* Fix gif animation decoder
* Add ConstColorRgba8, ConstColorRgb8 for const color creation.

# 4.4.0

* Upgrade to Archive 4.0 dependency

# 4.3.0

* Fix exceptions loading some PSD files.
* Fix trim for palette images.
* Fix ICC decompression.
* Add physical size handling to PNG.
* Fix TIFF out of bounds error.

# 4.2.0 * May 22, 2024

* Fix decoding EXIF data from WebP.
* Add ContrastMode.scurve to contrast filter.
* Filter functions will auto-convert palette images
* Add BinaryQuantizer.
* Fix ditherImage not returning dithered image.
* Fix APNG decoding.
* drawString should use alpha color.
* Improve performance of animated GIF decoding.
* Fix TIFF tile decoding
* Add solarize filter function
* Fix decoding TIFF with ZLIB decoding
* Add PNM format decoder.
* Add support for uint16 palettes.

# 4.1.7

* JPEG images will finish decoding even if the file is incomplete or has errors.
* Fix performance bug with Image.getBytes

# 4.1.6

* Incomplete or JPEGs with errors will now finish loading.

# 4.1.5

* Optimize copying bytes in Image.fromBytes
* 2 channel images are treated as Luminance-Alpha

# 4.1.4

* Fix Image.getBytes when ChannelOrder has a different number of channels than the image.
* copyResize command accepts maintainAspect and backgroundColor args.
* Fix EXIF decoder when image has bad IFD offsets.
* Improve drawString handling of new line characters when wrap is true.
* Improve GIF animation decoding when each frame has its own palette.

# 4.1.3

* Fix crash in copyResize for non-nearest interpolation modes.

# 4.1.2

* No changes, removing unnecessary files in 4.1.1.

# 4.1.1

* Add maintainAspect and backgroundColor to copyResize to resize width and
  height of an image, without stretching the source (using background color to pad).
* drawString will word-wrap even when x or y is set.
* Don't clamp brightness in adjustColor.

# 4.1.0

* Update pub dependencies.

# 4.0.18

* Fix reading 64-bit double EXIF values.

# 4.0.17

* Fix resizing multi-frame palette images.
* Fix transparency issue with encodeGif.

# 4.0.16

* Fix GIF decoder not decoding some animation files transparency and frame duration.
* Fix default rowStride for Image.fromBytes.

# 4.0.15

* Fix JPEG encoder for non uint8 format images.

# 4.0.14

* Use Image.backgroundColor for copyRotate, copyCropCircle, and other functions that reveal background pixels.

# 4.0.13

* Fix transform functions for palette images.

# 4.0.12

* Fix EXIF parsing little endian data
* Fix bounds errors with filter functions and palette images.
* Fix BMP encoding palette rgba images by converting them to 32-bit rgba.

# 4.0.11

* Add decodeJpgExif and injectJpgExif functions to process JPG exif data without needing to decode the image.
* Fix EXIF parse exception from empty strings.
* Fix EXIF string data not writing out null character.

# 4.0.10

* Fix last-minute typo from previous release.

# 4.0.9

* Fix offset error with BMP encoder for images with < 8 bits per pixel
* Improve quality of converting 3-channel image to 1-channel.

# 4.0.8

* Fix ChannelOrder.bgra.
* Add Image.hasAlpha getter property that will be true if the Image has an alpha channel.

# 4.0.7

* Fix Image.getRangeIterator skipping last line.

# 4.0.6

* `Image.remapChannels(ChannelOrder order)` to remap the order of channels from rgb to bgr, etc.
* `Image.getBytes({ChannelOrder? order})` will return the image data, optionally reordering the channels.
* Image.fromBytes can take an optional `ChannelOrder? order` named arg to specify the channel order of the input data.

# 4.0.5

* Improved antialiasing for drawLine
* Add antialias arg for drawCircle, fillCircle.
* Added radius argument to drawRect, fillRect, copyCrop, and copyResizeCropSquare to support rounded rectangles.
* Add Image.getPixelClamped method.
* Added TGA decoder 8-bit, 16-bit, 32-bit, and RLE compression modes.

# 4.0.4

* Fix for animated PNG with palette images, which needed a global palette for all frames.
* Fix TIFF encoder for palette images.
* Cleaned up EXIF classes.

# 4.0.3

* Fix for encoding GIF transparency.

# 4.0.2

* No changes, dart formatted code and fix documentation link.

# 4.0.1

* Use strict analyzer settings, clean up warnings.

# 4.0.0

* Major update of the Dart Image Library. Includes support for:
  * Major overhaul of the API. Dart has changed a lot in the 10 years since this library was written,
    so the API has been modernized.
  * Flexible ImageData, with support for 1, 2, 4, 8, 16, and 32 bit images, and 1-4 channels per pixel.
  * 16, 32, and 64-bit floating-point format images.
  * 8, 16, and 32-bit integer format images.
  * Palette images with 1, 2, 4, and 8-bit colors.
  * Improved pixel access API.
  * Merged HDR and Animation functionality into the single Image class.
  * New Command API with support for executing on Isolate threads.
  * New filters and drawing commands.

# 3.3.0

* Improved EXIF data management
* Fix character code issue with BitmapFont.
* This is the last 3.x update before the big 4.0 release.

# 3.2.2

* Fix transparency issue with animated GIF images.

# 3.2.1

* Fixes for APNG: fix exception from some APNG files, and some frames were not composited correctly.

# 3.2.0

* Update SDK dependency to >2.15.0 and XML package dependency to >6.0.0

# 3.1.3

* Optimize Image.getWhiteBalance function, add asDouble argument to return double value.

# 3.1.2

* Add BmpEncoder to encode BMP images, along with encodeBmp function. Currently, only 24-bit or 32-bit BMP images will be encoded.

# 3.1.1

* Fix error loading some tiff images
* Fix jpeg comments to support non-strict utf8 text

# 3.1.0

* Update archive version requirement
* Fix JPGDecoder to return correct nullable types.

# 3.0.8

* Fix WebP lossless decoder.

# 3.0.7

* Change LICENSE to MIT.

# 3.0.6

* Clean up LICENSE file, moving other license references to LICENSE-other.

# 3.0.5

* Fix copyResize for landscape oriented images.

# 3.0.4

* Fix Dart warnings from the previous release.

# 3.0.3

* Fix #320 * copyResize incorrectly applies linear and cubic.
* Apply EXIF orientation when decoding JPEG images.

# 3.0.2

* Dithering support for GIF encoder.
* Fix PNGEncoder issue if addFrame is called directly instead than encodeImage or encodeAnimation.
* Optimization for drawImage.

# 3.0.1

* Improve NeuralQuantizer to fix issue encoding small GIF images.
* Code cleanup resolving lint issues.

# 3.0.0

* Migrate to null safety.

# 2.1.19

* Refactor HdrImage to better support more diverse formats, used for Hdr Tiff decoding.
* TiffDecoder will maintain Tag data after decoding, allowing them to be read to process image metadata.
* Added TiffEncoder. Still needs work to be able to add tag data to an encoded image.
* Clean up print statements from BmpDecoder.

# 2.1.18

* Added 64-bit float format to TIFF decoder.
* Fixed issues with TiffDecoder.decodeHdrImage.
* Added range clamping to copyCrop to avoid out-of-bound errors.
* Variable FPS for animated GIF encoding.

# 2.1.17

* Added 32-bit float and 16-bit half-float formats to the TIFF decoder.

# 2.1.16

* Downgrade Meta dependency to be compatible with flutter_test in the stable channel.

# 2.1.15

* Fix Image.getBytes for cropping images
* Fix bakeOrientation EXIF data
* Added ICO format decoder
* Fix JpegData.validate for unintended exceptions with non jpeg images

# 2.1.14

* Update xml dependency to 4.2.0

# 2.1.13

* Improvements for JPEG EXIF decoding
* Fix for the GIF animation decoder
* APNG encoder time delay correctly to milliseconds

# 2.1.12

* drawChar now uses color parameter.
* Fix index out of range bug in drawImage.
* Fix transparency with animated WebP images.

# 2.1.11

* Fix GIF animation loopCount encoding. Some viewers were not seeing the repeat count correctly.
* Resolve analysis warnings.

# 2.1.10

* Applied Pub's Health suggestions.
* Optimize use of slow typed_data methods.
* Add drawStringCentered function
* Add fillCircle function
* Fix drawLine thickness for axis-aligned lines

# 2.1.9

* JpegDecoder optimizations. Decoding an 8k jpeg went from 2048ms to 1340ms.

# 2.1.8

* Fix issue with XML parsing for font files not reading some files
* Fix bug with trim function for non-transparent trim mode

# 2.1.7

* Add ICO and CUR encoder.
* Fix BMP decoder for top-down BMP image files.

# 2.1.6

* Add BMP decoder, currently only supporting 24-bit and 32-bit non compressed BMP images. (Thanks Ryan Kauk)

# 2.1.5

* Updated some tests to use `test`-syntax.
* Fixed null value in `GifEncoder`.
* Added Dart syntax highlighting in the readme file.
* Formatted package using `dartfmt`.
* Fixed "Unnecessary new" and other Dart analyzer warnings.
* Added the `samplingFactor` parameter to GIF encoding, which allows to significantly speed up
  encoding times of GIF encoding.

# 2.1.4

* Optimize fillRect, drawPixel, and other drawing functions when opaque colors are used.

# 2.1.3

* Revert the internal color format to #AABBGGRR.

# 2.1.2

* Fix crash decoding some Jpeg images.
* Fix infinite recursion crash with fillFlood when fill color is the same as the start pixel color.

# 2.1.1

* Fix typo and missing license in license file.

# 2.1.0

* Big API clean-up to bring it up to a more modern Dart syntax.

# 2.0.9

* Use strict dartanalysys settings and clean up code.

# 2.0.8

* Add ability to quantize an image to any number of colors.
* Optimizations for the JPEG decoder.
* Use #AARRGGBB for colors instead of #AABBGGRR, to be compatible with Flutter image class.
* Add floodfill drawing function.
* CopyRectify to transform an arbitrary quad to the full image.
* Improve performance of CopyResize.

# 2.0.7

* Improve JPEG decoding performance.
* Decode and encode ICC profile data from PNG images.

# 2.0.6

* bakeOrientation will clear the image's exif orientation properties.
* copyResize will correctly maintain the image's orientation.

# 2.0.5

* Added APNG (animated PNG) encoding.
* Optimized drawString function.

# 2.0.3

* copyResize can maintain aspect ratio when resizing height by using -1 for the width.
* Added example for loading and processing images in an isolate.

# 2.0.2

* Re-added decoding of orientation exif value from jpeg images.
* Added bake_orientation function, which will rotate an image so that it physically matches its orientation exif value,
  useful for rotating an image prior to exporting it to a format that does not support exif data.

# 2.0.1

Fix for bad jpeg files when encoding EXIF data.

# 2.0.0

Remove the use of Dart 1 upper-case constants.
Update SDK dependency to a 2.0 development release.

# 1.1.33

Maintain EXIF data from JPEG images.

# 1.1.32

Remove the use of `part` and `part of` in the main library.

# 1.1.30

Update pubspec to account for the new version of xml package that has been
published.

# 1.1.29

* Add fixes for strong mode support.

# 1.1.28

* Update pubspec to fix recent pub issues.
* Rename changelog.txt to CHANGELOG.md.
* Fix for 8-bit PNG decoding.

# 1.1.27

* Fix crash decoding some jpeg images.

# 1.1.24

* PVR encoding/decoding
* Fix 16-bit tiff decoding

# 1.1.23

* Fix alpha for PSD images.

# 1.1.22

* Various bug fixes

# 1.1.21

* Add drawImage function
* Update XML dependency to 2.0.0

# 1.1.20

* Fix OpenEXR decoder for dart2js

# 1.1.19

* OpenEXR fixes.

# 1.1.18

* Added OpenEXR format decoder.

# 1.1.17

* Add Photoshop PSD format decoder

# 1.1.16

* Fix JPEG encoder for compression quality < 100.

# 1.1.15

* Update to new version of archive.

# 1.1.14

* Optimizations

# 1.1.13

* Added TIFF decoder

# 1.1.10

* Added APNG animated PNG decoding support.
* Improved JPEG decoding performance
* Various bug fixes

# 1.1.8

* Added GIF decoding support, including animated gifs.

# 1.1.7

* Added WebP decoding support, included animated WebP.
