# Animated Images

GIF, PNG (APNG) and WebP files can hold an animation. TIFF and PSD files can hold several pages, and ICO
files several sizes of an icon. The library stores all of these the same way: as a list of frames on an
[Image](image_data.md).

## How frames are stored

Every `Image` has a `frames` list. The first frame is the image itself, so a still image has one frame and
an animated image has more than one.

| Member | Description |
|---|---|
| `frames` | The list of frames. `frames[0]` is the image itself. |
| `numFrames` | `frames.length`. |
| `hasAnimation` | True if there's more than one frame. |
| `getFrame(int index)` | The frame at `index`. |
| `addFrame([Image? image])` | Append a frame and return it. With no argument, adds a new blank frame with the same size and format. |
| `frameIndex` | The index of a frame in its animation's `frames` list. |
| `frameDuration` | How long the frame is shown, in milliseconds. 0 means no delay. |
| `loopCount` | How many times the animation plays, 0 for forever. Read it from the first frame. |
| `frameType` | How the frames should be interpreted: `FrameType.animation`, `FrameType.page` or `FrameType.sequence`. |

```dart
final anim = await img.decodeGifFile('animated.gif');
if (anim != null && anim.hasAnimation) {
  print('${anim.numFrames} frames, loop count ${anim.loopCount}');
  for (final frame in anim.frames) {
    print('frame ${frame.frameIndex}: ${frame.frameDuration} ms');
  }
}
```

