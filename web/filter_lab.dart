import 'dart:html';
import 'package:image/image.dart';

ImageData filterImageData;
CanvasElement canvas;
DivElement logDiv;
Image origImage;

void _addControl(String label, String value, DivElement parent, callback) {
  LabelElement amountLabel = LabelElement();
  amountLabel.text = label + ':';
  var amountEdit = InputElement();
  amountEdit.value = value;
  amountEdit.id = label + '_edit';
  amountEdit.onChange.listen((e) {
    try {
      double d = double.parse(amountEdit.value);
      callback(d);
    } catch (e) {
      print(e);
    }
  });
  amountLabel.htmlFor = label + '_edit';
  parent.append(amountLabel);
  parent.append(amountEdit);
  parent.append(new ParagraphElement());
}

void testSepia() {
  DivElement sidebar = document.querySelector('#sidebar');
  sidebar.children.clear();

  var label = Element.tag('h1');
  label.text = 'Sepia';
  sidebar.children.add(label);

  double amount = 1.0;

  void _apply() {
    Stopwatch t = Stopwatch();
    t.start();
    Image image = Image.from(origImage);
    image = sepia(image, amount: amount);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.getBytes());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width, canvas.height);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('Amount', amount.toString(), sidebar, (v) {
    amount = v;
    _apply();
  });

  _apply();
}

void testSobel() {
  DivElement sidebar = document.querySelector('#sidebar');
  sidebar.children.clear();

  var label = Element.tag('h1');
  label.text = 'Sepia';
  sidebar.children.add(label);

  double amount = 1.0;

  void _apply() {
    Stopwatch t = Stopwatch();
    t.start();
    Image image = Image.from(origImage);
    image = sobel(image, amount: amount);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.getBytes());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width, canvas.height);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('Amount', amount.toString(), sidebar, (v) {
    amount = v;
    _apply();
  });

  _apply();
}

void testGaussian() {
  DivElement sidebar = document.querySelector('#sidebar');
  sidebar.children.clear();

  var label = Element.tag('h1');
  label.text = 'Gaussian Blur';
  sidebar.children.add(label);

  int radius = 5;

  void _apply() {
    Stopwatch t = Stopwatch();
    t.start();
    Image image = Image.from(origImage);
    image = gaussianBlur(image, radius);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.getBytes());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width, canvas.height);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('Radius', radius.toString(), sidebar, (v) {
    radius = v.toInt();
    _apply();
  });

  _apply();
}

void testVignette() {
  DivElement sidebar = document.querySelector('#sidebar');
  sidebar.children.clear();

  var label = Element.tag('h1');
  label.text = 'Vignette';
  sidebar.children.add(label);

  double start = 0.3;
  double end = 0.75;
  double amount = 1.0;

  void _apply() {
    Stopwatch t = Stopwatch();
    t.start();
    Image image = Image.from(origImage);
    image = vignette(image, start: start, end: end, amount: amount);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.getBytes());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width, canvas.height);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('Start', start.toString(), sidebar, (v) {
    start = v;
    _apply();
  });

  _addControl('End', end.toString(), sidebar, (v) {
    end = v;
    _apply();
  });

  _addControl('Amount', amount.toString(), sidebar, (v) {
    amount = v;
    _apply();
  });

  _apply();
}

void testPixelate() {
  DivElement sidebar = document.querySelector('#sidebar');
  sidebar.children.clear();

  var label = Element.tag('h1');
  label.text = 'Pixelate';
  sidebar.children.add(label);

  int blockSize = 5;

  void _apply() {
    Stopwatch t = Stopwatch();
    t.start();
    Image image = Image.from(origImage);
    image = pixelate(image, blockSize);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.getBytes());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width, canvas.height);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('blockSize', blockSize.toString(), sidebar, (v) {
    blockSize = v.toInt();
    _apply();
  });

  _apply();
}

