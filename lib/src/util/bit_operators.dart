part of image;

int _shiftR(int v, int n) {
  // dart2js can't handle binary operations on negative numbers, so
  // until that issue is fixed (issues 16506, 1533), we'll have to do it
  // the slow way.
  return (v / _SHIFT_BITS[n]).floor();
}

int _shiftL(int v, int n) {
  // dart2js can't handle binary operations on negative numbers, so
  // until that issue is fixed (issues 16506, 1533), we'll have to do it
  // the slow way.
  return (v * _SHIFT_BITS[n]);
}

const List<int> _SHIFT_BITS = const [
  1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384,
  32768, 65536];


/**
 * Binary conversion of a uint8 to an int8.  This is equivalent in C to
 * typecasting an unsigned char to a char.
 */
int _uint8ToInt8(int d) {
  _uint8ToInt8_uint8[0] = d;
  return _uint8ToInt8_int8[0];
}

/**
 * Binary conversion of a uint16 to an int16.  This is equivalent in C to
 * typecasting an unsigned short to a short.
 */
int _uint16ToInt16(int d) {
  _uint16ToInt16_uint16[0] = d;
  return _uint16ToInt16_int16[0];
}

/**
 * Binary conversion of a uint32 to an int32.  This is equivalent in C to
 * typecasting an unsigned int to signed int.
 */
int _uint32ToInt32(int d) {
  _uint32ToInt32_uint32[0] = d;
  return _uint32ToInt32_int32[0];
}

/**
 * Binary conversion of an int32 to a uint32. This is equivalent in C to
 * typecasting an int to an unsigned int.
 */
int _int32ToUint32(int d) {
  _int32ToUint32_int32[0] = d;
  return _int32ToUint32_uint32[0];
}

final Uint8List _uint8ToInt8_uint8 = new Uint8List(1);
final Int8List _uint8ToInt8_int8 =
    new Int8List.view(_uint8ToInt8_uint8.buffer);

final Uint16List _uint16ToInt16_uint16 = new Uint16List(1);
final Int16List _uint16ToInt16_int16 =
    new Int16List.view(_uint16ToInt16_uint16.buffer);

final Uint32List _uint32ToInt32_uint32 = new Uint32List(1);
final Int32List _uint32ToInt32_int32 =
    new Int32List.view(_uint16ToInt16_uint16.buffer);

final Int32List _int32ToUint32_int32 = new Int32List(1);
final Uint32List _int32ToUint32_uint32 =
    new Uint32List.view(_int32ToUint32_int32.buffer);
