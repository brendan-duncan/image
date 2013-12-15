part of dart_image;

/**
 * Decode a jpeg encoded image.
 *
 * Derived from:
 * https://github.com/notmasteryet/jpgjs
 */
class JpegDecoder {
  Image decode(List<int> data) {
    _ByteBuffer bytes = new _ByteBuffer.fromList(data);

    prepareComponents(_JpegFrame frame) {
      int maxH = 0;
      int maxV = 0;
      _JpegComponent component;
      int componentId;

      for (componentId in frame.components.keys) {
        component = frame.components[componentId];
        if (maxH < component.h) {
          maxH = component.h;
        }
        if (maxV < component.v) {
          maxV = component.v;
        }
      }

      int mcusPerLine = (frame.samplesPerLine / 8 / maxH).ceil();
      int mcusPerColumn = (frame.scanLines / 8 / maxV).ceil();

      for (componentId in frame.components.keys) {
        component = frame.components[componentId];
        int blocksPerLine = ((frame.samplesPerLine / 8).ceil() * component.h / maxH).ceil();
        int blocksPerColumn = ((frame.scanLines / 8).ceil() * component.v / maxV).ceil();
        int blocksPerLineForMcu = mcusPerLine * component.h;
        int blocksPerColumnForMcu = mcusPerColumn * component.v;
        List blocks = [];
        for (var i = 0; i < blocksPerColumnForMcu; i++) {
          List row = [];
          for (var j = 0; j < blocksPerLineForMcu; j++) {
            row.add(new Data.Int32List(64));
          }
          blocks.add(row);
        }
        component.blocksPerLine = blocksPerLine;
        component.blocksPerColumn = blocksPerColumn;
        component.blocks = blocks;
      }

      frame.maxH = maxH;
      frame.maxV = maxV;
      frame.mcusPerLine = mcusPerLine;
      frame.mcusPerColumn = mcusPerColumn;
    }

    var jfif = null;
    var adobe = null;
    var pixels = null;
    _JpegFrame frame;
    var resetInterval;
    var quantizationTables = [];
    List<_JpegFrame> frames = [];
    var huffmanTablesAC = [];
    var huffmanTablesDC = [];
    var fileMarker = bytes.readUint16();

    if (fileMarker != 0xFFD8) { // SOI (Start of Image)
      throw 'SOI not found';
    }

    fileMarker = bytes.readUint16();
    while (fileMarker != 0xFFD9) { // EOI (End of image)
      int i, j, l;
      switch(fileMarker) {
        case 0xFFE0: // APP0 (Application Specific)
        case 0xFFE1: // APP1
        case 0xFFE2: // APP2
        case 0xFFE3: // APP3
        case 0xFFE4: // APP4
        case 0xFFE5: // APP5
        case 0xFFE6: // APP6
        case 0xFFE7: // APP7
        case 0xFFE8: // APP8
        case 0xFFE9: // APP9
        case 0xFFEA: // APP10
        case 0xFFEB: // APP11
        case 0xFFEC: // APP12
        case 0xFFED: // APP13
        case 0xFFEE: // APP14
        case 0xFFEF: // APP15
        case 0xFFFE: // COM (Comment)
          var appData = bytes.readBlock();

          if (fileMarker == 0xFFE0) {
            // 'JFIF\x00'
            if (appData[0] == 0x4A && appData[1] == 0x46 &&
                appData[2] == 0x49 && appData[3] == 0x46 && appData[4] == 0) {
              jfif = {
                'version': { 'major': appData[5], 'minor': appData[6] },
                'densityUnits': appData[7],
                'xDensity': (appData[8] << 8) | appData[9],
                'yDensity': (appData[10] << 8) | appData[11],
                'thumbWidth': appData[12],
                'thumbHeight': appData[13],
                'thumbData': appData.sublist(14, 14 + 3 * appData[12] * appData[13])
              };
            }
          }

          // TODO APP1 - Exif
          if (fileMarker == 0xFFEE) {
            if (appData[0] == 0x41 && appData[1] == 0x64 && appData[2] == 0x6F &&
              appData[3] == 0x62 && appData[4] == 0x65 && appData[5] == 0) { // 'Adobe\x00'
              adobe = {
                'version': appData[6],
                'flags0': (appData[7] << 8) | appData[8],
                'flags1': (appData[9] << 8) | appData[10],
                'transformCode': appData[11]
              };
            }
          }
          break;

        case 0xFFDB: // DQT (Define Quantization Tables)
          var quantizationTablesLength = bytes.readUint16();
          var quantizationTablesEnd = quantizationTablesLength + bytes.position - 2;
          while (bytes.position < quantizationTablesEnd) {
            var quantizationTableSpec = bytes.readByte();
            var tableData = new Data.Int32List(64);
            if ((quantizationTableSpec >> 4) == 0) { // 8 bit values
              for (j = 0; j < 64; j++) {
                int z = _dctZigZag[j];
                tableData[z] = bytes.readByte();
              }
            } else if ((quantizationTableSpec >> 4) == 1) { //16 bit
              for (j = 0; j < 64; j++) {
                int z = _dctZigZag[j];
                tableData[z] = bytes.readUint16();
              }
            } else {
              throw 'DQT: invalid table spec';
            }
            var i = quantizationTableSpec & 15;
            if (quantizationTables.length <= i) {
              quantizationTables.length = i + 1;
            }
            quantizationTables[i] = tableData;
          }
          break;

        case 0xFFC0: // SOF0 (Start of Frame, Baseline DCT)
        case 0xFFC1: // SOF1 (Start of Frame, Extended DCT)
        case 0xFFC2: // SOF2 (Start of Frame, Progressive DCT)
          bytes.readUint16(); // skip data length
          frame = new _JpegFrame();

          frame.extended = (fileMarker == 0xFFC1);
          frame.progressive = (fileMarker == 0xFFC2);
          frame.precision = bytes.readByte();
          frame.scanLines = bytes.readUint16();
          frame.samplesPerLine = bytes.readUint16();

          var componentsCount = bytes.readByte();
          var componentId;
          var maxH = 0;
          var maxV = 0;
          for (i = 0; i < componentsCount; i++) {
            componentId = bytes.readByte();
            int x = bytes.readByte();
            var h = x >> 4;
            var v = x & 15;
            var qId = bytes.readByte();
            frame.componentsOrder.add(componentId);
            frame.components[componentId] =
                new _JpegComponent(h, v, quantizationTables[qId]);
          }
          prepareComponents(frame);
          frames.add(frame);
          break;

        case 0xFFC4: // DHT (Define Huffman Tables)
          var huffmanLength = bytes.readUint16();
          for (i = 2; i < huffmanLength;) {
            var huffmanTableSpec = bytes.readByte();
            var codeLengths = new Data.Uint8List(16);
            var codeLengthSum = 0;
            for (j = 0; j < 16; j++) {
              codeLengthSum += (codeLengths[j] = bytes.readByte());
            }
            var huffmanValues = new Data.Uint8List(codeLengthSum);
            for (j = 0; j < codeLengthSum; j++) {
              huffmanValues[j] = bytes.readByte();
            }
            i += 17 + codeLengthSum;

            var l = ((huffmanTableSpec >> 4) == 0 ?
              huffmanTablesDC : huffmanTablesAC);
            if (l.length <= huffmanTableSpec & 15) {
              l.length = (huffmanTableSpec & 15) + 1;
            }
            l[huffmanTableSpec & 15] =
              _buildHuffmanTable(codeLengths, huffmanValues);
          }
          break;

        case 0xFFDD: // DRI (Define Restart Interval)
          bytes.readUint16(); // skip data length
          resetInterval = bytes.readUint16();
          break;

        case 0xFFDA: // SOS (Start of Scan)
          var scanLength = bytes.readUint16();
          var selectorsCount = bytes.readByte();
          var components = [];
          _JpegComponent component;
          for (i = 0; i < selectorsCount; i++) {
            component = frame.components[bytes.readByte()];
            int tableSpec = bytes.readByte();
            component.huffmanTableDC = huffmanTablesDC[tableSpec >> 4];
            component.huffmanTableAC = huffmanTablesAC[tableSpec & 15];
            components.add(component);
          }
          var spectralStart = bytes.readByte();
          var spectralEnd = bytes.readByte();
          var successiveApproximation = bytes.readByte();
          _decodeScan(bytes,
                      frame, components, resetInterval,
                      spectralStart, spectralEnd,
                      successiveApproximation >> 4,
                      successiveApproximation & 15);
          break;
        default:
          if (bytes.peakAtOffset(-3) == 0xFF &&
              bytes.peakAtOffset(-2) >= 0xC0 &&
              bytes.peakAtOffset(-2) <= 0xFE) {
            // could be incorrect encoding -- last 0xFF byte of the previous
            // block was eaten by the encoder
            bytes.position -= 3;
            break;
          }
          throw 'unknown JPEG marker ' + fileMarker;
      }
      fileMarker = bytes.readUint16();
    }

    if (frames.length != 1) {
      throw 'only single frame JPEGs supported';
    }

    int width = frame.samplesPerLine;
    int height = frame.scanLines;
    Image image = new Image(width, height);

    var jpeg = {
      'jfif': jfif,
      'adobe': adobe
    };

    var components = [];
    for (int i = 0; i < frame.componentsOrder.length; ++i) {
      var component = frame.components[frame.componentsOrder[i]];
      components.add({
        'scaleX': component.h / frame.maxH,
        'scaleY': component.v / frame.maxV,
        'lines': buildComponentData(frame, component)
      });
    }
    jpeg['components'] = components;

    copyToImage(jpeg, image);

    return image;
  }

