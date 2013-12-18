part of dart_image;

/**
 * Decode a jpeg encoded image.
 *
 * Derived from:
 * https://github.com/notmasteryet/jpgjs
 */
class JpegDecoder {
  Stopwatch timer = new Stopwatch();

  Image decode(List<int> data) {
    print(MAX_INT);
    timer.start();
    _ByteBuffer bytes = new _ByteBuffer.fromList(data);

    Map jfif = null;
    Map adobe = null;
    _JpegFrame frame;
    int resetInterval;
    List quantizationTables = [];
    List<_JpegFrame> frames = [];
    List huffmanTablesAC = [];
    List huffmanTablesDC = [];

    var fileMarker = bytes.readUint16();
    if (fileMarker != 0xFFD8) { // SOI (Start of Image)
      throw 'SOI not found';
    }

    Duration t1, t2;
    fileMarker = bytes.readUint16();
    while (fileMarker != 0xFFD9 && !bytes.isEOF) { // EOI (End of image)
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
          t1 = timer.elapsed;
          List<int> appData = bytes.readBlock();

          if (fileMarker == 0xFFE0) {
            // 'JFIF\0'
            if (appData[0] == 0x4A && appData[1] == 0x46 &&
                appData[2] == 0x49 && appData[3] == 0x46 && appData[4] == 0) {
              List<int> thumbData = appData.sublist(14,
                                           14 + 3 * appData[12] * appData[13]);
              jfif = {
                'version': { 'major': appData[5], 'minor': appData[6] },
                'densityUnits': appData[7],
                'xDensity': (appData[8] << 8) | appData[9],
                'yDensity': (appData[10] << 8) | appData[11],
                'thumbWidth': appData[12],
                'thumbHeight': appData[13],
                'thumbData': thumbData
              };
            }
          }

          // TODO APP1 - Exif
          if (fileMarker == 0xFFEE) {
            // 'Adobe\0'
            if (appData[0] == 0x41 && appData[1] == 0x64 &&
                appData[2] == 0x6F && appData[3] == 0x62 &&
                appData[4] == 0x65 && appData[5] == 0) {
              adobe = {
                'version': appData[6],
                'flags0': (appData[7] << 8) | appData[8],
                'flags1': (appData[9] << 8) | appData[10],
                'transformCode': appData[11]
              };
            }
          }

          t2 = timer.elapsed;
          print('[A] ${t2 - t1}');
          break;

        case 0xFFDB: // DQT (Define Quantization Tables)
          t1 = timer.elapsed;
          int quantizationTablesLength = bytes.readUint16();
          int quantizationTablesEnd = quantizationTablesLength + bytes.position - 2;
          while (bytes.position < quantizationTablesEnd) {
            int quantizationTableSpec = bytes.readByte();
            Data.Int32List tableData = new Data.Int32List(64);
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

            int i = quantizationTableSpec & 15;
            if (quantizationTables.length <= i) {
              quantizationTables.length = i + 1;
            }
            quantizationTables[i] = tableData;
          }
          t2 = timer.elapsed;
          print('[B] ${t2 - t1}');
          break;

        case 0xFFC0: // SOF0 (Start of Frame, Baseline DCT)
        case 0xFFC1: // SOF1 (Start of Frame, Extended DCT)
        case 0xFFC2: // SOF2 (Start of Frame, Progressive DCT)
          t1 = timer.elapsed;
          bytes.readUint16(); // skip data length
          frame = new _JpegFrame();

          frame.extended = (fileMarker == 0xFFC1);
          frame.progressive = (fileMarker == 0xFFC2);
          frame.precision = bytes.readByte();
          frame.scanLines = bytes.readUint16();
          frame.samplesPerLine = bytes.readUint16();

          int componentsCount = bytes.readByte();
          int componentId;
          int maxH = 0;
          int maxV = 0;
          for (i = 0; i < componentsCount; i++) {
            componentId = bytes.readByte();
            int x = bytes.readByte();
            int h = x >> 4;
            int v = x & 15;
            int qId = bytes.readByte();
            frame.componentsOrder.add(componentId);
            frame.components[componentId] =
                new _JpegComponent(h, v, quantizationTables[qId]);
          }
          _prepareComponents(frame);
          frames.add(frame);
          t2 = timer.elapsed;
          print('[C] ${t2 - t1}');
          break;

        case 0xFFC4: // DHT (Define Huffman Tables)
          t1 = timer.elapsed;
          int huffmanLength = bytes.readUint16();
          print('length: $huffmanLength');

          for (i = 2; i < huffmanLength;) {
            int huffmanTableSpec = bytes.readByte();
            print('spec: $huffmanTableSpec');

            Data.Uint8List codeLengths = new Data.Uint8List(16);
            int codeLengthSum = 0;
            for (j = 0; j < 16; j++) {
              codeLengths[j] = bytes.readByte();
              codeLengthSum += codeLengths[j];
            }

            Data.Uint8List huffmanValues = new Data.Uint8List(codeLengthSum);
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
          t2 = timer.elapsed;
          print('[D] ${t2 - t1}');
          break;

        case 0xFFDD: // DRI (Define Restart Interval)
          t1 = timer.elapsed;
          bytes.readUint16(); // skip data length
          resetInterval = bytes.readUint16();
          t2 = timer.elapsed;
          print('[E] ${t2 - t1}');
          break;

        case 0xFFDA: // SOS (Start of Scan)
          t1 = timer.elapsed;
          int scanLength = bytes.readUint16();
          int selectorsCount = bytes.readByte();
          List components = new List(selectorsCount);
          for (i = 0; i < selectorsCount; i++) {
            _JpegComponent component = frame.components[bytes.readByte()];
            int tableSpec = bytes.readByte();
            print('spec $tableSpec');
            if (huffmanTablesDC.length > (tableSpec >> 4)) {
              component.huffmanTableDC = huffmanTablesDC[tableSpec >> 4];
            }
            if (huffmanTablesAC.length > (tableSpec & 15)) {
              component.huffmanTableAC = huffmanTablesAC[tableSpec & 15];
            }
            components[i] = component;
          }
          int spectralStart = bytes.readByte();
          int spectralEnd = bytes.readByte();
          int successiveApproximation = bytes.readByte();
          _decodeScan(bytes,
                      frame, components, resetInterval,
                      spectralStart, spectralEnd,
                      successiveApproximation >> 4,
                      successiveApproximation & 15);
          t2 = timer.elapsed;
          print('[F] ${t2 - t1}');
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

          throw 'unknown JPEG marker ' + fileMarker.toRadixString(16);
      }

      fileMarker = bytes.readUint16();
    }

    if (frames.length != 1) {
      throw 'only single frame JPEGs supported';
    }

    int width = frame.samplesPerLine;
    int height = frame.scanLines;
    Image image = new Image(width, height, Image.RGB);

    var jpeg = {
      'jfif': jfif,
      'adobe': adobe
    };

    List components = [];
    for (int i = 0; i < frame.componentsOrder.length; ++i) {
      var component = frame.components[frame.componentsOrder[i]];
      components.add({
        'scaleX': component.h / frame.maxH,
        'scaleY': component.v / frame.maxV,
        'lines': _buildComponentData(frame, component)
      });
    }
    jpeg['components'] = components;

    _copyToImage(jpeg, image);
    print('[Total] ${timer.elapsed}');

    return image;
  }

