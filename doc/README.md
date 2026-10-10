# Dart Image Library

The Dart Image Library loads, saves and manipulates images in many file formats. It's written in pure Dart, so
it works in command-line apps, servers, Flutter (mobile, desktop and web) and the browser.

## Getting started

- [Tutorial](tutorial.md): add the library, decode, inspect, process and encode images, with recipes.
- [Flutter](flutter.md): use the library in Flutter apps, off the UI thread, and convert to and from `dart:ui` images.

## Guides

- [Image Formats](formats.md): supported file formats, decoders, encoders and their options.
- [Image Data](image_data.md): the `Image` class, pixel formats, channels, palettes, colors and pixel access.
- [Commands and Async Execution](commands.md): chain operations and run them on a separate isolate.
- [Image Processing](filters.md): color adjustment, blur, effects and other filters.
- [Color Quantization and Dithering](color_quantization.md): reduce an image to a palette, with dithering.
- [Transform Functions](transform.md): resize, crop, rotate, flip and trim.
- [Drawing Functions](draw.md): lines, shapes, fills, text and compositing.
- [Font Rendering](fonts.md): draw text with the built-in or your own bitmap fonts.
- [EXIF Data](exif.md): read and write EXIF metadata, including orientation.
- [High Dynamic Range Images](hdr.md): floating point images and tone mapping.
- [Animated Images](animation.md): decode, create and encode animated GIF, PNG and WebP images.
- [Performance](performance.md): make decoding and processing faster and use less memory, on phones and desktops.

## Reference

- [API reference](https://pub.dev/documentation/image/latest): every class and function.
- [Changelog](https://github.com/brendan-duncan/image/blob/main/CHANGELOG.md)
- [Issues](https://github.com/brendan-duncan/image/issues)
