import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('successor Flutter keeps its standalone strict lint policy', () {
    final options = _map('clients/aonw_flutter/analysis_options.yaml');
    expect(options.keys.toSet(), {'include', 'analyzer', 'linter'});
    expect(options['include'], 'package:flutter_lints/flutter.yaml');

    final analyzer = options['analyzer'] as YamlMap;
    expect(analyzer.keys.toSet(), {'language'});
    final language = analyzer['language'] as YamlMap;
    expect(language.keys.toSet(), {
      'strict-casts',
      'strict-inference',
      'strict-raw-types',
    });
    expect(language.values, everyElement(isTrue));

    final linter = options['linter'] as YamlMap;
    expect(linter.keys.toSet(), {'rules'});
    expect((linter['rules'] as YamlList).toSet(), {
      'always_declare_return_types',
      'directives_ordering',
      'prefer_final_locals',
    });
  });

  test('successor Flutter lint dependency and Make gates cannot drift', () {
    final manifest = _map('clients/aonw_flutter/pubspec.yaml');
    final devDependencies = manifest['dev_dependencies'] as YamlMap;
    expect(devDependencies['flutter_lints'], '^6.0.0');
    expect(devDependencies.containsKey('lints'), isFalse);
    expect(devDependencies.containsKey('analyzer'), isFalse);

    final lock = _map('clients/aonw_flutter/pubspec.lock');
    final packages = lock['packages'] as YamlMap;
    final flutterLints = packages['flutter_lints'] as YamlMap;
    expect(flutterLints['dependency'], 'direct dev');
    expect(flutterLints['source'], 'hosted');
    expect(flutterLints['version'], '6.0.0');

    final makefile = File('Makefile').readAsStringSync();
    expect(
      _target(makefile, 'successor-flutter-dependencies'),
      const _Target(
        prerequisites: ['toolchain-check'],
        recipes: [
          '@cd clients/aonw_flutter && flutter pub get --enforce-lockfile',
        ],
      ),
    );
    expect(
      _target(makefile, 'successor-flutter-analyze'),
      const _Target(
        prerequisites: ['successor-flutter-dependencies'],
        recipes: [
          '@cd clients/aonw_flutter && flutter analyze --no-pub '
              '--fatal-infos --fatal-warnings',
        ],
      ),
    );
    expect(
      _target(makefile, 'successor-flutter-test'),
      const _Target(
        prerequisites: ['successor-flutter-analyze'],
        recipes: ['@cd clients/aonw_flutter && flutter test --no-pub'],
      ),
    );
    expect(
      _target(makefile, '.PHONY').prerequisites,
      containsAll({
        'successor-flutter-dependencies',
        'successor-flutter-analyze',
        'successor-flutter-test',
      }),
    );
  });
}

YamlMap _map(String path) {
  final value = loadYaml(File(path).readAsStringSync());
  expect(value, isA<YamlMap>(), reason: path);
  return value! as YamlMap;
}

_Target _target(String source, String name) {
  final lines = source.split('\n');
  final prefix = '$name:';
  final matches = <int>[
    for (var index = 0; index < lines.length; index++)
      if (lines[index].startsWith(prefix)) index,
  ];
  expect(matches, hasLength(1), reason: 'Make target $name');
  final index = matches.single;
  final prerequisites = lines[index]
      .substring(prefix.length)
      .trim()
      .split(RegExp(r'\s+'))
      .where((value) => value.isNotEmpty)
      .toList();
  final recipes = <String>[];
  for (var lineIndex = index + 1; lineIndex < lines.length; lineIndex++) {
    final line = lines[lineIndex];
    if (!line.startsWith('\t')) break;
    recipes.add(line.substring(1));
  }
  return _Target(prerequisites: prerequisites, recipes: recipes);
}

final class _Target {
  const _Target({required this.prerequisites, required this.recipes});

  final List<String> prerequisites;
  final List<String> recipes;

  @override
  bool operator ==(Object other) =>
      other is _Target &&
      _listEquals(prerequisites, other.prerequisites) &&
      _listEquals(recipes, other.recipes);

  @override
  int get hashCode => Object.hashAll([...prerequisites, null, ...recipes]);
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
