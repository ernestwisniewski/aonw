import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage_gate/coverable_source.dart';

void main() {
  test('keeps an LCOV-recorded path without parsing its source', () {
    var resolved = false;

    final retained = retainCoverable(
      const {'lib/recorded.dart'},
      recorded: const {'lib/recorded.dart'},
      resolve: (_) {
        resolved = true;
        throw StateError('Recorded sources must not be parsed.');
      },
    );

    expect(retained, {'lib/recorded.dart'});
    expect(resolved, isFalse);
  });

  test('drops barrels, pure interfaces, and compile-time constant holders', () {
    final fixture = _SourceFixture.create({
      'lib/barrel.dart': "export 'logic.dart';\n",
      'lib/lookup.dart': '''
abstract interface class Lookup {
  Object? find(String id);
}
''',
      'lib/map_constraints.dart': '''
const schemaVersion = 3;

abstract final class MapConstraints {
  static const int minCols = 5;
  static const values = <String>['small', 'large'];
}
''',
    });
    addTearDown(fixture.dispose);

    expect(
      retainCoverable(
        fixture.paths,
        recorded: const {},
        resolve: fixture.resolve,
      ),
      isEmpty,
    );
  });

  test('keeps executable bodies, enums, and initialized variables', () {
    final fixture = _SourceFixture.create({
      'lib/function.dart': 'int answer() => 42;\n',
      'lib/enum.dart': 'enum Choice { yes, no }\n',
      'lib/value.dart': 'final answer = 42;\n',
    });
    addTearDown(fixture.dispose);

    expect(
      retainCoverable(
        fixture.paths,
        recorded: const {},
        resolve: fixture.resolve,
      ),
      fixture.paths,
    );
  });
}

final class _SourceFixture {
  _SourceFixture._(this.directory, this.paths);

  factory _SourceFixture.create(Map<String, String> sources) {
    final directory = Directory.systemTemp.createTempSync(
      'aonw-coverable-source-',
    );
    for (final entry in sources.entries) {
      final file = File('${directory.path}/${entry.key}');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
    return _SourceFixture._(directory, sources.keys.toSet());
  }

  final Directory directory;
  final Set<String> paths;

  String resolve(String path) => '${directory.path}/$path';

  void dispose() => directory.deleteSync(recursive: true);
}
