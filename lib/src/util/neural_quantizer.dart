import 'dart:typed_data';

import '../color.dart';
import '../image.dart';
import '../image_exception.dart';

/* NeuQuant Neural-Net Quantization Algorithm
 * ------------------------------------------
 *
 * Copyright (c) 1994 Anthony Dekker
 *
 * NEUQUANT Neural-Net quantization algorithm by Anthony Dekker, 1994.
 * See "Kohonen neural networks for optimal colour quantization"
 * in "Network: Computation in Neural Systems" Vol. 5 (1994) pp 351-367.
 * for a discussion of the algorithm.
 * See also  http://members.ozemail.com.au/~dekker/NEUQUANT.HTML
 *
 * Any party obtaining a copy of these files from the author, directly or
 * indirectly, is granted, free of charge, a full and unrestricted irrevocable,
 * world-wide, paid up, royalty-free, nonexclusive right and license to deal
 * in this software and documentation files (the "Software"), including without
 * limitation the rights to use, copy, modify, merge, publish, distribute,
 * sublicense,
 * and/or sell copies of the Software, and to permit persons who receive
 * copies from any such party to do so, with the only requirement being
 * that this copyright notice remain intact.
 *
 * Dart port by Brendan Duncan.
 */

/**
 * Compute a color map with a given number of colors that best represents
 * the given image.
 */
class NeuralQuantizer {
  Uint8List colorMap;

  NeuralQuantizer(Image image, {int numberOfColors=256}) {
    if (image.width * image.height < MAX_PRIME) {
      throw new ImageException('Image is too small');
    }

    _initialize(numberOfColors);

    _setupArrays();
    addImage(image);
  }

  /**
   * Add an image to the quantized color table.
   */
  void addImage(Image image) {
    _learn(image);
    _fix();
    _inxBuild();
    _copyColorMap();
  }

  /**
   * How many colors are in the [colorMap]?
   */
  int get numColors => NET_SIZE;

  /**
   * Get a color from the [colorMap].
   */
  int color(int index) => getColor(colorMap[index * 3],
                                   colorMap[index * 3 + 1],
                                   colorMap[index * 3 + 2]);

  /**
   * Find the index of the closest color to [c] in the [colorMap].
   */
  int lookup(int c) {
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    return _inxSearch(b, g, r);
  }

  /**
     * Find the index of the closest color to [r],[g],[b] in the [colorMap].
     */
  int lookupRGB(int r, int g, int b) {
    return _inxSearch(b, g, r);
  }

  /**
   * Find the color closest to [c] in the [colorMap].
   */
  int getQuantizedColor(int c) {
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    int a = getAlpha(c);
    int i = _inxSearch(b, g, r);
    i *= 3;
    return getColor(colorMap[i], colorMap[i + 1], colorMap[i + 2], a);
  }

  /**
   * Convert the [image] to an index map, mapping to this [colorMap].
   */
  Uint8List getIndexMap(Image image) {
    Uint8List map = Uint8List(image.width * image.height);
    for (int i = 0, len = image.length; i < len; ++i) {
      map[i] = lookup(image[i]);
    }
    return map;
  }

  void _initialize(int numberOfColors) {
    NET_SIZE = numberOfColors; // number of colours used
    CUT_NET_SIZE = NET_SIZE - SPECIALS;
    MAX_NET_POS = NET_SIZE - 1;
    INIT_RAD = NET_SIZE ~/ 8; // for 256 cols, radius starts at 32
    INIT_BIAS_RADIUS = INIT_RAD * RADIUS_BIAS;
    _network = List<double>(NET_SIZE * 3);
    _colorMap = Int32List(NET_SIZE * 4);
    _bias = List<double>(NET_SIZE);
    _freq = List<double>(NET_SIZE);
    colorMap = Uint8List(NET_SIZE * 3);
  }

