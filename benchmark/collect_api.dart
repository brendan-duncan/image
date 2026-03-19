import 'dart:io';

class ApiSymbol {
  ApiSymbol(this.kind, this.name, this.file, {this.parent});

  final String kind; // function | class | enum | typedef
  final String name;
  final String file;
  final String? parent;

  Map<String, Object?> toJson() => {
        'kind': kind,
        'name': name,
        'file': file,
        if (parent != null) 'parent': parent,
      };
}

List<String> readExports(String root) {
  final imageLib = File('$root/lib/image.dart').readAsLinesSync();
  final exports = <String>[];
  final exportRe = RegExp(r"^export '([^']+)'\s*;");
  for (final line in imageLib) {
    final m = exportRe.firstMatch(line);
    if (m != null) {
      exports.add(m.group(1)!);
    }
  }
  return exports;
}

List<ApiSymbol> parseSymbols(String root, String relPath) {
  final file = File('$root/lib/$relPath');
  if (!file.existsSync()) {
    return const [];
  }
  final content = file.readAsStringSync();
  final symbols = <ApiSymbol>[];

  final lines = content.split('\n');

  for (final line in lines) {
    // Only consider top-level declarations (column 0) and skip comments.
    if (line.isEmpty || line.startsWith(RegExp(r'\s'))) {
      continue;
    }

    final noIndent = line.trimLeft();
    if (noIndent.startsWith('//') ||
        noIndent.startsWith('///') ||
        noIndent.startsWith('/*') ||
        noIndent.startsWith('*')) {
      continue;
    }

    final trimmed = line.trim();
    if (trimmed.startsWith('class ')) {
      final name = trimmed.split(RegExp(r'\s+'))[1];
      symbols.add(ApiSymbol('class', name, relPath));
      continue;
    }
    if (trimmed.startsWith('enum ')) {
      final name = trimmed.split(RegExp(r'\s+'))[1];
      symbols.add(ApiSymbol('enum', name, relPath));
      continue;
    }
    if (trimmed.startsWith('typedef ')) {
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length > 1) {
        symbols.add(ApiSymbol('typedef', parts[1], relPath));
      }
      continue;
    }

    // top-level function: returnType name(
    final funcMatch = RegExp(r'^([A-Za-z0-9_<>,\[\]\? ]+)\s+(\w+)\s*\(')
        .firstMatch(trimmed);
    if (funcMatch != null) {
      final name = funcMatch.group(2)!;
      if (name != 'operator') {
        symbols.add(ApiSymbol('function', name, relPath));
      }
    }
  }

  return symbols;
}

List<ApiSymbol> collectApi(String root) {
  final exports = readExports(root);
  final symbols = <ApiSymbol>[];
  for (final rel in exports) {
    symbols.addAll(parseSymbols(root, rel));
  }
  return symbols;
}

void writeManifest(String root, List<ApiSymbol> symbols) {
  final out = File('$root/benchmark/api_manifest.json');
  out.createSync(recursive: true);
  final json = symbols.map((s) => s.toJson()).toList();
  out.writeAsStringSync(_prettyJson(json));
}

String _prettyJson(Object value) {
  final sb = StringBuffer();
  _writeJson(sb, value, 0);
  return sb.toString();
}

void _writeJson(StringBuffer sb, Object? value, int indent) {
  final pad = '  ' * indent;
  if (value is List) {
    sb.writeln('[');
    for (var i = 0; i < value.length; i++) {
      sb.write('${pad}  ');
      _writeJson(sb, value[i], indent + 1);
      if (i != value.length - 1) sb.write(',');
      sb.writeln();
    }
    sb.write('$pad]');
  } else if (value is Map) {
    sb.writeln('{');
    final keys = value.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      final k = keys[i];
      sb.write('${pad}  "${_escape(k.toString())}": ');
      _writeJson(sb, value[k], indent + 1);
      if (i != keys.length - 1) sb.write(',');
      sb.writeln();
    }
    sb.write('$pad}');
  } else if (value is String) {
    sb.write('"${_escape(value)}"');
  } else {
    sb.write(value.toString());
  }
}

String _escape(String s) => s.replaceAll('"', '\\"');
