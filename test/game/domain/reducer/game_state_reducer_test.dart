import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _emptyMap() => MapData(cols: 5, rows: 5, tiles: []);

MapData _landMap() => MapData(
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

TileData _tile(int col, int row) => TileData(
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
  // GameStateTransition

  group('GameStateTransition', () {
    test('holds state and defaults to empty uiEffects and events', () {
      const state = GameState();
      const transition = GameStateTransition(state: state);
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
      expect(effect, isA<RendererEffect>());
      expect(effect.unitId, 'u1');
      expect(effect.fromCol, 0);
      expect(effect.fromRow, 1);
      expect(effect.steps, equals(const [step]));
    });

    test('PlayCombatAnimationEffect holds combat participants', () {
      const effect = PlayCombatAnimationEffect(
        attackerUnitId: 'attacker',
        defenderUnitId: 'defender',
        attackerKilled: true,
      );
      expect(effect, isA<RendererEffect>());
      expect(effect.attackerUnitId, 'attacker');
      expect(effect.defenderUnitId, 'defender');
      expect(effect.attackerKilled, isTrue);
      expect(effect.defenderKilled, isFalse);
    });
  });
  // Stub commands

  group('stub commands (no-op)', () {
    const state = GameState(activePlayerId: 'p1');

    final stubCommands = <GameCommand>[
      const TileTappedCommand(1, 2),
      const CityTappedCommand('c1'),
      const MoveUnitCommand('u1', 3, 4),
      const FoundCityCommand('u1'),
      const StartBuildingCommand('c1', CityBuildingType.granary),
      const StartUnitProductionCommand('c1', GameUnitType.warrior),
      const StartCityProjectCommand('c1', CityProjectType.wealth),
      const CancelResearchSelectionCommand('p1'),
      const DetachTroopCommand('u1', TroopType.settler),
      const ResetUnitMovementCommand(),
      const ToggleMoveTargetingCommand(),
      const StartCityFoundingCommand(),
      const CancelCityFoundingCommand(),
      const SelectTileCommand(0, 0),
      const SelectUnitCommand('u1'),
      const SelectCityCommand('c1'),
    ];

    for (final cmd in stubCommands) {
      test('${cmd.runtimeType} returns unchanged state', () {
        final result = reducer.reduce(state, cmd);
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
      final state = GameState(
        activePlayerId: 'p1',
        fogOfWar: FogOfWarState(
          players: {
            'p1': PlayerFogOfWar(
              playerId: 'p1',
              visibleHexes: {const HexCoordinate(col: 2, row: 3)},
            ),
          },
        ),
        interaction: const GameInteractionState(
          pendingAction: pendingAction,
          moveCommandActive: true,
        ),
      );

      final result = reducer.reduce(state, const TileTappedCommand(2, 3));

      expect(result.state.pendingAction, pendingAction);
      expect(result.state.moveCommandActive, isFalse);
      expect(result.state.selection?.type, GameSelectionType.tile);
      expect(result.state.selection?.tile?.col, 2);
      expect(result.state.selection?.tile?.row, 3);
    });
  });
  // EndTurnCommand

  group('EndTurnCommand', () {
    test('always emits TurnEndedEvent even when no state data changes', () {
      const state = GameState(activePlayerId: 'p1');
      final result = reducer.reduce(state, const EndTurnCommand('p1'));
      final turnEvents = result.events.whereType<TurnEndedEvent>();
      expect(turnEvents, hasLength(1));
      expect(turnEvents.first.playerId, equals('p1'));
    });

    test('adds wealth project gold after project is queued', () {
      final reducer = GameStateReducer(mapData: _landMap());
      final city = _city(id: 'c1', ownerPlayerId: 'p1');
      final state = GameState(
        cities: [city],
        activePlayerId: 'p1',
        playerGold: const {'p1': 5},
      );

      final queued = reducer
          .reduce(
            state,
            const StartCityProjectCommand('c1', CityProjectType.wealth),
          )
          .state;
      final result = reducer.reduce(queued, const EndTurnCommand('p1'));

      expect(result.state.playerGold['p1'], 6);
      expect(
        result.state.cities.single.productionQueue,
        CityProductionQueue.project(projectType: CityProjectType.wealth),
      );
    });

    test(
      'adds research project science to active research after project is queued',
      () {
        final reducer = GameStateReducer(mapData: _landMap());
        final city = _city(id: 'c1', ownerPlayerId: 'p1');
        final state = GameState(
          cities: [city],
          activePlayerId: 'p1',
          research: ResearchState(
            players: {
              'p1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );

        final queued = reducer
            .reduce(
              state,
              const StartCityProjectCommand('c1', CityProjectType.research),
            )
            .state;
        final result = reducer.reduce(queued, const EndTurnCommand('p1'));

        expect(
          result.state.research
              .forPlayer('p1')
              .progressFor(TechnologyId.agriculture),
          3,
        );
        expect(
          result.events.whereType<ResearchPointsGainedEvent>().single.points,
          3,
        );
      },
    );
  });

  group('SubmitTurnCommand', () {
    test('marks player as submitted without ending the turn pipeline', () {
      const state = GameState(activePlayerId: 'p1');

      final result = reducer.reduce(state, const SubmitTurnCommand('p1'));

      expect(result.state.submittedPlayerIds, {'p1'});
      expect(result.events.whereType<TurnEndedEvent>(), isEmpty);
    });

    test('turns off active player actions after submit', () {
      final plan = UnitMovementPlan(
        unitId: 'u1',
        targetCol: 2,
        targetRow: 3,
        totalCost: 1,
        availableMovementPoints: 3,
        steps: const [
          UnitMovementStep(col: 2, row: 3, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final state = const GameState(
        activePlayerId: 'p1',
        activePlayerCanAct: true,
        interaction: GameInteractionState(
          moveCommandActive: true,
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: 'p1',
            attackerUnitId: 'u1',
          ),
        ),
      ).copyWithInteraction(movePreview: plan);

      final result = reducer.reduce(state, const SubmitTurnCommand('p1'));

      expect(result.state.activePlayerCanAct, isFalse);
      expect(result.state.moveCommandActive, isFalse);
      expect(result.state.movePreview, isNull);
      expect(result.state.pendingAction, isNull);
    });

    test('duplicate submit is a no-op', () {
      const state = GameState(activePlayerId: 'p1', submittedPlayerIds: {'p1'});

      final result = reducer.reduce(state, const SubmitTurnCommand('p1'));

      expect(result.state, state);
    });
  });
  // SetActivePlayerCommand

  group('SetActivePlayerCommand', () {
    test('updates activePlayerId and activePlayerCanAct', () {
      const state = GameState(activePlayerId: 'p1', activePlayerCanAct: true);
      final result = reducer.reduce(
        state,
        const SetActivePlayerCommand('p2', canAct: false),
      );
      expect(result.state.activePlayerId, equals('p2'));
      expect(result.state.activePlayerCanAct, isFalse);
    });

    test('clears moveCommandActive', () {
      const state = GameState(
        activePlayerId: 'p1',
        interaction: GameInteractionState(moveCommandActive: true),
      );
      final result = reducer.reduce(
        state,
        const SetActivePlayerCommand('p2', canAct: true),
      );
      expect(result.state.moveCommandActive, isFalse);
    });

    test('clears movePreview', () {
      final plan = UnitMovementPlan(
        unitId: 'u1',
        targetCol: 2,
        targetRow: 3,
        totalCost: 1,
        availableMovementPoints: 3,
        steps: const [
          UnitMovementStep(col: 2, row: 3, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final state = const GameState(
        activePlayerId: 'p1',
      ).copyWithInteraction(movePreview: plan);

      final result = reducer.reduce(
        state,
        const SetActivePlayerCommand('p2', canAct: true),
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
      final state = GameState(
        activePlayerId: 'p1',
        units: [unit],
      ).copyWithInteraction(cityFoundingDraft: draft);

      final result = reducer.reduce(
        state,
        const SetActivePlayerCommand('p2', canAct: true),
      );
      expect(result.state.cityFoundingDraft, isNull);
    });

    test(
      'preserves pendingAction when SetActivePlayer targets same player',
      () {
        const state = GameState(
          activePlayerId: 'p1',
          activePlayerCanAct: true,
          interaction: GameInteractionState(
            pendingAction: PendingAttackTargeting(
              ownerPlayerId: 'p1',
              attackerUnitId: 'u1',
            ),
          ),
        );

        final result = reducer.reduce(
          state,
          const SetActivePlayerCommand('p1', canAct: true),
        );

        expect(result.state.pendingAction, state.pendingAction);
      },
    );

    test(
      'clears unit selection when selected unit is not controllable by new player',
      () {
        final unit = _unit(ownerPlayerId: 'p1');
        final selection = GameSelection.unit(unit);
        final state = GameState(
          activePlayerId: 'p1',
          activePlayerCanAct: true,
          units: [unit],
        ).copyWithInteraction(selection: selection);

        final result = reducer.reduce(
          state,
          const SetActivePlayerCommand('p2', canAct: true),
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
        final state = GameState(
          activePlayerId: 'p1',
          activePlayerCanAct: true,
          cities: [city],
        ).copyWithInteraction(selection: selection);

        final result = reducer.reduce(
          state,
          const SetActivePlayerCommand('p2', canAct: true),
        );
        expect(result.state.selection, isNull);
      },
    );

    test('preserves tile selection when switching player', () {
      final tile = _tile(3, 4);
      final selection = GameSelection.tile(tile);
      final state = const GameState(
        activePlayerId: 'p1',
        activePlayerCanAct: true,
      ).copyWithInteraction(selection: selection);

      final result = reducer.reduce(
        state,
        const SetActivePlayerCommand('p2', canAct: true),
      );
      expect(result.state.selection, isNotNull);
      expect(result.state.selection!.type, equals(GameSelectionType.tile));
    });

    test(
      'preserves unit selection when unit is controllable by new player',
      () {
        final unit = _unit(ownerPlayerId: 'p2');
        final selection = GameSelection.unit(unit);
        final state = GameState(
          activePlayerId: 'p1',
          activePlayerCanAct: true,
          units: [unit],
        ).copyWithInteraction(selection: selection);

        final result = reducer.reduce(
          state,
          const SetActivePlayerCommand('p2', canAct: true),
        );
        expect(result.state.selection, isNotNull);
        expect(result.state.selection!.type, equals(GameSelectionType.unit));
      },
    );

    test('preserves own unit selection when active player starts waiting', () {
      final unit = _unit(ownerPlayerId: 'p1');
      final selection = GameSelection.unit(unit);
      final state = GameState(
        activePlayerId: 'p1',
        activePlayerCanAct: true,
        units: [unit],
      ).copyWithInteraction(selection: selection);

      final result = reducer.reduce(
        state,
        const SetActivePlayerCommand('p1', canAct: false),
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
        final state = GameState(
          activePlayerId: 'p1',
          activePlayerCanAct: true,
          cities: [city],
        ).copyWithInteraction(selection: selection);

        final result = reducer.reduce(
          state,
          const SetActivePlayerCommand('p2', canAct: true),
        );
        expect(result.state.selection, isNotNull);
        expect(result.state.selection!.type, equals(GameSelectionType.city));
      },
    );

    test('returns no UI effects', () {
      const state = GameState(activePlayerId: 'p1');
      final result = reducer.reduce(
        state,
        const SetActivePlayerCommand('p2', canAct: true),
      );
      expect(result.uiEffects, isEmpty);
    });

    test('recomputes fog for the selected active player', () {
      final reducer = GameStateReducer(mapData: _landMap());
      final unit = _unit(ownerPlayerId: 'p2', col: 2, row: 2);
      final state = GameState(activePlayerId: 'p1', units: [unit]);

      final result = reducer.reduce(
        state,
        const SetActivePlayerCommand('p2', canAct: true),
      );

      expect(result.state.activePlayerVisibility.canSeeDynamicAt(2, 2), isTrue);
    });
  });
}