  void _copyToImage(Map jpeg, Image imageData) {
    int width = imageData.width;
    int height = imageData.height;
    Data.Uint32List imageDataArray = imageData.buffer;
    Data.Uint8List data = _getData(width, height, jpeg);
    int i = 0, j = 0, x, y;
    int Y, K, C, M, R, G, B;
    List components = jpeg['components'];

    switch (components.length) {
      case 1:
        for (y = 0; y < height; y++) {
          for (x = 0; x < width; x++) {
            Y = data[i++];
            imageDataArray[j++] = getColor(Y, Y, Y, 255);
          }
        }
        break;
      case 3:
        for (y = 0; y < height; y++) {
          for (x = 0; x < width; x++) {
            R = data[i++];
            G = data[i++];
            B = data[i++];

            int c = getColor(R, G, B, 255);
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

            R = 255 - _clamp(C * (1 - K ~/ 255) + K);
            G = 255 - _clamp(M * (1 - K ~/ 255) + K);
            B = 255 - _clamp(Y * (1 - K ~/ 255) + K);

            imageDataArray[j++] = getColor(R, G, B, 255);
          }
        }
        break;
      default:
        throw 'Unsupported color mode';
    }
  }

  Data.Uint8List _getData(int width, int height, Map jpeg) {
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
    bool colorTransform = false;
    int dataLength = width * height * components.length;
    Data.Uint8List data = new Data.Uint8List(dataLength);

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

        num sy1 = component1['scaleY'] * scaleY;
        num sy2 = component2['scaleY'] * scaleY;
        num sy3 = component3['scaleY'] * scaleY;
        num sx1 = component1['scaleX'] * scaleX;
        num sx2 = component2['scaleX'] * scaleX;
        num sx3 = component3['scaleX'] * scaleX;

        var lines1 = component1['lines'];
        var lines2 = component2['lines'];
        var lines3 = component3['lines'];

        for (y = 0; y < height; y++) {
          component1Line = lines1[(y * sy1).toInt()];
          component2Line = lines2[(y * sy2).toInt()];
          component3Line = lines3[(y * sy3).toInt()];
          for (x = 0; x < width; x++) {
            if (!colorTransform) {
              R = component1Line[(x * sx1).toInt()];
              G = component2Line[(x * sx2).toInt()];
              B = component3Line[(x * sx3).toInt()];
            } else {
              Y = component1Line[(x * sx1).toInt()];
              Cb = component2Line[(x * sx2).toInt()];
              Cr = component3Line[(x * sx3).toInt()];

              R = _clamp((Y + 1.402 * (Cr - 128)).toInt());
              G = _clamp((Y - 0.3441363 * (Cb - 128) -
                         0.71413636 * (Cr - 128)).toInt());
              B = _clamp((Y + 1.772 * (Cb - 128)).toInt());
            }

            data[offset++] = R;
            data[offset++] = G;
            data[offset++] = B;
          }
        }
        break;
      case 4:
        if (adobe == null) {
          throw 'Unsupported color mode (4 components)';
        }
        // The default transform for four components is false
        colorTransform = false;
        // The adobe transform marker overrides any previous setting
        if (adobe['transformCode']) {
          colorTransform = true;
        } /*else if (typeof this.colorTransform !== 'undefined') {
          colorTransform = !!this.colorTransform;
        }*/

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

              C = 255 - _clamp((Y + 1.402 * (Cr - 128)).toInt());
              M = 255 - _clamp((Y - 0.3441363 * (Cb - 128) - 0.71413636 * (Cr - 128)).toInt());
              Ye = 255 - _clamp((Y + 1.772 * (Cb - 128)).toInt());
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

  void _prepareComponents(_JpegFrame frame) {
    int maxH = 0;
    int maxV = 0;

    for (int componentId in frame.components.keys) {
      _JpegComponent component = frame.components[componentId];
      if (maxH < component.h) {
        maxH = component.h;
      }
      if (maxV < component.v) {
        maxV = component.v;
      }
    }

    int mcusPerLine = (frame.samplesPerLine / 8 / maxH).ceil();
    int mcusPerColumn = (frame.scanLines / 8 / maxV).ceil();

    for (int componentId in frame.components.keys) {
      _JpegComponent component = frame.components[componentId];
      int blocksPerLine = ((frame.samplesPerLine / 8).ceil() * component.h / maxH).ceil();
      int blocksPerColumn = ((frame.scanLines / 8).ceil() * component.v / maxV).ceil();
      int blocksPerLineForMcu = mcusPerLine * component.h;
      int blocksPerColumnForMcu = mcusPerColumn * component.v;

      List blocks = new List(blocksPerColumnForMcu);
      for (int i = 0; i < blocksPerColumnForMcu; i++) {
        List row = new List(blocksPerLineForMcu);
        for (int j = 0; j < blocksPerLineForMcu; j++) {
          row[j] = new Data.Int32List(64);
        }
        blocks[i] = row;
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

  int _decodeScan(_ByteBuffer bytes,
                  _JpegFrame frame,
                  List components,
                  int resetInterval,
                  int spectralStart,
                  int spectralEnd,
                  int successivePrev,
                  int successive) {
    int precision = frame.precision;
    int samplesPerLine = frame.samplesPerLine;
    int scanLines = frame.scanLines;
    int mcusPerLine = frame.mcusPerLine;
    bool progressive = frame.progressive;
    int maxH = frame.maxH;
    int maxV = frame.maxV;

    int bitsData = 0;
    int bitsCount = 0;

    int _readBit() {
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
      }

      bitsCount = 7;
      return bitsData >> 7;
    }

    int _decodeHuffman(tree) {
      var node = tree;
      int bit;
      while ((bit = _readBit()) != null) {
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

    void _decodeBaseline(_JpegComponent component, List zz) {
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
          if (r < 15)
            break;
          k += 16;
          continue;
        }
        k += r;
        int z = _dctZigZag[k];
        zz[z] = _receiveAndExtend(s);
        k++;
      }
    }

    void _decodeDCFirst(_JpegComponent component, List zz) {
      int t = _decodeHuffman(component.huffmanTableDC);
      int diff = (t == 0) ? 0 : (_receiveAndExtend(t) << successive);
      component.pred += diff;
      zz[0] = component.pred;
    }

    void _decodeDCSuccessive(_JpegComponent component, List zz) {
      zz[0] = (zz[0] | (_readBit() << successive));
    }

    int eobrun = 0;

    void _decodeACFirst(_JpegComponent component, List zz) {
      if (eobrun > 0) {
        eobrun--;
        return;
      }
      int k = spectralStart;
      int e = spectralEnd;
      while (k <= e) {
        int rs = _decodeHuffman(component.huffmanTableAC);
        int s = rs & 15, r = rs >> 4;
        if (s == 0) {
          if (r < 15) {
            eobrun = (_receive(r) + (1 << r) - 1);
            break;
          }
          k += 16;
          continue;
        }
        k += r;
        int z = _dctZigZag[k];
        zz[z] = (_receiveAndExtend(s) * (1 << successive));
        k++;
      }
    }

    int successiveACState = 0, successiveACNextValue;

    void _decodeACSuccessive(_JpegComponent component, zz) {
      int k = spectralStart;
      int e = spectralEnd;
      int r = 0;
      while (k <= e) {
        int z = _dctZigZag[k];
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
                throw 'invalid ACn encoding';
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

    void _decodeMcu(_JpegComponent component, decodeFn,
                    int mcu, int row, int col) {
      int mcuRow = (mcu ~/ mcusPerLine);
      int mcuCol = mcu % mcusPerLine;
      int blockRow = mcuRow * component.v + row;
      int blockCol = mcuCol * component.h + col;
      decodeFn(component, component.blocks[blockRow][blockCol]);
    }

    void _decodeBlock(_JpegComponent component, decodeFn, int mcu) {
      int blockRow = mcu ~/ component.blocksPerLine;
      int blockCol = mcu % component.blocksPerLine;
      decodeFn(component, component.blocks[blockRow][blockCol]);
    }

    int componentsLength = components.length;
    _JpegComponent component;
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
    int marker;
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
      marker = (((bytes.peakAtOffset(0) << 8) | bytes.peakAtOffset(1)));
      if (marker <= 0xFF00) {
        //throw 'marker was not found';
      }

      if (marker >= 0xFFD0 && marker <= 0xFFD7) { // RSTx
        bytes.position += 2;
      } else {
        break;
      }
    }
  }

  List<List<int>> _buildComponentData(_JpegFrame frame,
                                      _JpegComponent component) {
    Duration t1 = timer.elapsed;
    int blocksPerLine = component.blocksPerLine;
    int blocksPerColumn = component.blocksPerColumn;
    int samplesPerLine = (blocksPerLine << 3);
    Data.Int32List R = new Data.Int32List(64);
    Data.Uint8List r = new Data.Uint8List(64);
    List<Data.Uint8List> lines = new List(blocksPerColumn * 8);

    print('$blocksPerColumn $blocksPerLine');
    int l = 0;
    for (int blockRow = 0; blockRow < blocksPerColumn; blockRow++) {
      int scanLine = blockRow << 3;
      for (int i = 0; i < 8; i++) {
        lines[l++] = new Data.Uint8List(samplesPerLine);
      }

      for (int blockCol = 0; blockCol < blocksPerLine; blockCol++) {
        _quantizeAndInverse(component.quantizationTable,
                            component.blocks[blockRow][blockCol],
                            r, R);

        int offset = 0;
        int sample = (blockCol << 3);
        for (int j = 0; j < 8; j++) {
          Data.Uint8List line = lines[scanLine + j];
          for (int i = 0; i < 8; i++) {
            line[sample + i] = r[offset++];
          }
        }
      }
    }
    Duration t2 = timer.elapsed;
    print('[G] ${t2 - t1}');

    return lines;
  }

  // A port of poppler's IDCT method which in turn is taken from:
  //   Christoph Loeffler, Adriaan Ligtenberg, George S. Moschytz,
  //   "Practical Fast 1-D DCT Algorithms with 11 Multiplications",
  //   IEEE Intl. Conf. on Acoustics, Speech & Signal Processing, 1989,
  //   988-991.
  void _quantizeAndInverse(Data.Int32List quantizationTable,
                           Data.Int32List zz,
                           Data.Uint8List dataOut,
                           Data.Int32List dataIn) {
    Data.Int32List p = dataIn;

    // de-quantize
    for (int i = 0; i < 64; i++) {
      p[i] = (zz[i] * quantizationTable[i]);
    }

    // inverse DCT on rows
    int row = 0;
    for (int i = 0; i < 8; ++i, row += 8) {
      // check for all-zero AC coefficients
      if (p[1 + row] == 0 &&
          p[2 + row] == 0 &&
          p[3 + row] == 0 &&
          p[4 + row] == 0 &&
          p[5 + row] == 0 &&
          p[6 + row] == 0 &&
          p[7 + row] == 0) {
        int t = ((_dctSqrt2 * p[0 + row] + 512) >> 10);
        p.fillRange(row, row + 8, t);
        continue;
      }

      // stage 4
      int v0 = ((_dctSqrt2 * p[0 + row] + 128) >> 8);
      int v1 = ((_dctSqrt2 * p[4 + row] + 128) >> 8);
      int v2 = p[2 + row];
      int v3 = p[6 + row];
      int v4 = ((_dctSqrt1d2 * (p[1 + row] - p[7 + row]) + 128) >> 8);
      int v7 = ((_dctSqrt1d2 * (p[1 + row] + p[7 + row]) + 128) >> 8);
      int v5 = (p[3 + row] << 4);
      int v6 = (p[5 + row] << 4);

      // stage 3
      int t = ((v0 - v1+ 1) >> 1);
      v0 = ((v0 + v1 + 1) >> 1);
      v1 = t;
      t = ((v2 * _dctSin6 + v3 * _dctCos6 + 128) >> 8);
      v2 = ((v2 * _dctCos6 - v3 * _dctSin6 + 128) >> 8);
      v3 = t;
      t = ((v4 - v6 + 1) >> 1);
      v4 = ((v4 + v6 + 1) >> 1);
      v6 = t;
      t = ((v7 + v5 + 1) >> 1);
      v5 = ((v7 - v5 + 1) >> 1);
      v7 = t;

      // stage 2
      t = ((v0 - v3 + 1) >> 1);
      v0 = ((v0 + v3 + 1) >> 1);
      v3 = t;
      t = ((v1 - v2 + 1) >> 1);
      v1 = ((v1 + v2 + 1) >> 1);
      v2 = t;
      t = ((v4 * _dctSin3 + v7 * _dctCos3 + 2048) >> 12);
      v4 = ((v4 * _dctCos3 - v7 * _dctSin3 + 2048) >> 12);
      v7 = t;
      t = ((v5 * _dctSin1 + v6 * _dctCos1 + 2048) >> 12);
      v5 = ((v5 * _dctCos1 - v6 * _dctSin1 + 2048) >> 12);
      v6 = t;

      // stage 1
      p[0 + row] = (v0 + v7);
      p[7 + row] = (v0 - v7);
      p[1 + row] = (v1 + v6);
      p[6 + row] = (v1 - v6);
      p[2 + row] = (v2 + v5);
      p[5 + row] = (v2 - v5);
      p[3 + row] = (v3 + v4);
      p[4 + row] = (v3 - v4);
    }

    // inverse DCT on columns
    for (int i = 0; i < 8; ++i) {
      int col = i;

      // check for all-zero AC coefficients
      if (p[1 * 8 + col] == 0 &&
          p[2 * 8 + col] == 0 &&
          p[3 * 8 + col] == 0 &&
          p[4 * 8 + col] == 0 &&
          p[5 * 8 + col] == 0 &&
          p[6 * 8 + col] == 0 &&
          p[7 * 8 + col] == 0) {
        int t = ((_dctSqrt2 * dataIn[i] + 8192) >> 14);
        p[0 * 8 + col] = t;
        p[1 * 8 + col] = t;
        p[2 * 8 + col] = t;
        p[3 * 8 + col] = t;
        p[4 * 8 + col] = t;
        p[5 * 8 + col] = t;
        p[6 * 8 + col] = t;
        p[7 * 8 + col] = t;
        continue;
      }

      // stage 4
      int v0 = ((_dctSqrt2 * p[0 * 8 + col] + 2048) >> 12);
      int v1 = ((_dctSqrt2 * p[4 * 8 + col] + 2048) >> 12);
      int v2 = p[2 * 8 + col];
      int v3 = p[6 * 8 + col];
      int v4 = ((_dctSqrt1d2 * (p[1 * 8 + col] - p[7*8 + col]) + 2048) >> 12);
      int v7 = ((_dctSqrt1d2 * (p[1 * 8 + col] + p[7*8 + col]) + 2048) >> 12);
      int v5 = p[3 * 8 + col];
      int v6 = p[5 * 8 + col];

      // stage 3
      int t = ((v0 - v1 + 1) >> 1);
      v0 = ((v0 + v1 + 1) >> 1);
      v1 = t;
      t = ((v2 * _dctSin6 + v3 * _dctCos6 + 2048) >> 12);
      v2 = ((v2 * _dctCos6 - v3 * _dctSin6 + 2048) >> 12);
      v3 = t;
      t = ((v4 - v6 + 1) >> 1);
      v4 = ((v4 + v6 + 1) >> 1);
      v6 = t;
      t = ((v7 + v5 + 1) >> 1);
      v5 = ((v7 - v5 + 1) >> 1);
      v7 = t;

      // stage 2
      t = ((v0 - v3 + 1) >> 1);
      v0 = ((v0 + v3 + 1) >> 1);
      v3 = t;
      t = ((v1 - v2 + 1) >> 1);
      v1 = ((v1 + v2 + 1) >> 1);
      v2 = t;
      t = ((v4 * _dctSin3 + v7 * _dctCos3 + 2048) >> 12);
      v4 = ((v4 * _dctCos3 - v7 * _dctSin3 + 2048) >> 12);
      v7 = t;
      t = ((v5 * _dctSin1 + v6 * _dctCos1 + 2048) >> 12);
      v5 = ((v5 * _dctCos1 - v6 * _dctSin1 + 2048) >> 12);
      v6 = t;

      // stage 1
      p[0 * 8 + col] = (v0 + v7);
      p[7 * 8 + col] = (v0 - v7);
      p[1 * 8 + col] = (v1 + v6);
      p[6 * 8 + col] = (v1 - v6);
      p[2 * 8 + col] = (v2 + v5);
      p[5 * 8 + col] = (v2 - v5);
      p[3 * 8 + col] = (v3 + v4);
      p[4 * 8 + col] = (v3 - v4);
    }

    // convert to 8-bit integers
    for (int i = 0; i < 64; ++i) {
      int sample = (128 + ((p[i] + 8) >> 4));
      dataOut[i] = sample < 0 ? 0 : sample > 0xFF ? 0xFF : sample;
    }
  }

  int _clamp(int a) {
    int i = a;//.toInt();
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
        q = { 'children': [],
              'index': 0 };
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

  static const int _dctCos1  = 4017;  // cos(pi/16)
  static const int _dctSin1  = 799;   // sin(pi/16)
  static const int _dctCos3  = 3406;  // cos(3*pi/16)
  static const int _dctSin3  = 2276;  // sin(3*pi/16)
  static const int _dctCos6  = 1567;  // cos(6*pi/16)
  static const int _dctSin6  = 3784;  // sin(6*pi/16)
  static const int _dctSqrt2 = 5793;  // sqrt(2)
  static const int _dctSqrt1d2 = 2896; // sqrt(2) / 2
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
  Data.Int32List quantizationTable;
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
