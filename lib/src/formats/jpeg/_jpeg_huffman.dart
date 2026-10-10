import 'dart:typed_data';

class HuffmanNode {
  const HuffmanNode();
}

class HuffmanParent extends HuffmanNode {
  final List<HuffmanNode?> children;
  const HuffmanParent(this.children);
}

class HuffmanValue extends HuffmanNode {
  final int value;
  const HuffmanValue(this.value);
}

/// The number of bits [huffmanLookup] tables are indexed by.
const huffmanLookupBits = 9;

/// Returns a lookahead table for the Huffman [tree]. For the next
/// [huffmanLookupBits] bits of input i, entry i is
/// `(codeLength << 8) | value` when the code is at most [huffmanLookupBits]
/// long, or 0 when the tree has to be walked.
Uint16List huffmanLookup(List<HuffmanNode?> tree) =>
    _lookups[tree] ??= _buildLookup(tree);

final _lookups = Expando<Uint16List>();

Uint16List _buildLookup(List<HuffmanNode?> tree) {
  final lookup = Uint16List(1 << huffmanLookupBits);
  for (var i = 0; i < lookup.length; ++i) {
    var children = tree;
    for (var length = 1; length <= huffmanLookupBits; ++length) {
      final node = children[(i >> (huffmanLookupBits - length)) & 1];
      if (node is HuffmanValue) {
        lookup[i] = (length << 8) | node.value;
        break;
      }
      if (node is! HuffmanParent) {
        break;
      }
      children = node.children;
    }
  }
  return lookup;
}
