import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'reducer_parity_fixture.dart';

part 'reducer_parity_fixture_start_unit_guard_tests.dart';
part 'reducer_parity_fixture_rush_guard_tests.dart';

void main() {
  _registerStartUnitFixtureGuardTests();
  _registerRushFixtureGuardTests();

  test(
    'StartBuilding corpus fails closed when one reviewed path is removed',
    () {
      final repository = _copyCorpus();
      File(
        '${repository.path}/test/fixtures/reducer_parity/'
        'city-production-building-map-requirement-rejected.json',
      ).deleteSync();

      expect(
        () => ReducerParityCorpus.load(repository),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('StartBuilding fixture ids must be exactly'),
          ),
        ),
      );
    },
  );

  test('StartBuilding corpus rejects a mislabeled unavailable cause', () {
    final repository = _copyCorpus();
    final fixture = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-building-locked-rejected.json',
    );
    _unlockWorkshop(fixture, playerId: 'player_1');

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains(
            'does not isolate its reviewed building_not_available cause',
          ),
        ),
      ),
    );
  });

  test('StartBuilding corpus rejects wrong-actor availability mode drift', () {
    final repository = _copyCorpus();
    final fixture = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-building-wrong-actor-unavailable-rejected.json',
    );
    _unlockWorkshop(fixture, playerId: 'player_2');

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('reviewed city_not_controlled availability mode'),
        ),
      ),
    );
  });

  test('StartWonder corpus fails closed when one reviewed path is removed', () {
    final repository = _copyCorpus();
    File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-wonder-map-requirement-rejected.json',
    ).deleteSync();

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('StartWonder fixture ids must be exactly'),
        ),
      ),
    );
  });

  test('StartWonder corpus independently classifies all five statuses', () {
    final mutations = <({String fileName, _JsonMutation mutate})>[
      (
        fileName: 'city-production-wonder-completed-rejected.json',
        mutate: (json) {
          final state = _inputState(json);
          (state['wonderRegistry'] as Map<String, dynamic>).remove('petra');
          _mirrorExpectedState(json);
        },
      ),
      (
        fileName: 'city-production-wonder-locked-rejected.json',
        mutate: (json) {
          final state = _inputState(json);
          state['research'] = {
            'players': {
              'player_1': {
                'unlockedTechnologyIds': ['stoneworking'],
                'progressByTechnologyId': <String, dynamic>{},
              },
            },
          };
          _mirrorExpectedState(json);
        },
      ),
      (
        fileName: 'city-production-wonder-map-requirement-rejected.json',
        mutate: (json) {
          final input = json['input'] as Map<String, dynamic>;
          final map = input['map'] as Map<String, dynamic>;
          final tiles = map['tiles'] as List<dynamic>;
          final target = tiles.cast<Map<String, dynamic>>().singleWhere(
            (tile) => tile['col'] == 1 && tile['row'] == 0,
          );
          _replaceTileTerrainSemantics(target, 'desert');
        },
      ),
      (
        fileName: 'city-production-wonder-same-target-rejected.json',
        mutate: (json) {
          final city = _inputCity(json, 'city_1');
          city['productionQueue'] = {
            'target': {'kind': 'building', 'buildingType': 'granary'},
            'investedProduction': 5,
          };
          _mirrorExpectedState(json);
        },
      ),
      (
        fileName: 'city-production-wonder-other-city-active-rejected.json',
        mutate: (json) {
          _inputCity(json, 'city_peer')['ownerPlayerId'] = 'player_2';
          _mirrorExpectedState(json);
        },
      ),
    ];

    for (final mutation in mutations) {
      final repository = _copyCorpus();
      final fixture = File(
        '${repository.path}/test/fixtures/reducer_parity/${mutation.fileName}',
      );
      _mutateFixture(fixture, mutation.mutate);

      expect(
        () => ReducerParityCorpus.load(repository),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'does not isolate its reviewed wonder_not_available status',
            ),
          ),
        ),
        reason: mutation.fileName,
      );
    }
  });

  test('StartWonder wrong actor must remain otherwise available', () {
    final repository = _copyCorpus();
    final fixture = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-wonder-wrong-actor-rejected.json',
    );
    _mutateFixture(fixture, (json) {
      final state = _inputState(json);
      state['research'] = {'players': <String, dynamic>{}};
      _mirrorExpectedState(json);
    });

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('otherwise available wrong-actor wonder'),
        ),
      ),
    );
  });

  test('StartWonder wrong-actor precedence pins the compound mode', () {
    final mutations = <_JsonMutation>[
      (json) {
        _inputCity(json, 'city_1').remove('productionQueue');
        _mirrorExpectedState(json);
      },
      (json) {
        final input = json['input'] as Map<String, dynamic>;
        input['actorPlayerId'] = 'player_2';
      },
      (json) {
        final expected = json['expected'] as Map<String, dynamic>;
        expected['reason'] = 'wonder_not_available';
      },
    ];

    for (final mutate in mutations) {
      final repository = _copyCorpus();
      final fixture = File(
        '${repository.path}/test/fixtures/reducer_parity/'
        'city-production-wonder-wrong-actor-unavailable-rejected.json',
      );
      _mutateFixture(fixture, mutate);

      expect(
        () => ReducerParityCorpus.load(repository),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'city_not_controlled before an unavailable same-target wonder',
            ),
          ),
        ),
      );
    }
  });

  test('StartWonder same-target fixture pins the requested wonder', () {
    final repository = _copyCorpus();
    final fixture = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-wonder-same-target-rejected.json',
    );
    _mutateFixture(fixture, (json) {
      final city = _inputCity(json, 'city_1');
      final queue = city['productionQueue'] as Map<String, dynamic>;
      final target = queue['target'] as Map<String, dynamic>;
      target['wonderType'] = 'greatLibrary';
      _mirrorExpectedState(json);
    });

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('exact requested wonder as the active target'),
        ),
      ),
    );
  });

  test('StartWonder accepted oracle rejects pace rollover drift', () {
    final repository = _copyCorpus();
    final fixture = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-wonder-overflow-accepted.json',
    );
    _mutateFixture(fixture, (json) {
      final expected = json['expected'] as Map<String, dynamic>;
      final state = expected['state'] as Map<String, dynamic>;
      final cities = (state['cities'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final city = cities.singleWhere((city) => city['id'] == 'city_1');
      final queue = city['productionQueue'] as Map<String, dynamic>;
      queue['investedProduction'] = 63;
    });

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('pace-scaled overflow'),
        ),
      ),
    );
  });
}

