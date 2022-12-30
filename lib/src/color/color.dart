import '../image/palette.dart';
import 'channel.dart';
import 'format.dart';

/// The abstract Color class is the base class for all specific color classes
/// and Pixel classes. Colors are iterable, iterating over its channels.
abstract class Color extends Iterable<num> {
  /// The number of channels used by the color.
  int get length;
  /// The maximum value for a color channel.
  num get maxChannelValue;
  /// The maximum value for a palette index.
  num get maxIndexValue;
  /// The [Format] of the color.
  Format get format;
  /// True if the format is low dynamic range.
  bool get isLdrFormat;
  /// True if the format is high dynamic range.
  bool get isHdrFormat;
  /// True if the color uses a palette.
  bool get hasPalette;
  /// The palette used by the color, or null.
  Palette? get palette;

  /// Gets a channel from the color by its index.
  num operator[](int index);
  void operator[]=(int index, num value);

  /// Palette index value (or red channel if there is no palette).
  num get index;
  void set index(num i);

  /// Red channel.
  num get r;
  void set r(num r);

  /// Green channel.
  num get g;
  void set g(num g);

  /// Blue channel.
  num get b;
  void set b(num b);

  /// Alpha channel.
  num get a;
  void set a(num a);

  /// Normalized \[0, 1\] red.
  num get rNormalized;
  void set rNormalized(num v);

  /// Normalized \[0, 1\] green.
  num get gNormalized;
  void set gNormalized(num v);

  /// Normalized \[0, 1\] blue.
  num get bNormalized;
  void set bNormalized(num v);

  /// Normalized \[0, 1\] alpha.
  num get aNormalized;
  void set aNormalized(num v);

  /// The luminance (grayscale) of the color.
  num get luminance;
  num get luminanceNormalized;

  /// Get a [channel] from the color. If the channel isn't available,
  /// 0 will be returned.
  num getChannel(Channel channel);

  /// Get the normalized \[0, 1\] value of a [channel] from the color. If the
  /// channel isn't available, 0 will be returned.
  num getChannelNormalized(Channel channel);

  /// The the values of this color to the given [color].
  void set(Color color);
  /// Set the individual [r], [g], [b], and [a] channels of the color.
  void setColor(num r, [num g = 0, num b = 0, num a = 0]);

  /// Returns a copy of the color.
  Color clone();

  /// Convert the [format] and/or the [numChannels] of the color. If
  /// [numChannels] is 4 and the current color does not have an alpha value,
  /// then [alpha] can specify what value to use for the new alpha channel.
  /// If [alpha] is not given, then [maxChannelValue] will be used.
  Color convert({ Format? format, int? numChannels, num? alpha });

  /// Tests if this color is equivalent to another [Color].
  bool operator==(Object? other);

  /// Compute a hashCode for this color.
  int get hashCode;
}
