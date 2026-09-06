import 'dart:typed_data';

import '../color/color.dart';
import '../image/icc_profile.dart';
import '../image/image.dart';
import '../util/image_exception.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';
import 'webp/vp8_config.dart';
import 'webp/vp8_encoder.dart';
import 'webp/vp8l_encoder.dart';
import 'webp/webp_container.dart';

/// Encode an image to the WebP format, losslessly or lossily.
///
/// **[lossless] is on by default**, and it makes [quality], [method] and
/// [alphaQuality] do nothing, so an encoder built with a quality alone will
/// quietly ignore it:
///
/// ```dart
/// WebPEncoder(quality: 40);                    // still lossless
/// WebPEncoder(lossless: false, quality: 40);   // lossy, as intended
/// ```
///
/// Lossless uses the VP8L bitstream, lossy the VP8 one, wrapped either way in a
/// RIFF/WebP container. Animation, an ICC profile and EXIF are carried in the
/// extended format when the image has them. XMP is not: the decoder reports it
/// on WebPInfo but never puts it on the Image, so there is nothing here to
/// write back.
class WebPEncoder extends Encoder {
  WebPEncoder({
    this.exact = true,
    this.lossless = true,
    this.quality = 75,
    this.method = 4,
    this.alphaQuality = 100,
  });

  /// Whether to preserve the colour under fully transparent pixels.
  ///
  /// Clearing it flattens that colour into long runs, worth 15-20% on an image
  /// with large transparent areas, which is what cwebp does unless given its
  /// own `-exact`
  final bool exact;

  /// Whether to reproduce the image exactly.
  ///
  /// Lossless keeps every pixel and typically saves 20-30% against PNG. Lossy
  /// discards what the eye is least likely to miss and is several times
  /// smaller again, which is what makes WebP an alternative to JPEG.
  final bool lossless;

  /// Between 0 and 100, how much the lossy encoder may discard. Ignored when
  /// [lossless] is set.
  ///
  /// The scale belongs to this encoder and does not line up with JPEG's: a
  /// JPEG at 75 and a WebP at 75 are not the same request, and comparing the
  /// two formats by their quality numbers says nothing. Compare the size and
  /// the fidelity they actually produce.
  ///
  /// Above about 90 the file grows very steeply for very little. Measured on
  /// one corpus of screenshots, 90 cost twice the bytes of 75 and 100 cost
  /// four times, for 3 and 4.5 dB. Below 75 the curve is even: every five
  /// points takes off about six per cent, with no natural stopping point, so
  /// how low to go is a judgement about the material rather than a number to
  /// be found.
  final int quality;

  /// How much work the lossy encoder puts into each block, 0 to 6. Ignored
  /// when [lossless] is set.
  ///
  /// This trades encoding time against size at a fixed [quality], and the two
  /// are independent: measured at qualities 40, 60 and 75 the effect was the
  /// same at each.
  ///
  /// - 0 and 1 skip the rate-distortion search entirely: about 20% larger,
  ///   four times faster. For encoding on demand.
  /// - 2 and 3 add the search but not the coefficient trellis.
  /// - 4, the default, is a reasonable middle.
  /// - 5 and 6 add the trellis on every candidate: about 5% smaller than 4 for
  ///   twice the time. Worth it for a batch job, where the whole difference is
  ///   seconds over a run.
  final int method;

  /// Between 0 and 100, how exactly the alpha plane is kept. Ignored when
  /// [lossless] is set, where transparency is always exact.
  ///
  /// The alpha plane rides in its own losslessly coded chunk, so at 100 it
  /// survives untouched however low [quality] goes. Below 100 it is first
  /// reduced to fewer distinct levels, which is worth a great deal on a soft
  /// edge or a gradient mask and nothing at all on a hard-edged cut-out.
  final int alphaQuality;

  @override
  bool get supportsAnimation => true;

  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    final animate = !singleFrame && image.hasAnimation;
    if (animate) {
      _checkFramesFitCanvas(image);
    }
    final exif = _exifBytes(image);
    final icc = _iccBytes(image);

    final frame = _encodeFrame(image);
    // A lossy bitstream cannot carry transparency itself, so a picture that
    // has any needs the extended format even with no metadata at all.
    final hasAlphaChunk = frame.length > 1;

