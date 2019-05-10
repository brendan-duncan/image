import 'dart:math';
import 'dart:typed_data';

import 'hdr_image.dart';

/// Applies an HDR bloom filter to the image, in-place.
HdrImage hdrBloom(HdrImage hdr, {double radius = 0.01, double weight = 0.1}) {
  double _lerp(double t, double a, double b) => (1.0 - t) * a + t * b;

  //int nPix = xResolution * yResolution;
  // Possibly apply bloom effect to image
  if (radius > 0.0 && weight > 0.0) {
    // Compute image-space extent of bloom effect
    int bloomSupport = (radius * max(hdr.width, hdr.height)).ceil();
    int bloomWidth = bloomSupport ~/ 2;
    // Initialize bloom filter table
    Float32List bloomFilter = Float32List(bloomWidth * bloomWidth);
    for (int i = 0; i < bloomWidth * bloomWidth; ++i) {
      double dist = sqrt(i / bloomWidth);
      bloomFilter[i] = pow(max(0.0, 1.0 - dist), 4.0).toDouble();
    }

    // Apply bloom filter to image pixels
    Float32List bloomImage = Float32List(3 * hdr.width * hdr.height);
    for (int y = 0, offset = 0; y < hdr.height; ++y) {
      for (int x = 0; x < hdr.width; ++x, ++offset) {
        // Compute bloom for pixel _(x,y)_
        // Compute extent of pixels contributing bloom
        int x0 = max(0, x - bloomWidth);
        int x1 = min(x + bloomWidth, hdr.width - 1);
        int y0 = max(0, y - bloomWidth);
        int y1 = min(y + bloomWidth, hdr.height - 1);

        double sumWt = 0.0;
        for (int by = y0; by <= y1; ++by) {
          for (int bx = x0; bx <= x1; ++bx) {
            // Accumulate bloom from pixel $(bx,by)$
            int dx = x - bx;
            int dy = y - by;
            if (dx == 0 && dy == 0) {
              continue;
            }
            int dist2 = dx * dx + dy * dy;
            if (dist2 < bloomWidth * bloomWidth) {
              //int bloomOffset = bx + by * hdr.width;
              double wt = bloomFilter[dist2];

              sumWt += wt;

              bloomImage[3 * offset] += wt * hdr.getRed(bx, by);
              bloomImage[3 * offset + 1] += wt * hdr.getGreen(bx, by);
              bloomImage[3 * offset + 2] += wt * hdr.getBlue(bx, by);
            }
          }
        }

        bloomImage[3 * offset] /= sumWt;
        bloomImage[3 * offset + 1] /= sumWt;
        bloomImage[3 * offset + 2] /= sumWt;
      }
    }

    // Mix bloom effect into each pixel
    for (int y = 0, offset = 0; y < hdr.height; ++y) {
      for (int x = 0; x < hdr.width; ++x, offset += 3) {
        hdr.setRed(x, y, _lerp(weight, hdr.getRed(x, y), bloomImage[offset]));
        hdr.setGreen(
            x, y, _lerp(weight, hdr.getGreen(x, y), bloomImage[offset + 1]));
        hdr.setBlue(
            x, y, _lerp(weight, hdr.getBlue(x, y), bloomImage[offset + 2]));
      }
    }
  }

  return hdr;
}
