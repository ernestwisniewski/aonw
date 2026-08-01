import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/canonical_command_test_dispatch.dart';

void main() {
  group('BasicStrategy simulation', () {
    test(
      'turns a detached settler opening into a city and expansion setup',
      () {
        final mapData = _plainsMap();
        const player = Player(
          id: 'player_1',
          name: 'AI Basic',
          colorValue: 0xFFDC2626,
          kind: PlayerKind.ai,
          ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 1001),
        );
        final initialUnits = StartingUnits.unitsForPlayers(const [
          player,
        ], mapData: mapData);
        var state = GameClientState(
          playerColors: const {'player_1': 0xFFDC2626},
          units: initialUnits,
          activePlayerId: 'player_1',
        );
        state = _recomputeFog(state, mapData);

        final result = _simulateBasicAiTurns(
          state: state,
          mapData: mapData,
          turns: 3,
          player: player,
        );
        final cityId = result.state.cities.single.id;

        expect(
          result.appliedCommands.whereType<FoundCityCommand>().single.founderId,
          'settler_player_1',
        );
        expect(
          result.plannedCommands.length,
          greaterThanOrEqualTo(result.appliedCommands.length),
        );
        expect(
          result.appliedCommands.whereType<SelectTechnologyCommand>(),
          isNotEmpty,
        );
        expect(
          result.appliedCommands.whereType<StartUnitProductionCommand>(),
          contains(StartUnitProductionCommand(cityId, GameUnitType.settler)),
        );
        expect(result.state.cities, hasLength(1));
        expect(
          result.state.units.where((unit) => unit.type == GameUnitType.settler),
          isEmpty,
        );
        expect(
          result.state.units.where(
            (unit) => unit.type == GameUnitType.commander,
          ),
          isEmpty,
        );
        expect(
          result.state.units.where((unit) => unit.type == GameUnitType.warrior),
          isNotEmpty,
        );

        final research = result.state.research.forPlayer('player_1');
        expect(
          research.activeTechnologyId == TechnologyId.agriculture ||
              research.unlockedTechnologyIds.contains(TechnologyId.agriculture),
          isTrue,
        );
      },
    );
  });
}

_SimulationResult _simulateBasicAiTurns({
  required GameClientState state,
  required WorldMap mapData,
  required int turns,
  required Player player,
}) {
  final reducer = GameStateReducer(mapData: mapData);
  final plannedCommands = <DomainCommand>[];
  final appliedCommands = <DomainCommand>[];

  for (var turn = 1; turn <= turns; turn++) {
    final context = GameCommandContext(
      actorPlayerId: player.id,
      combatSeedTurn: turn,
      ignoreFogOfWar: true,
    );
    state = MovementReducer.resetUnitMovementForNewTurn(
      state,
      mapData,
      playerId: player.id,
    ).state;

    final view = GameView.fromDomainState(
      _persistentStateFor(state),
      forPlayerId: player.id,
      turn: turn,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final aiContext = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: turn,
      rng: AiRng.fromTurn(
        turn: turn,
        playerId: player.id,
        baseSeed: player.ai!.seed,
      ),
      persona: player.ai!.persona,
      difficulty: player.ai!.difficulty,
    );
    final plan = const BasicStrategy().plan(view, aiContext);

    for (final command in plan.commands) {
      plannedCommands.add(command);
      final transition = dispatchCanonicalTestCommand(
        reducer: reducer,
        state: state,
        command: command,
        context: context,
      );
      if (transition.state == state) continue;
      state = transition.state;
      appliedCommands.add(command);
    }

    state = dispatchCanonicalTestCommand(
      reducer: reducer,
      state: state,
      command: EndTurnCommand(player.id),
      context: context,
    ).state;
  }

  return _SimulationResult(
    state: state,
    plannedCommands: plannedCommands,
    appliedCommands: appliedCommands,
  );
}

GameClientState _recomputeFog(GameClientState state, WorldMap mapData) {
  final fog = const FogOfWarService().recompute(
    current: state.fogOfWar,
    mapData: mapData,
    playerIds: state.playerColors.keys,
    units: state.units,
    cities: state.cities,
  );
  return state.copyWith(fogOfWar: fog);
}

DomainState _persistentStateFor(GameClientState state) {
  return DomainState.snapshot(
    playerColors: state.playerColors,
    playerGold: state.playerGold,
    units: state.units,
    cities: state.cities,
    fieldImprovements: state.fieldImprovements,
    fogOfWar: state.fogOfWar,
    research: state.research,
  );
}

WorldMap _plainsMap() {
  final tiles = <WorldTile>[];
  for (var col = 0; col < 7; col++) {
    for (var row = 0; row < 7; row++) {
      tiles.add(
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
      );
    }
  }
  return WorldMap(cols: 7, rows: 7, tiles: tiles);
}

class _SimulationResult {
  const _SimulationResult({
    required this.state,
    required this.plannedCommands,
    required this.appliedCommands,
  });

  final GameClientState state;
  final List<DomainCommand> plannedCommands;
  final List<DomainCommand> appliedCommands;
}