  void _copyColorMap() {
    for (int i = 0, p = 0, q = 0; i < NET_SIZE; ++i) {
      colorMap[p++] = _colorMap[q + 2].abs() & 0xff;
      colorMap[p++] = _colorMap[q + 1].abs() & 0xff;
      colorMap[p++] = _colorMap[q].abs() & 0xff;
      q += 4;
    }
  }

  int _inxSearch(int b, int g, int r) {
    // Search for BGR values 0..255 and return colour index
    int bestd = 1000;   // biggest possible dist is 256*3
    int best = -1;
    int i = _netIndex[g];  // index on g
    int j = i - 1;    // start at netindex[g] and work outwards

    while ((i < NET_SIZE) || (j >= 0)) {
      if (i < NET_SIZE) {
        int p = i * 4;
        int dist = _colorMap[p + 1] - g;    // inx key
        if (dist >= bestd) {
          i = NET_SIZE; // stop iter
        } else {
          if (dist < 0) {
            dist = -dist;
          }
          int a = _colorMap[p] - b;
          if (a < 0) {
            a = -a;
          }
          dist += a;
          if (dist < bestd) {
            a = _colorMap[p + 2] - r;
            if (a < 0) {
              a = -a;
            }
            dist += a;
            if (dist < bestd) {
              bestd = dist;
              best = i;
            }
          }
          i++;
        }
      }

      if (j >= 0) {
        int p = j * 4;
        int dist = g - _colorMap[p + 1]; // inx key - reverse dif
        if (dist >= bestd) {
          j = -1; // stop iter
        } else {
          if (dist < 0) {
            dist = -dist;
          }
          int a = _colorMap[p] - b;
          if (a < 0) {
            a = -a;
          }
          dist += a;
          if (dist < bestd) {
            a = _colorMap[p + 2] - r;
            if (a < 0) {
              a = -a;
            }
            dist += a;
            if (dist < bestd) {
              bestd = dist;
              best = j;
            }
          }
          j--;
        }
      }
    }

    return best;
  }

  void _fix() {
    for (int i = 0, p = 0, q = 0; i < NET_SIZE; i++, q += 4) {
      for (int j = 0; j < 3; ++j, ++p) {
        int x = (0.5 + _network[p]).toInt();
        if (x < 0) {
          x = 0;
        }
        if (x > 255) {
          x = 255;
        }
        _colorMap[q + j] = x;
      }
      _colorMap[q + 3] = i;
    }
  }

  /**
   * Insertion sort of network and building of netindex[0..255]
   */
  void _inxBuild() {
    int previouscol = 0;
    int startpos = 0;

    for (int i = 0, p = 0; i < NET_SIZE; i++, p += 4) {
      int smallpos = i;
      int smallval = _colorMap[p + 1]; // index on g

      // find smallest in i..netsize-1
      for (int j = i + 1, q = p + 4; j < NET_SIZE; j++, q += 4) {
        if (_colorMap[q + 1] < smallval) {    // index on g
          smallpos = j;
          smallval = _colorMap[q + 1];  // index on g
        }
      }

      int q = smallpos * 4;

      // swap p (i) and q (smallpos) entries
      if (i != smallpos) {
        int j = _colorMap[q];
        _colorMap[q] = _colorMap[p];
        _colorMap[p] = j;

        j = _colorMap[q + 1];
        _colorMap[q + 1] = _colorMap[p + 1];
        _colorMap[p + 1] = j;

        j = _colorMap[q + 2];
        _colorMap[q + 2] = _colorMap[p + 2];
        _colorMap[p + 2] = j;

        j = _colorMap[q + 3];
        _colorMap[q + 3] = _colorMap[p + 3];
        _colorMap[p + 3] = j;
      }

      // smallval entry is now in position i
      if (smallval != previouscol) {
        _netIndex[previouscol] = (startpos + i) >> 1;
        for (int j = previouscol + 1; j < smallval; j++) {
          _netIndex[j] = i;
        }
        previouscol = smallval;
         startpos = i;
      }
    }

    _netIndex[previouscol] = (startpos + MAX_NET_POS) >> 1;
    for (int j = previouscol + 1; j < 256; j++) {
       _netIndex[j] = MAX_NET_POS; // really 256
    }
  }

