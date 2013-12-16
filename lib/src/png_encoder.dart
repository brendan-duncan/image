part of dart_image;

/**
 * Encode an image to the PNG format.
 */
class PngEncoder {
  List<int> encode(Image image) {
    _ByteBuffer out = new _ByteBuffer();

    // PNG file signature
    out.writeBytes([137, 80, 78, 71, 13, 10, 26, 10]);

    // IHDR chunk
    _ByteBuffer chunk = new _ByteBuffer();
    chunk.writeUint32(image.width);
    chunk.writeUint32(image.height);
    chunk.writeByte(8);
    chunk.writeByte(image.format == Image.RGB ? 2 : 6);
    chunk.writeByte(0); // compression method
    chunk.writeByte(0); // filter method
    chunk.writeByte(0); // interlace method
    _writeChunk(out, 'IHDR', chunk);

    Image filteredImage = new Image.from(image);
    _filter(filteredImage);
    var bytes = new List<int>.from(filteredImage.buffer, growable: false);
  }

  void _writeChunk(_ByteBuffer out, String type, _ByteBuffer chunk) {
    out.writeUint32(chunk.length);
    out.writeBytes(type.codeUnits);
    out.writeBytes(chunk.buffer);
    out.writeUint32(_crc(chunk.buffer));
  }

  void _filter(Image image) {

  }

  /**
   * Make the table for a fast CRC.
   */
  void _makeCrcTable() {
    for (int n = 0; n < 256; n++) {
      int c = n;
      for (int k = 0; k < 8; k++) {
        if ((c & 1) != 0) {
          c = 0xedb88320 ^ (c >> 1);
        } else {
          c = c >> 1;
        }
      }
      _crcTable[n] = c;
    }
    _crcTableComputed = true;
  }

  /**
   * Update a running CRC with the bytes buf[0..len-1]--the CRC
   * should be initialized to all 1's, and the transmitted value
   * is the 1's complement of the final running CRC (see the
   * crc() routine below)).
   */
  int _updateCrc(int crc, List<int> buffer) {
    int c = crc;

    if (!_crcTableComputed) {
      _makeCrcTable();
    }

    int len = buffer.length;
    for (int n = 0; n < len; n++) {
      c = _crcTable[(c ^ buffer[n]) & 0xff] ^ (c >> 8);
    }

    return c;
  }

  /**
   * Return the CRC of the bytes buf[0..len-1].
   */
  int _crc(List<int> buffer) {
    return _updateCrc(0xffffffff, buffer) ^ 0xffffffff;
  }

  // Table of CRCs of all 8-bit messages.
  final List<int> _crcTable = new List<int>(256);

  // Flag: has the table been computed? Initially false.
  bool _crcTableComputed = false;
}
