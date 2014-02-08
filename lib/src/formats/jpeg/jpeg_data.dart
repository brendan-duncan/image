part of image;

class JpegData {
  InputStream input;
  JpegJfif jfif;
  JpegAdobe adobe;
  JpegFrame frame;
  int resetInterval;
  final List quantizationTables = new List(Jpeg.NUM_QUANT_TBLS);
  final List<JpegFrame> frames = [];
  final List huffmanTablesAC = [];
  final List huffmanTablesDC = [];
  final List<Map> components = [];

  bool validate(List<int> bytes) {
    InputStream input = new InputStream(bytes,
                                                byteOrder: BIG_ENDIAN);

    int marker = _nextMarker();
    if (marker != Jpeg.M_SOI) {
      return false;
    }

    bool hasSOF = false;
    bool hasSOS = false;

    marker = _nextMarker();
    while (marker != Jpeg.M_EOI && !input.isEOS) { // EOI (End of image)
      _skipBlock();
      switch (marker) {
        case Jpeg.M_APP0:
        case Jpeg.M_APP1:
        case Jpeg.M_APP2:
        case Jpeg.M_APP3:
        case Jpeg.M_APP4:
        case Jpeg.M_APP5:
        case Jpeg.M_APP6:
        case Jpeg.M_APP7:
        case Jpeg.M_APP8:
        case Jpeg.M_APP9:
        case Jpeg.M_APP10:
        case Jpeg.M_APP11:
        case Jpeg.M_APP12:
        case Jpeg.M_APP13:
        case Jpeg.M_APP14:
        case Jpeg.M_APP15:
        case Jpeg.M_COM:
          break;

        case Jpeg.M_DQT: // DQT (Define Quantization Tables)
          break;

        case Jpeg.M_SOF0: // SOF0 (Start of Frame, Baseline DCT)
        case Jpeg.M_SOF1: // SOF1 (Start of Frame, Extended DCT)
        case Jpeg.M_SOF2: // SOF2 (Start of Frame, Progressive DCT)
          hasSOF = true;
          break;

        case Jpeg.M_SOF3:
        case Jpeg.M_SOF5:
        case Jpeg.M_SOF6:
        case Jpeg.M_SOF7:
        case Jpeg.M_JPG:
        case Jpeg.M_SOF9:
        case Jpeg.M_SOF10:
        case Jpeg.M_SOF11:
        case Jpeg.M_SOF13:
        case Jpeg.M_SOF14:
        case Jpeg.M_SOF15:
          break;

        case Jpeg.M_DHT: // DHT (Define Huffman Tables)
          break;

        case Jpeg.M_DRI: // DRI (Define Restart Interval)
          break;

        case Jpeg.M_SOS: // SOS (Start of Scan)
          hasSOS = true;
          break;

        default:
          if (input.buffer[input.position - 3] == 0xFF &&
              input.buffer[input.position - 2] >= 0xC0 &&
              input.buffer[input.position - 2] <= 0xFE) {
            // could be incorrect encoding -- last 0xFF byte of the previous
            // block was eaten by the encoder
            input.position -= 3;
            break;
          }

          if (marker != 0) {
            return false;
          }
          break;
      }

      marker = _nextMarker();
    }

    return hasSOF && hasSOS;
  }

  void read(List<int> bytes) {
    input = new InputStream(bytes, byteOrder: BIG_ENDIAN);

    _read();

    if (frames.length != 1) {
      throw new ImageException('Only single frame JPEGs supported');
    }

    for (int i = 0; i < frame.componentsOrder.length; ++i) {
      JpegComponent component = frame.components[frame.componentsOrder[i]];
      components.add({
        'scaleX': component.h / frame.maxH,
        'scaleY': component.v / frame.maxV,
        'lines': _buildComponentData(frame, component)
      });
    }
  }

  int get width => frame.samplesPerLine;

  int get height => frame.scanLines;

