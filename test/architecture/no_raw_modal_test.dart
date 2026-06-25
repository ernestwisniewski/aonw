import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app layers use shared game modal helpers', () {
    expect(
      _rawModalViolations(
        roots: const [
          'lib/game',
          'lib/editor',
          'lib/developer',
          'lib/shared/widgets/game_ui',
        ],
        allowedPaths: const {
          'lib/shared/widgets/game_ui/game_modal.dart',
          'lib/shared/widgets/game_ui/game_modal_scaffold.dart',
        },
      ),
      isEmpty,
    );
  });

  test('app layers do not use the modal surface primitive directly', () {
    expect(
      _forbiddenPatternViolations(
        roots: const ['lib/game', 'lib/editor', 'lib/developer'],
        patterns: const ['EpicCardSurface', 'epic_card_surface.dart'],
        message: 'use GameModalScaffold',
      ),
      isEmpty,
    );
  });
}

List<String> _rawModalViolations({
  required List<String> roots,
  required Set<String> allowedPaths,
}) {
  final violations = <String>[];
  final patterns = <RegExp>[
    RegExp(r'\bshowDialog\s*(?:<|\()'),
    RegExp(r'\bshowModalBottomSheet\s*(?:<|\()'),
    RegExp(r'\bAlertDialog\s*\('),
    RegExp(r'\bDialog\s*\('),
  ];

  for (final file in roots.expand(_dartFiles)) {
    final relativePath = _relativePath(file.path);
    if (allowedPaths.contains(relativePath)) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final pattern in patterns) {
        if (pattern.hasMatch(line)) {
          violations.add('$relativePath:${i + 1} use game_modal.dart helpers');
          break;
        }
      }
    }
  }

  return violations;
}

List<String> _forbiddenPatternViolations({
  required List<String> roots,
  required List<String> patterns,
  required String message,
}) {
  final violations = <String>[];

  for (final file in roots.expand(_dartFiles)) {
    final relativePath = _relativePath(file.path);
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final pattern in patterns) {
        if (line.contains(pattern)) {
          violations.add('$relativePath:${i + 1} $message');
          break;
        }
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
