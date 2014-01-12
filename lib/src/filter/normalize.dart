part of image;

/**
 * Linearly normalize the colors of the image.
 */
Image normalize(Image image, int minValue, int maxValue) {
  int A = minValue < maxValue ? minValue : maxValue;
  int B = minValue < maxValue ? maxValue : minValue;

  List mM = minMax(image);
  int m = mM[0];
  int M = mM[1];

  double fm = m.toDouble();
  double fM = M.toDouble();

  if (m == M) {
    return fill(image, minValue);
  }

  if (m != A || M != B) {
    final int len = image.length;
    for (int i = 0; i < len; ++i) {
      int c = image[i];
      int r = getRed(c);
      int g = getGreen(c);
      int b = getBlue(c);
      int a = getAlpha(c);
      r = ((r - fm) / (fM - fm) * (B - A) + A).toInt();
      g = ((g - fm) / (fM - fm) * (B - A) + A).toInt();
      b = ((b - fm) / (fM - fm) * (B - A) + A).toInt();
      a = ((a - fm) / (fM - fm) * (B - A) + A).toInt();
      image[i] = getColor(r, g, b, a);
    }
  }
}
