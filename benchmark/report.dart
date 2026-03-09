import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final input = args.isNotEmpty ? args[0] : 'benchmark/results.json';
  final outPath = args.length > 1 ? args[1] : 'doc/benchmark_report.md';

  final data = jsonDecode(File(input).readAsStringSync()) as List;
  final buffer = StringBuffer();
  buffer.writeln('# Benchmark Report');
  buffer.writeln('');
  buffer.writeln('Each test runs 100 iterations; values are average ms/op.');
  buffer.writeln('');

  final ok = data.where((e) => e['status'] == 'ok').toList();
  final skipped = data.where((e) => e['status'] == 'skipped').toList();

  buffer.writeln('## Results');
  buffer.writeln('');
  buffer.writeln('| Name | Avg ms/op | Runs | Resolution | File | Note |');
  buffer.writeln('|---|---:|---:|---|---|---|');
  for (final r in ok) {
    buffer.writeln(
        '| ${r['name']} | ${r['avg_ms']} | ${r['runs']} | ${r['resolution'] ?? ''} | ${r['file'] ?? ''} | ${r['note'] ?? ''} |');
  }

  buffer.writeln('');
  buffer.writeln('## Skipped');
  buffer.writeln('');
  buffer.writeln('| Name | Reason | File |');
  buffer.writeln('|---|---|---|');
  for (final r in skipped) {
    buffer.writeln('| ${r['name']} | ${r['note']} | ${r['file']} |');
  }

  File(outPath).writeAsStringSync(buffer.toString());
  print('Wrote $outPath');
}
