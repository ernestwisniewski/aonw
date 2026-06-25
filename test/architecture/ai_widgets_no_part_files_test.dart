import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI widgets use importable modules instead of part files', () {
    expect(_partFileViolations('lib/game/presentation/widgets/ai'), isEmpty);
  });
}

List<String> _partFileViolations(String root) {
  final violations = <String>[];
  final directive = RegExp(r'''^\s*part\s+('|"|of\s+)''');

  for (final file in _dartFiles(root)) {
    final relativePath = _relativePath(file.path);
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (directive.hasMatch(lines[i])) {
        violations.add('$relativePath:${i + 1} uses ${lines[i].trim()}');
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
