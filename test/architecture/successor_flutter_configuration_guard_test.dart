import 'dart:convert';
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
    final dependencies = manifest['dependencies'] as YamlMap;
    final devDependencies = manifest['dev_dependencies'] as YamlMap;
    expect(dependencies['flame'], '1.38.0');
    expect(devDependencies['flame_test'], '2.3.0');
    expect(devDependencies['vm_service'], '15.3.0');
    expect(devDependencies['flutter_lints'], '^6.0.0');
    expect(devDependencies.containsKey('lints'), isFalse);
    expect(devDependencies.containsKey('analyzer'), isFalse);

    final lock = _map('clients/aonw_flutter/pubspec.lock');
    final packages = lock['packages'] as YamlMap;
    final flame = packages['flame'] as YamlMap;
    expect(flame['dependency'], 'direct main');
    expect(flame['version'], '1.38.0');
    final flameTest = packages['flame_test'] as YamlMap;
    expect(flameTest['dependency'], 'direct dev');
    expect(flameTest['version'], '2.3.0');
    final vmService = packages['vm_service'] as YamlMap;
    expect(vmService['dependency'], 'direct dev');
    expect(vmService['version'], '15.3.0');
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

  test('macOS gamepad support stays on the pinned CocoaPods path', () {
    final podfile = File(
      'clients/aonw_flutter/macos/Podfile',
    ).readAsStringSync();
    final lock = File(
      'clients/aonw_flutter/macos/Podfile.lock',
    ).readAsStringSync();

    expect(podfile, contains('flutter_macos_podfile_setup'));
    expect(podfile, contains('flutter_install_all_macos_pods'));
    expect(lock, contains('gamepads_darwin (0.1.1)'));
    expect(
      lock,
      contains('gamepads_darwin: 643b6a69e20ca678fae83781b7f7fc8f15f5d710'),
    );
  });

  test('MapRenderSnapshot stays a framework-neutral renderer seam', () {
    final source = File(
      'clients/aonw_flutter/lib/features/map/presentation/'
      'map_render_snapshot.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('package:flutter/')));
    expect(source, isNot(contains('package:flame/')));
    expect(source, isNot(contains('package:aonw_rust_client/')));
    expect(source, contains('final class MapRenderSnapshot'));
  });

  test('macOS profiling network access stays debug-only', () {
    final debug = File(
      'clients/aonw_flutter/macos/Runner/DebugProfile.entitlements',
    ).readAsStringSync();
    final release = File(
      'clients/aonw_flutter/macos/Runner/Release.entitlements',
    ).readAsStringSync();

    expect(debug, contains('com.apple.security.network.client'));
    expect(release, isNot(contains('com.apple.security.network.client')));
  });

  test('FM0 viewport baseline keeps raw device evidence', () {
    final baseline =
        jsonDecode(
              File(
                'clients/aonw_flutter/performance/'
                'fm0_custom_painter_baseline.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final environment = baseline['environment'] as Map<String, dynamic>;
    final metrics = baseline['metrics'] as Map<String, dynamic>;
    final frames = metrics['frameTimes'] as Map<String, dynamic>;

    expect(baseline['schemaVersion'], 1);
    expect(environment['nativeBuildIdentity'], 'aonw_flutter/0.1.0');
    expect(environment['flame'], '1.38.0');
    expect(metrics['profiledPaintEvents'], greaterThan(0));
    expect(metrics['allocatedInstances'], greaterThan(0));
    expect(metrics['allocatedBytes'], greaterThan(0));
    expect(
      frames['frameBuildTimesMicros'],
      hasLength(frames['frameCount'] as int),
    );
    expect(
      frames['frameRasterizerTimesMicros'],
      hasLength(frames['frameCount'] as int),
    );
    expect((baseline['policy'] as Map<String, dynamic>)['hardBudget'], isFalse);
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
