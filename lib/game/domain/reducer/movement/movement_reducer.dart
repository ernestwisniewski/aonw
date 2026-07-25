import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw/game/domain/reducer/unit/unit_command_validator.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_auto_explore_advancer.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

part 'movement_reducer_auto_explore.dart';
part 'movement_reducer_direct_move.dart';
part 'movement_reducer_move_preview.dart';
part 'movement_selection_projector.dart';
part 'movement_reducer_turn_reset.dart';
part 'movement_reducer_unit_action_state.dart';

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

  static GameStateTransition moveUnitWithEnvironment(
    GameState state,
    MoveUnitCommand command,
    ReducerEnvironment environment,
  ) {
    return moveUnit(
      state,
      command,
      environment.mapData,
      context: environment.context,
      fogOfWarService: environment.fogOfWarService,
    );
  }

  static GameStateTransition cancelUnitActionWithEnvironment(
    GameState state,
    CancelUnitActionCommand command,
    ReducerEnvironment environment,
  ) {
    return cancelUnitAction(
      state,
      command,
      environment.mapData,
      context: environment.context,
    );
  }

  static GameStateTransition skipUnitTurnWithEnvironment(
    GameState state,
    SkipUnitTurnCommand command,
    ReducerEnvironment environment,
  ) {
    return skipUnitTurn(
      state,
      command,
      environment.mapData,
      context: environment.context,
    );
  }

  static GameStateTransition fortifyUnitWithEnvironment(
    GameState state,
    FortifyUnitCommand command,
    ReducerEnvironment environment,
  ) {
    return fortifyUnit(
      state,
      command,
      environment.mapData,
      context: environment.context,
    );
  }

  static GameStateTransition autoExploreUnitWithEnvironment(
    GameState state,
    AutoExploreUnitCommand command,
    ReducerEnvironment environment,
  ) {
    return autoExploreUnit(
      state,
      command,
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
    final isUnreachableConfirm =
        preview != null &&
        preview.unitId == selected.id &&
        preview.isStepUnreachableThisTurn(targetTile.col, targetTile.row);

    if (isConfirmation || isUnreachableConfirm) {
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

  /// Applies an explicit movement command without relying on presentation
  /// selection state or the two-tap move preview flow.
  static GameStateTransition moveUnit(
    GameState state,
    MoveUnitCommand command,
    MapTraversalView mapView, {
    GameCommandContext context = const GameCommandContext(),
    FogOfWarService fogOfWarService = const FogOfWarService(),
    MovementCommandVisibilityMode visibilityMode =
        MovementCommandVisibilityMode.authoritative,
  }) {
    return _DirectMoveProcessor.run(
      state,
      command,
      mapView,
      context: context,
      fogOfWarService: fogOfWarService,
      visibilityMode: visibilityMode,
    );
  }

  /// Cancels transient action state owned by a unit: movement plans, worker
  /// work, worker assignment, city founding draft, and unit-targeted modes.
  static GameStateTransition cancelUnitAction(
    GameState state,
    CancelUnitActionCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final validation = UnitCommandValidator.controllableUnit(
      state,
      unitId: command.unitId,
      context: context,
    );
    if (validation is! ValidUnit) return GameStateTransition(state: state);
    final unit = validation.unit;
    final wasFortified = unit.isFortified;
    final input = _captureUnitActionInput(state);
    final result = UnitActionCommandResolver.cancelUnitAction(
      units: input.units,
      artifacts: input.artifacts,
      interaction: _persistedUnitActionInteraction(state),
      command: command,
      actorPlayerId: unit.ownerPlayerId,
    );
    if (!result.accepted) return GameStateTransition(state: state);
    final updatedUnit = result.units.byId(unit.id)!;
    final cleanup =
        _UnitActionStateCleanup(
            _applyUnitActionResult(state, result, input),
            unit,
            updatedUnit,
            mapTiles,
          )
          ..clearMoveTargetingOwnedByUnit()
          ..refreshSelection()
          ..activateMoveTargetingWhenReady(wasFortified);

    return GameStateTransition(state: cleanup.state);
  }

  /// Skips a unit for the current turn without preventing manual reselection.
  static GameStateTransition skipUnitTurn(
    GameState state,
    SkipUnitTurnCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final validation = UnitCommandValidator.controllableUnit(
      state,
      unitId: command.unitId,
      context: context,
    );
    if (validation is! ValidUnit) return GameStateTransition(state: state);
    final unit = validation.unit;
    final input = _captureUnitActionInput(state);
    final result = UnitActionCommandResolver.skipUnitTurn(
      units: input.units,
      artifacts: input.artifacts,
      interaction: _persistedUnitActionInteraction(state),
      command: command,
      actorPlayerId: unit.ownerPlayerId,
    );
    if (!result.accepted) return GameStateTransition(state: state);
    final updatedUnit = result.units.byId(unit.id)!;
    final cleanup =
        _UnitActionStateCleanup(
            _applyUnitActionResult(state, result, input),
            unit,
            updatedUnit,
            mapTiles,
          )
          ..clearMoveTargetingOwnedByUnit()
          ..refreshSelection();

    return GameStateTransition(state: cleanup.state);
  }

  static GameStateTransition fortifyUnit(
    GameState state,
    FortifyUnitCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final validation = UnitCommandValidator.controllableUnit(
      state,
      unitId: command.unitId,
      context: context,
    );
    if (validation is! ValidUnit) return GameStateTransition(state: state);
    final unit = validation.unit;
    final input = _captureUnitActionInput(state);
    final result = UnitActionCommandResolver.fortifyUnit(
      units: input.units,
      artifacts: input.artifacts,
      interaction: _persistedUnitActionInteraction(state),
      command: command,
      actorPlayerId: unit.ownerPlayerId,
    );
    if (!result.accepted) return GameStateTransition(state: state);
    final updatedUnit = result.units.byId(unit.id)!;
    final cleanup =
        _UnitActionStateCleanup(
            _applyUnitActionResult(state, result, input),
            unit,
            updatedUnit,
            mapTiles,
          )
          ..clearMoveTargetingOwnedByUnit()
          ..refreshSelection();

    return GameStateTransition(state: cleanup.state);
  }

  static GameStateTransition autoExploreUnit(
    GameState state,
    AutoExploreUnitCommand command,
    MapTraversalView mapView, {
    GameCommandContext context = const GameCommandContext(),
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    return _AutoExploreProcessor.run(
      state,
      command,
      mapView,
      context: context,
      fogOfWarService: fogOfWarService,
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

  static bool _moveStateBelongsToUnit(GameState state, String unitId) {
    return state.selectedUnitId == unitId ||
        state.movePreview?.unitId == unitId;
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