Frames are always stored as complete images: each frame is the full size of the animation's canvas, with
every pixel of the picture shown at that point. There are no partial frames, blend modes or disposal
methods on a decoded `Image`; the decoders apply them while decoding (see
[Compositing and disposal](#compositing-and-disposal)).

`frameType` is set to `FrameType.page` by the TIFF and PSD decoders. The GIF, PNG and WebP decoders leave
it at the default, `FrameType.sequence`, so don't rely on it to tell whether a decoded image is an
animation; use `hasAnimation`. The encoders don't look at `frameType`.

## Decoding animations

The decoders for GIF, PNG and WebP read all frames of an animated file by default, along with the frame
durations and, for GIF and WebP, the loop count:

```dart
final gif = img.decodeGif(gifBytes);
final apng = img.decodePng(pngBytes);
final webp = img.decodeWebP(webpBytes);
// Or let the library find the format.
final any = img.decodeImage(bytes);
print([gif, apng, webp, any].map((i) => i?.numFrames));
```

| Format | What the frames are | Notes |
|---|---|---|
| GIF | Animation | Palette images. Delays are stored in 1/100 s and converted to milliseconds. |
| PNG (APNG) | Animation | Delays converted to milliseconds. The APNG loop count isn't copied to `loopCount`; read it from `PngDecoder().info.repeat`. |
| WebP | Animation | |
| TIFF, PSD | Pages | `frameType` is `FrameType.page`. |
| ICO | Icon sizes | Frames can have different sizes. |

### Compositing and disposal

GIF, APNG and animated WebP files usually store each frame as a change to the previous one: a rectangle
smaller than the canvas, blended onto what's already there, and a disposal method saying what happens to
it before the next frame is drawn. The decoders do this work for you: they composite each frame onto the
canvas, applying the blend mode and the previous frame's disposal, and store the result as a full-canvas
frame. Every frame in `image.frames` can be shown or processed on its own.

The cost is memory: an animation decodes to `numFrames` full images, so a 100-frame 1000 × 1000 RGBA
animation takes about 400 MB. If you need only some frames, decode them individually.

### Decoding one frame at a time

To decode a single frame, pass `frame` to any decode function. Only that frame is decoded:

```dart
// The first frame only, for example for a thumbnail or a preview.
final firstFrame = img.decodeImage(bytes, frame: 0);
```

For more control, use a decoder's `startDecode`, `numFrames` and `decodeFrame`. `startDecode` reads the
file's structure without decoding pixels, and `decodeFrame` decodes one frame on request:

```dart
final decoder = img.GifDecoder();
final info = decoder.startDecode(bytes);
if (info != null) {
  for (var i = 0; i < decoder.numFrames(); ++i) {
    final frame = decoder.decodeFrame(i);
    if (frame == null) continue;
    // Position and timing of the frame on the canvas.
    final desc = info.frames[i];
    print('frame $i: ${frame.width}x${frame.height} at ${desc.x},${desc.y}, '
        '${desc.duration * 10} ms');
  }
}
```

A frame decoded on its own, with `frame` or `decodeFrame`, is the frame **as stored in the file**: it isn't
composited onto the earlier frames, its disposal and blending aren't applied, and for GIF, APNG and WebP
it may be a rectangle smaller than the canvas. Frame 0 is usually the full first picture. For later frames,
the position and timing are in the decoder's info:

| Decoder | Frame information |
|---|---|
| `GifDecoder` | `info.frames[i]` (`GifImageDesc`): `x`, `y`, `width`, `height`, `duration` (1/100 s), `disposal` |
| `PngDecoder` | `info.frames[i]` (`PngFrame`): `xOffset`, `yOffset`, `width`, `height`, `delay` (seconds), `dispose`, `blend` |
| `WebPDecoder` | `info!.frames[i]` (`WebPFrame`): `x`, `y`, `width`, `height`, `duration` (ms), `clearFrame`, `blendFrame` |

The `frameDuration` of a frame decoded this way isn't set; take it from the frame information.

## Creating an animation

Build an animation by adding frames to the first image. Each frame should have the same size as the first,
and its own `frameDuration`:

```dart
img.Image makeAnimation() {
  final anim = img.Image(width: 64, height: 64, frameDuration: 100)
    ..loopCount = 0; // Loop forever.
  img.fillCircle(anim, x: 8, y: 32, radius: 8, color: img.ColorRgb8(255, 0, 0));

  for (var i = 1; i < 8; ++i) {
    final frame = img.Image(width: 64, height: 64, frameDuration: 100);
    img.fillCircle(frame, x: 8 + i * 7, y: 32, radius: 8, color: img.ColorRgb8(255, 0, 0));
    anim.addFrame(frame);
  }
  return anim;
}
```

`addFrame()` with no argument adds a blank frame with the same size and format as the image, which you can
then draw into.

## Encoding animations

The GIF, PNG and WebP encoders write every frame of an image with more than one frame. Pass
`singleFrame: true` to write only the first.

```dart
final anim = makeAnimation();
final gif = img.encodeGif(anim);
final apng = img.encodePng(anim);
final webp = img.encodeWebP(anim); // Lossless; pass lossless: false for lossy frames.
await img.encodeImageFile('anim.gif', anim);
```

| Format | Frame durations | Loop count | Notes |
|---|---|---|---|
| GIF | Stored in 1/100 s, so rounded down to a multiple of 10 ms. | `loopCount` | Each frame is quantized to its own 256-color palette. |
| PNG (APNG) | Milliseconds. | `loopCount` | Palette animations are given one palette shared by all frames. |
| WebP | Milliseconds. | `loopCount` | Every frame must fit within the first frame's size. |

The encoders write every frame as a full image, not as a change from the previous frame, so files can be
larger than the original animation they were decoded from. All frames should be the same size as the first
frame.

Formats without animation (JPEG, BMP, TGA, TIFF, PVR) write only the first frame. ICO and CUR write each
frame as a separate icon.

### Encoding frame by frame

`GifEncoder` and `PngEncoder` can encode frames as you produce them, without building the whole animation
in memory first.

```dart
Uint8List? encodeGifFrames(List<img.Image> frames) {
  final encoder = img.GifEncoder(repeat: 0);
  for (final frame in frames) {
    // GIF durations are in 1/100 seconds.
    encoder.addFrame(frame, duration: frame.frameDuration ~/ 10);
  }
  return encoder.finish();
}

Uint8List? encodePngFrames(List<img.Image> frames) {
  final encoder = img.PngEncoder()..repeat = 0; // Loop forever.
  encoder.start(frames.length); // The number of frames must be known up front.
  for (final frame in frames) {
    encoder.addFrame(frame); // Uses frame.frameDuration.
  }
  return encoder.finish();
}
```

## Filters and transforms on animations

Most filters and transforms apply to every frame of an animated image:

```dart
// Decode an animated PNG file.
final anim = await img.decodePngFile('animated.png');
if (anim != null) {
  // Resize the animation to 128 pixels wide, keeping the aspect ratio.
  final resized = img.copyResize(anim, width: 128);
  // Smooth every frame of the resized animation.
  img.smooth(resized, weight: 0.8);
  // Save it as an animated GIF.
  await img.encodeGifFile('resized_animated.gif', resized);
}
```

Some functions work on a single frame, the image you pass: for example `quantize`, `ditherImage`,
`hdrToLdr` and `reinhardTonemap`. Loop over `image.frames` to apply them to every frame. See
[Image Processing](filters.md) and [Transform Functions](transform.md).
