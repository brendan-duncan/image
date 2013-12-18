part of dart_image;

class _JpegData {
  _ByteBuffer fp;
  _JpegJfif jfif;
  _JpegAdobe adobe;
  _JpegFrame frame;
  int resetInterval;
  List quantizationTables = new List(_Jpeg.NUM_QUANT_TBLS);
  List<_JpegFrame> frames = [];
  List huffmanTablesAC = [];
  List huffmanTablesDC = [];

  List components = [];

  _JpegData(List<int> data) :
    fp = new _ByteBuffer.fromList(data) {
    _read();

    if (frames.length != 1) {
      throw 'Only single frame JPEGs supported';
    }

    for (int i = 0; i < frame.componentsOrder.length; ++i) {
      var component = frame.components[frame.componentsOrder[i]];
      components.add({
        'scaleX': component.h / frame.maxH,
        'scaleY': component.v / frame.maxV,
        'lines': _buildComponentData(frame, component)
      });
    }
  }

  int get width => frame.samplesPerLine;

  int get height => frame.scanLines;

  Data.Uint8List getData(int width, int height) {
    num scaleX = 1;
    num scaleY = 1;
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
        if (adobe.transformCode != 0) {
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

  void _read() {
    int marker = _nextMarker();
    if (marker != _Jpeg.M_SOI) { // SOI (Start of Image)
      throw 'SOI not found';
    }

    marker = _nextMarker();
    while (marker != _Jpeg.M_EOI && !fp.isEOF) { // EOI (End of image)
      switch(marker) {
        case _Jpeg.M_APP0:
        case _Jpeg.M_APP1:
        case _Jpeg.M_APP2:
        case _Jpeg.M_APP3:
        case _Jpeg.M_APP4:
        case _Jpeg.M_APP5:
        case _Jpeg.M_APP6:
        case _Jpeg.M_APP7:
        case _Jpeg.M_APP8:
        case _Jpeg.M_APP9:
        case _Jpeg.M_APP10:
        case _Jpeg.M_APP11:
        case _Jpeg.M_APP12:
        case _Jpeg.M_APP13:
        case _Jpeg.M_APP14:
        case _Jpeg.M_APP15:
        case _Jpeg.M_COM:
          _readAppData(marker);
          break;

        case _Jpeg.M_DQT: // DQT (Define Quantization Tables)
          _readDQT();
          break;

        case _Jpeg.M_SOF0: // SOF0 (Start of Frame, Baseline DCT)
        case _Jpeg.M_SOF1: // SOF1 (Start of Frame, Extended DCT)
        case _Jpeg.M_SOF2: // SOF2 (Start of Frame, Progressive DCT)
          _readFrame(marker);
          break;

        case _Jpeg.M_SOF3:
        case _Jpeg.M_SOF5:
        case _Jpeg.M_SOF6:
        case _Jpeg.M_SOF7:
        case _Jpeg.M_JPG:
        case _Jpeg.M_SOF9:
        case _Jpeg.M_SOF10:
        case _Jpeg.M_SOF11:
        case _Jpeg.M_SOF13:
        case _Jpeg.M_SOF14:
        case _Jpeg.M_SOF15:
          throw 'Unhandled frame type ${marker.toRadixString(16)}';
          break;

        case _Jpeg.M_DHT: // DHT (Define Huffman Tables)
          _readDHT();
          break;

        case _Jpeg.M_DRI: // DRI (Define Restart Interval)
          _readDRI();
          break;

        case _Jpeg.M_SOS: // SOS (Start of Scan)
          _readSOS();
          break;

        default:
          if (fp.peakAtOffset(-3) == 0xFF &&
              fp.peakAtOffset(-2) >= 0xC0 &&
              fp.peakAtOffset(-2) <= 0xFE) {
            // could be incorrect encoding -- last 0xFF byte of the previous
            // block was eaten by the encoder
            fp.position -= 3;
            break;
          }

          throw 'unknown JPEG marker ' + marker.toRadixString(16);
      }

      marker = _nextMarker();
    }
  }

  int _nextMarker() {
    int b = fp.readByte();
    if (b != 0xff) {
      throw 'Invalid Marker ${b.toRadixString(16)}';
    }
    return fp.readByte();
  }

  void _readAppData(int marker) {
    List<int> appData = fp.readBlock();

    if (marker == _Jpeg.M_APP0) {
      // 'JFIF\0'
      if (appData[0] == 0x4A && appData[1] == 0x46 &&
          appData[2] == 0x49 && appData[3] == 0x46 && appData[4] == 0) {
        jfif = new _JpegJfif();
        jfif.majorVersion = appData[5];
        jfif.minorVersion = appData[6];
        jfif.densityUnits = appData[7];
        jfif.xDensity = (appData[8] << 8) | appData[9];
        jfif.yDensity = (appData[10] << 8) | appData[11];
        jfif.thumbWidth = appData[12];
        jfif.thumbHeight = appData[13];
        int thumbSize = 3 * jfif.thumbWidth * jfif.thumbHeight;
        jfif.thumbData = appData.sublist(14, 14 + thumbSize);
      }
    }

    if (marker == _Jpeg.M_APP14) {
      // 'Adobe\0'
      if (appData[0] == 0x41 && appData[1] == 0x64 &&
          appData[2] == 0x6F && appData[3] == 0x62 &&
          appData[4] == 0x65 && appData[5] == 0) {
        adobe = new _JpegAdobe();
        adobe.version = appData[6];
        adobe.flags0 = (appData[7] << 8) | appData[8];
        adobe.flags1 = (appData[9] << 8) | appData[10];
        adobe.transformCode = appData[11];
      }
    }
  }

  void _readDQT() {
    int length = fp.readUint16();

    length -= 2;

    while (length > 0) {
      int n = fp.readByte();
      int prec = n >> 4;
      n &= 0x0F;

      if (n >= _Jpeg.NUM_QUANT_TBLS) {
        throw 'Invalid number of quantization tables';
      }

      if (quantizationTables[n] == null) {
        quantizationTables[n] = new Data.Int32List(64);;
      }

      Data.Int32List tableData = quantizationTables[n];
      for (int i = 0; i < _Jpeg.DCTSIZE2; i++) {
        int tmp;
        if (prec != 0) {
          tmp = fp.readUint16();
        } else {
          tmp = fp.readByte();
        }

        tableData[_Jpeg.dctNaturalOrder[i]] = tmp;
      }

      length -= _Jpeg.DCTSIZE2 + 1;
      if (prec != 0) {
        length -= _Jpeg.DCTSIZE2;
      }
    }

    if (length != 0) {
      throw 'Bad length for DQT block';
    }
  }

  void _readFrame(int marker) {
    if (frame != null) {
      throw 'Duplicate Frame';
    }

    int length = fp.readUint16(); // skip data length
    frame = new _JpegFrame();

    frame.extended = (marker == _Jpeg.M_SOF1);
    frame.progressive = (marker == _Jpeg.M_SOF2);
    frame.precision = fp.readByte();
    frame.scanLines = fp.readUint16();
    frame.samplesPerLine = fp.readUint16();

    int numComponents = fp.readByte();

    length -= 8;

    for (int i = 0; i < numComponents; i++) {
      int componentId = fp.readByte();
      int x = fp.readByte();
      int h = (x >> 4) & 15;
      int v = x & 15;
      int qId = fp.readByte();
      frame.componentsOrder.add(componentId);
      frame.components[componentId] =
          new _JpegComponent(h, v, quantizationTables[qId]);
    }

    frame.prepare();
    frames.add(frame);
  }

  void _readDHT() {
    int length = fp.readUint16();
    length -= 2;

    while (length > 16) {
      int index = fp.readByte();

      Data.Uint8List bits = new Data.Uint8List(16);
      int count = 0;
      for (int j = 0; j < 16; j++) {
        bits[j] = fp.readByte();
        count += bits[j];
      }

      length -= 17;

      Data.Uint8List huffmanValues = new Data.Uint8List(count);
      for (int j = 0; j < count; j++) {
        huffmanValues[j] = fp.readByte();
      }
      length -= count;

      var ht;
      if (index & 0x10 != 0) { // AC table definition
        index -= 0x10;
        ht = huffmanTablesAC;
      } else { // DC table definition
        ht = huffmanTablesDC;
      }

      if (ht.length <= index) {
        ht.length = index + 1;
      }

      ht[index] = _buildHuffmanTable(bits, huffmanValues);
    }
  }

  void _readDRI() {
    int length = fp.readUint16(); // skip data length
    resetInterval = fp.readUint16();
  }

  void _readSOS() {
    int length = fp.readUint16();
    int n = fp.readByte();

    if (length != (n * 2 + 6) || n < 1 || n > _Jpeg.MAX_COMPS_IN_SCAN) {
      throw 'Invalid SOS block';
    }

    List components = new List(n);
    for (int i = 0; i < n; i++) {
      int id = fp.readByte();
      int c = fp.readByte();

      if (!frame.components.containsKey(id)) {
        throw 'Invalid Component in SOS block';
      }

      _JpegComponent component = frame.components[id];
      components[i] = component;

      int dc_tbl_no = (c >> 4) & 15;
      int ac_tbl_no = c & 15;

      if (dc_tbl_no < huffmanTablesDC.length) {
        component.huffmanTableDC = huffmanTablesDC[dc_tbl_no];
      }
      if (ac_tbl_no < huffmanTablesAC.length) {
        component.huffmanTableAC = huffmanTablesAC[ac_tbl_no];
      }
    }

    int spectralStart = fp.readByte();
    int spectralEnd = fp.readByte();
    int successiveApproximation = fp.readByte();

    int Ah = (successiveApproximation >> 4) & 15;
    int Al = successiveApproximation & 15;

    new _JpegScan(fp, frame, components, resetInterval,
                  spectralStart, spectralEnd, Ah, Al).decode();
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

  List<Data.Uint8List> _buildComponentData(_JpegFrame frame,
                                           _JpegComponent component) {
    int blocksPerLine = component.blocksPerLine;
    int blocksPerColumn = component.blocksPerColumn;
    int samplesPerLine = (blocksPerLine << 3);
    Data.Int32List R = new Data.Int32List(64);
    Data.Uint8List r = new Data.Uint8List(64);
    List<Data.Uint8List> lines = new List(blocksPerColumn * 8);

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
        int t = ((_Jpeg.dctSqrt2 * p[0 + row] + 512) >> 10);
        p.fillRange(row, row + 8, t);
        continue;
      }

      // stage 4
      int v0 = ((_Jpeg.dctSqrt2 * p[0 + row] + 128) >> 8);
      int v1 = ((_Jpeg.dctSqrt2 * p[4 + row] + 128) >> 8);
      int v2 = p[2 + row];
      int v3 = p[6 + row];
      int v4 = ((_Jpeg.dctSqrt1d2 * (p[1 + row] - p[7 + row]) + 128) >> 8);
      int v7 = ((_Jpeg.dctSqrt1d2 * (p[1 + row] + p[7 + row]) + 128) >> 8);
      int v5 = (p[3 + row] << 4);
      int v6 = (p[5 + row] << 4);

      // stage 3
      int t = ((v0 - v1+ 1) >> 1);
      v0 = ((v0 + v1 + 1) >> 1);
      v1 = t;
      t = ((v2 * _Jpeg.dctSin6 + v3 * _Jpeg.dctCos6 + 128) >> 8);
      v2 = ((v2 * _Jpeg.dctCos6 - v3 * _Jpeg.dctSin6 + 128) >> 8);
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
      t = ((v4 * _Jpeg.dctSin3 + v7 * _Jpeg.dctCos3 + 2048) >> 12);
      v4 = ((v4 * _Jpeg.dctCos3 - v7 * _Jpeg.dctSin3 + 2048) >> 12);
      v7 = t;
      t = ((v5 * _Jpeg.dctSin1 + v6 * _Jpeg.dctCos1 + 2048) >> 12);
      v5 = ((v5 * _Jpeg.dctCos1 - v6 * _Jpeg.dctSin1 + 2048) >> 12);
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
        int t = ((_Jpeg.dctSqrt2 * dataIn[i] + 8192) >> 14);
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
      int v0 = ((_Jpeg.dctSqrt2 * p[0 * 8 + col] + 2048) >> 12);
      int v1 = ((_Jpeg.dctSqrt2 * p[4 * 8 + col] + 2048) >> 12);
      int v2 = p[2 * 8 + col];
      int v3 = p[6 * 8 + col];
      int v4 = ((_Jpeg.dctSqrt1d2 * (p[1 * 8 + col] - p[7*8 + col]) + 2048) >> 12);
      int v7 = ((_Jpeg.dctSqrt1d2 * (p[1 * 8 + col] + p[7*8 + col]) + 2048) >> 12);
      int v5 = p[3 * 8 + col];
      int v6 = p[5 * 8 + col];

      // stage 3
      int t = ((v0 - v1 + 1) >> 1);
      v0 = ((v0 + v1 + 1) >> 1);
      v1 = t;
      t = ((v2 * _Jpeg.dctSin6 + v3 * _Jpeg.dctCos6 + 2048) >> 12);
      v2 = ((v2 * _Jpeg.dctCos6 - v3 * _Jpeg.dctSin6 + 2048) >> 12);
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
      t = ((v4 * _Jpeg.dctSin3 + v7 * _Jpeg.dctCos3 + 2048) >> 12);
      v4 = ((v4 * _Jpeg.dctCos3 - v7 * _Jpeg.dctSin3 + 2048) >> 12);
      v7 = t;
      t = ((v5 * _Jpeg.dctSin1 + v6 * _Jpeg.dctCos1 + 2048) >> 12);
      v5 = ((v5 * _Jpeg.dctCos1 - v6 * _Jpeg.dctSin1 + 2048) >> 12);
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

  int _clamp(int i) {
    return i < 0 ? 0 : i > 255 ? 255 : i;
  }
}
