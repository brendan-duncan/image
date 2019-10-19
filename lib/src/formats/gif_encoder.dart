import 'dart:typed_data';

import '../animation.dart';
import '../image.dart';
import '../util/neural_quantizer.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';

class GifEncoder extends Encoder {
  int samplingFactor;

  GifEncoder({this.delay = 80, this.repeat = 0, this.samplingFactor = 10})
      : _encodedFrames = 0;

  /// This adds the frame passed to [image].
  /// After the last frame has been added, [finish] is required to be called.
  void addFrame(Image image, {int duration}) {
    if (duration != null) {
      delay = duration;
    }

    if (output == null) {
      output = OutputBuffer();

      _lastColorMap = NeuralQuantizer(image, samplingFactor: samplingFactor);
      _lastImage = _lastColorMap.getIndexMap(image);

      _width = image.width;
      _height = image.height;
      return;
    }

    if (_encodedFrames == 0) {
      _writeHeader(_width, _height);
    }

    _writeGraphicsCtrlExt();

    _addImage(_lastImage, _width, _height, _lastColorMap.colorMap, 256);
    _encodedFrames++;

    _lastColorMap = NeuralQuantizer(image, samplingFactor: samplingFactor);
    _lastImage = _lastColorMap.getIndexMap(image);
  }

  /// Encode the images that were added with [addFrame].
  /// After this has been called (returning the finishes GIF),
  /// calling [addFrame] for a new animation or image is safe again.
  ///
  /// [addFrame] will not encode the first image passed and after that
  /// always encode the previous image. Hence, the last image needs to be
  /// encoded here.
  List<int> finish() {
    List<int> bytes;
    if (output == null) {
      return bytes;
    }

    if (_encodedFrames == 0) {
      _writeHeader(_width, _height);
    } else {
      _writeApplicationExt();
      _writeGraphicsCtrlExt();
    }

    _addImage(_lastImage, _width, _height, _lastColorMap.colorMap, 256);

    output.writeByte(TERMINATE_RECORD_TYPE);

    _lastImage = null;
    _lastColorMap = null;
    _encodedFrames = 0;

    bytes = output.getBytes();
    output = null;
    return bytes;
  }

  /// Encode a single frame image.
  List<int> encodeImage(Image image) {
    addFrame(image);
    return finish();
  }

  /// Does this encoder support animation?
  bool get supportsAnimation => true;

  /// Encode an animation.
  List<int> encodeAnimation(Animation anim) {
    repeat = anim.loopCount;

    for (Image f in anim) {
      addFrame(f, duration: f.duration);
    }

    return finish();
  }

  void _addImage(Uint8List image, int width, int height, Uint8List colorMap,
      int numColors) {
    // Image desc
    output.writeByte(IMAGE_DESC_RECORD_TYPE);
    output.writeUint16(0); // image position x,y = 0,0
    output.writeUint16(0);
    output.writeUint16(width); // image size
    output.writeUint16(height);

    // Local Color Map
    // (0x80: Use LCM, 0x07: Palette Size (7 = 8-bit))
    output.writeByte(0x87);
    output.writeBytes(colorMap);
    for (int i = numColors; i < 256; ++i) {
      output.writeByte(0);
      output.writeByte(0);
      output.writeByte(0);
    }

    _encodeLZW(image, width, height);
  }

  void _encodeLZW(Uint8List image, int width, int height) {
    _curAccum = 0;
    _curBits = 0;
    _blockSize = 0;
    _block = Uint8List(256);

    const int initCodeSize = 8;
    output.writeByte(initCodeSize);

    Int32List hTab = Int32List(HSIZE);
    Int32List codeTab = Int32List(HSIZE);
    int remaining = width * height;
    int curPixel = 0;

    _initBits = initCodeSize + 1;
    _nBits = _initBits;
    _maxCode = (1 << _nBits) - 1;
    _clearCode = 1 << (_initBits - 1);
    _EOFCode = _clearCode + 1;
    _clearFlag = false;
    _freeEnt = _clearCode + 2;

    int _nextPixel() {
      if (remaining == 0) {
        return EOF;
      }
      --remaining;
      return image[curPixel++] & 0xff;
    }

    int ent = _nextPixel();

    int hshift = 0;
    for (int fcode = HSIZE; fcode < 65536; fcode *= 2) {
      hshift++;
    }
    hshift = 8 - hshift;

    int hSizeReg = HSIZE;
    for (var i = 0; i < hSizeReg; ++i) {
      hTab[i] = -1;
    }

    _output(_clearCode);

    bool outerLoop = true;
    while (outerLoop) {
      outerLoop = false;

      int c = _nextPixel();
      while (c != EOF) {
        int fcode = (c << BITS) + ent;
        int i = (c << hshift) ^ ent; // xor hashing

        if (hTab[i] == fcode) {
          ent = codeTab[i];
          c = _nextPixel();
          continue;
        } else if (hTab[i] >= 0) {
          // non-empty slot
          int disp = hSizeReg - i; // secondary hash (after G. Knott)
          if (i == 0) {
            disp = 1;
          }
          do {
            if ((i -= disp) < 0) {
              i += hSizeReg;
            }

            if (hTab[i] == fcode) {
              ent = codeTab[i];
              outerLoop = true;
              break;
            }
          } while (hTab[i] >= 0);
          if (outerLoop) {
            break;
          }
        }

        _output(ent);
        ent = c;

        if (_freeEnt < 1 << BITS) {
          codeTab[i] = _freeEnt++; // code -> hashtable
          hTab[i] = fcode;
        } else {
          for (int i = 0; i < HSIZE; ++i) {
            hTab[i] = -1;
          }
          _freeEnt = _clearCode + 2;
          _clearFlag = true;
          _output(_clearCode);
        }

        c = _nextPixel();
      }
    }

    _output(ent);
    _output(_EOFCode);

    output.writeByte(0);
  }

