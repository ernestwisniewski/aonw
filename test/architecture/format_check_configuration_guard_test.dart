import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('format-check skips tracked Dart files deleted in the worktree', () {
    final makefile = File('Makefile').readAsStringSync();
    final target = RegExp(
      r'^format-check:[^\n]*\n((?:\t[^\n]*\n)+)',
      multiLine: true,
    ).firstMatch(makefile);

    expect(target, isNotNull);
    final recipe = target!.group(1)!;
    expect(recipe, contains('while IFS= read -r file; do'));
    expect(recipe, contains(r'test -f "$$file"'));
    expect(recipe, contains(r'''printf '%s\n' "$$file"'''));
  });
}
