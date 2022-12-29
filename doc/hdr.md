# High Dynamic Range Images

The Dart Image Library supports high dynamic ranges. Normal images (low dynamic range), such as the usual RGBA 8-bit
images, have a maximum brightness of 1. That is, they store colors in the range [0, 255], where 255 is the full
intensity of the color channel.

High dynamic range images store pixel color values as floating-point, and can store color values greater than an
intensity of 1.0.

Only some image file formats support high dynamic range images, such as EXR and TIFF.
