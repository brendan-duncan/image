import 'dart:typed_data';

import '../../util/input_buffer.dart';

class PsdBlendingRanges {
  int grayBlackSrc;
  int grayWhiteSrc;
  int grayBlackDst;
  int grayWhiteDst;
  Uint16List blackSrc;
  Uint16List whiteSrc;
  Uint16List blackDst;
  Uint16List whiteDst;

  PsdBlendingRanges(InputBuffer input) {
    grayBlackSrc = input.readUint16();
    grayWhiteSrc = input.readUint16();

    grayBlackDst = input.readUint16();
    grayWhiteDst = input.readUint16();

    int len = input.length;
    int numChannels = len ~/ 8;

    if (numChannels > 0) {
      blackSrc = new Uint16List(numChannels);
      whiteSrc = new Uint16List(numChannels);
      blackDst = new Uint16List(numChannels);
      whiteDst = new Uint16List(numChannels);

      for (int i = 0; i < numChannels; ++i) {
        blackSrc[i] = input.readUint16();
        whiteSrc[i] = input.readUint16();
        blackDst[i] = input.readUint16();
        whiteDst[i] = input.readUint16();
      }
    }
  }
}