  void copyToImage(Map jpeg, Image imageData) {
    var width = imageData.width;
    var height = imageData.height;
    var imageDataArray = imageData.buffer;
    var data = getData(width, height, jpeg);
    var i = 0, j = 0, x, y;
    var Y, K, C, M, R, G, B;
    var components = jpeg['components'];

    switch (components.length) {
      case 1:
        for (y = 0; y < height; y++) {
          for (x = 0; x < width; x++) {
            Y = data[i++];
            imageDataArray[j++] = color(Y, Y, Y, 255);
          }
        }
        break;
      case 3:
        for (y = 0; y < height; y++) {
          for (x = 0; x < width; x++) {
            R = data[i++];
            G = data[i++];
            B = data[i++];

            int c = color(R, G, B, 255);
            imageDataArray[j++] = c;
          }
        }
        break;
      case 4:
        for (y = 0; y < height; y++) {
          for (x = 0; x < width; x++) {
            C = data[i++];
            M = data[i++];
            Y = data[i++];
            K = data[i++];

            R = 255 - clampTo8bit(C * (1 - K / 255) + K);
            G = 255 - clampTo8bit(M * (1 - K / 255) + K);
            B = 255 - clampTo8bit(Y * (1 - K / 255) + K);

            imageDataArray[j++] = color(R, G, B, 255);
          }
        }
        break;
      default:
        throw 'Unsupported color mode';
    }
  }

