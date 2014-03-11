part of image;

/**
 * Return a random variable between [-1,1].
 */
double crand(Math.Random rand) {
  return 1.0 - 2.0 * rand.nextDouble();
}

/**
 * Return a random variable following a gaussian distribution and a standard
 * deviation of 1.
 */
double grand(Math.Random rand) {
  double x1, w;
  do {
    double x2 = 2.0 * rand.nextDouble() - 1.0;
    x1 = 2.0 * rand.nextDouble() - 1.0;
    w = x1 * x1 + x2 * x2;
  } while (w <= 0.0 || w >= 1.0);

  return x1 * Math.sqrt((-2.0 * Math.log(w))  /w);
}

/**
 * Return a random variable following a Poisson distribution of parameter [z].
 */
int prand(Math.Random rand, double z) {
  if (z <= 1.0e-10) {
    return 0;
  }
  if (z > 100) {
    return ((Math.sqrt(z) * grand(rand)) + z).toInt();
  }
  int k = 0;
  double y = Math.exp(-z);
  for (double s = 1.0; s >= y; ++k) {
    s *= rand.nextDouble();
  }
  return k - 1;
}
