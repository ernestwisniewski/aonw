part of 'movement_reducer.dart';

abstract final class _AutoExploreProcessor {
  static GameStateTransition run(
    GameState state,
    AutoExploreUnitCommand command,
    MapData mapData, {
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

    final move = _commandFor(state: state, unit: unit, mapData: mapData);
    if (move == null) return GameStateTransition(state: state);

    final exploring = unit
        .copyWith(posture: UnitPosture.autoExploring)
        .copyWithQueuedPath(null);
    var primed = state.copyWith(
      units: replaceUnit(state.units, exploring),
      pendingAction: null,
      cityFoundingDraft: null,
    );
    primed = MovementReducer._clearMoveTargeting(primed);
    if (primed.selectedUnitId == unit.id) {
      primed = MovementReducer._selectUpdatedUnit(primed, exploring, mapData);
    }

    final moved = MovementReducer.moveUnit(
      primed,
      move,
      mapData,
      context: context,
      fogOfWarService: fogOfWarService,
      canEnterTile: (_) => true,
    );
    return keepPosture(moved, unit.id, mapData);
  }

  static _AutoExploreTurnResult advanceForNewTurn({
    required GameState state,
    required MapData mapData,
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
      final command = _commandFor(state: current, unit: unit, mapData: mapData);
      if (command == null) continue;

      final moved = MovementReducer.moveUnit(
        current,
        command,
        mapData,
        context: context,
        fogOfWarService: fogOfWarService,
        canEnterTile: (_) => true,
      );
      final kept = keepPosture(moved, unit.id, mapData);
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
    required MapData mapData,
  }) {
    return const ScoutAutoExplorePlanner().commandFor(
      unit: unit,
      mapData: mapData,
      units: state.units,
      fogOfWar: state.fogOfWar,
    );
  }

  static GameStateTransition keepPosture(
    GameStateTransition transition,
    String unitId,
    MapData mapData,
  ) {
    final moved = MovementReducer._unitById(transition.state.units, unitId);
    if (moved == null) return transition;

    final exploring = moved.copyWith(posture: UnitPosture.autoExploring);
    var next = transition.state.copyWith(
      units: replaceUnit(transition.state.units, exploring),
    );
    if (next.selectedUnitId == unitId) {
      next = MovementReducer._selectUpdatedUnit(next, exploring, mapData);
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
