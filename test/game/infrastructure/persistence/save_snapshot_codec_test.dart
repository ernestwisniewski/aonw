import 'dart:convert';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/transport.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaveSnapshotCodec', () {
    test('rejects schema-2 snapshots without an upcaster', () {
      final json = _mutableSnapshotJson(
        GameSnapshotFactory.create(save: _save()),
      );
      final save = json['save'] as Map<String, dynamic>;
      save['schemaVersion'] = 2;

      expect(
        () => SaveSnapshotCodec.fromJson(json),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Unsupported save schema version: 2'),
          ),
        ),
      );
    });

    test('rejects unknown older and future save schemas', () {
      for (final schemaVersion in [1, gameSaveCurrentSchemaVersion + 1]) {
        final json = _mutableSnapshotJson(
          GameSnapshotFactory.create(save: _save()),
        );
        final save = json['save'] as Map<String, dynamic>;
        save['schemaVersion'] = schemaVersion;

        expect(
          () => SaveSnapshotCodec.fromJson(json),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('Unsupported save schema version: $schemaVersion'),
            ),
          ),
        );
      }
    });

    test('migrates schema 3 snapshots with an empty transport network', () {
      final json = _mutableSnapshotJson(
        GameSnapshotFactory.create(save: _save()),
      );
      (json['save'] as Map<String, dynamic>)['schemaVersion'] = 3;
      json.remove('transportNetwork');

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(restored.save.schemaVersion, gameSaveCurrentSchemaVersion);
      expect(restored.domain.transportNetwork, TransportNetworkState.empty);
    });

    test('round-trips persistent snapshot slices', () {
      final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'p1',
        name: 'Capital',
        center: CityHex(col: 2, row: 3),
      );
      final snapshot = GameSnapshotFactory.create(
        save: _save(country: PlayerCountry.japan),
        playerGold: const {'p1': 7},
        playerWarWeariness: const {'p1': 3},
        playerStabilityNet: const {'p1': -2},
        units: [unit],
        cities: [city],
        transportNetwork: TransportNetworkState(
          segments: const [
            TransportSegment(
              hex: HexCoord(col: 1, row: 3),
              builtByPlayerId: 'p1',
              builtByCityId: 'city_1',
            ),
          ],
        ),

        pendingAction: const PendingCityWorkedHexSelection(
          ownerPlayerId: 'p1',
          cityId: 'city_1',
        ),
        submittedPlayerIds: const {'p1'},
        dominationHoldTurnsByPlayerId: const {'p1': 2},
        turnStartedAt: DateTime.utc(2026, 4, 27, 12),
        intendedAttacks: const [
          IntendedAttack(
            attackerUnitId: 'warrior_1',
            defenderCol: 4,
            defenderRow: 5,
            declaredAtTick: 7,
            declaringPlayerId: 'p1',
          ),
        ],

        eventLogOffset: 9,
      );

      final restored = SaveSnapshotCodec.fromJson(
        SaveSnapshotCodec.toJson(snapshot),
      );

      expect(restored.save.id, 'save_1');
      expect(restored.playerColors, {'p1': 0xFF4a7fc4});
      expect(restored.playerCountries, {'p1': PlayerCountry.japan});
      expect(restored.playerGold, {'p1': 7});
      expect(restored.playerWarWeariness, {'p1': 3});
      expect(restored.playerStabilityNet, {'p1': -2});
      expect(restored.units.single.id, unit.id);
      expect(restored.cities.single.id, city.id);
      expect(restored.domain.transportNetwork.hasOperationalRoadAt(1, 3), true);
      expect(
        restored.domain.actions.pendingAction,
        isA<PendingCityWorkedHexSelection>(),
      );
      expect(restored.domain.submittedPlayerIds, {'p1'});
      expect(restored.domain.dominationHoldTurnsByPlayerId, {'p1': 2});
      expect(restored.domain.turnStartedAt, DateTime.utc(2026, 4, 27, 12));
      expect(
        restored.domain.intendedAttacks.single.attackerUnitId,
        'warrior_1',
      );
      expect(restored.eventLogOffset, 9);
    });

    test('decodes omitted empty stability fields', () {
      final json =
          SaveSnapshotCodec.toJson(GameSnapshotFactory.create(save: _save()))
            ..remove('playerWarWeariness')
            ..remove('playerStabilityNet');

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(restored.playerWarWeariness, isEmpty);
      expect(restored.playerStabilityNet, isEmpty);
    });

    test('round-trips match rules in save metadata', () {
      final snapshot = GameSnapshotFactory.create(
        save: _save().copyWith(
          matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        ),
      );
      final json = SaveSnapshotCodec.toJson(snapshot);

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(restored.save.matchRules, snapshot.save.matchRules);
      expect(
        (json['save'] as Map<String, dynamic>)['ruleset'],
        snapshot.save.matchRules.toJson(),
      );
    });

    test('rejects unknown pending runtime actions', () {
      final snapshot = GameSnapshotFactory.create(
        save: _save(),

        pendingAction: const PendingCityWorkedHexSelection(
          ownerPlayerId: 'p1',
          cityId: 'city_1',
        ),
      );
      final json = _mutableSnapshotJson(snapshot);
      (json['lifecycle'] as Map<String, dynamic>)['pendingAction'] = {
        'type': 'futurePendingAction',
        'ownerPlayerId': 'p1',
      };

      expect(
        () => SaveSnapshotCodec.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid submitted players', () {
      final snapshot = GameSnapshotFactory.create(
        save: _save(),
        submittedPlayerIds: {'p1'},
      );
      final json = _mutableSnapshotJson(snapshot);
      (json['lifecycle'] as Map<String, dynamic>)['submittedPlayerIds'] = [
        'p1',
        '',
        7,
        'p2',
      ];

      expect(
        () => SaveSnapshotCodec.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid intended attacks', () {
      final snapshot = GameSnapshotFactory.create(
        save: _save(),

        intendedAttacks: [
          const IntendedAttack(
            attackerUnitId: 'warrior_1',
            defenderCol: 4,
            defenderRow: 5,
            declaredAtTick: 7,
            declaringPlayerId: 'p1',
          ),
        ],
      );
      final json = _mutableSnapshotJson(snapshot);
      (json['lifecycle'] as Map<String, dynamic>)['intendedAttacks'] = [
        {
          'attackerUnitId': 'warrior_1',
          'defenderCol': 4,
          'defenderRow': 5,
          'declaredAtTick': 7,
          'declaringPlayerId': 'p1',
        },
        {
          'attackerUnitId': '',
          'defenderCol': 4,
          'defenderRow': 5,
          'declaredAtTick': 8,
          'declaringPlayerId': 'p1',
        },
      ];

      expect(
        () => SaveSnapshotCodec.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an invalid turn start timestamp', () {
      final snapshot = GameSnapshotFactory.create(
        save: _save(),

        turnStartedAt: DateTime.utc(2026, 4, 27, 12),
      );
      final json = _mutableSnapshotJson(snapshot);
      (json['lifecycle'] as Map<String, dynamic>)['turnStartedAt'] = 'nope';

      expect(
        () => SaveSnapshotCodec.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an unknown worker improvement type', () {
      final snapshot = GameSnapshotFactory.create(
        save: _save(),

        pendingAction: const PendingWorkerActionSelection(
          ownerPlayerId: 'p1',
          unitId: 'worker_1',
          improvementType: FieldImprovementType.mine,
        ),
      );
      final json = _mutableSnapshotJson(snapshot);
      final pendingAction =
          (json['lifecycle'] as Map<String, dynamic>)['pendingAction']
              as Map<String, dynamic>;
      pendingAction['improvementType'] = 'futureImprovement';

      expect(
        () => SaveSnapshotCodec.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unknown research technology ids', () {
      final snapshot = GameSnapshotFactory.create(
        save: _save(),
        research: ResearchState(
          players: {
            'p1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.agriculture},
              activeTechnologyId: TechnologyId.mining,
              progressByTechnologyId: {TechnologyId.mining: 3},
            ),
          },
        ),
      );
      final json = _mutableSnapshotJson(snapshot);
      final playerResearch =
          ((json['research'] as Map<String, dynamic>)['players']
                  as Map<String, dynamic>)['p1']
              as Map<String, dynamic>;
      (playerResearch['unlockedTechnologyIds'] as List<dynamic>).add(
        'futureTechnology',
      );
      playerResearch['activeTechnologyId'] = 'futureTechnology';
      final progress =
          playerResearch['progressByTechnologyId'] as Map<String, dynamic>;
      progress['futureTechnology'] = 99;
      progress['trade'] = -1;

      expect(
        () => SaveSnapshotCodec.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a malformed research payload', () {
      final json = _mutableSnapshotJson(
        GameSnapshotFactory.create(save: _save()),
      );
      json['research'] = {'players': <dynamic>[]};

      expect(
        () => SaveSnapshotCodec.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed fog entries', () {
      final snapshot = GameSnapshotFactory.create(
        save: _save(),
        fogOfWar: FogOfWarState(
          players: {
            'p1': PlayerFogOfWar(
              playerId: 'p1',
              discoveredHexes: {const HexCoordinate(col: 1, row: 2)},
            ),
          },
        ),
      );
      final json = _mutableSnapshotJson(snapshot);
      final fogJson = List<dynamic>.from(json['fogOfWar'] as List<dynamic>)
        ..add({'discoveredHexes': <dynamic>[]})
        ..add('bad-player-fog');
      json['fogOfWar'] = fogJson;
      (fogJson.first as Map<String, dynamic>)['discoveredHexes'] = [
        {'col': 1, 'row': 2},
        {'col': 'bad', 'row': 3},
        {'col': 4},
      ];

      expect(
        () => SaveSnapshotCodec.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a malformed fog payload', () {
      final json = _mutableSnapshotJson(
        GameSnapshotFactory.create(save: _save()),
      );
      json['fogOfWar'] = {'players': <dynamic>[]};

      expect(
        () => SaveSnapshotCodec.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _mutableSnapshotJson(CanonicalGameSnapshot snapshot) =>
    jsonDecode(jsonEncode(SaveSnapshotCodec.toJson(snapshot)))
        as Map<String, dynamic>;

GameSave _save({PlayerCountry country = PlayerCountry.poland}) {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'p1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: [
      Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4, country: country),
    ],
  );
}