  void _output(int code) {
    _curAccum &= MASKS[_curBits];

    if (_curBits > 0) {
      _curAccum |= (code << _curBits);
    } else {
      _curAccum = code;
    }

    _curBits += _nBits;

    while (_curBits >= 8) {
      _addToBlock(_curAccum & 0xff);
      _curAccum >>= 8;
      _curBits -= 8;
    }

    // If the next entry is going to be too big for the code size,
    // then increase it, if possible.
    if (_freeEnt > _maxCode || _clearFlag) {
      if (_clearFlag) {
        _nBits = _initBits;
        _maxCode = (1 << _nBits) - 1;
        _clearFlag = false;
      } else {
        ++_nBits;
        if (_nBits == BITS) {
          _maxCode = 1 << BITS;
        } else {
          _maxCode = (1 << _nBits) - 1;
        }
      }
    }

    if (code == _EOFCode) {
      // At EOF, write the rest of the buffer.
      while (_curBits > 0) {
        _addToBlock(_curAccum & 0xff);
        _curAccum >>= 8;
        _curBits -= 8;
      }
      _writeBlock();
    }
  }

  void _writeBlock() {
    if (_blockSize > 0) {
      output.writeByte(_blockSize);
      output.writeBytes(_block, _blockSize);
      _blockSize = 0;
    }
  }

  void _addToBlock(int c) {
    _block[_blockSize++] = c;
    if (_blockSize >= 254) {
      _writeBlock();
    }
  }

  void _writeApplicationExt() {
    output.writeByte(EXTENSION_RECORD_TYPE);
    output.writeByte(APPLICATION_EXT);
    output.writeByte(11); // data block size
    output.writeBytes("NETSCAPE2.0".codeUnits); // app identifier
    output.writeBytes([0x03, 0x01]);
    output.writeUint16(repeat); // loop count
    output.writeByte(0); // block terminator
  }

  void _writeGraphicsCtrlExt() {
    output.writeByte(EXTENSION_RECORD_TYPE);
    output.writeByte(GRAPHIC_CONTROL_EXT);
    output.writeByte(4); // data block size

    int transparency = 0;
    int dispose = 0; // dispose = no action

    // packed fields
    output.writeByte(0 | // 1:3 reserved
        dispose | // 4:6 disposal
        0 | // 7   user input - 0 = none
        transparency); // 8   transparency flag

    output.writeUint16(delay); // delay x 1/100 sec
    output.writeByte(0); // transparent color index
    output.writeByte(0); // block terminator
  }

  // GIF header and Logical Screen Descriptor
  void _writeHeader(int width, int height) {
    output.writeBytes(GIF89_STAMP.codeUnits);
    output.writeUint16(width);
    output.writeUint16(height);
    output.writeByte(0); // global color map parameters (not being used).
    output.writeByte(0); // background color index.
    output.writeByte(0); // aspect
  }

  int background;
  int delay;
  int repeat;

  Uint8List _lastImage;
  NeuralQuantizer _lastColorMap;
  int _width;
  int _height;
  int _encodedFrames;

  int _curAccum;
  int _curBits;
  int _nBits;
  int _initBits;
  int _EOFCode;
  int _maxCode;
  int _clearCode;
  int _freeEnt;
  bool _clearFlag;
  Uint8List _block;
  int _blockSize;

  OutputBuffer output;

  static const String GIF89_STAMP = 'GIF89a';

  static const int IMAGE_DESC_RECORD_TYPE = 0x2c;
  static const int EXTENSION_RECORD_TYPE = 0x21;
  static const int TERMINATE_RECORD_TYPE = 0x3b;

  static const int APPLICATION_EXT = 0xff;
  static const int GRAPHIC_CONTROL_EXT = 0xf9;

  static const int EOF = -1;
  static const int BITS = 12;
  static const int HSIZE = 5003; // 80% occupancy
  static const List<int> MASKS = [
    0x0000,
    0x0001,
    0x0003,
    0x0007,
    0x000F,
    0x001F,
    0x003F,
    0x007F,
    0x00FF,
    0x01FF,
    0x03FF,
    0x07FF,
    0x0FFF,
    0x1FFF,
    0x3FFF,
    0x7FFF,
    0xFFFF
  ];
}
