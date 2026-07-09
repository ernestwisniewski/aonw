import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production code does not use the legacy simultaneous TurnPipeline', () {
    expect(
      _legacySimultaneousTurnUsages(roots: const ['lib', 'server/lib']),
      isEmpty,
    );
  });
}

List<String> _legacySimultaneousTurnUsages({required List<String> roots}) {
  final violations = <String>[];
  for (final file in roots.expand(_dartFiles)) {
    final relativePath = _relativePath(file.path);
    if (_allowedLegacyDeclarationPaths.contains(relativePath)) continue;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains('TurnPipeline.simultaneousTurn(')) {
        violations.add(
          '$relativePath:${i + 1} use PersistentTurnPipeline.simultaneousFinalize',
        );
      }
    }
  }
  return violations;
}

const _allowedLegacyDeclarationPaths = {
  'lib/game/domain/turn/turn_pipeline.dart',
};

Iterable<File> _dartFiles(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) return const [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'))
      .where((file) => !file.path.endsWith('.freezed.dart'));
}

String _relativePath(String path) {
  final root = '${Directory.current.path}${Platform.pathSeparator}';
  return path.startsWith(root) ? path.substring(root.length) : path;
}
