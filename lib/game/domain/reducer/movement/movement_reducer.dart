import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_auto_explore_advancer.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

part 'movement_reducer_auto_explore.dart';
part 'movement_reducer_move_preview.dart';
part 'movement_selection_projector.dart';
part 'movement_reducer_turn_reset.dart';

abstract final class MovementReducer {
  static GameState toggleMoveTargetingWithEnvironment(
    GameState state,
    ReducerEnvironment environment,
  ) {
    return toggleMoveTargeting(state, context: environment.context);
  }

  static GameStateTransition handleMoveTargetTileWithEnvironment(
    GameState state,
    MapTileView targetTile,
    ReducerEnvironment environment,
  ) {
    return handleMoveTargetTile(
      state,
      targetTile,
      environment.mapData,
      context: environment.context,
      fogOfWarService: environment.fogOfWarService,
    );
  }

  static GameStateTransition resetUnitMovementForNewTurnWithEnvironment(
    GameState state,
    ReducerEnvironment environment, {
    String? playerId,
  }) {
    return resetUnitMovementForNewTurn(
      state,
      environment.mapData,
      playerId: playerId,
      fogOfWarService: environment.fogOfWarService,
    );
  }

  /// Toggles move-command mode for the currently selected unit.
  static GameState toggleMoveTargeting(
    GameState state, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final selected = state.selectedUnit;

    if (selected == null || !context.canControlUnit(state, selected)) {
      return _clearMoveTargeting(state);
    }
    if (selected.isWorking ||
        selected.isFortified ||
        selected.type == GameUnitType.merchant) {
      return _clearMoveTargeting(state);
    }

    if (state.moveCommandActive) {
      return _clearMoveTargeting(state);
    }

    return _startMoveTargeting(state);
  }

  /// Handles a tile tap while move mode is active.
  static GameStateTransition handleMoveTargetTile(
    GameState state,
    MapTileView targetTile,
    MapTraversalView mapView, {
    GameCommandContext context = const GameCommandContext(),
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    final selected = state.selectedUnit;
    if (selected == null || !context.canControlUnit(state, selected)) {
      return GameStateTransition(state: _clearMoveTargeting(state));
    }
    if (selected.isMerchant) {
      return GameStateTransition(state: _clearMoveTargeting(state));
    }

    if (selected.occupies(targetTile.col, targetTile.row)) {
      var next = _clearMoveTargeting(state);
      next = _selectUpdatedUnit(next, selected, mapView);
      return GameStateTransition(state: next);
    }

    final preview = state.movePreview;

    final isConfirmation =
        preview != null &&
        preview.unitId == selected.id &&
        preview.targetCol == targetTile.col &&
        preview.targetRow == targetTile.row;

    if (isConfirmation) {
      return _MovePreviewReducer.confirmPreview(
        state,
        mapView,
        context: context,
        fogOfWarService: fogOfWarService,
      );
    }

    return _MovePreviewReducer.setPreview(
      state,
      selected,
      targetTile,
      mapView,
      context: context,
    );
  }

  /// Resets MP for a player's units and processes queued paths.
  static GameStateTransition resetUnitMovementForNewTurn(
    GameState state,
    MapTraversalView mapView, {
    String? playerId,
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    return _MovementTurnResetProcessor.run(
      state,
      mapView,
      playerId: playerId,
      fogOfWarService: fogOfWarService,
    );
  }

  static bool _blocksForeignCityCenter(
    GameState state,
    GameUnit unit,
    int col,
    int row,
  ) {
    return CityEntryPolicy.blocksCityCenterEntry(
      diplomacy: state.diplomacy,
      cities: state.cities,
      unitOwnerPlayerId: unit.ownerPlayerId,
      col: col,
      row: row,
    );
  }

  static bool _canCarryArtifactIntoTargetCity({
    required GameState state,
    required GameUnit unit,
    required MapTileView targetTile,
    required UnitMovementStep step,
  }) {
    if (unit.carriedArtifactId == null) return false;
    if (step.col != targetTile.col || step.row != targetTile.row) {
      return false;
    }
    final city = state.cityAt(step.col, step.row);
    return city?.ownerPlayerId == unit.ownerPlayerId;
  }

  static bool _canAutoActivateMoveTargeting(GameState state, GameUnit unit) {
    return state.canControlUnit(unit) &&
        !unit.isWorking &&
        !unit.isMerchant &&
        unit.queuedPath == null &&
        !unit.isFortified &&
        !unit.isAutoExploring;
  }

  static GameState _clearMoveTargeting(GameState state) {
    return state.copyWithInteraction(
      moveCommandActive: false,
      movePreview: null,
    );
  }

  static GameState _selectUpdatedUnit(
    GameState state,
    GameUnit unit,
    MapTileLookup mapTiles,
  ) {
    return state.copyWithInteraction(
      selection: _MoveSelection.forUnit(state, unit, mapTiles),
    );
  }
}

GameState _startMoveTargeting(GameState state) {
  return state.copyWith(
    interaction: state.interaction
        .clearMapState(clearPendingAction: true)
        .copyWith(moveCommandActive: true),
  );
}
