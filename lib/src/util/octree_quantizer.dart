import 'dart:math';
import 'dart:typed_data';

import '../color.dart';
import '../image.dart';
import '../image_exception.dart';


// Color quantization using octree,
// from https://rosettacode.org/wiki/Color_quantization/C
class OctreeQuantizer {
  _OctreeNode _root;

  OctreeQuantizer(Image image, {int numberOfColors=256}) {
    _root = new _OctreeNode(0, 0, null);

    _HeapNode heap = _HeapNode();
    for (int si = 0; si < image.length; ++si) {
      int c = image[si];
      int r = getRed(c);
      int g = getGreen(c);
      int b = getBlue(c);
      _heapAdd(heap, _nodeInsert(_root, r, g, b));
    }

    while (heap.buf.length > numberOfColors + 1) {
      _heapAdd(heap, _nodeFold(_popHeap(heap)));
    }

    for (int i = 1; i < heap.buf.length; i++) {
      var got = heap.buf[i];
      int c = got.count;
      got.r = (got.r / c).round();
      got.g = (got.g / c).round();
      got.b = (got.b / c).round();
    }
  }

  /**
   * Find the index of the closest color to [c] in the [colorMap].
   */
  int getQuantizedColor(int c) {
    int r = getRed(c);
    int g = getGreen(c);
    int b = getBlue(c);
    var root = _root;

    for (int bit = 1 << 7; bit != 0; bit >>= 1) {
      int i = ((g & bit) != 0 ? 1 : 0) * 4 + ((r & bit) != 0 ? 1 : 0) * 2 + ((b & bit) != 0 ? 1 : 0);
      if (root.children[i] != null) {
        break;
      }
      root = root.children[i];
    }

    r = root.r;
    g = root.g;
    b = root.b;
    return getColor(r, g, b, 255);
  }

  int _compareNode(_OctreeNode a, _OctreeNode b) {
    if (a.children.length < b.children.length) {
      return -1;
    }
    if (a.children.length > b.children.length) {
      return 1;
    }

    int ac = a.count * (1 + a.childIndex) >> a.depth;
    int bc = b.count * (1 + b.childIndex) >> b.depth;
    return ac < bc ? -1 : (ac > bc) ? 1 : 0;
  }


  _OctreeNode _nodeInsert(_OctreeNode root, int r, int g, int b) {
    const int OCT_DEPTH = 8;
    int depth = 0;
    for (int bit = 1 << 7; ++depth < OCT_DEPTH; bit >>= 1) {
      int i = ((g & bit) != 0 ? 1 : 0) * 4 +
          ((r & bit) != 0 ? 1 : 0) * 2 + ((b & bit) != 0 ? 1 : 0);
      if (root.children[i] == null) {
        root.children[i] = new _OctreeNode(i, depth, root);
      }

      root = root.children[i];
    }

    root.r += r;
    root.g += g;
    root.b += b;
    root.count++;
    return root;
  }

  _OctreeNode _nodeFold(_OctreeNode p) {
    if (p.childCount > 0) {
      return null;
    }
    var q = p.parent;
    q.count += p.count;

    q.r += p.r;
    q.g += p.g;
    q.b += p.b;
    q.childCount--;
    q.children[p.childIndex] = null;
    return q;
  }

  static const _ON_INHEAP = 1;

  _OctreeNode _popHeap(_HeapNode h) {
    if (h.buf.length <= 1) {
      return null;
    }

    _OctreeNode ret = h.buf[1];
    h.buf[1] = h.buf.removeLast();
    h.buf[1].heap_idx = 1;
    _downHeap(h, h.buf[1]);

    return ret;
  }

  void _heapAdd(_HeapNode h, _OctreeNode p) {
    if ((p.flags & _ON_INHEAP) != 0) {
      _downHeap(h, p);
      _upHeap(h, p);
      return;
    }

    p.flags |= _ON_INHEAP;
    h.buf.add(p);
    _upHeap(h, p);
  }

  void _downHeap(_HeapNode h, _OctreeNode p) {
    int n = p.heap_idx;
    while (true) {
      int m = n * 2;
      if (m >= h.buf.length) {
        break;
      }
      if ((m + 1) < h.buf.length && _compareNode(h.buf[m], h.buf[m + 1]) > 0) {
        m++;
      }

      if (_compareNode(p, h.buf[m]) <= 0) {
        break;
      }

      h.buf[n] = h.buf[m];
      h.buf[n].heap_idx = n;
      n = m;
    }

    h.buf[n] = p;
    p.heap_idx = n;
  }

  void _upHeap(_HeapNode h, _OctreeNode p) {
    int n = p.heap_idx;
    _OctreeNode prev;

    while (n > 1) {
      prev = h.buf[n ~/ 2];
      if (_compareNode(p, prev) >= 0) {
        break;
      }

      h.buf[n] = prev;
      prev.heap_idx = n;
      n ~/= 2;
    }
    h.buf[n] = p;
    p.heap_idx = n;
  }
}

class _OctreeNode {
  // sum of all colors represented by this node.
  int r = 0;
  int g = 0;
  int b = 0;
  int count = 0;
  int heap_idx = 0;
  List<_OctreeNode> children = List<_OctreeNode>(8);
  _OctreeNode parent = null;
  int childCount = 0;
  int childIndex = 0;
  int flags = 0;
  int depth = 0;

  _OctreeNode(this.childIndex, this.depth, this.parent) {
    if (parent != null) {
      parent.childCount++;
    }
  }
}

class _HeapNode {
  List<_OctreeNode> buf = [];
}