part of 'reducer_parity_fixture_guard_test.dart';

void _registerStartUnitFixtureGuardTests() {
  test('StartUnit corpus fails closed when one reviewed path is removed', () {
    final repository = _copyCorpus();
    File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-unit-coast-required-rejected.json',
    ).deleteSync();

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('StartUnitProduction fixture ids must be exactly'),
        ),
      ),
    );
  });

  test('StartUnit precedence fixtures pin every reviewed rejection stage', () {
    final mutations = <({String fileName, String message, _JsonMutation mutate})>[
      (
        fileName: 'city-production-unit-not-found-rejected.json',
        message:
            'must characterize city_not_found before all later unit checks',
        mutate: (json) {
          _command(json)['cityId'] = 'city_1';
        },
      ),
      (
        fileName: 'city-production-unit-wrong-actor-rejected.json',
        message:
            'must characterize its reviewed city_not_controlled precedence mode',
        mutate: (json) {
          _command(json)['unitType'] = 'warship';
        },
      ),
      (
        fileName: 'city-production-unit-wrong-actor-compound-rejected.json',
        message:
            'must characterize its reviewed city_not_controlled precedence mode',
        mutate: (json) {
          _command(json)['unitType'] = 'warrior';
        },
      ),
      (
        fileName: 'city-production-unit-not-available-rejected.json',
        message:
            'does not isolate its reviewed StartUnitProduction rejection stage',
        mutate: (json) {
          _unlockTechnology(json, 'navalDoctrine');
        },
      ),
      (
        fileName: 'city-production-unit-resource-required-rejected.json',
        message:
            'does not isolate its reviewed StartUnitProduction rejection stage',
        mutate: (json) {
          _addReviewedIronImport(json);
        },
      ),
      (
        fileName: 'city-production-unit-coast-required-rejected.json',
        message:
            'does not isolate its reviewed StartUnitProduction rejection stage',
        mutate: (json) {
          _command(json)['unitType'] = 'warrior';
        },
      ),
      (
        fileName: 'city-production-unit-supply-full-rejected.json',
        message:
            'does not isolate its reviewed StartUnitProduction rejection stage',
        mutate: (json) {
          _inputState(json)['units'] = <dynamic>[];
          _mirrorExpectedState(json);
        },
      ),
    ];

    for (final mutation in mutations) {
      final repository = _copyCorpus();
      final fixture = File(
        '${repository.path}/test/fixtures/reducer_parity/'
        '${mutation.fileName}',
      );
      _mutateFixture(fixture, mutation.mutate);

      expect(
        () => ReducerParityCorpus.load(repository),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(mutation.message),
          ),
        ),
        reason: mutation.fileName,
      );
    }
  });

  test('StartUnit accepted oracle rejects standard60 rollover drift', () {
    final repository = _copyCorpus();
    final fixture = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-unit-overflow-accepted.json',
    );
    _mutateFixture(fixture, (json) {
      final city = _expectedCity(json, 'city_1');
      final queue = city['productionQueue'] as Map<String, dynamic>;
      queue['investedProduction'] = 5;
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

  test('StartUnit supply fixture requires both reviewed bonuses', () {
    final mutations = <_JsonMutation>[
      (json) {
        _inputState(json)['artifacts'] = <dynamic>[];
        _mirrorExpectedState(json);
      },
      (json) {
        _inputState(json)['fieldImprovements'] = <dynamic>[];
        _mirrorExpectedState(json);
      },
    ];
    for (final mutate in mutations) {
      final repository = _copyCorpus();
      final fixture = File(
        '${repository.path}/test/fixtures/reducer_parity/'
        'city-production-unit-supply-bonuses-accepted.json',
      );
      _mutateFixture(fixture, mutate);

      expect(
        () => ReducerParityCorpus.load(repository),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('must characterize an otherwise available accepted unit'),
          ),
        ),
      );
    }
  });

  test(
    'StartUnit accepted modes pin replacement and same-target sentinels',
    () {
      final mutations =
          <({String fileName, String message, _JsonMutation mutate})>[
            (
              fileName:
                  'city-production-unit-import-coast-replacement-accepted.json',
              message: 'must replace the reviewed active queue',
              mutate: (json) {
                final city = _inputCity(json, 'city_1');
                final queue = city['productionQueue'] as Map<String, dynamic>;
                queue['investedProduction'] = 6;
                _mirrorExpectedState(json);
              },
            ),
            (
              fileName: 'city-production-unit-same-target-no-op-accepted.json',
              message:
                  'must characterize the accepted same-target unit value no-op',
              mutate: (json) {
                _inputCity(json, 'city_1')['productionOverflow'] = 12;
                _mirrorExpectedState(json);
              },
            ),
          ];

      for (final mutation in mutations) {
        final repository = _copyCorpus();
        final fixture = File(
          '${repository.path}/test/fixtures/reducer_parity/'
          '${mutation.fileName}',
        );
        _mutateFixture(fixture, mutation.mutate);

        expect(
          () => ReducerParityCorpus.load(repository),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains(mutation.message),
            ),
          ),
          reason: mutation.fileName,
        );
      }
    },
  );
}

Map<String, dynamic> _command(Map<String, dynamic> json) {
  final input = json['input'] as Map<String, dynamic>;
  return input['command'] as Map<String, dynamic>;
}

Map<String, dynamic> _expectedCity(Map<String, dynamic> json, String cityId) {
  final expected = json['expected'] as Map<String, dynamic>;
  final state = expected['state'] as Map<String, dynamic>;
  final cities = (state['cities'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  return cities.singleWhere((city) => city['id'] == cityId);
}

void _unlockTechnology(Map<String, dynamic> json, String technologyId) {
  final state = _inputState(json);
  final city = _inputCity(json, 'city_1');
  final playerId = city['ownerPlayerId'] as String;
  state['research'] = {
    'players': {
      playerId: {
        'unlockedTechnologyIds': [technologyId],
        'progressByTechnologyId': <String, dynamic>{},
      },
    },
  };
  _mirrorExpectedState(json);
}

void _addReviewedIronImport(Map<String, dynamic> json) {
  final state = _inputState(json);
  final city = _inputCity(json, 'city_1');
  final playerId = city['ownerPlayerId'] as String;
  final runtime = state['runtimeState'] as Map<String, dynamic>;
  runtime['resourceTradeAgreements'] = [
    {
      'id': 'trade_iron_guard',
      'exporterPlayerId': playerId == 'player_1' ? 'player_2' : 'player_1',
      'importerPlayerId': playerId,
      'resource': 'iron',
      'remainingTurns': 3,
    },
  ];
  _mirrorExpectedState(json);
}
