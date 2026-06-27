import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class PersistentUnitActionResult {
  const PersistentUnitActionResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final String? reason;
}

class PersistentUnitActionResolver {
  const PersistentUnitActionResolver();

  PersistentUnitActionResult cancelUnitAction({
    required PersistentGameState state,
    required CancelUnitActionCommand command,
    required String actorPlayerId,
  }) {
    final unit = state.units.byId(command.unitId);
    if (unit == null) return _reject(state, 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'unit_not_controlled');
    }

    final pendingTurnSkip =
        state.runtimeState.pendingAction is PendingUnitTurnSkip
        ? state.runtimeState.pendingAction as PendingUnitTurnSkip
        : null;
    final restoreMovementPoints = pendingTurnSkip?.unitId == unit.id
        ? pendingTurnSkip!.restoreMovementPoints
        : null;
    final nextMovementPoints =
        restoreMovementPoints ??
        (unit.isFortified
            ? UnitMovementBalance.maxMovementPointsFor(
                type: unit.type,
                carriedArtifactId: unit.carriedArtifactId,
              )
            : unit.movementPoints);
    final updatedUnit = unit
        .copyWith(movementPoints: nextMovementPoints)
        .copyWithQueuedPath(null)
        .copyWithWorkerJob(null)
        .copyWithWorkerAssignment(null)
        .copyWithExcavatingArtifact(null)
        .copyWithPosture(UnitPosture.active);
    final artifacts = _cancelArtifactExcavation(state.artifacts, unit);
    final next = _replaceUnitAndClearRuntimeAction(
      state,
      unit,
      updatedUnit,
    ).copyWith(artifacts: artifacts);
    return PersistentUnitActionResult(accepted: true, state: next);
  }

  PersistentUnitActionResult skipUnitTurn({
    required PersistentGameState state,
    required SkipUnitTurnCommand command,
    required String actorPlayerId,
  }) {
    final unit = state.units.byId(command.unitId);
    if (unit == null) return _reject(state, 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'unit_not_controlled');
    }

    final updatedUnit = unit
        .copyWith(movementPoints: 0)
        .copyWithQueuedPath(null)
        .copyWithPosture(UnitPosture.active);
    return PersistentUnitActionResult(
      accepted: true,
      state: _replaceUnitAndSetTurnSkipAction(state, unit, updatedUnit),
    );
  }

  PersistentUnitActionResult fortifyUnit({
    required PersistentGameState state,
    required FortifyUnitCommand command,
    required String actorPlayerId,
  }) {
    final unit = state.units.byId(command.unitId);
    if (unit == null) return _reject(state, 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'unit_not_controlled');
    }
    if (unit.isWorking) return _reject(state, 'unit_busy');
    final updatedUnit = UnitFortificationRules.fortify(unit);
    return PersistentUnitActionResult(
      accepted: true,
      state: _replaceUnitAndClearRuntimeAction(state, unit, updatedUnit),
    );
  }

  PersistentUnitActionResult autoExploreUnit({
    required PersistentGameState state,
    required AutoExploreUnitCommand command,
    required String actorPlayerId,
    required MapDefinition mapDefinition,
  }) {
    final unit = state.units.byId(command.unitId);
    if (unit == null) return _reject(state, 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'unit_not_controlled');
    }
    if (unit.type != GameUnitType.scout) {
      return _reject(state, 'unit_not_scout');
    }
    if (unit.isWorking || unit.isFortified) return _reject(state, 'unit_busy');
    if (unit.movementPoints <= 0) return _reject(state, 'unit_exhausted');
    if (unit.queuedPath != null) return _reject(state, 'unit_has_path');

    final mapData = _mapDataFromDefinition(mapDefinition);
    final move = const ScoutAutoExplorePlanner().commandFor(
      unit: unit,
      mapData: mapData,
      units: state.units,
      fogOfWar: state.fogOfWar,
    );
    if (move == null) return _reject(state, 'auto_explore_no_target');

    final exploring = unit
        .copyWith(posture: UnitPosture.autoExploring)
        .copyWithQueuedPath(null);
    final primed = _replaceUnitAndClearRuntimeAction(state, unit, exploring);
    final moved = const PersistentMoveUnitResolver().resolve(
      state: primed,
      command: move,
      actorPlayerId: actorPlayerId,
      mapDefinition: mapDefinition,
    );
    if (!moved.accepted) return _reject(state, moved.reason ?? 'move_failed');

    final movedUnit = moved.state.units.byId(unit.id);
    if (movedUnit == null) return _reject(state, 'unit_not_found');
    return PersistentUnitActionResult(
      accepted: true,
      state: moved.state.copyWith(
        units: _replaceUnit(
          moved.state.units,
          movedUnit.copyWith(posture: UnitPosture.autoExploring),
        ),
      ),
    );
  }

  PersistentUnitActionResult _reject(PersistentGameState state, String reason) {
    return PersistentUnitActionResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  static PersistentGameState _replaceUnitAndClearRuntimeAction(
    PersistentGameState state,
    GameUnit original,
    GameUnit updated,
  ) {
    final runtimeState = _clearRuntimeActionForUnit(
      state.runtimeState,
      original.id,
    );
    return state.copyWith(
      units: _replaceUnit(state.units, updated),
      runtimeState: runtimeState,
    );
  }

  static PersistentGameState _replaceUnitAndSetTurnSkipAction(
    PersistentGameState state,
    GameUnit original,
    GameUnit updated,
  ) {
    return state.copyWith(
      units: _replaceUnit(state.units, updated),
      runtimeState: GameRuntimeState(
        cityFoundingDraft:
            state.runtimeState.cityFoundingDraft?.unitId == original.id
            ? null
            : state.runtimeState.cityFoundingDraft,
        pendingAction: PendingUnitTurnSkip(
          ownerPlayerId: original.ownerPlayerId,
          unitId: original.id,
          restoreMovementPoints: original.movementPoints,
        ),
        submittedPlayerIds: state.runtimeState.submittedPlayerIds,
        timeoutStreaksByPlayerId: state.runtimeState.timeoutStreaksByPlayerId,
        afkPlayerIds: state.runtimeState.afkPlayerIds,
        kickedPlayerIds: state.runtimeState.kickedPlayerIds,
        intendedAttacks: state.runtimeState.intendedAttacks,
        diplomacy: state.runtimeState.diplomacy,
        dominationHoldTurnsByPlayerId:
            state.runtimeState.dominationHoldTurnsByPlayerId,
        culturalVictoryHoldTurnsByPlayerId:
            state.runtimeState.culturalVictoryHoldTurnsByPlayerId,
        turnStartedAt: state.runtimeState.turnStartedAt,
      ),
    );
  }

  static GameRuntimeState _clearRuntimeActionForUnit(
    GameRuntimeState runtimeState,
    String unitId,
  ) {
    final clearPending = runtimeState.pendingAction?.ownsUnit(unitId) ?? false;
    final clearDraft = runtimeState.cityFoundingDraft?.unitId == unitId;
    if (!clearPending && !clearDraft) return runtimeState;

    return GameRuntimeState(
      cityFoundingDraft: clearDraft ? null : runtimeState.cityFoundingDraft,
      pendingAction: clearPending ? null : runtimeState.pendingAction,
      submittedPlayerIds: runtimeState.submittedPlayerIds,
      timeoutStreaksByPlayerId: runtimeState.timeoutStreaksByPlayerId,
      afkPlayerIds: runtimeState.afkPlayerIds,
      kickedPlayerIds: runtimeState.kickedPlayerIds,
      intendedAttacks: runtimeState.intendedAttacks,
      diplomacy: runtimeState.diplomacy,
      dominationHoldTurnsByPlayerId: runtimeState.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          runtimeState.culturalVictoryHoldTurnsByPlayerId,
      turnStartedAt: runtimeState.turnStartedAt,
    );
  }

  static List<GameUnit> _replaceUnit(List<GameUnit> units, GameUnit updated) {
    return [
      for (final unit in units)
        if (unit.id == updated.id) updated else unit,
    ];
  }

  static List<WorldArtifact> _cancelArtifactExcavation(
    List<WorldArtifact> artifacts,
    GameUnit unit,
  ) {
    final artifactId = unit.excavatingArtifactId;
    if (artifactId == null) return artifacts;
    return [
      for (final artifact in artifacts)
        if (artifact.id == artifactId && artifact.location.isBeingExcavated)
          artifact.copyWith(
            location: WorldArtifactLocation.map(
              col: artifact.location.col ?? unit.col,
              row: artifact.location.row ?? unit.row,
            ),
          )
        else
          artifact,
    ];
  }

  static MapData _mapDataFromDefinition(MapDefinition mapDefinition) {
    return MapData(
      cols: mapDefinition.cols,
      rows: mapDefinition.rows,
      mapName: mapDefinition.mapName,
      defaultZoom: mapDefinition.defaultZoom,
      tiles: [
        for (final tile in mapDefinition.tiles)
          TileData(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
  }
}