typedef _JsonMutation = void Function(Map<String, dynamic> json);

void _unlockWorkshop(File fixture, {required String playerId}) {
  final json = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
  final input = json['input'] as Map<String, dynamic>;
  final state = input['state'] as Map<String, dynamic>;
  state['research'] = {
    'players': {
      playerId: {
        'unlockedTechnologyIds': ['craftsmanship'],
        'progressByTechnologyId': <String, dynamic>{},
      },
    },
  };
  final expected = json['expected'] as Map<String, dynamic>;
  expected['state'] = jsonDecode(jsonEncode(state));
  fixture.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(json)}\n',
  );
}

void _mutateFixture(File fixture, _JsonMutation mutate) {
  final json = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
  mutate(json);
  fixture.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(json)}\n',
  );
}

Map<String, dynamic> _inputState(Map<String, dynamic> json) {
  final input = json['input'] as Map<String, dynamic>;
  return input['state'] as Map<String, dynamic>;
}

Map<String, dynamic> _inputCity(Map<String, dynamic> json, String cityId) {
  final state = _inputState(json);
  final cities = (state['cities'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  return cities.singleWhere((city) => city['id'] == cityId);
}

void _mirrorExpectedState(Map<String, dynamic> json) {
  final expected = json['expected'] as Map<String, dynamic>;
  expected['state'] = jsonDecode(jsonEncode(_inputState(json)));
}

void _replaceTileTerrainSemantics(Map<String, dynamic> tile, String terrain) {
  tile
    ..['terrains'] = [terrain]
    ..['displayTerrain'] = terrain
    ..['yieldTerrain'] = terrain
    ..['terrainTags'] = [terrain];
}

Directory _copyCorpus() {
  final repository = Directory.systemTemp.createTempSync(
    'aonw-reducer-parity-guard-',
  );
  addTearDown(() => repository.deleteSync(recursive: true));
  final target = Directory('${repository.path}/test/fixtures/reducer_parity')
    ..createSync(recursive: true);
  final source = Directory('test/fixtures/reducer_parity');
  for (final entry in source.listSync()) {
    if (entry is File) {
      entry.copySync('${target.path}/${entry.uri.pathSegments.last}');
    }
  }
  return repository;
}