  void _learn(Image image) {
    int biasRadius = INIT_BIAS_RADIUS;
    int alphadec = 30 + ((_sampleFac - 1) ~/ 3);
    int lengthCount = image.length;
    int samplePixels = lengthCount ~/ _sampleFac;
    int delta = samplePixels ~/ NUM_CYCLES;
    int alpha = INIT_ALPHA;

    int rad = biasRadius >> RADIUS_BIAS_SHIFT;
    if (rad <= 1) {
      rad = 0;
    }

    int step = 0;
    int pos = 0;

    if ((lengthCount % PRIME1) != 0) {
      step = PRIME1;
    } else {
      if ((lengthCount % PRIME2) != 0) {
        step = PRIME2;
      } else {
        if ((lengthCount % PRIME3) != 0) {
          step = PRIME3;
        } else {
          step = PRIME4;
        }
      }
    }

    int i = 0;
    while (i < samplePixels) {
      int p = image[pos];
      int red   = getRed(p);
      int green = getGreen(p);
      int blue  = getBlue(p);

      double b = blue.toDouble();
      double g = green.toDouble();
      double r = red.toDouble();

      if (i == 0) {   // remember background colour
        _network[BG_COLOR * 3] = b;
        _network[BG_COLOR * 3 + 1] = g;
        _network[BG_COLOR * 3 + 2] = r;
      }

      int j = _specialFind(b, g, r);
      j = j < 0 ? _contest(b, g, r) : j;

      if (j >= SPECIALS) {   // don't learn for specials
        double a = (1.0 * alpha) / INIT_ALPHA;
        _alterSingle(a, j, b, g, r);
        if (rad > 0) {
          _alterNeighbors(a, rad, j, b, g, r);   // alter neighbours
        }
      }

      pos += step;
      while (pos >= lengthCount) {
        pos -= lengthCount;
      }

      i++;
      if (i % delta == 0) {
        alpha -= alpha ~/ alphadec;
        biasRadius -= biasRadius ~/ RADIUS_DEC;
        rad = biasRadius >> RADIUS_BIAS_SHIFT;
        if (rad <= 1) {
          rad = 0;
        }
      }
    }
  }

  void _alterSingle(double alpha, int i, double b, double g, double r) {
    // Move neuron i towards biased (b,g,r) by factor alpha
    int p = i * 3;
    _network[p] -= (alpha * (_network[p] - b));
    _network[p + 1] -= (alpha*(_network[p + 1] - g));
    _network[p + 2] -= (alpha*(_network[p + 2] - r));
  }

  void _alterNeighbors(double alpha, int rad, int i,
                       double b, double g, double r) {
    int lo = i - rad;
    if (lo < SPECIALS - 1) {
      lo = SPECIALS - 1;
    }

    int hi = i + rad;
    if (hi > NET_SIZE) {
      hi = NET_SIZE;
    }

    int j = i + 1;
    int k = i - 1;
    int q = 0;
    while ((j < hi) || (k > lo)) {
      double a = (alpha * (rad * rad - q * q)) / (rad * rad);
      q++;
      if (j < hi) {
        int p = j * 3;
        _network[p] -= (a * (_network[p] - b));
        _network[1] -= (a * (_network[p + 1] - g));
        _network[2] -= (a * (_network[p + 2] - r));
        j++;
      }
      if (k > lo) {
        int p = k * 3;
        _network[p] -= (a * (_network[p] - b));
        _network[p + 1] -= (a * (_network[p + 1] - g));
        _network[p + 2] -= (a * (_network[p + 2] - r));
        k--;
      }
    }
  }

