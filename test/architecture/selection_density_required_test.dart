import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared selection primitives declare their density contract', () {
    expect(_densityContractViolations(), isEmpty);
  });
}

List<String> _densityContractViolations() {
  final violations = <String>[];
  final root = Directory('lib/game/presentation/widgets/selection');
  if (!root.existsSync()) return ['widgets/selection must exist'];

  for (final file in _dartFiles(root.path)) {
    final relativePath = _relativePath(file.path);
    final name = relativePath.split(Platform.pathSeparator).last;
    if (_densityExemptFiles.contains(name)) continue;
    if (relativePath.contains('/view_models/')) continue;

    final source = file.readAsStringSync();
    if (!source.contains('SelectionDensity')) {
      violations.add('$relativePath must use SelectionDensity tokens');
    }
  }

  return violations;
}

const _densityExemptFiles = {
  'density.dart',
  'selection.dart',
  'selection_action_bar.dart',
  'selection_command_chip.dart',
  'selection_empty_message.dart',
  'view_models.dart',
};

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
