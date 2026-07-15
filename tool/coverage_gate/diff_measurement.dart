import 'dart:io';

import 'acknowledged_export_only_barrel.dart';

/// The coverage facts for changed source lines, grouped by coverage layer.
final class CoverageDiffMeasurement {
  const CoverageDiffMeasurement({
    required this.byLayer,
    required this.uncoveredByLayer,
    required this.structuralFailures,
  });

  final Map<String, ({int hit, int found})> byLayer;
  final Map<String, List<String>> uncoveredByLayer;
  final List<String> structuralFailures;
}

/// Measures changed-line coverage without depending on the coverage CLI.
CoverageDiffMeasurement measureCoverageDiff({
  required String repository,
  required String scopeName,
  required String label,
  required Map<String, Set<int>> changedLines,
  required Set<String> sources,
  required Map<String, Map<int, int>> lineHitsByPath,
  required bool Function(String path) isExcluded,
  required String Function(String path) layerFor,
  required Set<String> acknowledgedMissingFiles,
}) {
  final byLayer = <String, ({int hit, int found})>{};
  final uncoveredByLayer = <String, Set<String>>{};
  final failures = <String>[];

  for (final entry in changedLines.entries) {
    final path = entry.key;
    if (!sources.contains(path) || isExcluded(path)) continue;
    final layer = layerFor(path);
    final lineHits = lineHitsByPath[path];
    if (lineHits == null) {
      if (acknowledgedMissingFiles.contains(path) &&
          isAcknowledgedExportOnlyBarrel(
            path: path,
            acknowledgedMissingFiles: acknowledgedMissingFiles,
            source: File('$repository/$path').readAsStringSync(),
          )) {
        continue;
      }
      failures.add(
        '$scopeName $label: changed source is absent from LCOV: $path',
      );
      continue;
    }
    final coverable = entry.value.intersection(lineHits.keys.toSet());
    if (coverable.isEmpty) continue;
    final hit = coverable.where((line) => (lineHits[line] ?? 0) > 0).length;
    for (final line in coverable) {
      if ((lineHits[line] ?? 0) == 0) {
        uncoveredByLayer
            .putIfAbsent(layer, () => <String>{})
            .add('$path:$line');
      }
    }
    byLayer.update(
      layer,
      (counts) =>
          (hit: counts.hit + hit, found: counts.found + coverable.length),
      ifAbsent: () => (hit: hit, found: coverable.length),
    );
  }

  return CoverageDiffMeasurement(
    byLayer: byLayer,
    uncoveredByLayer: {
      for (final entry in uncoveredByLayer.entries)
        entry.key: entry.value.toList()..sort(),
    },
    structuralFailures: failures,
  );
}