  // Search for biased BGR values
  int _contest(double b, double g, double r) {
    // finds closest neuron (min dist) and updates freq
    // finds best neuron (min dist-bias) and returns position
    // for frequently chosen neurons, freq[i] is high and bias[i] is negative
    // bias[i] = gamma*((1/netsize)-freq[i])

    double bestd = 1.0e30;
    double bestbiasd = bestd;
    int bestpos = -1;
    int bestbiaspos = bestpos;

    for (int i = SPECIALS, p = SPECIALS * 3; i < NET_SIZE; i++) {
      double dist = _network[p++] - b;
      if (dist < 0) {
        dist = -dist;
      }
      double a = _network[p++] - g;
      if (a < 0) {
        a = -a;
      }
      dist += a;
      a = _network[p++] - r;
      if (a < 0) {
        a = -a;
      }
      dist += a;
      if (dist < bestd) {
        bestd = dist;
        bestpos = i;
      }

      double biasdist = dist - _bias[i];
      if (biasdist < bestbiasd) {
        bestbiasd = biasdist;
        bestbiaspos = i;
      }
      _freq[i] -= BETA * _freq[i];
      _bias[i] += BETA_GAMMA * _freq[i];
    }
    _freq[bestpos] += BETA;
    _bias[bestpos] -= BETA_GAMMA;
    return bestbiaspos;
  }

  int _specialFind(double b, double g, double r) {
    for (int i = 0, p = 0; i < SPECIALS; i++) {
      if (_network[p++] == b && _network[p++] == g && _network[p++] == r) {
        return i;
      }
    }
    return -1;
  }

  void _setupArrays() {
    _network[0] = 0.0;  // black
    _network[1] = 0.0;
    _network[2] = 0.0;

    _network[3] = 255.0;  // white
    _network[4] = 255.0;
    _network[5] = 255.0;

    // RESERVED bgColour  // background
    final double f = 1.0 / NET_SIZE;
    for (int i = 0; i < SPECIALS; ++i) {
      _freq[i] = f;
      _bias[i] = 0.0;
    }

    for (int i = SPECIALS, p = SPECIALS * 3; i < NET_SIZE; ++i) {
      _network[p++] = (255.0 * (i - SPECIALS)) / CUT_NET_SIZE;
      _network[p++] = (255.0 * (i - SPECIALS)) / CUT_NET_SIZE;
      _network[p++] = (255.0 * (i - SPECIALS)) / CUT_NET_SIZE;

      _freq[i] = f;
      _bias[i] = 0.0;
    }
  }

  static const int NUM_CYCLES = 100; // no. of learning cycles

  int NET_SIZE = 16; // number of colours used
  static const int SPECIALS = 3; // number of reserved colours used
  static const int BG_COLOR = SPECIALS - 1; // reserved background colour
  int CUT_NET_SIZE;
  int MAX_NET_POS;

  int INIT_RAD; // for 256 cols, radius starts at 32
  static const int RADIUS_BIAS_SHIFT = 6;
  static const int RADIUS_BIAS = 1 << RADIUS_BIAS_SHIFT;
  int INIT_BIAS_RADIUS;
  static const int RADIUS_DEC = 30; // factor of 1/30 each cycle

  static const int ALPHA_BIAS_SHIFT = 10; // alpha starts at 1
  static const int INIT_ALPHA = 1 << ALPHA_BIAS_SHIFT; // biased by 10 bits

  static const double GAMMA = 1024.0;
  static const double BETA = 1.0 / 1024.0;
  static const double BETA_GAMMA = BETA * GAMMA;

  /// the network itself
  List<double> _network ;
  Int32List _colorMap;
  Int32List _netIndex = Int32List(256);
  // bias and freq arrays for learning
  List<double> _bias;
  List<double> _freq;

  // four primes near 500 - assume no image has a length so large
  // that it is divisible by all four primes

  static const int PRIME1  = 499;
  static const int PRIME2  = 491;
  static const int PRIME3  = 487;
  static const int PRIME4  = 503;
  static const int MAX_PRIME = PRIME4;

  int _sampleFac = 1;
}