  Data.Uint8List getData(int width, int height, Map jpeg) {
    num scaleX = 1;
    num scaleY = 1;
    List components = jpeg['components'];
    var adobe = jpeg['adobe'];
    var component1;
    var component2;
    var component3;
    var component4;
    var component1Line;
    var component2Line;
    var component3Line;
    var component4Line;
    int x, y;
    int offset = 0;
    int Y, Cb, Cr, K, C, M, Ye, R, G, B;
    var colorTransform;
    var dataLength = width * height * components.length;
    var data = new Data.Uint8List(dataLength);
    switch (components.length) {
      case 1:
        component1 = components[0];
        for (y = 0; y < height; y++) {
          component1Line = component1.lines[(y * component1.scaleY * scaleY).toInt()];
          for (x = 0; x < width; x++) {
            Y = component1Line[(x * component1.scaleX * scaleX).toInt()];
            data[offset++] = Y;
          }
        }
        break;
      case 2:
        // PDF might compress two component data in custom colorspace
        component1 = components[0];
        component2 = components[1];
        for (y = 0; y < height; y++) {
          component1Line = component1.lines[0 | (y * component1.scaleY * scaleY)];
          component2Line = component2.lines[0 | (y * component2.scaleY * scaleY)];
          for (x = 0; x < width; x++) {
            Y = component1Line[(x * component1.scaleX * scaleX).toInt()];
            data[offset++] = Y;
            Y = component2Line[(x * component2.scaleX * scaleX).toInt()];
            data[offset++] = Y;
          }
        }
        break;
      case 3:
        // The default transform for three components is true
        colorTransform = true;
        // The adobe transform marker overrides any previous setting
        /*if (this.adobe && this.adobe.transformCode)
          colorTransform = true;
        else if (typeof this.colorTransform !== 'undefined')
          colorTransform = !!this.colorTransform;*/

        component1 = components[0];
        component2 = components[1];
        component3 = components[2];
        for (y = 0; y < height; y++) {
          component1Line = component1['lines'][(y * component1['scaleY'] * scaleY).toInt()];
          component2Line = component2['lines'][(y * component2['scaleY'] * scaleY).toInt()];
          component3Line = component3['lines'][(y * component3['scaleY'] * scaleY).toInt()];
          for (x = 0; x < width; x++) {
            if (!colorTransform) {
              R = component1Line[(x * component1['scaleX'] * scaleX).toInt()];
              G = component2Line[(x * component2['scaleX'] * scaleX).toInt()];
              B = component3Line[(x * component3['scaleX'] * scaleX).toInt()];
            } else {
              Y = component1Line[(x * component1['scaleX'] * scaleX).toInt()];
              Cb = component2Line[(x * component2['scaleX'] * scaleX).toInt()];
              Cr = component3Line[(x * component3['scaleX'] * scaleX).toInt()];

              R = clampTo8bit(Y + 1.402 * (Cr - 128));
              G = clampTo8bit(Y - 0.3441363 * (Cb - 128) - 0.71413636 * (Cr - 128));
              B = clampTo8bit(Y + 1.772 * (Cb - 128));
            }

            data[offset++] = R.toInt();
            data[offset++] = G.toInt();
            data[offset++] = B.toInt();
          }
        }
        break;
      case 4:
        if (adobe == null)
          throw 'Unsupported color mode (4 components)';
        // The default transform for four components is false
        colorTransform = false;
        // The adobe transform marker overrides any previous setting
        if (adobe['transformCode'])
          colorTransform = true;
        /*else if (typeof this.colorTransform !== 'undefined')
          colorTransform = !!this.colorTransform;*/

        component1 = components[0];
        component2 = components[1];
        component3 = components[2];
        component4 = components[3];
        for (y = 0; y < height; y++) {
          component1Line = component1['lines'][0 | (y * component1['scaleY'] * scaleY)];
          component2Line = component2['lines'][0 | (y * component2['scaleY'] * scaleY)];
          component3Line = component3['lines'][0 | (y * component3['scaleY'] * scaleY)];
          component4Line = component4['lines'][0 | (y * component4['scaleY'] * scaleY)];
          for (x = 0; x < width; x++) {
            if (!colorTransform) {
              C = component1Line[0 | (x * component1['scaleX'] * scaleX)];
              M = component2Line[0 | (x * component2['scaleX'] * scaleX)];
              Ye = component3Line[0 | (x * component3['scaleX'] * scaleX)];
              K = component4Line[0 | (x * component4['scaleX'] * scaleX)];
            } else {
              Y = component1Line[0 | (x * component1['scaleX'] * scaleX)];
              Cb = component2Line[0 | (x * component2['scaleX'] * scaleX)];
              Cr = component3Line[0 | (x * component3['scaleX'] * scaleX)];
              K = component4Line[0 | (x * component4['scaleX'] * scaleX)];

              C = 255 - clampTo8bit(Y + 1.402 * (Cr - 128));
              M = 255 - clampTo8bit(Y - 0.3441363 * (Cb - 128) - 0.71413636 * (Cr - 128));
              Ye = 255 - clampTo8bit(Y + 1.772 * (Cb - 128));
            }
            data[offset++] = C;
            data[offset++] = M;
            data[offset++] = Ye;
            data[offset++] = K;
          }
        }
        break;
      default:
        throw 'Unsupported color mode';
    }
    return data;
  }