  Uint8List getData(int width, int height) {
    num scaleX = 1;
    num scaleY = 1;
    Map component1;
    Map component2;
    Map component3;
    Map component4;
    Uint8List component1Line;
    Uint8List component2Line;
    Uint8List component3Line;
    Uint8List component4Line;
    int offset = 0;
    int Y, Cb, Cr, K, C, M, Ye, R, G, B;
    bool colorTransform = false;
    int dataLength = width * height * components.length;
    Uint8List data = new Uint8List(dataLength);

    switch (components.length) {
      case 1:
        component1 = components[0];
        for (int y = 0; y < height; y++) {
          component1Line = component1['lines'][(y * component1['scaleY'] * scaleY).toInt()];
          for (int x = 0; x < width; x++) {
            Y = component1Line[(x * component1['scaleX'] * scaleX).toInt()];
            data[offset++] = Y;
          }
        }
        break;
      case 2:
        // PDF might compress two component data in custom colorspace
        component1 = components[0];
        component2 = components[1];
        for (int y = 0; y < height; y++) {
          component1Line = component1['lines'][0 | (y * component1['scaleY'] * scaleY)];
          component2Line = component2['lines'][0 | (y * component2['scaleY'] * scaleY)];
          for (int x = 0; x < width; x++) {
            Y = component1Line[(x * component1['scaleX'] * scaleX).toInt()];
            data[offset++] = Y;
            Y = component2Line[(x * component2['scaleX'] * scaleX).toInt()];
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

        List<Uint8List> lines1 = component1['lines'];
        List<Uint8List> lines2 = component2['lines'];
        List<Uint8List> lines3 = component3['lines'];

        for (int y = 0; y < height; y++) {
          component1Line = lines1[(y * sy1).toInt()];
          component2Line = lines2[(y * sy2).toInt()];
          component3Line = lines3[(y * sy3).toInt()];
          for (int x = 0; x < width; x++) {
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
          throw new ImageException('Unsupported color mode (4 components)');
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

        for (int y = 0; y < height; y++) {
          component1Line = component1['lines'][0 | (y * component1['scaleY'] * scaleY)];
          component2Line = component2['lines'][0 | (y * component2['scaleY'] * scaleY)];
          component3Line = component3['lines'][0 | (y * component3['scaleY'] * scaleY)];
          component4Line = component4['lines'][0 | (y * component4['scaleY'] * scaleY)];
          for (int x = 0; x < width; x++) {
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
        throw new ImageException('Unsupported color mode');
    }
    return data;
  }

  void _read() {
    int marker = _nextMarker();
    if (marker != Jpeg.M_SOI) { // SOI (Start of Image)
      throw new ImageException('Start Of Image marker not found.');
    }

    marker = _nextMarker();
    while (marker != Jpeg.M_EOI && !input.isEOS) {
      InputStream block = _readBlock();
      switch (marker) {
        case Jpeg.M_APP0:
        case Jpeg.M_APP1:
        case Jpeg.M_APP2:
        case Jpeg.M_APP3:
        case Jpeg.M_APP4:
        case Jpeg.M_APP5:
        case Jpeg.M_APP6:
        case Jpeg.M_APP7:
        case Jpeg.M_APP8:
        case Jpeg.M_APP9:
        case Jpeg.M_APP10:
        case Jpeg.M_APP11:
        case Jpeg.M_APP12:
        case Jpeg.M_APP13:
        case Jpeg.M_APP14:
        case Jpeg.M_APP15:
        case Jpeg.M_COM:
          _readAppData(marker, block);
          break;

        case Jpeg.M_DQT: // DQT (Define Quantization Tables)
          _readDQT(block);
          break;

        case Jpeg.M_SOF0: // SOF0 (Start of Frame, Baseline DCT)
        case Jpeg.M_SOF1: // SOF1 (Start of Frame, Extended DCT)
        case Jpeg.M_SOF2: // SOF2 (Start of Frame, Progressive DCT)
          _readFrame(marker, block);
          break;

        case Jpeg.M_SOF3:
        case Jpeg.M_SOF5:
        case Jpeg.M_SOF6:
        case Jpeg.M_SOF7:
        case Jpeg.M_JPG:
        case Jpeg.M_SOF9:
        case Jpeg.M_SOF10:
        case Jpeg.M_SOF11:
        case Jpeg.M_SOF13:
        case Jpeg.M_SOF14:
        case Jpeg.M_SOF15:
          throw new ImageException('Unhandled frame type ${marker.toRadixString(16)}');
          break;

        case Jpeg.M_DHT: // DHT (Define Huffman Tables)
          _readDHT(block);
          break;

        case Jpeg.M_DRI: // DRI (Define Restart Interval)
          _readDRI(block);
          break;

        case Jpeg.M_SOS: // SOS (Start of Scan)
          _readSOS(block);
          break;

        default:
          if (input.buffer[input.position - 3] == 0xFF &&
              input.buffer[input.position - 2] >= 0xC0 &&
              input.buffer[input.position - 2] <= 0xFE) {
            // could be incorrect encoding -- last 0xFF byte of the previous
            // block was eaten by the encoder
            input.position -= 3;
            break;
          }

          if (marker != 0) {
            throw new ImageException('Unknown JPEG marker ' +
                marker.toRadixString(16));
          }
          break;
      }

      marker = _nextMarker();
    }
  }

  void _skipBlock() {
    int length = input.readUint16();
    if (length < 2) {
      throw new ImageException('Invalid Block');
    }
    input.position += length - 2;
  }

  InputStream _readBlock() {
    int length = input.readUint16();
    if (length < 2) {
      throw new ImageException('Invalid Block');
    }
    List<int> array = input.readBytes(length - 2);
    return new InputStream(array, byteOrder: BIG_ENDIAN);
  }

  int _nextMarker() {
    int c = 0;

    do {
      do {
        c = input.readByte();
      } while (c != 0xff && !input.isEOS);

      do {
        c = input.readByte();
      } while (c == 0xff && !input.isEOS);
    } while (c == 0 && !input.isEOS);

    return c;
  }

  void _readAppData(int marker, InputStream block) {
    List<int> appData = block.buffer;

    if (marker == Jpeg.M_APP0) {
      // 'JFIF\0'
      if (appData[0] == 0x4A && appData[1] == 0x46 &&
          appData[2] == 0x49 && appData[3] == 0x46 && appData[4] == 0) {
        jfif = new JpegJfif();
        jfif.majorVersion = appData[5];
        jfif.minorVersion = appData[6];
        jfif.densityUnits = appData[7];
        jfif.xDensity = _shiftL(appData[8], 8) | appData[9];
        jfif.yDensity = _shiftL(appData[10], 8) | appData[11];
        jfif.thumbWidth = appData[12];
        jfif.thumbHeight = appData[13];
        int thumbSize = 3 * jfif.thumbWidth * jfif.thumbHeight;
        jfif.thumbData = appData.sublist(14, 14 + thumbSize);
      }
    }

    if (marker == Jpeg.M_APP14) {
      // 'Adobe\0'
      if (appData[0] == 0x41 && appData[1] == 0x64 &&
          appData[2] == 0x6F && appData[3] == 0x62 &&
          appData[4] == 0x65 && appData[5] == 0) {
        adobe = new JpegAdobe();
        adobe.version = appData[6];
        adobe.flags0 = _shiftL(appData[7], 8) | appData[8];
        adobe.flags1 = _shiftL(appData[9], 8) | appData[10];
        adobe.transformCode = appData[11];
      }
    }
  }

  void _readDQT(InputStream block) {
    while (!block.isEOS) {
      int n = block.readByte();
      int prec = _shiftR(n, 4);
      n &= 0x0F;

      if (n >= Jpeg.NUM_QUANT_TBLS) {
        throw new ImageException('Invalid number of quantization tables');
      }

      if (quantizationTables[n] == null) {
        quantizationTables[n] = new Int32List(64);;
      }

      Int32List tableData = quantizationTables[n];
      for (int i = 0; i < Jpeg.DCTSIZE2; i++) {
        int tmp;
        if (prec != 0) {
          tmp = block.readUint16();
        } else {
          tmp = block.readByte();
        }

        tableData[Jpeg.dctNaturalOrder[i]] = tmp;
      }
    }

    if (!block.isEOS) {
      throw new ImageException('Bad length for DQT block');
    }
  }

  void _readFrame(int marker, InputStream block) {
    if (frame != null) {
      throw new ImageException('Duplicate JPG frame data found.');
    }

    frame = new JpegFrame();
    frame.extended = (marker == Jpeg.M_SOF1);
    frame.progressive = (marker == Jpeg.M_SOF2);
    frame.precision = block.readByte();
    frame.scanLines = block.readUint16();
    frame.samplesPerLine = block.readUint16();

    int numComponents = block.readByte();

    for (int i = 0; i < numComponents; i++) {
      int componentId = block.readByte();
      int x = block.readByte();
      int h = _shiftR(x, 4) & 15;
      int v = x & 15;
      int qId = block.readByte();
      frame.componentsOrder.add(componentId);
      frame.components[componentId] =
          new JpegComponent(h, v, quantizationTables, qId);
    }

    frame.prepare();
    frames.add(frame);
  }

  void _readDHT(InputStream block) {
    while (!block.isEOS) {
      int index = block.readByte();

      Uint8List bits = new Uint8List(16);
      int count = 0;
      for (int j = 0; j < 16; j++) {
        bits[j] = block.readByte();
        count += bits[j];
      }

      Uint8List huffmanValues = new Uint8List(count);
      for (int j = 0; j < count; j++) {
        huffmanValues[j] = block.readByte();
      }

      List ht;
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

  void _readDRI(InputStream block) {
    resetInterval = block.readUint16();
  }

  void _readSOS(InputStream block) {
    int n = block.readByte();

    if (n < 1 || n > Jpeg.MAX_COMPS_IN_SCAN) {
      throw new ImageException('Invalid SOS block');
    }

    List components = new List(n);
    for (int i = 0; i < n; i++) {
      int id = block.readByte();
      int c = block.readByte();

      if (!frame.components.containsKey(id)) {
        throw new ImageException('Invalid Component in SOS block');
      }

      JpegComponent component = frame.components[id];
      components[i] = component;

      int dc_tbl_no = _shiftR(c, 4) & 15;
      int ac_tbl_no = c & 15;

      if (dc_tbl_no < huffmanTablesDC.length) {
        component.huffmanTableDC = huffmanTablesDC[dc_tbl_no];
      }
      if (ac_tbl_no < huffmanTablesAC.length) {
        component.huffmanTableAC = huffmanTablesAC[ac_tbl_no];
      }
    }

    int spectralStart = block.readByte();
    int spectralEnd = block.readByte();
    int successiveApproximation = block.readByte();

    int Ah = _shiftR(successiveApproximation, 4) & 15;
    int Al = successiveApproximation & 15;

    new JpegScan(input, frame, components, resetInterval,
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

  List<Uint8List> _buildComponentData(JpegFrame frame,
                                           JpegComponent component) {
    int blocksPerLine = component.blocksPerLine;
    int blocksPerColumn = component.blocksPerColumn;
    int samplesPerLine = _shiftL(blocksPerLine, 3);
    Int32List R = new Int32List(64);
    Uint8List r = new Uint8List(64);
    List<Uint8List> lines = new List(blocksPerColumn * 8);

    int l = 0;
    for (int blockRow = 0; blockRow < blocksPerColumn; blockRow++) {
      int scanLine = _shiftL(blockRow, 3);
      for (int i = 0; i < 8; i++) {
        lines[l++] = new Uint8List(samplesPerLine);
      }

      for (int blockCol = 0; blockCol < blocksPerLine; blockCol++) {
        _quantizeAndInverse(component.quantizationTable,
                            component.blocks[blockRow][blockCol],
                            r, R);

        int offset = 0;
        int sample = _shiftL(blockCol, 3);
        for (int j = 0; j < 8; j++) {
          Uint8List line = lines[scanLine + j];
          for (int i = 0; i < 8; i++) {
            line[sample + i] = r[offset++];
          }
        }
      }
    }

    return lines;
  }

  /**
   * A port of poppler's IDCT method which in turn is taken from:
   * Christoph Loeffler, Adriaan Ligtenberg, George S. Moschytz,
   * "Practical Fast 1-D DCT Algorithms with 11 Multiplications",
   * IEEE Intl. Conf. on Acoustics, Speech & Signal Processing, 1989, 988-991.
   */
  void _quantizeAndInverse(Int32List quantizationTable,
                           Int32List zz,
                           Uint8List dataOut,
                           Int32List dataIn) {
    Int32List p = dataIn;

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
        int t = _shiftR((Jpeg.dctSqrt2 * p[0 + row] + 512), 10);
        p.fillRange(row, row + 8, t);
        continue;
      }

      // stage 4
      int v0 = _shiftR((Jpeg.dctSqrt2 * p[0 + row] + 128), 8);
      int v1 = _shiftR((Jpeg.dctSqrt2 * p[4 + row] + 128), 8);
      int v2 = p[2 + row];
      int v3 = p[6 + row];
      int v4 = _shiftR((Jpeg.dctSqrt1d2 * (p[1 + row] - p[7 + row]) + 128), 8);
      int v7 = _shiftR((Jpeg.dctSqrt1d2 * (p[1 + row] + p[7 + row]) + 128), 8);
      int v5 = _shiftL(p[3 + row], 4);
      int v6 = _shiftL(p[5 + row], 4);

      // stage 3
      int t = _shiftR((v0 - v1+ 1), 1);
      v0 = _shiftR((v0 + v1 + 1), 1);
      v1 = t;
      t = _shiftR((v2 * Jpeg.dctSin6 + v3 * Jpeg.dctCos6 + 128), 8);
      v2 = _shiftR((v2 * Jpeg.dctCos6 - v3 * Jpeg.dctSin6 + 128), 8);
      v3 = t;
      t = _shiftR((v4 - v6 + 1), 1);
      v4 = _shiftR((v4 + v6 + 1), 1);
      v6 = t;
      t = _shiftR((v7 + v5 + 1), 1);
      v5 = _shiftR((v7 - v5 + 1), 1);
      v7 = t;

      // stage 2
      t = _shiftR((v0 - v3 + 1), 1);
      v0 = _shiftR((v0 + v3 + 1), 1);
      v3 = t;
      t = _shiftR((v1 - v2 + 1), 1);
      v1 = _shiftR((v1 + v2 + 1), 1);
      v2 = t;
      t = _shiftR((v4 * Jpeg.dctSin3 + v7 * Jpeg.dctCos3 + 2048), 12);
      v4 = _shiftR((v4 * Jpeg.dctCos3 - v7 * Jpeg.dctSin3 + 2048), 12);
      v7 = t;
      t = _shiftR((v5 * Jpeg.dctSin1 + v6 * Jpeg.dctCos1 + 2048), 12);
      v5 = _shiftR((v5 * Jpeg.dctCos1 - v6 * Jpeg.dctSin1 + 2048), 12);
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
        int t = _shiftR((Jpeg.dctSqrt2 * dataIn[i] + 8192), 14);
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
      int v0 = _shiftR((Jpeg.dctSqrt2 * p[0 * 8 + col] + 2048), 12);
      int v1 = _shiftR((Jpeg.dctSqrt2 * p[4 * 8 + col] + 2048), 12);
      int v2 = p[2 * 8 + col];
      int v3 = p[6 * 8 + col];
      int v4 = _shiftR((Jpeg.dctSqrt1d2 * (p[1 * 8 + col] - p[7*8 + col]) + 2048), 12);
      int v7 = _shiftR((Jpeg.dctSqrt1d2 * (p[1 * 8 + col] + p[7*8 + col]) + 2048), 12);
      int v5 = p[3 * 8 + col];
      int v6 = p[5 * 8 + col];

      // stage 3
      int t = _shiftR((v0 - v1 + 1), 1);
      v0 = _shiftR((v0 + v1 + 1), 1);
      v1 = t;
      t = _shiftR((v2 * Jpeg.dctSin6 + v3 * Jpeg.dctCos6 + 2048), 12);
      v2 = _shiftR((v2 * Jpeg.dctCos6 - v3 * Jpeg.dctSin6 + 2048), 12);
      v3 = t;
      t = _shiftR((v4 - v6 + 1), 1);
      v4 = _shiftR((v4 + v6 + 1), 1);
      v6 = t;
      t = _shiftR((v7 + v5 + 1), 1);
      v5 = _shiftR((v7 - v5 + 1), 1);
      v7 = t;

      // stage 2
      t = _shiftR((v0 - v3 + 1), 1);
      v0 = _shiftR((v0 + v3 + 1), 1);
      v3 = t;
      t = _shiftR((v1 - v2 + 1), 1);
      v1 = _shiftR((v1 + v2 + 1), 1);
      v2 = t;
      t = _shiftR((v4 * Jpeg.dctSin3 + v7 * Jpeg.dctCos3 + 2048), 12);
      v4 = _shiftR((v4 * Jpeg.dctCos3 - v7 * Jpeg.dctSin3 + 2048), 12);
      v7 = t;
      t = _shiftR((v5 * Jpeg.dctSin1 + v6 * Jpeg.dctCos1 + 2048), 12);
      v5 = _shiftR((v5 * Jpeg.dctCos1 - v6 * Jpeg.dctSin1 + 2048), 12);
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
      int sample = (128 + (_shiftR(p[i] + 8), 4));
      dataOut[i] = sample < 0 ? 0 : sample > 0xFF ? 0xFF : sample;
    }
  }

  int _clamp(int i) {
    return i < 0 ? 0 : i > 255 ? 255 : i;
  }
}
