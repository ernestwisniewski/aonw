part of 'movement_reducer.dart';

abstract final class _DirectMoveProcessor {
  static GameStateTransition run(
    GameState state,
    MoveUnitCommand command,
    MapTraversalView mapView, {
    required GameCommandContext context,
    required FogOfWarService fogOfWarService,
    required MovementCommandVisibilityMode visibilityMode,
  }) {
    final unit = state.unitById(command.unitId);
    final input = MovementCommandState(
      units: state.units,
      cities: state.cities,
      fogOfWar: state.fogOfWar,
      diplomacy: state.diplomacy,
      playerIds: knownPlayerIds(state),
    );
    final result = MovementCommandResolver(fogOfWarService: fogOfWarService)
        .resolve(
          state: input,
          command: command,
          actorPlayerId: _actorPlayerId(state, unit, context),
          mapData: mapView,
          canAct: _canAct(state, context),
          visibilityMode: _visibilityMode(state, context, visibilityMode),
        );
    if (!result.accepted) {
      return result.reason == 'unit_movement_capacity_insufficient'
          ? _insufficientMovement(state)
          : GameStateTransition(state: state);
    }
    if (_keepsAllStateSlices(input, result)) {
      return GameStateTransition(state: state);
    }
    return _projectAcceptedResult(state, command.unitId, result, mapView);
  }

  static String _actorPlayerId(
    GameState state,
    GameUnit? unit,
    GameCommandContext context,
  ) {
    if (context.hasActor) return context.actorPlayerId!;
    if (state.activePlayerId.isNotEmpty) return state.activePlayerId;
    return unit?.ownerPlayerId ?? '';
  }

  static bool _canAct(GameState state, GameCommandContext context) {
    if (!context.canAct) return false;
    return context.hasActor || state.activePlayerCanAct;
  }

  static MovementCommandVisibilityMode _visibilityMode(
    GameState state,
    GameCommandContext context,
    MovementCommandVisibilityMode requested,
  ) {
    if (requested != MovementCommandVisibilityMode.authoritative) {
      return requested;
    }
    if (context.ignoreFogOfWar ||
        !context.hasActor && state.activePlayerId.isEmpty) {
      return MovementCommandVisibilityMode.unrestricted;
    }
    return requested;
  }

  static bool _keepsAllStateSlices(
    MovementCommandState input,
    MovementCommandResult result,
  ) {
    return identical(result.units, input.units) &&
        identical(result.fogOfWar, input.fogOfWar) &&
        identical(result.diplomacy, input.diplomacy);
  }

  static GameStateTransition _projectAcceptedResult(
    GameState state,
    String unitId,
    MovementCommandResult result,
    MapTileLookup mapTiles,
  ) {
    var next = state
        .copyWith(
          units: result.units,
          fogOfWar: result.fogOfWar,
          diplomacy: result.diplomacy,
        )
        .copyWithInteraction(movePreview: null);
    final updatedUnit = result.units.byId(unitId);
    if (updatedUnit != null && state.selectedUnitId == unitId) {
      next = MovementReducer._selectUpdatedUnit(next, updatedUnit, mapTiles);
    }

    final execution = result.execution;
    return GameStateTransition(
      state: next,
      events: result.events,
      uiEffects: [
        if (execution != null)
          AnimateUnitMoveEffect(
            unitId: execution.unitId,
            fromCol: execution.fromCol,
            fromRow: execution.fromRow,
            steps: execution.steps,
          ),
      ],
    );
  }

  static GameStateTransition _insufficientMovement(GameState state) {
    return GameStateTransition(
      state: state,
      uiEffects: const [
        ShowHudFeedbackEffect(
          reason: HudFeedbackReason.movementInsufficientUnitMovement,
        ),
      ],
    );
  }
}
