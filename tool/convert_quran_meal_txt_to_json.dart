import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final inputPath =
      args.isNotEmpty ? args.first : 'assets/content/quran_tr_meal.txt';
  final outputPath =
      args.length > 1 ? args[1] : 'assets/content/quran_tr_meal.json';

  final inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    stderr.writeln('Input file not found: $inputPath');
    exitCode = 1;
    return;
  }

  final raw = await inputFile.readAsString(encoding: utf8);
  final lines = const LineSplitter().convert(raw);
  final map = <String, String>{};
  var skipped = 0;

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    final parts = trimmed.split('|');
    if (parts.length < 3) {
      skipped++;
      continue;
    }

    final surah = int.tryParse(parts[0].trim());
    final ayah = int.tryParse(parts[1].trim());
    if (surah == null || ayah == null || surah < 1 || ayah < 1) {
      skipped++;
      continue;
    }

    final text = parts.sublist(2).join('|').trim();
    if (text.isEmpty) {
      skipped++;
      continue;
    }

    map['$surah|$ayah'] = text;
  }

  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  await outputFile.writeAsString(
    encoder.convert(map),
    encoding: utf8,
  );

  stdout.writeln('Converted: ${map.length} ayahs');
  stdout.writeln('Skipped: $skipped lines');
  stdout.writeln('Output: $outputPath');
}
