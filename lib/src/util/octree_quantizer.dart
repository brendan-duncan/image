import '../color/color.dart';
import '../color/color_uint8.dart';
import '../image/image.dart';
import '../image/palette_uint8.dart';
import 'quantizer.dart';

// Color quantization using octree,
// from https://rosettacode.org/wiki/Color_quantization/C
class OctreeQuantizer extends Quantizer {
  @override
  late PaletteUint8 palette;
  final _OctreeNode _root;

  OctreeQuantizer(Image image, {int numberOfColors = 256})
      : _root = _OctreeNode(0, 0, null) {
    final heap = _HeapNode();
    for (final p in image) {
      final r = p.r as int;
      final g = p.g as int;
      final b = p.b as int;
      _heapAdd(heap, _nodeInsert(_root, r, g, b));
    }

    final nc = numberOfColors + 1;
    while (heap.n > nc) {
      _heapAdd(heap, _nodeFold(_popHeap(heap)!)!);
    }

    for (var i = 1; i < heap.n; i++) {
      final got = heap.buf[i]!;
      final c = got.count;
      got
        ..r = (got.r / c).round()
        ..g = (got.g / c).round()
        ..b = (got.b / c).round();
    }

    // The palette is the set of nodes remaining in the heap: the surviving
    // leaves plus any partially-folded internal nodes, which hold the average
    // of the pixels that were folded into them. A lookup can legitimately
    // stop at either kind, so both need palette entries.
    palette = PaletteUint8(heap.n - 1, 3);
    for (var i = 1; i < heap.n; ++i) {
      final n = heap.buf[i]!..paletteIndex = i - 1;
      palette.setRgb(i - 1, n.r, n.g, n.b);
    }

    _fillPaletteIndex(_root);
  }

  // Lookups of colors not present in the source image (e.g. from dither
  // error diffusion) can stop at internal nodes that were never folded into
  // and so have no palette entry of their own. Give every such node the
  // palette index of its most-populous child so a lookup never falls through
  // to an arbitrary index.
  int _fillPaletteIndex(_OctreeNode node) {
    if (node.childCount > 0) {
      var bestCount = -1;
      var bestIndex = -1;
      for (final child in node.children) {
        if (child != null) {
          final childIndex = _fillPaletteIndex(child);
          if (child.count > bestCount) {
            bestCount = child.count;
            bestIndex = childIndex;
          }
        }
      }
      if (node.paletteIndex < 0) {
        node.paletteIndex = bestIndex;
      }
    }
    return node.paletteIndex;
  }

  @override
  int getColorIndex(Color c) =>
      getColorIndexRgb(c.r.toInt(), c.g.toInt(), c.b.toInt());

  @override
  int getColorIndexRgb(int r, int g, int b) {
    var node = _root;
    for (var bit = 1 << 7; bit != 0; bit >>= 1) {
      final i = ((g & bit) != 0 ? 1 : 0) * 4 +
          ((r & bit) != 0 ? 1 : 0) * 2 +
          ((b & bit) != 0 ? 1 : 0);
      final child = node.children[i];
      if (child == null) {
        break;
      }
      node = child;
    }
    final index = node.paletteIndex;
    return index < 0 ? 0 : index;
  }

  /// Find the index of the closest color to [c] in the colorMap.
  @override
  Color getQuantizedColor(Color c) {
    if (palette.numColors == 0) {
      return ColorRgb8(0, 0, 0);
    }
    final i = getColorIndex(c);
    return ColorRgb8(palette.get(i, 0).toInt(), palette.get(i, 1).toInt(),
        palette.get(i, 2).toInt());
  }

  int _compareNode(_OctreeNode a, _OctreeNode b) {
    if (a.childCount < b.childCount) {
      return -1;
    }
    if (a.childCount > b.childCount) {
      return 1;
    }

    final ac = a.count >> a.depth;
    final bc = b.count >> b.depth;
    return (ac < bc)
        ? -1
        : (ac > bc)
            ? 1
            : 0;
  }

  _OctreeNode _nodeInsert(_OctreeNode root, int r, int g, int b) {
    var depth = 0;
    for (var bit = 1 << 7; ++depth < 8; bit >>= 1) {
      final i = ((g & bit) != 0 ? 1 : 0) * 4 +
          ((r & bit) != 0 ? 1 : 0) * 2 +
          ((b & bit) != 0 ? 1 : 0);
      if (root.children[i] == null) {
        root.children[i] = _OctreeNode(i, depth, root);
      }

      root = root.children[i]!;
    }

    root
      ..r += r
      ..g += g
      ..b += b;
    root.count++;
    return root;
  }

  _OctreeNode? _nodeFold(_OctreeNode p) {
    if (p.childCount > 0) {
      return null;
    }
    final q = p.parent!
      ..count += p.count
      ..r += p.r
      ..g += p.g
      ..b += p.b;
    q.childCount--;
    q.children[p.childIndex] = null;
    return q;
  }

  static const _inHeap = 1;

  _OctreeNode? _popHeap(_HeapNode h) {
    if (h.n <= 1) {
      return null;
    }

    final ret = h.buf[1];
    h.buf[1] = h.buf.removeLast();
    h.buf[1]!.heapIndex = 1;
    _downHeap(h, h.buf[1]!);

    return ret;
  }

  void _heapAdd(_HeapNode h, _OctreeNode p) {
    if ((p.flags & _inHeap) != 0) {
      _downHeap(h, p);
      _upHeap(h, p);
      return;
    }

    p
      ..flags |= _inHeap
      ..heapIndex = h.n;
    h.buf.add(p);
    _upHeap(h, p);
  }

  void _downHeap(_HeapNode h, _OctreeNode p) {
    var n = p.heapIndex;
    while (true) {
      var m = n * 2;
      if (m >= h.n) {
        break;
      }
      if ((m + 1) < h.n && _compareNode(h.buf[m]!, h.buf[m + 1]!) > 0) {
        m++;
      }

      if (_compareNode(p, h.buf[m]!) <= 0) {
        break;
      }

      h.buf[n] = h.buf[m];
      h.buf[n]!.heapIndex = n;
      n = m;
    }

    h.buf[n] = p;
    p.heapIndex = n;
  }

  void _upHeap(_HeapNode h, _OctreeNode p) {
    var n = p.heapIndex;
    _OctreeNode? prev;

    while (n > 1) {
      prev = h.buf[n ~/ 2];
      if (_compareNode(p, prev!) >= 0) {
        break;
      }

      h.buf[n] = prev;
      prev.heapIndex = n;
      n ~/= 2;
    }
    h.buf[n] = p;
    p.heapIndex = n;
  }
}

class _OctreeNode {
  // sum of all colors represented by this node.
  int r = 0;
  int g = 0;
  int b = 0;
  int count = 0;
  int heapIndex = 0;
  // -1 marks a node with no palette entry of its own; _fillPaletteIndex
  // assigns these the index of a descendant after the palette is built.
  int paletteIndex = -1;
  List<_OctreeNode?> children = List<_OctreeNode?>.filled(8, null);
  _OctreeNode? parent;
  int childCount = 0;
  int childIndex = 0;
  int flags = 0;
  int depth = 0;

  _OctreeNode(this.childIndex, this.depth, this.parent) {
    if (parent != null) {
      parent!.childCount++;
    }
  }
}

class _HeapNode {
  List<_OctreeNode?> buf = [null];
  int get n => buf.length;
}
