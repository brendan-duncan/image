import 'dart:html';
import 'package:image/image.dart';

ImageData filterImageData;
CanvasElement canvas;
DivElement logDiv;
Image origImage;

void _addControl(
    String label, String value, DivElement parent, dynamic callback) {
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
  var sidebar = document.querySelector('#sidebar') as DivElement;
  sidebar.children.clear();

  var label = Element.tag('h1');
  label.text = 'Sepia';
  sidebar.children.add(label);

  num amount = 1.0;

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

  _addControl('Amount', amount.toString(), sidebar, (num v) {
    amount = v;
    _apply();
  });

  _apply();
}

void testSobel() {
  var sidebar = document.querySelector('#sidebar') as DivElement;
  sidebar.children.clear();

  var label = Element.tag('h1');
  label.text = 'Sepia';
  sidebar.children.add(label);

  num amount = 1.0;

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

  _addControl('Amount', amount.toString(), sidebar, (num v) {
    amount = v;
    _apply();
  });

  _apply();
}

void testGaussian() {
  var sidebar = document.querySelector('#sidebar') as DivElement;
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

  _addControl('Radius', radius.toString(), sidebar, (num v) {
    radius = v.toInt();
    _apply();
  });

  _apply();
}

void testVignette() {
  var sidebar = document.querySelector('#sidebar') as DivElement;
  sidebar.children.clear();

  var label = Element.tag('h1');
  label.text = 'Vignette';
  sidebar.children.add(label);

  num start = 0.3;
  num end = 0.75;
  num amount = 1.0;

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

  _addControl('Start', start.toString(), sidebar, (num v) {
    start = v;
    _apply();
  });

  _addControl('End', end.toString(), sidebar, (num v) {
    end = v;
    _apply();
  });

  _addControl('Amount', amount.toString(), sidebar, (num v) {
    amount = v;
    _apply();
  });

  _apply();
}

void testPixelate() {
  var sidebar = document.querySelector('#sidebar') as DivElement;
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

  _addControl('blockSize', blockSize.toString(), sidebar, (num v) {
    blockSize = v.toInt();
    _apply();
  });

  _apply();
}

void testColorOffset() {
  var sidebar = document.querySelector('#sidebar') as DivElement;
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
    image =
        colorOffset(image, red: red, green: green, blue: blue, alpha: alpha);

    // Fill the buffer with our image data.
    filterImageData.data
        .setRange(0, filterImageData.data.length, image.getBytes());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width, canvas.height);
    canvas.context2D.putImageData(filterImageData, 0, 0);
    logDiv.text = 'TIME: ${t.elapsedMilliseconds / 1000.0}';
    print(t.elapsedMilliseconds / 1000.0);
  }

  _addControl('red', red.toString(), sidebar, (num v) {
    red = v.toInt();
    _apply();
  });

  _addControl('green', red.toString(), sidebar, (num v) {
    green = v.toInt();
    _apply();
  });

  _addControl('blue', red.toString(), sidebar, (num v) {
    blue = v.toInt();
    _apply();
  });

  _addControl('alpha', red.toString(), sidebar, (num v) {
    alpha = v.toInt();
    _apply();
  });

  _apply();
}

void testAdjustColor() {
  var sidebar = document.querySelector('#sidebar') as DivElement;
  sidebar.children.clear();

  var label = Element.tag('h1');
  label.text = 'Adjust Color';
  sidebar.children.add(label);

  num contrast = 1.0;
  num saturation = 1.0;
  num brightness = 1.0;
  num gamma = 0.8;
  num exposure = 0.3;
  num hue = 0.0;
  num amount = 1.0;

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

  _addControl('Contrast', contrast.toString(), sidebar, (num v) {
    contrast = v;
    _apply();
  });

  _addControl('Saturation', saturation.toString(), sidebar, (num v) {
    saturation = v;
    _apply();
  });

  _addControl('Brightness', brightness.toString(), sidebar, (num v) {
    brightness = v;
    _apply();
  });

  _addControl('Gamma', gamma.toString(), sidebar, (num v) {
    gamma = v;
    _apply();
  });

  _addControl('Exposure', exposure.toString(), sidebar, (num v) {
    exposure = v;
    _apply();
  });

  _addControl('Hue', hue.toString(), sidebar, (num v) {
    hue = v;
    _apply();
  });

  _addControl('Amount', amount.toString(), sidebar, (num v) {
    amount = v;
    _apply();
  });

  _apply();
}

void main() {
  canvas = document.querySelector('#filter_canvas') as CanvasElement;
  logDiv = document.querySelector('#log') as DivElement;

  var menu = document.querySelector('#FilterType') as SelectElement;
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
