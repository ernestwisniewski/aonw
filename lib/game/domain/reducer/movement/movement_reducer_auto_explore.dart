part of 'movement_reducer.dart';

abstract final class _AutoExploreProcessor {
  static GameStateTransition run(
    GameState state,
    AutoExploreUnitCommand command,
    MapTraversalView mapView, {
    required GameCommandContext context,
    required FogOfWarService fogOfWarService,
  }) {
    final validation = UnitCommandValidator.autoExplorableScout(
      state,
      unitId: command.unitId,
      context: context,
    );
    if (validation is! ValidUnit) {
      return GameStateTransition(state: state);
    }
    final unit = validation.unit;

    final move = _commandFor(state: state, unit: unit, mapView: mapView);
    if (move == null) return GameStateTransition(state: state);

    final exploring = unit
        .copyWith(posture: UnitPosture.autoExploring)
        .copyWithQueuedPath(null);
    var primed = state
        .copyWith(units: replaceUnit(state.units, exploring))
        .copyWithInteraction(pendingAction: null, cityFoundingDraft: null);
    primed = MovementReducer._clearMoveTargeting(primed);
    if (primed.selectedUnitId == unit.id) {
      primed = MovementReducer._selectUpdatedUnit(primed, exploring, mapView);
    }

    final moved = MovementReducer.moveUnit(
      primed,
      move,
      mapView,
      context: context,
      fogOfWarService: fogOfWarService,
      visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
    );
    return keepPosture(moved, unit.id, mapView);
  }

  static _AutoExploreTurnResult advanceForNewTurn({
    required GameState state,
    required MapTraversalView mapView,
    required String? resetPlayerId,
    required FogOfWarService fogOfWarService,
  }) {
    var current = state;
    final effects = <AnimateUnitMoveEffect>[];
    var changed = false;

    for (var i = 0; i < current.units.length; i++) {
      final unit = current.units[i];
      if (resetPlayerId != null && unit.ownerPlayerId != resetPlayerId) {
        continue;
      }
      if (!unit.isAutoExploring) continue;
      if (unit.movementPoints <= 0 ||
          unit.queuedPath != null ||
          unit.isWorking ||
          unit.isFortified) {
        continue;
      }

      final context = GameCommandContext(actorPlayerId: unit.ownerPlayerId);
      final command = _commandFor(state: current, unit: unit, mapView: mapView);
      if (command == null) continue;

      final moved = MovementReducer.moveUnit(
        current,
        command,
        mapView,
        context: context,
        fogOfWarService: fogOfWarService,
        visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
      );
      final kept = keepPosture(moved, unit.id, mapView);
      current = kept.state;
      effects.addAll(kept.uiEffects.whereType<AnimateUnitMoveEffect>());
      changed = true;
    }

    return _AutoExploreTurnResult(
      units: current.units,
      fogOfWar: current.fogOfWar,
      uiEffects: effects,
      changed: changed,
    );
  }

  static MoveUnitCommand? _commandFor({
    required GameState state,
    required GameUnit unit,
    required MapTraversalView mapView,
  }) {
    return const ScoutAutoExplorePlanner().commandFor(
      unit: unit,
      mapData: mapView,
      units: state.units,
      fogOfWar: state.fogOfWar,
    );
  }

  static GameStateTransition keepPosture(
    GameStateTransition transition,
    String unitId,
    MapTileLookup mapTiles,
  ) {
    final moved = transition.state.unitById(unitId);
    if (moved == null) return transition;

    final exploring = moved.copyWith(posture: UnitPosture.autoExploring);
    var next = transition.state.copyWith(
      units: replaceUnit(transition.state.units, exploring),
    );
    if (next.selectedUnitId == unitId) {
      next = MovementReducer._selectUpdatedUnit(next, exploring, mapTiles);
    }
    return GameStateTransition(
      state: next,
      events: transition.events,
      uiEffects: transition.uiEffects,
    );
  }
}

class _AutoExploreTurnResult {
  final List<GameUnit> units;
  final FogOfWarState fogOfWar;
  final List<AnimateUnitMoveEffect> uiEffects;
  final bool changed;

  const _AutoExploreTurnResult({
    required this.units,
    required this.fogOfWar,
    required this.uiEffects,
    required this.changed,
  });
}