  int _decodeScan(_ByteBuffer bytes,
                  _JpegFrame frame,
                  components,
                  resetInterval,
                  spectralStart, spectralEnd,
                  successivePrev, successive) {
    var precision = frame.precision;
    var samplesPerLine = frame.samplesPerLine;
    var scanLines = frame.scanLines;
    var mcusPerLine = frame.mcusPerLine;
    var progressive = frame.progressive;
    var maxH = frame.maxH;
    var maxV = frame.maxV;

    int bitsData = 0;
    int bitsCount = 0;

    int readBit() {
      if (bitsCount > 0) {
        bitsCount--;
        return (bitsData >> bitsCount) & 1;
      }

      bitsData = bytes.readByte();
      if (bitsData == 0xFF) {
        int nextByte = bytes.readByte();
        if (nextByte != 0) {
          throw 'unexpected marker: ' + ((bitsData << 8) | nextByte).toString();
        }
        // unstuff 0
      }

      bitsCount = 7;
      return bitsData >> 7;
    }

    int decodeHuffman(tree) {
      var node = tree;
      int bit;
      while ((bit = readBit()) != null) {
        node = node[bit];
        if (node is num) {
          return node.toInt();
        }
      }

      return null;
    }

    int receive(length) {
      int  n = 0;
      while (length > 0) {
        int bit = readBit();
        if (bit == null) {
          return null;
        }
        n = (n << 1) | bit;
        length--;
      }
      return n;
    }

    receiveAndExtend(int length) {
      int n = receive(length);
      if (n >= 1 << (length - 1)) {
        return n;
      }
      return n + (-1 << length) + 1;
    }

    void decodeBaseline(_JpegComponent component, List zz) {
      int t = decodeHuffman(component.huffmanTableDC);
      int diff = t == 0 ? 0 : receiveAndExtend(t);
      zz[0] = (component.pred += diff);
      int k = 1;
      while (k < 64) {
        var rs = decodeHuffman(component.huffmanTableAC);
        int s = rs & 15;
        int r = rs >> 4;
        if (s == 0) {
          if (r < 15)
            break;
          k += 16;
          continue;
        }
        k += r;
        int z = _dctZigZag[k];
        zz[z] = receiveAndExtend(s);
        k++;
      }
    }

    void decodeDCFirst(_JpegComponent component, List zz) {
      var t = decodeHuffman(component.huffmanTableDC);
      int diff = (t == 0) ? 0 : (receiveAndExtend(t) << successive);
      zz[0] = (component.pred += diff);
    }

    void decodeDCSuccessive(_JpegComponent component, List zz) {
      zz[0] |= readBit() << successive;
    }

    int eobrun = 0;

    void decodeACFirst(_JpegComponent component, List zz) {
      if (eobrun > 0) {
        eobrun--;
        return;
      }
      int k = spectralStart;
      int e = spectralEnd;
      while (k <= e) {
        int rs = decodeHuffman(component.huffmanTableAC);
        int s = rs & 15, r = rs >> 4;
        if (s == 0) {
          if (r < 15) {
            eobrun = receive(r) + (1 << r) - 1;
            break;
          }
          k += 16;
          continue;
        }
        k += r;
        int z = _dctZigZag[k];
        zz[z] = receiveAndExtend(s) * (1 << successive);
        k++;
      }
    }

    int successiveACState = 0, successiveACNextValue;

    void decodeACSuccessive(_JpegComponent component, zz) {
      int k = spectralStart;
      int e = spectralEnd;
      int r = 0;
      while (k <= e) {
        int z = _dctZigZag[k];
        switch (successiveACState) {
          case 0: // initial state
            int rs = decodeHuffman(component.huffmanTableAC);
            int s = rs & 15;
            int r = rs >> 4;
            if (s == 0) {
              if (r < 15) {
                eobrun = receive(r) + (1 << r);
                successiveACState = 4;
              } else {
                r = 16;
                successiveACState = 1;
              }
            } else {
              if (s != 1) {
                throw 'invalid ACn encoding';
              }
              successiveACNextValue = receiveAndExtend(s);
              successiveACState = r != 0 ? 2 : 3;
            }
            continue;
          case 1: // skipping r zero items
          case 2:
            if (zz[z]) {
              zz[z] += (readBit() << successive);
            } else {
              r--;
              if (r == 0) {
                successiveACState = successiveACState == 2 ? 3 : 0;
              }
            }
            break;
          case 3: // set value for a zero item
            if (zz[z]) {
              zz[z] += (readBit() << successive);
            } else {
              zz[z] = successiveACNextValue << successive;
              successiveACState = 0;
            }
            break;
          case 4: // eob
            if (zz[z]) {
              zz[z] += (readBit() << successive);
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

    void decodeMcu(_JpegComponent component, decode, mcu, row, col) {
      var mcuRow = (mcu / mcusPerLine).toInt();
      var mcuCol = mcu % mcusPerLine;
      var blockRow = mcuRow * component.v + row;
      var blockCol = mcuCol * component.h + col;
      decode(component, component.blocks[blockRow][blockCol]);
    }

    void decodeBlock(_JpegComponent component, decode, mcu) {
      var blockRow = (mcu / component.blocksPerLine).toInt();
      var blockCol = mcu % component.blocksPerLine;
      decode(component, component.blocks[blockRow][blockCol]);
    }

    int componentsLength = components.length;
    _JpegComponent component;
    int i, j, k, n;
    var decodeFn;

    if (progressive) {
      if (spectralStart == 0) {
        decodeFn = successivePrev == 0 ? decodeDCFirst : decodeDCSuccessive;
      } else {
        decodeFn = successivePrev == 0 ? decodeACFirst : decodeACSuccessive;
      }
    } else {
      decodeFn = decodeBaseline;
    }

    int mcu = 0;
    int marker;
    int mcuExpected;

    if (componentsLength == 1) {
      mcuExpected = components[0].blocksPerLine * components[0].blocksPerColumn;
    } else {
      mcuExpected = mcusPerLine * frame.mcusPerColumn;
    }

    if (resetInterval == null || resetInterval == 0) {
      resetInterval = mcuExpected;
    }

    int h, v;
    while (mcu < mcuExpected) {
      // reset interval stuff
      for (i = 0; i < componentsLength; i++) {
        components[i].pred = 0;
      }
      eobrun = 0;

      if (componentsLength == 1) {
        component = components[0];
        for (n = 0; n < resetInterval; n++) {
          decodeBlock(component, decodeFn, mcu);
          mcu++;
        }
      } else {
        for (n = 0; n < resetInterval; n++) {
          for (i = 0; i < componentsLength; i++) {
            component = components[i];
            h = component.h;
            v = component.v;
            for (j = 0; j < v; j++) {
              for (k = 0; k < h; k++) {
                decodeMcu(component, decodeFn, mcu, j, k);
              }
            }
          }
          mcu++;
        }
      }

      // find marker
      bitsCount = 0;
      marker = (bytes.peakAtOffset(0) << 8) | bytes.peakAtOffset(1);
      if (marker <= 0xFF00) {
        throw 'marker was not found';
      }

      if (marker >= 0xFFD0 && marker <= 0xFFD7) { // RSTx
        bytes.position += 2;
      } else {
        break;
      }
    }
  }

  List buildComponentData(_JpegFrame frame, _JpegComponent component) {
    List lines = [];
    int blocksPerLine = component.blocksPerLine;
    int blocksPerColumn = component.blocksPerColumn;
    int samplesPerLine = blocksPerLine << 3;
    Data.Int32List R = new Data.Int32List(64);
    Data.Uint8List r = new Data.Uint8List(64);

    // A port of poppler's IDCT method which in turn is taken from:
    //   Christoph Loeffler, Adriaan Ligtenberg, George S. Moschytz,
    //   "Practical Fast 1-D DCT Algorithms with 11 Multiplications",
    //   IEEE Intl. Conf. on Acoustics, Speech & Signal Processing, 1989,
    //   988-991.
    void quantizeAndInverse(List zz, List dataOut, List dataIn) {
      List qt = component.quantizationTable;
      int v0, v1, v2, v3, v4, v5, v6, v7, t;
      List p = dataIn;
      int i;

      // dequant
      for (i = 0; i < 64; i++) {
        p[i] = zz[i] * qt[i];
      }

      // inverse DCT on rows
      for (i = 0; i < 8; ++i) {
        int row = 8 * i;

        // check for all-zero AC coefficients
        if (p[1 + row] == 0 && p[2 + row] == 0 && p[3 + row] == 0 &&
            p[4 + row] == 0 && p[5 + row] == 0 && p[6 + row] == 0 &&
            p[7 + row] == 0) {
          t = (_dctSqrt2 * p[0 + row] + 512).toInt() >> 10;
          p[0 + row] = t;
          p[1 + row] = t;
          p[2 + row] = t;
          p[3 + row] = t;
          p[4 + row] = t;
          p[5 + row] = t;
          p[6 + row] = t;
          p[7 + row] = t;
          continue;
        }

        // stage 4
        v0 = (_dctSqrt2 * p[0 + row] + 128).toInt() >> 8;
        v1 = (_dctSqrt2 * p[4 + row] + 128).toInt() >> 8;
        v2 = p[2 + row];
        v3 = p[6 + row];
        v4 = (_dctSqrt1d2 * (p[1 + row] - p[7 + row]) + 128).toInt() >> 8;
        v7 = (_dctSqrt1d2 * (p[1 + row] + p[7 + row]) + 128).toInt() >> 8;
        v5 = p[3 + row] << 4;
        v6 = p[5 + row] << 4;

        // stage 3
        t = (v0 - v1+ 1) >> 1;
        v0 = (v0 + v1 + 1) >> 1;
        v1 = t;
        t = (v2 * _dctSin6 + v3 * _dctCos6 + 128) >> 8;
        v2 = (v2 * _dctCos6 - v3 * _dctSin6 + 128) >> 8;
        v3 = t;
        t = (v4 - v6 + 1) >> 1;
        v4 = (v4 + v6 + 1) >> 1;
        v6 = t;
        t = (v7 + v5 + 1) >> 1;
        v5 = (v7 - v5 + 1) >> 1;
        v7 = t;

        // stage 2
        t = (v0 - v3 + 1) >> 1;
        v0 = (v0 + v3 + 1) >> 1;
        v3 = t;
        t = (v1 - v2 + 1) >> 1;
        v1 = (v1 + v2 + 1) >> 1;
        v2 = t;
        t = (v4 * _dctSin3 + v7 * _dctCos3 + 2048) >> 12;
        v4 = (v4 * _dctCos3 - v7 * _dctSin3 + 2048) >> 12;
        v7 = t;
        t = (v5 * _dctSin1 + v6 * _dctCos1 + 2048) >> 12;
        v5 = (v5 * _dctCos1 - v6 * _dctSin1 + 2048) >> 12;
        v6 = t;

        // stage 1
        p[0 + row] = v0 + v7;
        p[7 + row] = v0 - v7;
        p[1 + row] = v1 + v6;
        p[6 + row] = v1 - v6;
        p[2 + row] = v2 + v5;
        p[5 + row] = v2 - v5;
        p[3 + row] = v3 + v4;
        p[4 + row] = v3 - v4;
      }

      // inverse DCT on columns
      for (i = 0; i < 8; ++i) {
        int col = i;

        // check for all-zero AC coefficients
        if (p[1*8 + col] == 0 && p[2*8 + col] == 0 && p[3*8 + col] == 0 &&
            p[4*8 + col] == 0 && p[5*8 + col] == 0 && p[6*8 + col] == 0 &&
            p[7*8 + col] == 0) {
          t = (_dctSqrt2 * dataIn[i+0] + 8192).toInt() >> 14;
          p[0*8 + col] = t;
          p[1*8 + col] = t;
          p[2*8 + col] = t;
          p[3*8 + col] = t;
          p[4*8 + col] = t;
          p[5*8 + col] = t;
          p[6*8 + col] = t;
          p[7*8 + col] = t;
          continue;
        }

        // stage 4
        v0 = (_dctSqrt2 * p[0*8 + col] + 2048).toInt() >> 12;
        v1 = (_dctSqrt2 * p[4*8 + col] + 2048).toInt() >> 12;
        v2 = p[2*8 + col];
        v3 = p[6*8 + col];
        v4 = (_dctSqrt1d2 * (p[1*8 + col] - p[7*8 + col]) + 2048).toInt() >> 12;
        v7 = (_dctSqrt1d2 * (p[1*8 + col] + p[7*8 + col]) + 2048).toInt() >> 12;
        v5 = p[3*8 + col];
        v6 = p[5*8 + col];

        // stage 3
        t = (v0 - v1 + 1) >> 1;
        v0 = (v0 + v1 + 1) >> 1;
        v1 = t;
        t = (v2 * _dctSin6 + v3 * _dctCos6 + 2048) >> 12;
        v2 = (v2 * _dctCos6 - v3 * _dctSin6 + 2048) >> 12;
        v3 = t;
        t = (v4 - v6 + 1) >> 1;
        v4 = (v4 + v6 + 1) >> 1;
        v6 = t;
        t = (v7 + v5 + 1) >> 1;
        v5 = (v7 - v5 + 1) >> 1;
        v7 = t;

        // stage 2
        t = (v0 - v3 + 1) >> 1;
        v0 = (v0 + v3 + 1) >> 1;
        v3 = t;
        t = (v1 - v2 + 1) >> 1;
        v1 = (v1 + v2 + 1) >> 1;
        v2 = t;
        t = (v4 * _dctSin3 + v7 * _dctCos3 + 2048) >> 12;
        v4 = (v4 * _dctCos3 - v7 * _dctSin3 + 2048) >> 12;
        v7 = t;
        t = (v5 * _dctSin1 + v6 * _dctCos1 + 2048) >> 12;
        v5 = (v5 * _dctCos1 - v6 * _dctSin1 + 2048) >> 12;
        v6 = t;

        // stage 1
        p[0 * 8 + col] = v0 + v7;
        p[7 * 8 + col] = v0 - v7;
        p[1 * 8 + col] = v1 + v6;
        p[6 * 8 + col] = v1 - v6;
        p[2 * 8 + col] = v2 + v5;
        p[5 * 8 + col] = v2 - v5;
        p[3 * 8 + col] = v3 + v4;
        p[4 * 8 + col] = v3 - v4;
      }

      // convert to 8-bit integers
      for (i = 0; i < 64; ++i) {
        var sample = 128 + ((p[i] + 8) >> 4);
        dataOut[i] = sample < 0 ? 0 : sample > 0xFF ? 0xFF : sample;
      }
    }

    int i, j;
    for (int blockRow = 0; blockRow < blocksPerColumn; blockRow++) {
      int scanLine = blockRow << 3;
      for (i = 0; i < 8; i++) {
        lines.add(new Data.Uint8List(samplesPerLine));
      }

      for (int blockCol = 0; blockCol < blocksPerLine; blockCol++) {
        quantizeAndInverse(component.blocks[blockRow][blockCol], r, R);

        int offset = 0;
        int sample = blockCol << 3;
        for (j = 0; j < 8; j++) {
          List line = lines[scanLine + j];
          for (i = 0; i < 8; i++)
            line[sample + i] = r[offset++];
        }
      }
    }

    return lines;
  }

  int clampTo8bit(num a) {
    int i = a.toInt();
    return i < 0 ? 0 : i > 255 ? 255 : i;
  }

  List _buildHuffmanTable(List codeLengths, List values) {
    int k = 0;
    List code = [];
    int length = 16;

    while (length > 0 && codeLengths[length - 1] == 0) {
      length--;
    }

    code.add({'children': [], 'index': 0});

    Map p = code[0];
    Map q;

    for (int i = 0; i < length; i++) {
      for (int j = 0; j < codeLengths[i]; j++) {
        p = code.removeLast();
        if (p['children'].length <= p['index']) {
          p['children'].length = p['index'] + 1;
        }
        p['children'][p['index']] = values[k];
        while (p['index'] > 0) {
          p = code.removeLast();
        }
        p['index']++;
        code.add(p);
        while (code.length <= i) {
          q = {'children': [], 'index': 0};
          code.add(q);
          if (p['children'].length <= p['index']) {
            p['children'].length = p['index'] + 1;
          }
          p['children'][p['index']] = q['children'];
          p = q;
        }
        k++;
      }

      if (i + 1 < length) {
        // p here points to last code
        q = {'children': [], 'index': 0};
        code.add(q);
        if (p['children'].length <= p['index']) {
          p['children'].length = p['index'] + 1;
        }
        p['children'][p['index']] = q['children'];
        p = q;
      }
    }

    return code[0]['children'];
  }

  static const _dctZigZag = const [
      0,
      1,  8,
      16,  9,  2,
      3, 10, 17, 24,
      32, 25, 18, 11, 4,
      5, 12, 19, 26, 33, 40,
      48, 41, 34, 27, 20, 13,  6,
      7, 14, 21, 28, 35, 42, 49, 56,
      57, 50, 43, 36, 29, 22, 15,
      23, 30, 37, 44, 51, 58,
      59, 52, 45, 38, 31,
      39, 46, 53, 60,
      61, 54, 47,
      55, 62,
      63 ];

  static const int _dctCos1  =  4017;   // cos(pi/16)
  static const int _dctSin1  =  799;   // sin(pi/16)
  static const int _dctCos3  =  3406;   // cos(3*pi/16)
  static const int _dctSin3  =  2276;   // sin(3*pi/16)
  static const int _dctCos6  =  1567;   // cos(6*pi/16)
  static const int _dctSin6  =  3784;   // sin(6*pi/16)
  static const int _dctSqrt2 =  5793;   // sqrt(2)
  static const int _dctSqrt1d2 = 2896;  // sqrt(2) / 2
}


class _JpegFrame {
  bool extended;
  bool progressive;
  int precision;
  int scanLines;
  int samplesPerLine;
  int maxH;
  int maxV;
  int mcusPerLine;
  int mcusPerColumn;
  final Map components = {};
  final List componentsOrder = new List<int>();
}

class _JpegComponent {
  int h;
  int v;
  List quantizationTable;
  int blocksPerLine;
  int blocksPerColumn;
  List blocks;
  List huffmanTableDC;
  List huffmanTableAC;
  int pred;

  _JpegComponent(this.h, this.v,dynamic this.quantizationTable);
}

class _JpegVersion {
  int major;
  int minor;
}

class _JpegJfif {
  _JpegVersion version = new _JpegVersion();
  int densityUnits;
  int xDensity;
  int yDensity;
  int thumbWidth;
  int thumbHeight;
  List<int> thumbData;
}
