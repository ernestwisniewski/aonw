import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaveSnapshotCodec', () {
    test('round-trips persistent snapshot slices', () {
      final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'p1',
        name: 'Capital',
        center: CityHex(col: 2, row: 3),
      );
      final snapshot = SaveSnapshot(
        save: _save(),
        playerColors: const {'p1': 0xFF4a7fc4},
        playerCountries: const {'p1': PlayerCountry.japan},
        playerGold: const {'p1': 7},
        playerWarWeariness: const {'p1': 3},
        playerStabilityNet: const {'p1': -2},
        units: [unit],
        cities: [city],
        runtimeState: GameRuntimeState(
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
        ),
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
      expect(
        restored.runtimeState.pendingAction,
        isA<PendingCityWorkedHexSelection>(),
      );
      expect(restored.runtimeState.submittedPlayerIds, {'p1'});
      expect(restored.runtimeState.dominationHoldTurnsByPlayerId, {'p1': 2});
      expect(
        restored.runtimeState.turnStartedAt,
        DateTime.utc(2026, 4, 27, 12),
      );
      expect(
        restored.runtimeState.intendedAttacks.single.attackerUnitId,
        'warrior_1',
      );
      expect(restored.eventLogOffset, 9);
    });

    test('defaults stability state for snapshots created before stability', () {
      final json = SaveSnapshotCodec.toJson(SaveSnapshot(save: _save()))
        ..remove('playerWarWeariness')
        ..remove('playerStabilityNet');

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(restored.playerWarWeariness, isEmpty);
      expect(restored.playerStabilityNet, isEmpty);
    });

    test('round-trips match rules in save metadata', () {
      final snapshot = SaveSnapshot(
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

    test('drops unknown pending runtime actions while loading', () {
      final snapshot = SaveSnapshot(
        save: _save(),
        runtimeState: const GameRuntimeState(
          pendingAction: PendingCityWorkedHexSelection(
            ownerPlayerId: 'p1',
            cityId: 'city_1',
          ),
        ),
      );
      final json = SaveSnapshotCodec.toJson(snapshot);
      (json['runtimeState'] as Map<String, dynamic>)['pendingAction'] = {
        'type': 'futurePendingAction',
        'ownerPlayerId': 'p1',
      };

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(restored.runtimeState.pendingAction, isNull);
    });

    test('drops invalid submitted players while loading runtime state', () {
      final snapshot = SaveSnapshot(
        save: _save(),
        runtimeState: const GameRuntimeState(submittedPlayerIds: {'p1'}),
      );
      final json = SaveSnapshotCodec.toJson(snapshot);
      (json['runtimeState'] as Map<String, dynamic>)['submittedPlayerIds'] = [
        'p1',
        '',
        7,
        'p2',
      ];

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(restored.runtimeState.submittedPlayerIds, {'p1', 'p2'});
    });

    test('drops invalid intended attacks while loading runtime state', () {
      final snapshot = SaveSnapshot(
        save: _save(),
        runtimeState: const GameRuntimeState(
          intendedAttacks: [
            IntendedAttack(
              attackerUnitId: 'warrior_1',
              defenderCol: 4,
              defenderRow: 5,
              declaredAtTick: 7,
              declaringPlayerId: 'p1',
            ),
          ],
        ),
      );
      final json = SaveSnapshotCodec.toJson(snapshot);
      (json['runtimeState'] as Map<String, dynamic>)['intendedAttacks'] = [
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

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(restored.runtimeState.intendedAttacks, hasLength(1));
      expect(
        restored.runtimeState.intendedAttacks.single.attackerUnitId,
        'warrior_1',
      );
    });

    test('drops invalid turnStartedAt while loading runtime state', () {
      final snapshot = SaveSnapshot(
        save: _save(),
        runtimeState: GameRuntimeState(
          turnStartedAt: DateTime.utc(2026, 4, 27, 12),
        ),
      );
      final json = SaveSnapshotCodec.toJson(snapshot);
      (json['runtimeState'] as Map<String, dynamic>)['turnStartedAt'] = 'nope';

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(restored.runtimeState.turnStartedAt, isNull);
    });

    test('clears unknown worker improvement type while loading', () {
      final snapshot = SaveSnapshot(
        save: _save(),
        runtimeState: const GameRuntimeState(
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'p1',
            unitId: 'worker_1',
            improvementType: FieldImprovementType.mine,
          ),
        ),
      );
      final json = SaveSnapshotCodec.toJson(snapshot);
      final pendingAction =
          (json['runtimeState'] as Map<String, dynamic>)['pendingAction']
              as Map<String, dynamic>;
      pendingAction['improvementType'] = 'futureImprovement';

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(
        restored.runtimeState.pendingAction,
        isA<PendingWorkerActionSelection>(),
      );
      expect(
        (restored.runtimeState.pendingAction as PendingWorkerActionSelection)
            .improvementType,
        isNull,
      );
    });

    test('filters unknown research technology ids while loading', () {
      final snapshot = SaveSnapshot(
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
      final json = SaveSnapshotCodec.toJson(snapshot);
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

      final restored = SaveSnapshotCodec.fromJson(json);
      final restoredResearch = restored.research.forPlayer('p1');

      expect(restoredResearch.hasUnlocked(TechnologyId.agriculture), isTrue);
      expect(restoredResearch.activeTechnologyId, isNull);
      expect(restoredResearch.progressFor(TechnologyId.mining), 3);
      expect(restoredResearch.progressFor(TechnologyId.trade), 0);
    });

    test('defaults malformed research payload to empty state', () {
      final json = SaveSnapshotCodec.toJson(SaveSnapshot(save: _save()));
      json['research'] = {'players': <dynamic>[]};

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(restored.research, ResearchState.empty);
    });

    test('filters malformed fog entries while loading', () {
      final snapshot = SaveSnapshot(
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
      final json = SaveSnapshotCodec.toJson(snapshot);
      final fogJson = List<dynamic>.from(json['fogOfWar'] as List<dynamic>)
        ..add({'discoveredHexes': <dynamic>[]})
        ..add('bad-player-fog');
      json['fogOfWar'] = fogJson;
      (fogJson.first as Map<String, dynamic>)['discoveredHexes'] = [
        {'col': 1, 'row': 2},
        {'col': 'bad', 'row': 3},
        {'col': 4},
      ];

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(
        restored.fogOfWar.isKnown('p1', const HexCoordinate(col: 1, row: 2)),
        isTrue,
      );
      expect(restored.fogOfWar.playerIds, ['p1']);
    });

    test('defaults malformed fog payload to empty state', () {
      final json = SaveSnapshotCodec.toJson(SaveSnapshot(save: _save()));
      json['fogOfWar'] = {'players': <dynamic>[]};

      final restored = SaveSnapshotCodec.fromJson(json);

      expect(restored.fogOfWar, FogOfWarState.empty);
    });
  });
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'p1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
  );
}
