import 'dart:html' as Html;
import 'package:image/image.dart';

Html.ImageData filterImageData;
Html.CanvasElement canvas;
Html.DivElement logDiv;
Image origImage;

void _addControl(String label, String value, Html.DivElement parent,
                 callback) {
  Html.LabelElement amountLabel = new Html.LabelElement();
  amountLabel.text = label + ':';
  var amountEdit = new Html.InputElement();
  amountEdit.value = value;
  amountEdit.id = label + '_edit';
  amountEdit.onChange.listen((e) {
    try {
      double d = double.parse(amountEdit.value);
      callback(d);
    } catch (e) {
    }
  });
  amountLabel.htmlFor = label + '_edit';
  parent.append(amountLabel);
  parent.append(amountEdit);
  parent.append(new Html.ParagraphElement());
}


void testSepia() {
  Html.DivElement sidebar = Html.document.querySelector('#sidebar');
  sidebar.children.clear();

  var label = new Html.Element.tag('h1');
  label.text = 'Sepia';
  sidebar.children.add(label);

  double amount = 1.0;

  void _apply() {
    Image image = new Image.from(origImage);
    image = sepia(image, amount: amount);

    // Fill the buffer with our image data.
    filterImageData.data.setRange(0, filterImageData.data.length,
                                  image.getBytes());
    // Draw the buffer onto the canvas.
    canvas.context2D.clearRect(0, 0, canvas.width, canvas.height);
    canvas.context2D.putImageData(filterImageData, 0, 0);
  }

  _addControl('Amount', amount.toString(), sidebar, (v) {
    amount = v;
    _apply();
  });

  _apply();
}


void testAdjustColor() {
  Html.DivElement sidebar = Html.document.querySelector('#sidebar');
  sidebar.children.clear();

  var label = new Html.Element.tag('h1');
  label.text = 'Adjust Color';
  sidebar.children.add(label);

  double contrast = 1.0;
  double saturation = 1.0;
  double brightness = 1.0;
  double gamma = 1.0;
  double exposure = 0.0;
  double hue = 0.0;
  double amount = 1.0;

  void _apply() {
    Stopwatch t = new Stopwatch();

    Image image = new Image.from(origImage);
    t.start();
    image = adjustColor(image, contrast: contrast, saturation: saturation,
        brightness: brightness, gamma: gamma, exposure: exposure,
        hue: hue, amount: amount);
    t.stop();

    // Fill the buffer with our image data.
    filterImageData.data.setRange(0, filterImageData.data.length,
                                  image.getBytes());
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
  canvas = Html.document.querySelector('#filter_canvas');
  logDiv = Html.document.querySelector('#log');

  Html.ImageElement img = new Html.ImageElement();
  img.src = 'res/big_buck_bunny.jpg';
  img.onLoad.listen((e) {
    var c = new Html.CanvasElement();
    c.width = img.width;
    c.height = img.height;
    c.context2D.drawImage(img, 0, 0);

    var imageData = c.context2D.getImageData(0, 0, img.width, img.height);
    origImage = new Image.fromBytes(img.width, img.height, imageData.data);

    canvas.width = img.width;
    canvas.height = img.height;
    filterImageData = canvas.context2D.createImageData(img.width, img.height);

    testAdjustColor();
  });
}
