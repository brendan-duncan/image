import 'dart:io';
import 'package:image/image.dart';

/**
 * Work in progress experimental PSD to HTML converter.
 */
void main() {
  File f = new File('res/example1.psd');
  PsdImage psd = new PsdDecoder().decodePsd(f.readAsBytesSync());
  print('${psd.width} ${psd.height}');

  print('SIGNATURE: ${psd.signature}');
  print('VERSION: ${psd.version}');
  print('CHANNELS: ${psd.channels}');
  print('depth: ${psd.depth}');
  print('colorMode: ${psd.colorMode}');
  print('hasAlpha: ${psd.hasAlpha}');
  print('numLayers: ${psd.layers.length}');

  var outHtml = '<html>\n<body>\n';

  int i = 1;
  for (PsdLayer l in psd.layers) {
    print('LAYER ${l.name}');
    print('    RECT: ${l.left} ${l.top} ${l.right} ${l.bottom}');
    print('    RES: ${l.width} ${l.height}');
    print('    BLENDMODE: ${l.blendMode}');
    print('    OPACITY: ${l.opacity}');
    print('    CLIPPING: ${l.clipping}');
    print('    FLAGS: ${l.flags}');
    print('    COMPRESSION: ${l.compression}');
    print('    NUM CHANNELS: ${l.channels.length}');
    print('    NUM CHILDREN: ${l.children.length}');
    print('    IMAGE: ${l.layerImage}');

    if (l.width == 0 || l.height == 0) {
      continue;
    }

    var name = 'layer_$i.png';
    i++;

    outHtml += '<image src="$name" style="';
    outHtml += 'position: absolute; left: ${l.left}px; top: ${l.top}px;';

    // The layer has effects
    if (l.additionalData.containsKey('lrFX')) {
      var fxData = l.additionalData['lrFX'];
      var data = new InputBuffer.from(fxData.data);
      int version = data.readUint16();
      int numFx = data.readUint16();
      print('      FX: $numFx');
      for (int j = 0; j < numFx; ++j) {
        var tag = data.readString(4); // 8BIM
        var fxTag = data.readString(4);
        int size = data.readUint32();
        data.skip(size);
        if (fxTag == 'cmnS') {
          print('            Common State');
        } else if (fxTag == 'dsdw') {
          print('            Drop Shadow');
        } else if (fxTag == 'isdw') {
          print('            Inner Shadow');
        } else if (fxTag == 'oglw') {
          print('            Outer Glow');
        } else if (fxTag == 'iglw') {
          print('            Inner Glow');
        } else if (fxTag == 'bevl') {
          print('            Bevel');
        } else if (fxTag == 'sofi') {
          print('            Solid Fill');
        } else {
          print('            UNKNOWN $fxTag');
        }
      }
    }

    outHtml += '">\n';

    List<int> outPng = new PngEncoder().encodeImage(l.layerImage);
    new File('out/$name')
        ..createSync(recursive: true)
        ..writeAsBytesSync(outPng);
  }

  outHtml += '</body>\n</html>\n';

  new File('out/test.html')
      ..writeAsString(outHtml);
}
