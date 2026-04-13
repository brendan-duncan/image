import 'dart:io';
import 'collect_api.dart';
import 'registry.dart';

class Result {
  Result(
    this.name,
    this.status, {
    this.avgMs,
    this.runs,
    this.note,
    this.kind,
    this.file,
    this.resolution,
  });

  final String name;
  final String status; // ok | skipped
  final double? avgMs;
  final int? runs;
  final String? note;
  final String? kind;
  final String? file;
  final String? resolution;

  Map<String, Object?> toJson() => {
    'name': name,
    'status': status,
    if (avgMs != null) 'avg_ms': avgMs,
    if (runs != null) 'runs': runs,
    if (note != null) 'note': note,
    if (kind != null) 'kind': kind,
    if (file != null) 'file': file,
    if (resolution != null) 'resolution': resolution,
  };
}

void main(List<String> args) {
  final root = Directory.current.path;
  final symbols = collectApi(root);
  writeManifest(root, symbols);

  final casesByName = buildCases();
  final results = <Result>[];
  var totalCases = 0;
  for (final sym in symbols) {
    if (sym.kind != 'function') {
      continue;
    }
    final list = casesByName[sym.name];
    if (list != null) {
      totalCases += list.length;
    }
  }
  var done = 0;

  for (final sym in symbols) {
    if (sym.kind != 'function') {
      results.add(
        Result(
          sym.name,
          'skipped',
          note: 'non-function symbol',
          kind: sym.kind,
          file: sym.file,
        ),
      );
      continue;
    }

    final list = casesByName[sym.name];
    if (list == null || list.isEmpty) {
      results.add(
        Result(
          sym.name,
          'skipped',
          note: 'no benchmark case',
          kind: sym.kind,
          file: sym.file,
        ),
      );
      continue;
    }

    for (final c in list) {
      done++;
      final res = c.resolution ?? '';
      final suffix = res.isEmpty ? '' : ' [$res]';
      stdout.writeln('Progress $done/$totalCases: ${c.name}$suffix');
      final avg = runCase(c, 100);
      results.add(
        Result(
          c.name,
          'ok',
          avgMs: avg,
          runs: 100,
          note: c.note,
          kind: sym.kind,
          file: sym.file,
          resolution: c.resolution,
        ),
      );
    }
  }

  File(
    '$root/benchmark/results.json',
  ).writeAsStringSync(_prettyJson(results.map((r) => r.toJson()).toList()));
}

double runCase(BenchmarkCase c, int runs) {
  // Warm-up
  for (var i = 0; i < 5; i++) {
    c.fn();
  }

  final sw = Stopwatch()..start();
  for (var i = 0; i < runs; i++) {
    c.fn();
  }
  sw.stop();
  return sw.elapsedMilliseconds / runs;
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
      sb.write('$pad  ');
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
      sb.write('$pad  "${_escape(k.toString())}": ');
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
