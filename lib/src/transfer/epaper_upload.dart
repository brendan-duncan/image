import '../color.dart';
import '../image.dart';
import 'dart:convert';
import 'package:http/http.dart';

// write to waveshare epaper and esp8266 driver board demo code
// using simple (and unsecure) URIs
// https://www.waveshare.com/wiki/E-Paper_ESP8266_Driver_Board
//
Future<bool> epaperUpload(Image image, String host) async {
  await makePostRequest(host + '/EPD', 'db');

  String pixels = "";
  var currentByte = 0x0;
  var bitCount = 0;
  var linecount = 0;

  for (var i = 0; i < image.length; ++i) {
    final c = image[i];
    final white = isWhite(c);

    if (white == true) {
      currentByte |= 0x01;
    }
    bitCount += 1;
    if (bitCount >= 8) {
      pixels += String.fromCharCode(97 + ((currentByte & 0x0f)));
      pixels += String.fromCharCode(97 + ((currentByte & 0xf0) >> 4));

      if (pixels.length >= 1500) {
        var l = pixels.length;
        pixels += String.fromCharCode(((l & 0x000f) >> 0) + 97);
        pixels += String.fromCharCode(((l & 0x00f0) >> 4) + 97);
        pixels += String.fromCharCode(((l & 0x0f00) >> 8) + 97);
        pixels += String.fromCharCode(((l & 0x0f00) >> 12) + 97);
        pixels += "LOAD";

        await makePostRequest(host + '/LOAD', pixels);

        linecount += 1;
        pixels = "";
      }

      currentByte = 0x0;
      bitCount = 0;
    } else {
      currentByte = currentByte << 1;
    }
  }

  if (pixels.length >= 1500) {
    var l = pixels.length;
    pixels += String.fromCharCode(((l & 0x000f) >> 0) + 97);
    pixels += String.fromCharCode(((l & 0x00f0) >> 4) + 97);
    pixels += String.fromCharCode(((l & 0x0f00) >> 8) + 97);
    pixels += String.fromCharCode(((l & 0x0f00) >> 12) + 97);
    pixels += "LOAD";

    await makePostRequest(host + '/LOAD', pixels);
  }

  await makePostRequest(host + '/SHOW', '');

  return true;
}

makePostRequest(uriIn, bodyIn) async {
  final uri = Uri.parse(uriIn);
  final headers = {'Content-Type': 'text/plain'};
  final body = bodyIn;
  final encoding = Encoding.getByName('utf-8');

  Response response = await post(
    uri,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  int statusCode = response.statusCode;
  String responseBody = response.body;
}
