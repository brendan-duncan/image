import 'dart:io';
import '../lib/image.dart';

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
    if (l.effects.isNotEmpty) {
      print('        Effects');
    }
    for (var fx in l.effects) {
      if (!fx.enabled) {
        continue;
      }
      if (fx is PsdBevelEffect) {
        print('            Bevel');
      } else if (fx is PsdDropShadowEffect) {
        print('            Drop Shadow');
      } else if (fx is PsdInnerGlowEffect) {
        print('            Inner Glow');
      } else if (fx is PsdInnerShadowEffect) {
        print('            Inner Shadow');
      } else if (fx is PsdOuterGlowEffect) {
        print('            Outer Glow');
      } else if (fx is PsdSolidFillEffect) {
        print('            Solid Fill');
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
