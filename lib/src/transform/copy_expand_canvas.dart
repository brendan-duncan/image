import '../color/color.dart';
import '../image/image.dart';

enum ExpandCanvasPosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Returns a copy of the [src] image, where the original image has been placed
/// on a new canvas of specified size at a specified location, and the rest of
/// the canvas is filled with the specified color or transparent if
/// no color is provided.
Image copyExpandCanvas(Image src,
    {required int newWidth,
    required int newHeight,
    ExpandCanvasPosition position = ExpandCanvasPosition.center,
    Color? backgroundColor,
    Image? toImage}) {
  // Convert the image if it has a palette
  final Image srcConverted =
      src.hasPalette ? src.convert(numChannels: src.numChannels) : src;

  // Check if new dimensions are larger or equal to the original image
  if (newWidth < srcConverted.width || newHeight < srcConverted.height) {
    throw ArgumentError(
        'New dimensions must be larger or equal to the original image');
  }

  // Check if the provided image has the correct dimensions
  if (toImage != null &&
      (toImage.width != newWidth || toImage.height != newHeight)) {
    throw ArgumentError('Provided image does not match the new dimensions');
  }

  // Create a new Image with the specified dimensions or use the provided image
  final Image expandedCanvas =
      toImage ?? Image(width: newWidth, height: newHeight);

  // If a background color is provided, set all pixels to that color
  // If not, leave them transparent (default behavior)
  if (backgroundColor != null) {
    expandedCanvas.clear(backgroundColor);
  }

  // Define the position where the original image will be put on the new canvas
  int xPos, yPos;

  switch (position) {
    case ExpandCanvasPosition.topLeft:
      xPos = 0;
      yPos = 0;
      break;
    case ExpandCanvasPosition.topCenter:
      xPos = (newWidth - srcConverted.width) ~/ 2;
      yPos = 0;
      break;
    case ExpandCanvasPosition.topRight:
      xPos = newWidth - srcConverted.width;
      yPos = 0;
      break;
    case ExpandCanvasPosition.centerLeft:
      xPos = 0;
      yPos = (newHeight - srcConverted.height) ~/ 2;
      break;
    case ExpandCanvasPosition.center:
      xPos = (newWidth - srcConverted.width) ~/ 2;
      yPos = (newHeight - srcConverted.height) ~/ 2;
      break;
    case ExpandCanvasPosition.centerRight:
      xPos = newWidth - srcConverted.width;
      yPos = (newHeight - srcConverted.height) ~/ 2;
      break;
    case ExpandCanvasPosition.bottomLeft:
      xPos = 0;
      yPos = newHeight - srcConverted.height;
      break;
    case ExpandCanvasPosition.bottomCenter:
      xPos = (newWidth - srcConverted.width) ~/ 2;
      yPos = newHeight - srcConverted.height;
      break;
    case ExpandCanvasPosition.bottomRight:
      xPos = newWidth - srcConverted.width;
      yPos = newHeight - srcConverted.height;
      break;
    default:
      throw ArgumentError('Invalid position provided');
  }

  // Copy the original image to the new frames/canvas
  for (var i = 0; i < srcConverted.numFrames; ++i) {
    // Ensure the frame exists in the expanded canvas
    if (i >= expandedCanvas.numFrames) {
      expandedCanvas.addFrame();
    }

    final frame = srcConverted.frames[i];
    final expandedCanvasFrame = expandedCanvas.frames[i];

    for (final p in frame) {
      // Skip if the pixel position is outside the bounds of the new canvas
      if (xPos + p.x >= newWidth || yPos + p.y >= newHeight) {
        continue;
      }
      expandedCanvasFrame.setPixel(xPos + p.x, yPos + p.y, p);
    }
  }

  return expandedCanvas;
}
