import 'dart:convert';
import 'dart:io';

typedef BenchmarkRow = Map<String, Object?>;

void main(List<String> args) {
  final input = args.isNotEmpty ? args[0] : 'benchmark/results.json';
  final outPath = args.length > 1 ? args[1] : 'benchmark/benchmark_report.md';

  final data =
      (jsonDecode(File(input).readAsStringSync()) as List).cast<BenchmarkRow>();
  final buffer = StringBuffer()
    ..writeln('# Benchmark Report')
    ..writeln()
    ..writeln('Each test runs 100 iterations; values are average ms/op.')
    ..writeln();

  final ok = data.where((e) => e['status'] == 'ok').toList();
  final skipped = data.where((e) => e['status'] == 'skipped').toList();

  buffer
    ..writeln('## Results')
    ..writeln()
    ..writeln('| Name | Avg ms/op | Runs | Resolution | File | Note |')
    ..writeln('|---|---:|---:|---|---|---|');
  for (final r in ok) {
    buffer.writeln(
      '| ${r['name']} | ${r['avg_ms']} | ${r['runs']} | '
      '${r['resolution'] ?? ''} | ${r['file'] ?? ''} | '
      '${r['note'] ?? ''} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Skipped')
    ..writeln()
    ..writeln('| Name | Reason | File |')
    ..writeln('|---|---|---|');
  for (final r in skipped) {
    buffer.writeln('| ${r['name']} | ${r['note']} | ${r['file']} |');
  }

  File(outPath).writeAsStringSync(buffer.toString());
  stdout.writeln('Wrote $outPath');
}
