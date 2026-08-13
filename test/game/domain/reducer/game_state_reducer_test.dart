import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/canonical_command_test_dispatch.dart';
import '../../../support/game_intent_test_resolver.dart';

WorldMap _emptyMap() => WorldMap(cols: 5, rows: 5, tiles: []);

WorldMap _landMap() => WorldMap(
  cols: 5,
  rows: 5,
  tiles: [
    for (int row = 0; row < 5; row++)
      for (int col = 0; col < 5; col++) _tile(col, row),
  ],
);

GameUnit _unit({
  String id = 'u1',
  String ownerPlayerId = 'p1',
  int col = 0,
  int row = 0,
}) => GameUnit(
  id: id,
  ownerPlayerId: ownerPlayerId,
  type: GameUnitType.commander,
  name: 'Commander',
  col: col,
  row: row,
);

GameCity _city({
  String id = 'c1',
  String ownerPlayerId = 'p1',
  int col = 0,
  int row = 0,
}) => GameCity(
  id: id,
  ownerPlayerId: ownerPlayerId,
  name: 'City',
  center: CityHex(col: col, row: row),
);

WorldTile _tile(int col, int row) => WorldTile(
  col: col,
  row: row,
  terrains: const [TerrainType.grassland],
  resources: const [],
  height: 0,
);
void main() {
  late GameStateReducer reducer;

  setUp(() {
    reducer = GameStateReducer(mapData: _emptyMap());
  });

  group('GameStateTransition', () {
    test('holds state and defaults to empty uiEffects and events', () {
      final state = GameClientState();
      final transition = GameStateTransition(state: state);
      expect(transition.state, same(state));
      expect(transition.uiEffects, isEmpty);
      expect(transition.events, isEmpty);
    });
  });

  group('RendererEffect', () {
    test('JumpCameraEffect holds col and row', () {
      const effect = JumpCameraEffect(col: 3, row: 7);
      expect(effect, isA<RendererEffect>());
      expect(effect.col, 3);
      expect(effect.row, 7);
    });

    test('AnimateUnitMoveEffect holds unitId and steps', () {
      const step = UnitMovementStep(
        col: 1,
        row: 2,
        enterCost: 1,
        cumulativeCost: 1,
      );
      const effect = AnimateUnitMoveEffect(
        unitId: 'u1',
        fromCol: 0,
        fromRow: 1,
        steps: [step],
      );
      expect(effect.unitId, 'u1');
      expect((effect.fromCol, effect.fromRow), (0, 1));
      expect(effect.steps, equals(const [step]));
    });

    test('PlayCombatAnimationEffect holds combat participants', () {
      const effect = PlayCombatAnimationEffect(
        attackerUnitId: 'attacker',
        defenderUnitId: 'defender',
        attackerKilled: true,
      );
      expect(effect.attackerUnitId, 'attacker');
      expect(effect.defenderUnitId, 'defender');
      expect(effect.attackerKilled, isTrue);
      expect(effect.defenderKilled, isFalse);
    });
  });

  group('stub commands (no-op)', () {
    final state = GameClientState(activePlayerId: 'p1');

    final stubCommands = <Object>[
      const TileTappedCommand(1, 2),
      const CityTappedCommand('c1'),
      const MoveUnitCommand('u1', 3, 4),
      FoundCityCommand('u1', controlledHexes: const []),
      const StartBuildingCommand('c1', CityBuildingType.granary),
      const StartUnitProductionCommand('c1', GameUnitType.warrior),
      const StartCityProjectCommand('c1', CityProjectType.wealth),
      const CancelResearchSelectionCommand('p1'),
      const DetachTroopCommand('u1', TroopType.settler),
      const ToggleMoveTargetingCommand(),
      const StartCityFoundingCommand(),
      const CancelCityFoundingCommand(),
      const SelectTileCommand(0, 0),
      const SelectUnitCommand('u1'),
      const SelectCityCommand('c1'),
    ];

    for (final cmd in stubCommands) {
      test('${cmd.runtimeType} returns unchanged state', () {
        final result = dispatchCanonicalTestCommand(
          reducer: reducer,
          state: state,
          command: cmd,
        );
        expect(result.state, equals(state));
        expect(result.uiEffects, isEmpty);
      });
    }
  });

  group('TileTappedCommand', () {
    test('selects inspection hex while research selection is pending', () {
      final mapData = _landMap();
      final reducer = GameStateReducer(mapData: mapData);
      const pendingAction = PendingResearchSelection(ownerPlayerId: 'p1');
      final state = GameClientState(
        activePlayerId: 'p1',
        fogOfWar: FogOfWarState(
          players: {
            'p1': PlayerFogOfWar(
              playerId: 'p1',
              visibleHexes: {const HexCoordinate(col: 2, row: 3)},
            ),
          },
        ),
        interaction: const InteractionState(
          pendingAction: pendingAction,
          moveCommandActive: true,
        ),
      );

      final result = resolveGameIntent(
        reducer,
        state,
        const TileTappedCommand(2, 3),
      );

      expect(result.state.pendingAction, pendingAction);
      expect(result.state.moveCommandActive, isFalse);
      expect(result.state.selection?.type, GameSelectionType.tile);
      expect(result.state.selection?.tile?.col, 2);
      expect(result.state.selection?.tile?.row, 3);
    });
  });

  group('active player interaction sync', () {
    test('updates activePlayerId and activePlayerCanAct', () {
      final state = GameClientState(
        activePlayerId: 'p1',
        activePlayerCanAct: true,
      );
      final result = reducer.syncActivePlayer(
        state,
        playerId: 'p2',
        canAct: false,
      );
      expect(result.state.activePlayerId, equals('p2'));
      expect(result.state.activePlayerCanAct, isFalse);
    });

    test('clears moveCommandActive', () {
      final state = GameClientState(
        activePlayerId: 'p1',
        interaction: const InteractionState(moveCommandActive: true),
      );
      final result = reducer.syncActivePlayer(
        state,
        playerId: 'p2',
        canAct: true,
      );
      expect(result.state.moveCommandActive, isFalse);
    });

    test('clears movePreview', () {
      final plan = UnitMovementPlan(
        unitId: 'u1',
        targetCol: 2,
        targetRow: 3,
        totalCost: 1,
        availableMovementUnits: 3,
        steps: const [
          UnitMovementStep(col: 2, row: 3, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final state = GameClientState(
        activePlayerId: 'p1',
      ).copyWithInteraction(movePreview: plan);

      final result = reducer.syncActivePlayer(
        state,
        playerId: 'p2',
        canAct: true,
      );
      expect(result.state.movePreview, isNull);
    });

    test('clears cityFoundingDraft', () {
      final unit = _unit(ownerPlayerId: 'p1');
      final draft = CityFoundingDraft(
        unitId: unit.id,
        ownerPlayerId: unit.ownerPlayerId,
        center: CityHex(col: unit.col, row: unit.row),
      );
      final state = GameClientState(
        activePlayerId: 'p1',
        units: [unit],
      ).copyWithInteraction(cityFoundingDraft: draft);

      final result = reducer.syncActivePlayer(
        state,
        playerId: 'p2',
        canAct: true,
      );
      expect(result.state.cityFoundingDraft, isNull);
    });

    test(
      'preserves pendingAction when SetActivePlayer targets same player',
      () {
        final state = GameClientState(
          activePlayerId: 'p1',
          activePlayerCanAct: true,
          interaction: const InteractionState(
            pendingAction: PendingAttackTargeting(
              ownerPlayerId: 'p1',
              attackerUnitId: 'u1',
            ),
          ),
        );

        final result = reducer.syncActivePlayer(
          state,
          playerId: 'p1',
          canAct: true,
        );

        expect(result.state.pendingAction, state.pendingAction);
      },
    );

    test(
      'clears unit selection when selected unit is not controllable by new player',
      () {
        final unit = _unit(ownerPlayerId: 'p1');
        final selection = GameSelection.unit(unit);
        final state = GameClientState(
          activePlayerId: 'p1',
          activePlayerCanAct: true,
          units: [unit],
        ).copyWithInteraction(selection: selection);

        final result = reducer.syncActivePlayer(
          state,
          playerId: 'p2',
          canAct: true,
        );
        expect(result.state.selection, isNull);
      },
    );

    test(
      'clears city selection when selected city is not controllable by new player',
      () {
        final city = _city(ownerPlayerId: 'p1');
        final selection = GameSelection.city(
          city,
          cityYield: TileYield.zero,
          playerColor: 0xFF0000FF,
        );
        final state = GameClientState(
          activePlayerId: 'p1',
          activePlayerCanAct: true,
          cities: [city],
        ).copyWithInteraction(selection: selection);

        final result = reducer.syncActivePlayer(
          state,
          playerId: 'p2',
          canAct: true,
        );
        expect(result.state.selection, isNull);
      },
    );

    test('preserves tile selection when switching player', () {
      final tile = _tile(3, 4);
      final selection = GameSelection.tile(tile);
      final state = GameClientState(
        activePlayerId: 'p1',
        activePlayerCanAct: true,
      ).copyWithInteraction(selection: selection);

      final result = reducer.syncActivePlayer(
        state,
        playerId: 'p2',
        canAct: true,
      );
      expect(result.state.selection, isNotNull);
      expect(result.state.selection!.type, equals(GameSelectionType.tile));
    });

    test(
      'preserves unit selection when unit is controllable by new player',
      () {
        final unit = _unit(ownerPlayerId: 'p2');
        final selection = GameSelection.unit(unit);
        final state = GameClientState(
          activePlayerId: 'p1',
          activePlayerCanAct: true,
          units: [unit],
        ).copyWithInteraction(selection: selection);

        final result = reducer.syncActivePlayer(
          state,
          playerId: 'p2',
          canAct: true,
        );
        expect(result.state.selection, isNotNull);
        expect(result.state.selection!.type, equals(GameSelectionType.unit));
      },
    );

    test('preserves own unit selection when active player starts waiting', () {
      final unit = _unit(ownerPlayerId: 'p1');
      final selection = GameSelection.unit(unit);
      final state = GameClientState(
        activePlayerId: 'p1',
        activePlayerCanAct: true,
        units: [unit],
      ).copyWithInteraction(selection: selection);

      final result = reducer.syncActivePlayer(
        state,
        playerId: 'p1',
        canAct: false,
      );

      expect(result.state.selection, isNotNull);
      expect(result.state.selection!.type, GameSelectionType.unit);
      expect(result.state.moveCommandActive, isFalse);
    });

    test(
      'preserves city selection when city is controllable by new player',
      () {
        final city = _city(ownerPlayerId: 'p2');
        final selection = GameSelection.city(
          city,
          cityYield: TileYield.zero,
          playerColor: 0xFF0000FF,
        );
        final state = GameClientState(
          activePlayerId: 'p1',
          activePlayerCanAct: true,
          cities: [city],
        ).copyWithInteraction(selection: selection);

        final result = reducer.syncActivePlayer(
          state,
          playerId: 'p2',
          canAct: true,
        );
        expect(result.state.selection, isNotNull);
        expect(result.state.selection!.type, equals(GameSelectionType.city));
      },
    );

    test('returns no UI effects', () {
      final state = GameClientState(activePlayerId: 'p1');
      final result = reducer.syncActivePlayer(
        state,
        playerId: 'p2',
        canAct: true,
      );
      expect(result.uiEffects, isEmpty);
    });

    test('does not mutate authoritative fog while switching presentation', () {
      final reducer = GameStateReducer(mapData: _landMap());
      final unit = _unit(ownerPlayerId: 'p2', col: 2, row: 2);
      final state = GameClientState(activePlayerId: 'p1', units: [unit]);

      final result = reducer.syncActivePlayer(
        state,
        playerId: 'p2',
        canAct: true,
      );

      expect(result.state.fogOfWar, same(state.fogOfWar));
    });
  });
}
