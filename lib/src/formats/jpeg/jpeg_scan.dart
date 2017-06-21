part of image;


class JpegScan {
  InputBuffer input;
  JpegFrame frame;
  int precision;
  int samplesPerLine;
  int scanLines;
  int mcusPerLine;
  bool progressive;
  int maxH;
  int maxV;
  List components;
  int resetInterval;
  int spectralStart;
  int spectralEnd;
  int successivePrev;
  int successive;

  int bitsData = 0;
  int bitsCount = 0;
  int eobrun = 0;
  int successiveACState = 0;
  int successiveACNextValue;

  JpegScan(this.input, this.frame, this.components,
           this.resetInterval, this.spectralStart, this.spectralEnd,
           this.successivePrev, this.successive) {
    precision = frame.precision;
    samplesPerLine = frame.samplesPerLine;
    scanLines = frame.scanLines;
    mcusPerLine = frame.mcusPerLine;
    progressive = frame.progressive;
    maxH = frame.maxH;
    maxV = frame.maxV;
  }

  void decode() {
    int componentsLength = components.length;
    JpegComponent component;
    var decodeFn;

    if (progressive) {
      if (spectralStart == 0) {
        decodeFn = successivePrev == 0 ? _decodeDCFirst : _decodeDCSuccessive;
      } else {
        decodeFn = successivePrev == 0 ? _decodeACFirst : _decodeACSuccessive;
      }
    } else {
      decodeFn = _decodeBaseline;
    }

    int mcu = 0;

    int mcuExpected;
    if (componentsLength == 1) {
      mcuExpected = (components[0].blocksPerLine * components[0].blocksPerColumn);
    } else {
      mcuExpected = (mcusPerLine * frame.mcusPerColumn);
    }

    if (resetInterval == null || resetInterval == 0) {
      resetInterval = mcuExpected;
    }

    int h, v;
    while (mcu < mcuExpected) {
      // reset interval stuff
      for (int i = 0; i < componentsLength; i++) {
        components[i].pred = 0;
      }
      eobrun = 0;

      if (componentsLength == 1) {
        component = components[0];
        for (int n = 0; n < resetInterval; n++) {
          _decodeBlock(component, decodeFn, mcu);
          mcu++;
        }
      } else {
        for (int n = 0; n < resetInterval; n++) {
          for (int i = 0; i < componentsLength; i++) {
            component = components[i];
            h = component.h;
            v = component.v;
            for (int j = 0; j < v; j++) {
              for (int k = 0; k < h; k++) {
                _decodeMcu(component, decodeFn, mcu, j, k);
              }
            }
          }
          mcu++;
        }
      }

      // find marker
      bitsCount = 0;
      int m1 = input[0];
      int m2 = input[1];
      if (m1 == 0xff) {
        if (m2 >= Jpeg.M_RST0 && m2 <= Jpeg.M_RST7) {
          input.offset += 2;
        } else {
          break;
        }
      }
    }
  }

  int _readBit() {
    if (bitsCount > 0) {
      bitsCount--;
      return (bitsData >> bitsCount) & 1;
    }

    bitsData = input.readByte();
    if (bitsData == 0xff) {
      int nextByte = input.readByte();
      if (nextByte != 0) {
        throw new ImageException('unexpected marker: ' +
              ((bitsData << 8) | nextByte).toRadixString(16));
      }
    }

    bitsCount = 7;
    return bitsData >> 7;
  }

  int _decodeHuffman(tree) {
    var node = tree;
    int bit;
    while ((bit = _readBit()) != null) {
      if (bit >= node.length) {
        // what does this mean? Some images have this error.
        continue;
      }
      node = node[bit];
      if (node is num) {
        return node.toInt();
      }
    }

    return null;
  }

  int _receive(int length) {
    int  n = 0;
    while (length > 0) {
      int bit = _readBit();
      if (bit == null) {
        return null;
      }
      n = ((n << 1) | bit);
      length--;
    }
    return n;
  }

  int _receiveAndExtend(int length) {
    int n = _receive(length);
    if (n >= 1 << (length - 1)) {
      return n;
    }
    return n + (-1 << length) + 1;
  }

