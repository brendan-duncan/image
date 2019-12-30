import 'dart:typed_data';

import '../../image_exception.dart';
import '../../formats/decode_info.dart';
import '../../hdr/hdr_slice.dart';
import '../../util/input_buffer.dart';
import 'exr_part.dart';

class ExrImage extends DecodeInfo {
  /// An EXR image has one or more parts, each of which contains a framebuffer.
  final List<InternalExrPart> _parts = [];

  ExrImage(List<int> bytes) {
    var input = InputBuffer(bytes);
    var magic = input.readUint32();
    if (magic != MAGIC) {
      throw ImageException('File is not an OpenEXR image file.');
    }

    version = input.readByte();
    if (version != EXR_VERSION) {
      throw ImageException('Cannot read version $version image files.');
    }

    flags = input.readUint24();
    if (!_supportsFlags(flags)) {
      throw ImageException('The file format version number\'s flag field '
          'contains unrecognized flags.');
    }

    if (!_isMultiPart()) {
      ExrPart part = InternalExrPart(_isTiled(), input);
      if (part.isValid) {
        _parts.add(part as InternalExrPart);
      }
    } else {
      while (true) {
        ExrPart part = InternalExrPart(_isTiled(), input);
        if (!part.isValid) {
          break;
        }
        _parts.add(part as InternalExrPart);
      }
    }

    if (_parts.isEmpty) {
      throw ImageException('Error reading image header');
    }

    for (var part in _parts) {
      part.readOffsets(input);
    }

    _readImage(input);
  }

  List<ExrPart> get parts => _parts;

  @override
  int get numFrames => 1;

  /// Parse just enough of the file to identify that it's an EXR image.
  static bool isValidFile(List<int> bytes) {
    var input = InputBuffer(bytes);

    var magic = input.readUint32();
    if (magic != MAGIC) {
      return false;
    }

    var version = input.readByte();
    if (version != EXR_VERSION) {
      return false;
    }

    var flags = input.readUint24();
    if (!_supportsFlags(flags)) {
      return false;
    }

    return true;
  }

  int numParts() => _parts.length;

  ExrPart getPart(int i) => _parts[i];

  bool _isTiled() {
    return (flags & TILED_FLAG) != 0;
  }

  bool _isMultiPart() {
    return flags & MULTI_PART_FILE_FLAG != 0;
  }

  /*bool _isNonImage() {
    return flags & NON_IMAGE_FLAG != 0;
  }*/

  static bool _supportsFlags(int flags) {
    return (flags & ~ALL_FLAGS) == 0;
  }

  void _readImage(InputBuffer input) {
    //final bool multiPart = _isMultiPart();

    for (var pi = 0; pi < _parts.length; ++pi) {
      var part = _parts[pi];
      var framebuffer = part.framebuffer;

      for (var ci = 0; ci < part.channels.length; ++ci) {
        var ch = part.channels[ci];
        if (!framebuffer.hasChannel(ch.name)) {
          width = part.width;
          height = part.height;
          framebuffer
              .addSlice(HdrSlice(ch.name, part.width, part.height, ch.type));
        }
      }

      if (part.tiled) {
        _readTiledPart(pi, input);
      } else {
        _readScanlinePart(pi, input);
      }
    }
  }

