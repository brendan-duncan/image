import 'dart:typed_data';
import 'package:image/image.dart';
import 'utils.dart';

class BenchmarkCase {
  BenchmarkCase(this.name, this.fn, {this.note, this.resolution});

  final String name;
  final void Function() fn;
  final String? note;
  final String? resolution;
}

class PngSample {
  PngSample(this.path, this.width, this.height, this.bytes, this.image);

  final String path;
  final int width;
  final int height;
  final Uint8List bytes;
  final Image image;

  String get resolution => '${width}x${height}';
}

List<PngSample> _loadBuckSamples() {
  final files = listBuckPngFiles();
  final re = RegExp(r'buck_(\d+)_(\d+)\.png$');
  final samples = <PngSample>[];
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final m = re.firstMatch(name);
    if (m == null) {
      continue;
    }
    final w = int.parse(m.group(1)!);
    final h = int.parse(m.group(2)!);
    final bytes = f.readAsBytesSync();
    final img = decodePng(bytes);
    if (img == null) {
      continue;
    }
    samples.add(PngSample(f.path, w, h, bytes, img));
  }
  return samples;
}

Map<String, List<BenchmarkCase>> buildCases() {
  final cases = <String, List<BenchmarkCase>>{};
  void add(String name, BenchmarkCase c) =>
      cases.putIfAbsent(name, () => <BenchmarkCase>[]).add(c);

  final samples = _loadBuckSamples();
  final jpgBytes = loadBytes('test/_data/jpg/buck_24.jpg');
  final gifBytes = loadBytes('test/_data/gif/buck_24.gif');
  final bmpBytes = loadBytes('test/_data/bmp/buck_24.bmp');
  final tgaBytes = loadBytes('test/_data/tga/buck_24.tga');
  final tiffBytes = loadBytes('test/_data/tiff/small.tif');
  final webpBytes = loadBytes('test/_data/webp/buck_24.webp');
  final pnmBytes = loadBytes('test/_data/pnm/test.ppm');
  final psdBytes = loadBytes('test/_data/psd/psd1.psd');
  final pvrBytes = loadBytes('test/_data/pvr/RGB888.pvr');
  final exrBytes = loadBytes('test/_data/exr/grid.exr');
  final icoBytes = loadBytes('test/_data/ico/wikipedia-favicon.ico');

  String resTo(Image img, int w, int h) => '${img.width}x${img.height} -> ${w}x${h}';

  // Multi-resolution PNG-based formats (benchmark/_data)
  for (final s in samples) {
    add('findFormatForData',
        BenchmarkCase('findFormatForData', () => findFormatForData(s.bytes),
            resolution: s.resolution));
    add('findDecoderForData',
        BenchmarkCase('findDecoderForData', () => findDecoderForData(s.bytes),
            resolution: s.resolution));
    add(
        'findDecoderForNamedImage',
        BenchmarkCase(
            'findDecoderForNamedImage',
            () => findDecoderForNamedImage('buck_${s.width}_${s.height}.png'),
            resolution: s.resolution));
    add(
        'findEncoderForNamedImage',
        BenchmarkCase(
            'findEncoderForNamedImage',
            () => findEncoderForNamedImage('buck_${s.width}_${s.height}.png'),
            resolution: s.resolution));
    add('decodeImage',
        BenchmarkCase('decodeImage', () => decodeImage(s.bytes),
            resolution: s.resolution));
    add(
        'decodeNamedImage',
        BenchmarkCase(
            'decodeNamedImage',
            () => decodeNamedImage('buck_${s.width}_${s.height}.png', s.bytes),
            resolution: s.resolution));
    add('decodePng',
        BenchmarkCase('decodePng', () => decodePng(s.bytes),
            resolution: s.resolution));
    add('encodePng',
        BenchmarkCase('encodePng', () => encodePng(s.image),
            resolution: s.resolution));
    add('encodeJpg',
        BenchmarkCase('encodeJpg', () => encodeJpg(s.image),
            resolution: s.resolution));
    add('encodeGif',
        BenchmarkCase('encodeGif', () => encodeGif(s.image, singleFrame: true),
            resolution: s.resolution));
    add('encodeBmp',
        BenchmarkCase('encodeBmp', () => encodeBmp(s.image),
            resolution: s.resolution));
    add('encodeTga',
        BenchmarkCase('encodeTga', () => encodeTga(s.image),
            resolution: s.resolution));
    add('encodeTiff',
        BenchmarkCase('encodeTiff', () => encodeTiff(s.image, singleFrame: true),
            resolution: s.resolution));
    add('encodeNamedImage',
        BenchmarkCase('encodeNamedImage', () => encodeNamedImage('out.png', s.image),
            resolution: s.resolution));

    // Transforms
    final halfW = (s.width ~/ 2).clamp(1, s.width);
    final minDim = [s.width, s.height].reduce((a, b) => a < b ? a : b);
    add('copyResize',
        BenchmarkCase('copyResize',
            () => copyResize(s.image, width: halfW),
            resolution: resTo(s.image, halfW,
                (halfW * (s.height / s.width)).round())));
    add('copyResizeCropSquare',
        BenchmarkCase('copyResizeCropSquare',
            () => copyResizeCropSquare(s.image, size: minDim ~/ 2),
            resolution: resTo(s.image, minDim ~/ 2, minDim ~/ 2)));
    add('resize',
        BenchmarkCase('resize',
            () => resize(s.image.clone(), width: halfW),
            resolution: resTo(s.image, halfW,
                (halfW * (s.height / s.width)).round())));
    add('copyRotate',
        BenchmarkCase('copyRotate', () => copyRotate(s.image, angle: 90),
            resolution: s.resolution));
    add('copyFlip',
        BenchmarkCase('copyFlip',
            () => copyFlip(s.image, direction: FlipDirection.horizontal),
            resolution: s.resolution));
    add('flip',
        BenchmarkCase('flip',
            () => flip(s.image.clone(), direction: FlipDirection.horizontal),
            resolution: s.resolution));
    add('flipVertical',
        BenchmarkCase('flipVertical', () => flipVertical(s.image.clone()),
            resolution: s.resolution));
    add('flipHorizontal',
        BenchmarkCase('flipHorizontal', () => flipHorizontal(s.image.clone()),
            resolution: s.resolution));
    add('flipHorizontalVertical',
        BenchmarkCase('flipHorizontalVertical',
            () => flipHorizontalVertical(s.image.clone()),
            resolution: s.resolution));
    final cropW = (s.width ~/ 2).clamp(1, s.width);
    final cropH = (s.height ~/ 2).clamp(1, s.height);
    add('copyCrop',
        BenchmarkCase('copyCrop',
            () => copyCrop(s.image, x: 0, y: 0, width: cropW, height: cropH),
            resolution: resTo(s.image, cropW, cropH)));
    final circleSize = minDim ~/ 2;
    add('copyCropCircle',
        BenchmarkCase('copyCropCircle',
            () => copyCropCircle(s.image, radius: circleSize ~/ 2),
            resolution: resTo(s.image, circleSize, circleSize)));
    add('copyExpandCanvas',
        BenchmarkCase('copyExpandCanvas',
            () => copyExpandCanvas(s.image,
                newWidth: s.width + 20,
                newHeight: s.height + 10,
                backgroundColor: ColorRgb8(16, 32, 48)),
            resolution: resTo(s.image, s.width + 20, s.height + 10)));
    add('copyRectify',
        BenchmarkCase('copyRectify',
            () => copyRectify(s.image,
                topLeft: Point(0, 0),
                topRight: Point(s.width - 1, 3),
                bottomLeft: Point(5, s.height - 1),
                bottomRight: Point(s.width - 1, s.height - 1)),
            resolution: s.resolution));
    add('bakeOrientation',
        BenchmarkCase('bakeOrientation', () => bakeOrientation(s.image.clone()),
            resolution: s.resolution));
    add('trim',
        BenchmarkCase('trim', () => trim(s.image), resolution: s.resolution));

    // Filters
    add('gaussianBlur',
        BenchmarkCase('gaussianBlur', () => gaussianBlur(s.image.clone(), radius: 5),
            resolution: s.resolution));
    add('convolution',
        BenchmarkCase('convolution',
            () => convolution(s.image.clone(), filter: const [
              0, -1, 0,
              -1, 5, -1,
              0, -1, 0,
            ]),
            resolution: s.resolution));
    add('separableConvolution',
        BenchmarkCase('separableConvolution', () {
          final kernel = SeparableKernel(1);
          kernel[0] = 0.25;
          kernel[1] = 0.5;
          kernel[2] = 0.25;
          separableConvolution(s.image.clone(), kernel: kernel);
        }, resolution: s.resolution));
    add('adjustColor',
        BenchmarkCase('adjustColor',
            () => adjustColor(s.image.clone(), contrast: 1.2, saturation: 1.1),
            resolution: s.resolution));
    add('contrast',
        BenchmarkCase('contrast', () => contrast(s.image.clone(), contrast: 120),
            resolution: s.resolution));
    add('gamma',
        BenchmarkCase('gamma', () => gamma(s.image.clone(), gamma: 1.2),
            resolution: s.resolution));
    add('colorOffset',
        BenchmarkCase('colorOffset',
            () => colorOffset(s.image.clone(), red: 10, green: -5, blue: 5),
            resolution: s.resolution));
    add('remapColors',
        BenchmarkCase('remapColors',
            () => remapColors(s.image.clone(),
                red: Channel.green, green: Channel.red, blue: Channel.blue),
            resolution: s.resolution));
    add('scaleRgba',
        BenchmarkCase('scaleRgba',
            () => scaleRgba(s.image.clone(),
                scale: ColorRgba8(200, 180, 160, 255)),
            resolution: s.resolution));
    add('copyImageChannels',
        BenchmarkCase('copyImageChannels',
            () => copyImageChannels(s.image.clone(),
                from: s.image, red: Channel.red, green: Channel.green),
            resolution: s.resolution));
    add('noise',
        BenchmarkCase('noise', () => noise(s.image.clone(), 10),
            resolution: s.resolution));
    add('pixelate',
        BenchmarkCase('pixelate', () => pixelate(s.image.clone(), size: 6),
            resolution: s.resolution));
    add('hexagonPixelate',
        BenchmarkCase('hexagonPixelate',
            () => hexagonPixelate(s.image.clone(), size: 8),
            resolution: s.resolution));
    add('bulgeDistortion',
        BenchmarkCase('bulgeDistortion',
            () => bulgeDistortion(s.image.clone(), scale: 0.4),
            resolution: s.resolution));
    add('stretchDistortion',
        BenchmarkCase('stretchDistortion',
            () => stretchDistortion(s.image.clone()),
            resolution: s.resolution));
    add('colorHalftone',
        BenchmarkCase('colorHalftone',
            () => colorHalftone(s.image.clone(), size: 6),
            resolution: s.resolution));
    add('dotScreen',
        BenchmarkCase('dotScreen',
            () => dotScreen(s.image.clone(), size: 6),
            resolution: s.resolution));
    add('chromaticAberration',
        BenchmarkCase('chromaticAberration',
            () => chromaticAberration(s.image.clone(), shift: 4),
            resolution: s.resolution));
    add('edgeGlow',
        BenchmarkCase('edgeGlow', () => edgeGlow(s.image.clone()),
            resolution: s.resolution));
    add('emboss',
        BenchmarkCase('emboss', () => emboss(s.image.clone()),
            resolution: s.resolution));
    add('sketch',
        BenchmarkCase('sketch', () => sketch(s.image.clone()),
            resolution: s.resolution));
    add('smooth',
        BenchmarkCase('smooth', () => smooth(s.image.clone(), weight: 1.2),
            resolution: s.resolution));
    add('bleachBypass',
        BenchmarkCase('bleachBypass', () => bleachBypass(s.image.clone()),
            resolution: s.resolution));
    add('billboard',
        BenchmarkCase('billboard', () => billboard(s.image.clone()),
            resolution: s.resolution));
    add('dropShadow',
        BenchmarkCase('dropShadow', () => dropShadow(s.image.clone(), 8, 8, 4),
            resolution: s.resolution));
    add('grayscale',
        BenchmarkCase('grayscale', () => grayscale(s.image.clone()),
            resolution: s.resolution));
    add('invert',
        BenchmarkCase('invert', () => invert(s.image.clone()),
            resolution: s.resolution));
    add('sepia',
        BenchmarkCase('sepia', () => sepia(s.image.clone()),
            resolution: s.resolution));
    add('monochrome',
        BenchmarkCase('monochrome', () => monochrome(s.image.clone()),
            resolution: s.resolution));
    add('luminanceThreshold',
        BenchmarkCase('luminanceThreshold',
            () => luminanceThreshold(s.image.clone(), threshold: 0.4),
            resolution: s.resolution));
    add('normalize',
        BenchmarkCase('normalize',
            () => normalize(s.image.clone(), min: 0, max: 255),
            resolution: s.resolution));
    add('quantize',
        BenchmarkCase('quantize',
            () => quantize(s.image.clone(), numberOfColors: 64),
            resolution: s.resolution));
    add('ditherImage',
        BenchmarkCase('ditherImage',
            () => ditherImage(s.image.clone(),
                kernel: DitherKernel.floydSteinberg),
            resolution: s.resolution));
    add('solarize',
        BenchmarkCase('solarize',
            () => solarize(s.image.clone(), threshold: 128),
            resolution: s.resolution));
    add('sobel',
        BenchmarkCase('sobel', () => sobel(s.image.clone()),
            resolution: s.resolution));
    add('vignette',
        BenchmarkCase('vignette', () => vignette(s.image.clone()),
            resolution: s.resolution));
    add('hdrToLdr',
        BenchmarkCase('hdrToLdr',
            () => hdrToLdr(s.image.clone(), exposure: 0.5),
            resolution: s.resolution));
    add('reinhardTonemap',
        BenchmarkCase('reinhardTonemap',
            () => reinhardTonemap(s.image.clone()),
            resolution: s.resolution));
    add('bumpToNormal',
        BenchmarkCase('bumpToNormal',
            () => bumpToNormal(s.image.clone(), strength: 2.0),
            resolution: s.resolution));
    add('histogramEqualization',
        BenchmarkCase('histogramEqualization',
            () => histogramEqualization(s.image.clone()),
            resolution: s.resolution));
    add('histogramStretch',
        BenchmarkCase('histogramStretch',
            () => histogramStretch(s.image.clone()),
            resolution: s.resolution));

    // Draw (canvas matches resolution)
    add('drawLine',
        BenchmarkCase('drawLine', () {
          final img = makeSolidImage(s.width, s.height);
          drawLine(img,
              x1: 0,
              y1: 0,
              x2: s.width - 1,
              y2: s.height - 1,
              color: ColorRgb8(255, 0, 0));
        }, resolution: s.resolution));
    add('drawRect',
        BenchmarkCase('drawRect', () {
          final img = makeSolidImage(s.width, s.height);
          drawRect(img,
              x1: s.width ~/ 10,
              y1: s.height ~/ 10,
              x2: (s.width * 0.8).round(),
              y2: (s.height * 0.8).round(),
              color: ColorRgb8(0, 255, 0));
        }, resolution: s.resolution));
    add('drawCircle',
        BenchmarkCase('drawCircle', () {
          final img = makeSolidImage(s.width, s.height);
          final r = (minDim ~/ 4).clamp(1, 99999).toInt();
          drawCircle(img,
              x: s.width ~/ 2,
              y: s.height ~/ 2,
              radius: r,
              color: ColorRgb8(0, 0, 255));
        }, resolution: s.resolution));
    add('drawPixel',
        BenchmarkCase('drawPixel', () {
          final img = makeSolidImage(s.width, s.height);
          drawPixel(img, s.width ~/ 2, s.height ~/ 2,
              ColorRgba8(255, 255, 0, 255));
        }, resolution: s.resolution));
    add('drawChar',
        BenchmarkCase('drawChar', () {
          final img = makeSolidImage(s.width, s.height);
          drawChar(img, 'A',
              font: arial14,
              x: s.width ~/ 10,
              y: s.height ~/ 10,
              color: ColorRgb8(255, 255, 255));
        }, resolution: s.resolution));
    add('drawString',
        BenchmarkCase('drawString', () {
          final img = makeSolidImage(s.width, s.height);
          drawString(img, 'image',
              font: arial14,
              x: s.width ~/ 10,
              y: s.height ~/ 10,
              color: ColorRgb8(255, 255, 255));
        }, resolution: s.resolution));
    add('drawPolygon',
        BenchmarkCase('drawPolygon', () {
          final img = makeSolidImage(s.width, s.height);
          drawPolygon(img,
              vertices: [
                Point(s.width * 0.1, s.height * 0.1),
                Point(s.width * 0.8, s.height * 0.2),
                Point(s.width * 0.6, s.height * 0.8)
              ],
              color: ColorRgb8(255, 0, 0));
        }, resolution: s.resolution));
    add('fillPolygon',
        BenchmarkCase('fillPolygon', () {
          final img = makeSolidImage(s.width, s.height);
          fillPolygon(img,
              vertices: [
                Point(s.width * 0.1, s.height * 0.1),
                Point(s.width * 0.8, s.height * 0.2),
                Point(s.width * 0.6, s.height * 0.8)
              ],
              color: ColorRgb8(0, 255, 0));
        }, resolution: s.resolution));
    add('fillRect',
        BenchmarkCase('fillRect', () {
          final img = makeSolidImage(s.width, s.height);
          fillRect(img,
              x1: s.width ~/ 10,
              y1: s.height ~/ 10,
              x2: (s.width * 0.8).round(),
              y2: (s.height * 0.8).round(),
              color: ColorRgb8(0, 0, 255));
        }, resolution: s.resolution));
    add('fillCircle',
        BenchmarkCase('fillCircle', () {
          final img = makeSolidImage(s.width, s.height);
          final r = (minDim ~/ 4).clamp(1, 99999).toInt();
          fillCircle(img,
              x: s.width ~/ 2,
              y: s.height ~/ 2,
              radius: r,
              color: ColorRgb8(255, 0, 255));
        }, resolution: s.resolution));
    add('fill',
        BenchmarkCase('fill', () {
          final img = makeSolidImage(s.width, s.height);
          fill(img, color: ColorRgb8(32, 64, 96));
        }, resolution: s.resolution));
    add('fillFlood',
        BenchmarkCase('fillFlood', () {
          final img = makeSolidImage(s.width, s.height);
          fillFlood(img,
              x: s.width ~/ 2,
              y: s.height ~/ 2,
              color: ColorRgb8(0, 0, 0));
        }, resolution: s.resolution));
    add('maskFlood',
        BenchmarkCase('maskFlood', () {
          final img = makeSolidImage(s.width, s.height);
          maskFlood(img, s.width ~/ 2, s.height ~/ 2);
        }, resolution: s.resolution));
    add('compositeImage',
        BenchmarkCase('compositeImage', () {
          final dst = makeSolidImage(s.width, s.height);
          final src = makeSolidImage(s.width ~/ 2, s.height ~/ 2,
              color: ColorRgb8(200, 50, 50));
          compositeImage(dst, src,
              dstX: s.width ~/ 4, dstY: s.height ~/ 4);
        }, resolution: s.resolution));
  }

  // Single-sample formats without multi-res sources
  final jpgImg = decodeJpg(jpgBytes)!;
  final gifImg = decodeGif(gifBytes)!;
  final bmpImg = decodeBmp(bmpBytes)!;
  final tgaImg = decodeTga(tgaBytes)!;
  final tiffImg = decodeTiff(tiffBytes)!;
  final webpImg = decodeWebP(webpBytes)!;
  final pnmImg = decodePnm(pnmBytes)!;
  final psdImg = decodePsd(psdBytes)!;
  final pvrImg = decodePvr(pvrBytes)!;
  final exrImg = decodeExr(exrBytes)!;
  final icoImg = decodeIco(icoBytes)!;

  final jpgRes = '${jpgImg.width}x${jpgImg.height}';
  final gifRes = '${gifImg.width}x${gifImg.height}';
  final bmpRes = '${bmpImg.width}x${bmpImg.height}';
  final tgaRes = '${tgaImg.width}x${tgaImg.height}';
  final tiffRes = '${tiffImg.width}x${tiffImg.height}';
  final webpRes = '${webpImg.width}x${webpImg.height}';
  final pnmRes = '${pnmImg.width}x${pnmImg.height}';
  final psdRes = '${psdImg.width}x${psdImg.height}';
  final pvrRes = '${pvrImg.width}x${pvrImg.height}';
  final exrRes = '${exrImg.width}x${exrImg.height}';
  final icoRes = '${icoImg.width}x${icoImg.height}';
  final iconImage = makeSolidImage(32, 32);
  final pvrImage = makeSolidImage(128, 128);

  add('decodeJpg',
      BenchmarkCase('decodeJpg', () => decodeJpg(jpgBytes),
          resolution: jpgRes, note: 'single sample'));
  add('decodeGif',
      BenchmarkCase('decodeGif', () => decodeGif(gifBytes),
          resolution: gifRes, note: 'single sample'));
  add('decodeBmp',
      BenchmarkCase('decodeBmp', () => decodeBmp(bmpBytes),
          resolution: bmpRes, note: 'single sample'));
  add('decodeTga',
      BenchmarkCase('decodeTga', () => decodeTga(tgaBytes),
          resolution: tgaRes, note: 'single sample'));
  add('decodeTiff',
      BenchmarkCase('decodeTiff', () => decodeTiff(tiffBytes),
          resolution: tiffRes, note: 'single sample'));
  add('decodeWebP',
      BenchmarkCase('decodeWebP', () => decodeWebP(webpBytes),
          resolution: webpRes, note: 'single sample'));
  add('decodePnm',
      BenchmarkCase('decodePnm', () => decodePnm(pnmBytes),
          resolution: pnmRes, note: 'single sample'));
  add('decodePsd',
      BenchmarkCase('decodePsd', () => decodePsd(psdBytes),
          resolution: psdRes, note: 'single sample'));
  add('decodeExr',
      BenchmarkCase('decodeExr', () => decodeExr(exrBytes),
          resolution: exrRes, note: 'single sample'));
  add('decodeIco',
      BenchmarkCase('decodeIco', () => decodeIco(icoBytes),
          resolution: icoRes, note: 'single sample'));
  add('decodePvr',
      BenchmarkCase('decodePvr', () => decodePvr(pvrBytes),
          resolution: pvrRes, note: 'single sample'));

  add('encodeCur',
      BenchmarkCase('encodeCur', () => encodeCur(iconImage, singleFrame: true),
          resolution: '32x32', note: 'fixed size'));
  add('encodeIco',
      BenchmarkCase('encodeIco', () => encodeIco(iconImage, singleFrame: true),
          resolution: '32x32', note: 'fixed size'));
  add('encodePvr',
      BenchmarkCase('encodePvr', () => encodePvr(pvrImage, singleFrame: true),
          resolution: '128x128', note: 'fixed size'));
  add('decodeJpgExif',
      BenchmarkCase('decodeJpgExif', () => decodeJpgExif(jpgBytes),
          resolution: jpgRes, note: 'single sample'));
  add('injectJpgExif',
      BenchmarkCase('injectJpgExif', () {
        final exif = decodeJpgExif(jpgBytes);
        if (exif != null) {
          injectJpgExif(jpgBytes, exif);
        }
      }, resolution: jpgRes, note: 'single sample'));

  return cases;
}
