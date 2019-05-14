import 'dart:html';
import 'dart:math';
import 'package:image/image.dart';

double logN(num x, num div) {
  return log(x) / div;
}

/// Render the Mandelbrot Set into an Image and display it.
void main() {
  const int width = 1024;
  const int height = 1024;

  // Create a canvas to put our decoded image into.
  var c = CanvasElement(width: width, height: height);
  document.body.append(c);

  double zoom = 1.0;
  double moveX = -0.5;
  double moveY = 0.0;
  const int MaxIterations = 255;
  const double radius = 2.0;
  const double radius_squared = radius * radius;
  final double log2 = log(2.0);
  double Log2MaxIterations = logN(MaxIterations, log2);
  const double h_2 = height / 2.0;
  const double w_2 = width / 2.0;
  const double aspect = 0.5;

  Image image = Image(width, height);
  for (int y = 0; y < height; ++y) {
    double pi = (y - h_2) / (0.5 * zoom * aspect * height) + moveY;

    for (int x = 0; x < width; ++x) {
      double pr = 1.5 * (x - w_2) / (0.5 * zoom * width) + moveX;

      double newRe = 0.0;
      double newIm = 0.0;
      int i = 0;
      for (; i < MaxIterations; i++) {
        double oldRe = newRe;
        double oldIm = newIm;

        newRe = oldRe * oldRe - oldIm * oldIm + pr;
        newIm = 2.0 * oldRe * oldIm + pi;

        if ((newRe * newRe + newIm * newIm) > radius_squared) {
          break;
        }
      }

      if (i == MaxIterations) {
        image.setPixelRgba(x, y, 0, 0, 0);
      } else {
        double z = sqrt(newRe * newRe + newIm * newIm);
        double b = 256.0 *
            logN(1.75 + i - logN(logN(z, log2), log2), log2) /
            Log2MaxIterations;
        int brightness = b.toInt();
        image.setPixelRgba(x, y, brightness, brightness, 255);
      }
    }
  }

  // Create a buffer that the canvas can draw.
  ImageData d = c.context2D.createImageData(image.width, image.height);
  // Fill the buffer with our image data.
  d.data.setRange(0, d.data.length, image.getBytes(format: Format.rgba));
  // Draw the buffer onto the canvas.
  c.context2D.putImageData(d, 0, 0);
}
