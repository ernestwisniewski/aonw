import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiStrategicPlanProvider', () {
    test('reuses current plan inside the strategic window', () {
      final provider = AiStrategicPlanProvider();
      final first = _resolve(provider, _snapshot(turn: 1));
      final sameTurn = _resolve(provider, _snapshot(turn: 1));
      final nextTurn = _resolve(provider, _snapshot(turn: 4));

      expect(first.economyHealth.underperformanceStreak, 0);
      expect(sameTurn, same(first));
      expect(nextTurn, same(first));
      expect(provider.length, 1);
    });

    test('recomputes on checkpoint and compares against old expectations', () {
      final provider = AiStrategicPlanProvider();
      final first = _resolve(provider, _snapshot(turn: 1));
      final checkpoint = _resolve(provider, _collapsedSnapshot(turn: 6));

      expect(checkpoint, isNot(same(first)));
      expect(checkpoint.computedAtTurn, 6);
      expect(checkpoint.economyHealth.underperformanceStreak, 1);
      expect(checkpoint.economyHealth.isBehind, isTrue);
    });

    test('early trigger does not reset the economy checkpoint', () {
      final provider = AiStrategicPlanProvider();
      final first = _resolve(provider, _snapshot(turn: 1));
      final withWorker = _resolve(
        provider,
        _snapshot(
          turn: 3,
          units: [_workerA.copyWith(col: 2), _workerB, _workerC],
        ),
      );
      final checkpoint = _resolve(provider, _collapsedSnapshot(turn: 6));

      expect(withWorker, isNot(same(first)));
      expect(withWorker.computedAtTurn, 3);
      expect(withWorker.economyHealth.underperformanceStreak, 0);
      expect(checkpoint.computedAtTurn, 6);
      expect(checkpoint.economyHealth.underperformanceStreak, 1);
    });
  });
}

StrategicPlan _resolve(
  AiStrategicPlanProvider provider,
  SaveSnapshot snapshot,
) {
  final player = snapshot.save.players.singleWhere((p) => p.id == 'player_2');
  final ai = player.ai!;
  final ruleset = GameRuleset.defaults.copyWith(
    paceBalance: snapshot.save.matchRules.paceBalance,
  );
  final view = GameView.fromPersistentState(
    snapshot.persistentState,
    forPlayerId: player.id,
    turn: snapshot.save.turn,
    mapData: _mapData,
    ruleset: ruleset,
  );
  const civRegistry = CivilizationProfileRegistry();
  final civProfile = civRegistry.profileFor(player.country);
  final context = AiContext(
    ruleset: ruleset,
    mapData: _mapData,
    turn: snapshot.save.turn,
    rng: AiRng.fromTurn(
      turn: snapshot.save.turn,
      playerId: player.id,
      baseSeed: ai.seed,
    ),
    persona: ai.personaForProfile(civProfile),
    difficulty: ai.difficulty,
    civProfile: civProfile,
  );
  final assessment = AiEmpireAssessment.fromView(view, context);
  return provider.resolve(
    snapshot: snapshot,
    player: player,
    view: view,
    context: context,
    assessment: assessment,
  );
}

SaveSnapshot _snapshot({
  required int turn,
  List<GameCity> cities = _healthyCities,
  List<GameUnit>? units,
  int gold = 50,
}) {
  return SaveSnapshot(
    save: _save(turn: turn),
    cities: cities,
    units: units ?? _healthyWorkers,
    playerGold: {'player_2': gold},
  );
}

SaveSnapshot _collapsedSnapshot({required int turn}) {
  return _snapshot(
    turn: turn,
    cities: const [_cityA],
    units: const [],
    gold: 0,
  );
}

GameSave _save({required int turn}) {
  return GameSave(
    id: 'save_1',
    name: 'AI strategic provider test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: const {
      'player_1': PlayerTurnState.active,
      'player_2': PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 5, 17, 12),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Human', colorValue: 0xFF2563EB),
      Player(
        id: 'player_2',
        name: 'AI',
        colorValue: 0xFFDC2626,
        kind: PlayerKind.ai,
        ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 99),
      ),
    ],
    gameMode: GameMode.hotSeat,
  );
}

const _cityA = GameCity(
  id: 'city_2',
  ownerPlayerId: 'player_2',
  name: 'AI City A',
  center: CityHex(col: 1, row: 1),
);

const _cityB = GameCity(
  id: 'city_3',
  ownerPlayerId: 'player_2',
  name: 'AI City B',
  center: CityHex(col: 3, row: 1),
);

const _cityC = GameCity(
  id: 'city_4',
  ownerPlayerId: 'player_2',
  name: 'AI City C',
  center: CityHex(col: 1, row: 3),
);

const _healthyCities = [_cityA, _cityB, _cityC];

final _workerA = GameUnit.produced(
  id: 'worker_a',
  ownerPlayerId: 'player_2',
  type: GameUnitType.worker,
  col: 1,
  row: 1,
);

final _workerB = GameUnit.produced(
  id: 'worker_b',
  ownerPlayerId: 'player_2',
  type: GameUnitType.worker,
  col: 3,
  row: 1,
);

final _workerC = GameUnit.produced(
  id: 'worker_c',
  ownerPlayerId: 'player_2',
  type: GameUnitType.worker,
  col: 1,
  row: 3,
);

final _healthyWorkers = [_workerA, _workerB, _workerC];

final _mapData = MapData(
  cols: 5,
  rows: 5,
  tiles: [
    for (var row = 0; row < 5; row++)
      for (var col = 0; col < 5; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);
