part of 'reducer_parity_fixture_guard_test.dart';

void _registerRushFixtureGuardTests() {
  test('Rush corpus fails closed when one reviewed path is removed', () {
    final repository = _copyCorpus();
    File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-rush-unit-spawn-blocked-accepted.json',
    ).deleteSync();

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('RushProduction fixture ids must be exactly'),
        ),
      ),
    );
  });

  test('Rush corpus rejects an unreviewed extra mode', () {
    final repository = _copyCorpus();
    final source = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-rush-unrest-accepted.json',
    );
    final json = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
    json['id'] = 'city-production-rush-extra-accepted';
    File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-rush-extra-accepted.json',
    ).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('unreviewed RushProduction characterization id'),
        ),
      ),
    );
  });

  test('Rush wrong-actor fixtures pin both precedence modes', () {
    final mutations = <({String fileName, _JsonMutation mutate})>[
      (
        fileName: 'city-production-rush-wrong-actor-rejected.json',
        mutate: (json) {
          _inputCity(json, 'city_1')['ownerPlayerId'] = 'player_1';
          _mirrorExpectedState(json);
        },
      ),
      (
        fileName: 'city-production-rush-wrong-actor-compound-rejected.json',
        mutate: (json) {
          final city = _inputCity(json, 'city_1');
          city['productionQueue'] = {
            'target': {'kind': 'building', 'buildingType': 'granary'},
            'investedProduction': 0,
          };
          _mirrorExpectedState(json);
        },
      ),
      (
        fileName: 'city-production-rush-wrong-actor-compound-rejected.json',
        mutate: (json) {
          final city = _inputCity(json, 'city_1');
          final gold = _inputState(json)['playerGold'] as Map<String, dynamic>;
          gold[city['ownerPlayerId'] as String] = 100;
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
        throwsA(isA<FormatException>()),
        reason: mutation.fileName,
      );
    }
  });

  test('Rush project rejection pins precedence before an empty treasury', () {
    final repository = _copyCorpus();
    final fixture = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-rush-project-rejected.json',
    );
    _mutateFixture(fixture, (json) {
      final gold = _inputState(json)['playerGold'] as Map<String, dynamic>;
      gold['player_1'] = 100;
      _mirrorExpectedState(json);
    });

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('before a zero-gold treasury'),
        ),
      ),
    );
  });

  test('Rush unavailable fixtures pin both reviewed causes', () {
    final mutations = <({String fileName, _JsonMutation mutate})>[
      (
        fileName: 'city-production-rush-insufficient-gold-rejected.json',
        mutate: (json) {
          final gold = _inputState(json)['playerGold'] as Map<String, dynamic>;
          gold['player_1'] = 1000;
          _mirrorExpectedState(json);
        },
      ),
      (
        fileName: 'city-production-rush-complete-queue-rejected.json',
        mutate: (json) {
          final city = _inputCity(json, 'city_1');
          final queue = city['productionQueue'] as Map<String, dynamic>;
          queue['investedProduction'] = 0;
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
            contains('rush_production_unavailable cause'),
          ),
        ),
        reason: mutation.fileName,
      );
    }
  });

  test('Rush accepted oracle rejects gold, unit, and artifact-XP drift', () {
    final mutations = <({String fileName, _JsonMutation mutate})>[
      (
        fileName: 'city-production-rush-unrest-accepted.json',
        mutate: (json) {
          final expected = json['expected'] as Map<String, dynamic>;
          final state = expected['state'] as Map<String, dynamic>;
          final gold = state['playerGold'] as Map<String, dynamic>;
          gold['player_1'] = (gold['player_1'] as int) + 1;
        },
      ),
      (
        fileName: 'city-production-rush-unit-completed-accepted.json',
        mutate: (json) {
          final expected = json['expected'] as Map<String, dynamic>;
          final state = expected['state'] as Map<String, dynamic>;
          final units = (state['units'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          units.last['id'] = 'drifted_produced_unit';
        },
      ),
      (
        fileName: 'city-production-rush-unit-completed-accepted.json',
        mutate: (json) {
          final expected = json['expected'] as Map<String, dynamic>;
          final state = expected['state'] as Map<String, dynamic>;
          final units = (state['units'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          units.last['experiencePoints'] = 1;
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
            contains('complete reviewed RushProduction oracle'),
          ),
        ),
        reason: mutation.fileName,
      );
    }
  });

  test('Rush unit completion pins the Hero Sword XP source', () {
    final repository = _copyCorpus();
    final fixture = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-rush-unit-completed-accepted.json',
    );
    _mutateFixture(fixture, (json) {
      final artifacts = (_inputState(json)['artifacts'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final heroSword = artifacts.singleWhere(
        (artifact) => artifact['id'] == 'artifact.heroSword',
      );
      heroSword['type'] = 'queensMirror';
    });

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('RushProduction acceptance mode'),
        ),
      ),
    );
  });

  test('Rush blocked spawn remains an explicit acceptance branch', () {
    final repository = _copyCorpus();
    final fixture = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-rush-unit-spawn-blocked-accepted.json',
    );
    _mutateFixture(fixture, (json) {
      final input = json['input'] as Map<String, dynamic>;
      final map = input['map'] as Map<String, dynamic>;
      final tiles = (map['tiles'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (final tile in tiles) {
        tile
          ..['terrains'] = ['grassland']
          ..['displayTerrain'] = 'grassland'
          ..['yieldTerrain'] = 'grassland'
          ..['terrainTags'] = ['grassland'];
      }
      final state = _inputState(json);
      (state['units'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .removeWhere((unit) => unit['id'] != 'unit_sentinel');
    });

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('RushProduction acceptance mode'),
        ),
      ),
    );
  });

  test('Rush partial mode pins unrest, Mother Factory, and industry', () {
    final mutations = <_JsonMutation>[
      (json) {
        final stability =
            _inputState(json)['playerStabilityNet'] as Map<String, dynamic>;
        stability['player_1'] = 0;
      },
      (json) {
        _inputCity(json, 'city_1').remove('wonders');
      },
      (json) {
        _inputCity(json, 'city_1').remove('specialization');
      },
    ];

    for (final mutate in mutations) {
      final repository = _copyCorpus();
      final fixture = File(
        '${repository.path}/test/fixtures/reducer_parity/'
        'city-production-rush-unrest-accepted.json',
      );
      _mutateFixture(fixture, mutate);

      expect(
        () => ReducerParityCorpus.load(repository),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('RushProduction acceptance mode'),
          ),
        ),
      );
    }
  });

  test('Rush wonder completion pins Great Library effects and refund', () {
    final mutations = <_JsonMutation>[
      (json) {
        final queue =
            _inputCity(json, 'city_1')['productionQueue']
                as Map<String, dynamic>;
        queue['target'] = {'kind': 'wonder', 'wonderType': 'hangingGardens'};
      },
      (json) {
        final state = _inputState(json);
        final research = state['research'] as Map<String, dynamic>;
        final players = research['players'] as Map<String, dynamic>;
        (players['player_1'] as Map<String, dynamic>).remove(
          'activeTechnologyId',
        );
      },
      (json) {
        final queue =
            _inputCity(json, 'city_peer')['productionQueue']
                as Map<String, dynamic>;
        queue['target'] = {'kind': 'wonder', 'wonderType': 'petra'};
      },
    ];

    for (final mutate in mutations) {
      final repository = _copyCorpus();
      final fixture = File(
        '${repository.path}/test/fixtures/reducer_parity/'
        'city-production-rush-wonder-completed-accepted.json',
      );
      _mutateFixture(fixture, mutate);

      expect(
        () => ReducerParityCorpus.load(repository),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('RushProduction acceptance mode'),
          ),
        ),
      );
    }
  });

  test('Rush wonder fixtures pin registry status and ordered events', () {
    final repository = _copyCorpus();
    final completed = File(
      '${repository.path}/test/fixtures/reducer_parity/'
      'city-production-rush-wonder-completed-accepted.json',
    );
    _mutateFixture(completed, (json) {
      final expected = json['expected'] as Map<String, dynamic>;
      final events = expected['events'] as List<dynamic>;
      final first = events.removeAt(0);
      events.insert(1, first);
    });

    expect(
      () => ReducerParityCorpus.load(repository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('complete reviewed RushProduction oracle'),
        ),
      ),
    );

    final secondRepository = _copyCorpus();
    final refunded = File(
      '${secondRepository.path}/test/fixtures/reducer_parity/'
      'city-production-rush-wonder-precompleted-refund-accepted.json',
    );
    _mutateFixture(refunded, (json) {
      (_inputState(json)['wonderRegistry'] as Map<String, dynamic>).remove(
        'greatLibrary',
      );
    });

    expect(
      () => ReducerParityCorpus.load(secondRepository),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('RushProduction acceptance mode'),
        ),
      ),
    );
  });
}
