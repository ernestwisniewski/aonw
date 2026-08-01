import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
  final reducer = GameStateReducer(mapData: _map());
  final resolver = GameIntentResolver(reducer: reducer);

  test('resolves every concrete GameIntent without authoritative mutation', () {
    final state = GameClientState(
      units: [commander],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      interaction: InteractionState(selection: GameSelection.unit(commander)),
    );

    for (final intent in _allIntents) {
      final result = resolver.resolve(state.interaction, intent, state);
      expect(result.interaction, isA<InteractionState>());
      expect(result.presentationFocus, isA<List<UiEffect>>());
    }
  });

  test(
    'toggle changes interaction only and never creates a domain command',
    () {
      final state = GameClientState(
        units: [commander],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        interaction: InteractionState(selection: GameSelection.unit(commander)),
      );

      final result = resolver.resolve(
        state.interaction,
        const ToggleMoveTargetingCommand(),
        state,
      );

      expect(result.interaction.moveCommandActive, isTrue);
      expect(result.domainCommand, isNull);
      expect(result.presentationFocus, isEmpty);
      expect(state.moveCommandActive, isFalse);
    },
  );

  test('no-op intent preserves the interaction identity', () {
    final state = GameClientState();

    final result = resolver.resolve(
      state.interaction,
      const CancelCityFoundingCommand(),
      state,
    );

    expect(result.interaction, same(state.interaction));
    expect(result.domainCommand, isNull);
    expect(result.presentationFocus, isEmpty);
  });

  test('tile confirmation returns a DomainCommand without applying it', () {
    final preview = UnitMovementPlan(
      unitId: commander.id,
      targetCol: 1,
      targetRow: 0,
      totalCost: 1,
      availableMovementPoints: commander.movementPoints,
      steps: const [
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ],
    );
    final state = GameClientState(
      units: [commander],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      interaction: InteractionState(
        selection: GameSelection.unit(commander),
        moveCommandActive: true,
        movePreview: preview,
      ),
    );

    final result = resolver.resolve(
      state.interaction,
      const TileTappedCommand(1, 0),
      state,
    );

    expect(result.domainCommand, MoveUnitCommand(commander.id, 1, 0));
    expect(state.units.single.col, 0);
    expect(state.movePreview, same(preview));
  });

  test('tapping another route step retargets instead of confirming', () {
    final movingCommander = commander.copyWith(movementPoints: 1);
    final preview = UnitMovementPlan(
      unitId: movingCommander.id,
      targetCol: 3,
      targetRow: 0,
      totalCost: 3,
      availableMovementPoints: movingCommander.movementPoints,
      steps: const [
        UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
        UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
      ],
    );
    final state = GameClientState(
      units: [movingCommander],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      interaction: InteractionState(
        selection: GameSelection.unit(movingCommander),
        moveCommandActive: true,
        movePreview: preview,
      ),
    );
    final wideResolver = GameIntentResolver(
      reducer: GameStateReducer(mapData: _map(cols: 4, rows: 1)),
    );

    final result = wideResolver.resolve(
      state.interaction,
      const TileTappedCommand(2, 0),
      state,
    );

    expect(result.domainCommand, isNull);
    expect(result.interaction.movePreview?.targetCol, 2);
    expect(result.interaction.movePreview?.targetRow, 0);
    expect(state.movePreview, same(preview));
  });
}

const _allIntents = <GameIntent>[
  TileTappedCommand(0, 0),
  CityTappedCommand('city'),
  SelectTileCommand(0, 0),
  SelectUnitCommand('unit'),
  SelectCityCommand('city'),
  FocusNextPendingActionCommand('player_1'),
  FocusTurnStartActionCommand('player_1'),
  StartAttackTargetingCommand('unit'),
  CancelAttackTargetingCommand('unit'),
  CancelResearchSelectionCommand('player_1'),
  StartMerchantTradeRouteSelectionCommand('unit'),
  CancelMerchantTradeRouteSelectionCommand('unit'),
  StartMerchantMoveToCitySelectionCommand('unit'),
  CancelMerchantMoveToCitySelectionCommand('unit'),
  ToggleMoveTargetingCommand(),
  StartCommanderMergeSelectionCommand('unit'),
  CancelCommanderMergeSelectionCommand('unit'),
  StartCityFoundingCommand(),
  CancelCityFoundingCommand(),
  StartCityWorkedHexSelectionCommand('city'),
  CancelCityWorkedHexSelectionCommand('city'),
  StartCityExpansionSelectionCommand('city'),
  CancelCityExpansionSelectionCommand('city'),
  StartWorkerActionSelectionCommand('unit'),
  CancelWorkerActionSelectionCommand('unit'),
];

WorldMap _map({int cols = 2, int rows = 2}) => WorldMap(
  cols: cols,
  rows: rows,
  tiles: [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);