    // Nothing but pixels: the simple container is smaller, and is what every
    // reader handles.
    if (!animate && exif == null && icc == null && !hasAlphaChunk) {
      return buildRiff(frame);
    }

    final chunks = <WebPChunk>[
      WebPChunk(
          'VP8X',
          vp8xChunkData(
              vp8xFlags(
                hasIcc: icc != null,
                hasAlpha: hasAlphaChunk || _hasTransparency(image),
                hasExif: exif != null,
                hasXmp: false,
                hasAnimation: animate,
              ),
              image.width,
              image.height)),
    ];

    if (icc != null) {
      chunks.add(WebPChunk('ICCP', icc));
    }

    if (animate) {
      final bg = image.backgroundColor;
      chunks.add(WebPChunk(
          'ANIM',
          animChunkData(
              _channel8(bg, (c) => c.r),
              _channel8(bg, (c) => c.g),
              _channel8(bg, (c) => c.b),
              _channel8(bg, (c) => c.a),
              image.loopCount)));
      for (final f in image.frames) {
        chunks.add(WebPChunk(
            'ANMF',
            anmfChunkData(
              x: 0,
              y: 0,
              width: f.width,
              height: f.height,
              duration: f.frameDuration,
              // Frames are stored whole rather than as deltas, so each one
              // clears the canvas and replaces it instead of blending onto it
              clearToBackground: true,
              blend: false,
              frame: identical(f, image) ? frame : _encodeFrame(f),
            )));
      }
    } else {
      chunks.addAll(frame);
    }

    if (exif != null) {
      chunks.add(WebPChunk('EXIF', exif));
    }
    return buildRiff(chunks);
  }

  /// The chunks that carry one frame: its bitstream, preceded by an alpha
  /// plane when the bitstream is lossy and the frame has transparency.
  List<WebPChunk> _encodeFrame(Image frame) {
    if (lossless) {
      return [
        WebPChunk('VP8L', VP8LEncoder(exact: exact).encodeVP8L(frame)),
      ];
    }
    final coded = encodeVP8(
        frame,
        VP8Config(
          quality: quality.toDouble(),
          method: method,
          exact: exact,
          alphaQuality: alphaQuality,
        ));
    final alpha = coded.alpha;
    return [
      if (alpha != null) WebPChunk('ALPH', alpha),
      WebPChunk('VP8 ', coded.bitstream),
    ];
  }

  /// libwebp's demuxer rejects the whole file when a frame overruns the
  /// canvas, rather than skipping that one frame
  static void _checkFramesFitCanvas(Image image) {
    // The index is counted rather than read off the frame, since frameIndex is
    // only filled in by addFrame
    for (var i = 0; i < image.frames.length; i++) {
      final f = image.frames[i];
      if (f.width > image.width || f.height > image.height) {
        throw ImageException('WebP animation frames must fit the '
            '${image.width}x${image.height} canvas, but frame $i is '
            '${f.width}x${f.height}.');
      }
    }
  }

  /// One channel of [color], scaled rather than truncated: a wider channel
  /// written raw spills into the byte packed above it
  static int _channel8(Color? color, num Function(Color) channel) {
    if (color == null) {
      return 0;
    }
    final max = color.maxChannelValue;
    final value = channel(color);
    return (max == 255 ? value : value * 255 / max).round().clamp(0, 255);
  }

  /// [IccProfile.decompressed] inflates in place, so a deflated profile is
  /// copied first and encoding leaves the image it was given untouched
  static Uint8List? _iccBytes(Image image) {
    final profile = image.iccProfile;
    if (profile == null) {
      return null;
    }
    return profile.compression == IccProfileCompression.none
        ? profile.data
        : profile.clone().decompressed();
  }

  /// Whether any frame has a pixel that is not fully opaque.
  ///
  /// An opaque four channel image is written without alpha, so the flag cannot
  /// follow the channel count.
  static bool _hasTransparency(Image image) {
    for (final frame in image.frames) {
      if (!frame.hasAlpha) {
        continue;
      }
      for (final p in frame) {
        if (p.a != p.maxChannelValue) {
          return true;
        }
      }
    }
    return false;
  }

  static Uint8List? _exifBytes(Image image) {
    if (image.exif.isEmpty) {
      return null;
    }
    final out = OutputBuffer();
    image.exif.write(out);
    return out.getBytes();
  }
}