  void _decodeBaseline(JpegComponent component, List zz) {
    int t = _decodeHuffman(component.huffmanTableDC);
    int diff = t == 0 ? 0 : _receiveAndExtend(t);
    component.pred += diff;
    zz[0] = component.pred;

    int k = 1;
    while (k < 64) {
      var rs = _decodeHuffman(component.huffmanTableAC);
      int s = rs & 15;
      int r = rs >> 4;
      if (s == 0) {
        if (r < 15) {
          break;
        }
        k += 16;
        continue;
      }

      k += r;

      s = _receiveAndExtend(s);

      int z = Jpeg.dctZigZag[k];
      zz[z] = s;
      k++;
    }
  }

  void _decodeDCFirst(JpegComponent component, List zz) {
    int t = _decodeHuffman(component.huffmanTableDC);
    int diff = (t == 0) ? 0 : (_receiveAndExtend(t) << successive);
    component.pred += diff;
    zz[0] = component.pred;
  }

  void _decodeDCSuccessive(JpegComponent component, List zz) {
    zz[0] = (zz[0] | (_readBit() << successive));
  }

  void _decodeACFirst(JpegComponent component, List zz) {
    if (eobrun > 0) {
      eobrun--;
      return;
    }
    int k = spectralStart;
    int e = spectralEnd;
    while (k <= e) {
      int rs = _decodeHuffman(component.huffmanTableAC);
      int s = rs & 15;
      int r = rs >> 4;
      if (s == 0) {
        if (r < 15) {
          eobrun = (_receive(r) + (1 << r) - 1);
          break;
        }
        k += 16;
        continue;
      }
      k += r;
      int z = Jpeg.dctZigZag[k];
      zz[z] = (_receiveAndExtend(s) * (1 << successive));
      k++;
    }
  }

  void _decodeACSuccessive(JpegComponent component, zz) {
    int k = spectralStart;
    int e = spectralEnd;
    int r = 0;
    while (k <= e) {
      int z = Jpeg.dctZigZag[k];
      switch (successiveACState) {
        case 0: // initial state
          int rs = _decodeHuffman(component.huffmanTableAC);
          int s = rs & 15;
          int r = rs >> 4;
          if (s == 0) {
            if (r < 15) {
              eobrun = (_receive(r) + (1 << r));
              successiveACState = 4;
            } else {
              r = 16;
              successiveACState = 1;
            }
          } else {
            if (s != 1) {
              throw new ImageException('invalid ACn encoding');
            }
            successiveACNextValue = _receiveAndExtend(s);
            successiveACState = r != 0 ? 2 : 3;
          }
          continue;
        case 1: // skipping r zero items
        case 2:
          if (zz[z] != 0) {
            zz[z] += (_readBit() << successive);
          } else {
            r--;
            if (r == 0) {
              successiveACState = successiveACState == 2 ? 3 : 0;
            }
          }
          break;
        case 3: // set value for a zero item
          if (zz[z] != 0) {
            zz[z] += (_readBit() << successive);
          } else {
            zz[z] = (successiveACNextValue << successive);
            successiveACState = 0;
          }
          break;
        case 4: // eob
          if (zz[z] != 0) {
            zz[z] += (_readBit() << successive);
          }
          break;
      }
      k++;
    }
    if (successiveACState == 4) {
      eobrun--;
      if (eobrun == 0) {
        successiveACState = 0;
      }
    }
  }

  void _decodeMcu(JpegComponent component, decodeFn,
                  int mcu, int row, int col) {
    int mcuRow = (mcu ~/ mcusPerLine);
    int mcuCol = mcu % mcusPerLine;
    int blockRow = mcuRow * component.v + row;
    int blockCol = mcuCol * component.h + col;
    if (blockRow >= component.blocks.length ||
        blockCol >= component.blocks[blockRow].length) {
      return;
    }
    decodeFn(component, component.blocks[blockRow][blockCol]);
  }

  void _decodeBlock(JpegComponent component, decodeFn, int mcu) {
    int blockRow = mcu ~/ component.blocksPerLine;
    int blockCol = mcu % component.blocksPerLine;
    decodeFn(component, component.blocks[blockRow][blockCol]);
  }
}
