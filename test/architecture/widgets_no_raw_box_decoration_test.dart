import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/widget_style_debt_baseline.dart';

void main() {
  test('game and shared UI widgets do not use raw BoxDecoration', () {
    expect(
      _rawBoxDecorationViolations(
        roots: const [
          'lib/game/presentation/widgets',
          'lib/shared/widgets/game_ui',
        ],
      ),
      isEmpty,
    );
  });
}

List<String> _rawBoxDecorationViolations({required List<String> roots}) {
  final violations = <String>[];

  for (final file in roots.expand(_dartFiles)) {
    final relativePath = _relativePath(file.path);
    final lines = file.readAsLinesSync();
    final legacyCount =
        widgetStyleDebtBaseline[relativePath]?.rawBoxDecorations ?? 0;
    var rawBoxDecorationCount = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains('BoxDecoration(')) {
        rawBoxDecorationCount++;
        if (rawBoxDecorationCount <= legacyCount) continue;
        violations.add(
          '$relativePath:${i + 1} use SurfaceElevation or ShapeDecoration',
        );
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
