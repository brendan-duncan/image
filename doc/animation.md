# Animated Images

Some image formats, such as GIF, PNG, or WebP, support multiple frames for animation or other purposes.
An Image has a frames list. For non-animated images, the frames list will have a single element, the image
itself. For animated images, the frames list will include the other frames of the animation.

```dart
bool hasAnim = image.hasAnimation; // True if the image has more than 1 frame.
int loopCount = image.loopCount; // The repeat count for the animated image, 0 means repeat forever.
FrameType type = image.frameType; // How frames can be interpreted, as animation, pages, or just a sequence of images.
for (final frame in image.frames) { // Iterate over the frames of the image.
  final frameIndex = frame.frameIndex; // The index of the frame in the frame list.
  final duration = frmae.frameDuration; // The duration of the frame, in milliseconds.
}
```
Frames are always stored as full images, meaning they don't support blend modes, clear states, or partial frames.

## Filters and Transforms for Animated Images

Most filters and transforms will apply to all frames of an animated image.

```dart
// Decode an animated PNG file.
final anim = await decodePngFile('animated.png');
// Resize the animation to 128x*, maintaining the aspect ratio of the frames
final resizedAnim = copyResize(anim, width: 128);
// Apply smoothing to the resized animation
smooth(resizedAnim, weight: 0.8);
// Save the animation to an animated GIF
encodeGifFile('resized_animated.gif', resizedAnim);
```
