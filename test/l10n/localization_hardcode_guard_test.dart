import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production Dart sources keep Polish text in localization files', () {
    const polishLetterPattern =
        r'\u0105|\u0107|\u0119|\u0142|\u0144|\u00F3|\u015B|\u017A|\u017C|'
        r'\u0104|\u0106|\u0118|\u0141|\u0143|\u00D3|\u015A|\u0179|\u017B';
    final offenders = <String>[];
    final files =
        [
              Directory('lib'),
              Directory('packages/aonw_core/lib'),
              Directory('packages/aonw_core/tool'),
              Directory('server/bin'),
              Directory('server/lib'),
              Directory('tool'),
            ]
            .where((directory) => directory.existsSync())
            .expand((directory) => directory.listSync(recursive: true))
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => !file.path.contains('/l10n/'));

    final polishText = RegExp('(?:$polishLetterPattern)');
    final localizedFallbacks = [
      RegExp(
        r"\?\?\s*'[^']*(?:"
        '$polishLetterPattern'
        r")[^']*'",
      ),
      RegExp(
        r'\?\?\s*"[^"]*(?:'
        '$polishLetterPattern'
        r')[^"]*"',
      ),
    ];
    final keyLiteral = RegExp(
      r'''(?:const\s+)?(?:Key|ValueKey)(?:<[^>]+>)?\(\s*['"]([^'"]*)['"]''',
    );
    final stableKeyPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i += 1) {
        final line = lines[i];
        if (polishText.hasMatch(line)) {
          offenders.add('${file.path}:${i + 1}: Polish text outside l10n');
        }
        if (localizedFallbacks.any((pattern) => pattern.hasMatch(line))) {
          offenders.add('${file.path}:${i + 1}: localized fallback');
        }
        for (final match in keyLiteral.allMatches(line)) {
          final value = match.group(1)!;
          if (value.contains(r'$')) continue;
          if (!stableKeyPattern.hasMatch(value)) {
            offenders.add('${file.path}:${i + 1}: unstable key "$value"');
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
