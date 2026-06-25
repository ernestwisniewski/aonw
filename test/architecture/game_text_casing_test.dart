import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visible game UI builds uppercase styling through GameText', () {
    expect(
      _directUppercaseCalls(roots: const ['lib/game/presentation', 'lib/menu']),
      isEmpty,
    );
  });
}

List<String> _directUppercaseCalls({required List<String> roots}) {
  final violations = <String>[];
  for (final file in roots.expand(_dartFiles)) {
    final relativePath = _relativePath(file.path);
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains('.toUpperCase()')) {
        violations.add('$relativePath:${i + 1} use GameText.uppercase');
      }
    }
  }
  return violations;
}

Iterable<File> _dartFiles(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) return const [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'));
}

String _relativePath(String path) {
  final root = '${Directory.current.path}${Platform.pathSeparator}';
  return path.startsWith(root) ? path.substring(root.length) : path;
}
