import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selection visuals live in the shared selection module', () {
    expect(_selectionStructureViolations(), isEmpty);
  });
}

List<String> _selectionStructureViolations() {
  final violations = <String>[];

  if (Directory(
    'lib/game/presentation/widgets/bottom_toolbar/selection',
  ).existsSync()) {
    violations.add('bottom_toolbar/selection must not exist');
  }

  if (Directory(
    'lib/game/presentation/widgets/selection_info/view_models',
  ).existsSync()) {
    violations.add('selection_info/view_models must move to selection/');
  }

  if (File(
    'lib/game/presentation/widgets/selection_info/view_models.dart',
  ).existsSync()) {
    violations.add('selection_info/view_models.dart must not exist');
  }

  if (File(
    'lib/game/presentation/widgets/selection_info/selection_info_overlay.dart',
  ).existsSync()) {
    violations.add('selection_info_overlay.dart must not exist');
  }

  final selectionRoot = Directory('lib/game/presentation/widgets/selection');
  if (!selectionRoot.existsSync()) {
    violations.add('widgets/selection must exist');
  }

  final selectionViewModels = Directory(
    'lib/game/presentation/widgets/selection/view_models',
  );
  if (!selectionViewModels.existsSync()) {
    violations.add('widgets/selection/view_models must exist');
  }

  for (final file in _dartFiles('lib/game/presentation/widgets')) {
    final relativePath = _relativePath(file.path);
    if (_usesLegacySelectionPath(file)) {
      violations.add('$relativePath imports a legacy selection path');
    }
    if (_isDuplicateSelectionWidget(relativePath)) {
      violations.add('$relativePath duplicates a selection widget');
    }
  }

  return violations;
}

bool _usesLegacySelectionPath(File file) {
  final source = file.readAsStringSync();
  return source.contains('bottom_toolbar/selection') ||
      source.contains('selection_info/view_models') ||
      source.contains('selection_info/selection_info_overlay') ||
      source.contains('selection_info/selection_info_action_chip') ||
      source.contains('selection_info/selection_info_bar');
}

bool _isDuplicateSelectionWidget(String relativePath) {
  if (relativePath.startsWith('lib/game/presentation/widgets/selection/')) {
    return false;
  }
  if (!relativePath.startsWith('lib/game/presentation/widgets/')) {
    return false;
  }

  final name = relativePath.split(Platform.pathSeparator).last;
  return const {
    'army_troop_row.dart',
    'empty_army_message.dart',
    'selection_details_chips.dart',
    'selection_icon.dart',
    'selection_improvement_list.dart',
    'selection_info_action_chip.dart',
    'selection_info_bar.dart',
    'selection_info_chip.dart',
    'selection_tag_strip.dart',
    'selection_yield_strip.dart',
  }.contains(name);
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
