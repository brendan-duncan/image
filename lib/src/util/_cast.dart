import 'dart:typed_data';

Uint8List castToUint8List<T>(T data) =>
    data is Uint8List ? data : data as Uint8List;