void testColorOffset() {
  DivElement sidebar = document.querySelector('#sidebar');
  sidebar.children.clear();

  var label = Element.tag('h1');
  label.text = 'Pixelate';
  sidebar.children.add(label);

  int red = 0;
  int green = 0;
  int blue = 0;
  int alpha = 0;

  void _apply() {
    Stopwatch t = Stopwatch();
    t.start();
    Image image = Image.from(origImage);
    image = colorOffset(image, red, green, blue, alpha);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.getBytes());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width, canvas.height);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('red', red.toString(), sidebar, (v) {
    red = v.toInt();
    _apply();
  });

  _addControl('green', red.toString(), sidebar, (v) {
    green = v.toInt();
    _apply();
  });

  _addControl('blue', red.toString(), sidebar, (v) {
    blue = v.toInt();
    _apply();
  });

  _addControl('alpha', red.toString(), sidebar, (v) {
    alpha = v.toInt();
    _apply();
  });

  _apply();
}

void testAdjustColor() {
  DivElement sidebar = document.querySelector('#sidebar');
  sidebar.children.clear();

  var label = Element.tag('h1');
  label.text = 'Adjust Color';
  sidebar.children.add(label);

  double contrast = 1.0;
  double saturation = 1.0;
  double brightness = 1.0;
  double gamma = 0.8;
  double exposure = 0.3;
  double hue = 0.0;
  double amount = 1.0;

  void _apply() {
    Stopwatch t = Stopwatch();
    t.start();
    Image image = Image.from(origImage);

    image = adjustColor(image,
        contrast: contrast,
        saturation: saturation,
        brightness: brightness,
        gamma: gamma,
        exposure: exposure,
        hue: hue,
        amount: amount);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.getBytes());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width, canvas.height);
    canvas.context2D.putImageData(filterImageData, 0, 0);

    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('Contrast', contrast.toString(), sidebar, (v) {
    contrast = v;
    _apply();
  });

  _addControl('Saturation', saturation.toString(), sidebar, (v) {
    saturation = v;
    _apply();
  });

  _addControl('Brightness', brightness.toString(), sidebar, (v) {
    brightness = v;
    _apply();
  });

  _addControl('Gamma', gamma.toString(), sidebar, (v) {
    gamma = v;
    _apply();
  });

  _addControl('Exposure', exposure.toString(), sidebar, (v) {
    exposure = v;
    _apply();
  });

  _addControl('Hue', hue.toString(), sidebar, (v) {
    hue = v;
    _apply();
  });

  _addControl('Amount', amount.toString(), sidebar, (v) {
    amount = v;
    _apply();
  });

  _apply();
}

void main() {
  canvas = document.querySelector('#filter_canvas');
  logDiv = document.querySelector('#log');

  SelectElement menu = document.querySelector('#FilterType');
  menu.onChange.listen((e) {
    if (menu.value == 'Pixelate') {
      testPixelate();
    } else if (menu.value == 'Sepia') {
      testSepia();
    } else if (menu.value == 'Gaussian') {
      testGaussian();
    } else if (menu.value == 'Adjust Color') {
      testAdjustColor();
    } else if (menu.value == 'Sobel') {
      testSobel();
    } else if (menu.value == 'Vignette') {
      testVignette();
    } else if (menu.value == 'Color Offset') {
      testColorOffset();
    }
  });

  ImageElement img = ImageElement();
  img.src = 'res/big_buck_bunny.jpg';
  img.onLoad.listen((e) {
    var c = CanvasElement();
    c.width = img.width;
    c.height = img.height;
    c.context2D.drawImage(img, 0, 0);

    var imageData = c.context2D.getImageData(0, 0, img.width, img.height);
    origImage = Image.fromBytes(img.width, img.height, imageData.data);

    canvas.width = img.width;
    canvas.height = img.height;
    filterImageData = canvas.context2D.createImageData(img.width, img.height);

    testSepia();
  });
}