  void _readTiledPart(int pi, InputBuffer input) {
    var part = _parts[pi];
    final multiPart = _isMultiPart();
    var framebuffer = part.framebuffer;
    var compressor = part.compressor;
    var offsets = part.offsets;
    //Uint32List fbi = Uint32List(part.channels.length);

    var imgData = InputBuffer.from(input);
    for (var ly = 0, l = 0; ly < part.numYLevels; ++ly) {
      for (var lx = 0; lx < part.numXLevels; ++lx, ++l) {
        for (var ty = 0, oi = 0; ty < part.numYTiles[ly]; ++ty) {
          for (var tx = 0; tx < part.numXTiles[lx]; ++tx, ++oi) {
            // TODO support sub-levels (for rip/mip-mapping).
            if (l != 0) {
              break;
            }
            var offset = offsets[l][oi];
            imgData.offset = offset;

            if (multiPart) {
              var p = imgData.readUint32();
              if (p != pi) {
                throw ImageException('Invalid Image Data');
              }
            }

            var tileX = imgData.readUint32();
            var tileY = imgData.readUint32();
            /*int levelX =*/ imgData.readUint32();
            /*int levelY =*/ imgData.readUint32();
            var dataSize = imgData.readUint32();
            var data = imgData.readBytes(dataSize);

            var ty = tileY * part.tileHeight;
            var tx = tileX * part.tileWidth;

            var tileWidth = compressor.decodedWidth;
            var tileHeight = compressor.decodedHeight;

            if (tx + tileWidth > width) {
              tileWidth = width - tx;
            }
            if (ty + tileHeight > height) {
              tileHeight = height - ty;
            }

            Uint8List uncompressedData;
            if (compressor != null) {
              uncompressedData = compressor.uncompress(
                  data, tx, ty, part.tileWidth, part.tileHeight);
              tileWidth = compressor.decodedWidth;
              tileHeight = compressor.decodedHeight;
            } else {
              uncompressedData = data.toUint8List();
            }

            var si = 0;
            var len = uncompressedData.length;
            var numChannels = part.channels.length;
            //int lineCount = 0;
            for (var yi = 0; yi < tileHeight && ty < height; ++yi, ++ty) {
              for (var ci = 0; ci < numChannels; ++ci) {
                var ch = part.channels[ci];
                var slice = framebuffer[ch.name].getBytes();
                if (si >= len) {
                  break;
                }

                var tx = tileX * part.tileWidth;
                for (var xx = 0; xx < tileWidth; ++xx, ++tx) {
                  for (var bi = 0; bi < ch.size; ++bi) {
                    if (tx < part.width && ty < part.height) {
                      var di = (ty * part.width + tx) * ch.size + bi;
                      slice[di] = uncompressedData[si++];
                    } else {
                      si++;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  void _readScanlinePart(int pi, InputBuffer input) {
    var part = _parts[pi];
    final multiPart = _isMultiPart();
    var framebuffer = part.framebuffer;
    var compressor = part.compressor;
    var offsets = part.offsets[0];

    //var scanLineMin = part.top;
    //var scanLineMax = part.bottom;
    var linesInBuffer = part.linesInBuffer;

    //var minY = part.top;
    //var maxY = minY + part.linesInBuffer - 1;

    var fbi = Uint32List(part.channels.length);
    //var total = 0;

    //var xx = 0;
    var yy = 0;

    var imgData = InputBuffer.from(input);
    for (var offset in offsets) {
      imgData.offset = offset;

      if (multiPart) {
        var p = imgData.readUint32();
        if (p != pi) {
          throw ImageException('Invalid Image Data');
        }
      }

      /*var y =*/ imgData.readInt32();
      var dataSize = imgData.readInt32();
      var data = imgData.readBytes(dataSize);

      Uint8List uncompressedData;
      if (compressor != null) {
        uncompressedData = compressor.uncompress(data, 0, yy);
      } else {
        uncompressedData = data.toUint8List();
      }

      var si = 0;
      var len = uncompressedData.length;
      var numChannels = part.channels.length;
      //int lineCount = 0;
      for (var yi = 0; yi < linesInBuffer && yy < height; ++yi, ++yy) {
        si = part.offsetInLineBuffer[yy];
        if (si >= len) {
          break;
        }

        for (var ci = 0; ci < numChannels; ++ci) {
          var ch = part.channels[ci];
          var slice = framebuffer[ch.name].getBytes();
          if (si >= len) {
            break;
          }
          for (var xx = 0; xx < part.width; ++xx) {
            for (var bi = 0; bi < ch.size; ++bi) {
              slice[fbi[ci]++] = uncompressedData[si++];
            }
          }
        }
      }
    }
  }

  int version;
  int flags;

  /// The MAGIC number is stored in the first four bytes of every
  /// OpenEXR image file. This can be used to quickly test whether
  /// a given file is an OpenEXR image file (see isImfMagic(), below).
  static const MAGIC = 20000630;

  /// Value that goes into VERSION_NUMBER_FIELD.
  static const EXR_VERSION = 2;

  /// File is tiled
  static const TILED_FLAG = 0x000002;

  /// File contains long attribute or channel names
  static const LONG_NAMES_FLAG = 0x000004;

  /// File has at least one part which is not a regular scanline image or
  /// regular tiled image (that is, it is a deep format).
  static const NON_IMAGE_FLAG = 0x000008;

  /// File has multiple parts.
  static const MULTI_PART_FILE_FLAG = 0x000010;

  /// Bitwise OR of all supported flags.
  static const ALL_FLAGS = TILED_FLAG | LONG_NAMES_FLAG;
}
