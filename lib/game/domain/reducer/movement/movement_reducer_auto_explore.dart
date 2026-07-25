part of 'movement_reducer.dart';

abstract final class _AutoExploreProcessor {
  static GameStateTransition run(
    GameState state,
    AutoExploreUnitCommand command,
    MapTraversalView mapView, {
    required GameCommandContext context,
    required FogOfWarService fogOfWarService,
  }) {
    final unit = state.unitById(command.unitId);
    final result = AutoExploreCommandResolver(fogOfWarService: fogOfWarService)
        .resolve(
          state: AutoExploreCommandState(
            movement: MovementCommandState(
              units: state.units,
              cities: state.cities,
              fogOfWar: state.fogOfWar,
              diplomacy: state.diplomacy,
              playerIds: knownPlayerIds(state),
            ),
            interaction: _persistedUnitActionInteraction(state),
          ),
          command: command,
          actorPlayerId: _DirectMoveProcessor._actorPlayerId(
            state,
            unit,
            context,
          ),
          mapData: mapView,
          phase: AutoExploreCommandPhase.direct,
          canAct: _DirectMoveProcessor._canAct(state, context),
        );
    if (!result.accepted) return GameStateTransition(state: state);
    return _projectAcceptedResult(state, command.unitId, result, mapView);
  }

  static GameStateTransition _projectAcceptedResult(
    GameState state,
    String unitId,
    AutoExploreCommandResult result,
    MapTileLookup mapTiles,
  ) {
    final originalDraft = state.cityFoundingDraft;
    final resultDraft = result.interaction.cityFoundingDraft;
    var next = state
        .copyWith(
          units: result.units,
          fogOfWar: result.fogOfWar,
          diplomacy: result.diplomacy,
        )
        .copyWithInteraction(
          cityFoundingDraft: originalDraft == resultDraft
              ? originalDraft
              : resultDraft,
          pendingAction: result.interaction.pendingAction,
          moveCommandActive: false,
          movePreview: null,
        );
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

  static TurnAutoExploreAdvance advanceForNewTurn({
    required GameState state,
    required MapTraversalView mapView,
    required String? resetPlayerId,
    required FogOfWarService fogOfWarService,
  }) {
    final playerIds = resetPlayerId == null
        ? knownPlayerIds(state)
        : {resetPlayerId};
    return TurnAutoExploreAdvancer.advance(
      units: state.units,
      cities: state.cities,
      diplomacy: state.diplomacy,
      fogOfWar: state.fogOfWar,
      interaction: _persistedUnitActionInteraction(state),
      playerIds: playerIds,
      phaseKnownPlayerIds: knownPlayerIds(state),
      mapData: mapView,
      fogOfWarService: fogOfWarService,
    );
  }
}
