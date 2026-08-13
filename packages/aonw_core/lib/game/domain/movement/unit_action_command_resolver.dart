import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/movement/unit_manual_movement_rules.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/state/domain_action_unit_rules.dart';
import 'package:aonw_core/game/domain/unit.dart';

/// Persistence-neutral result of a unit action command.
///
/// Inputs are immutable state-boundary snapshots. Changed collections are
/// owned and unmodifiable; unchanged collections retain their input identity.
final class UnitActionCommandResult {
  const UnitActionCommandResult._accepted({
    required this.units,
    required this.artifacts,
    required this.interaction,
  }) : accepted = true,
       reason = null;

  const UnitActionCommandResult._rejected({
    required this.units,
    required this.artifacts,
    required this.interaction,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final List<GameUnit> units;
  final List<WorldArtifact> artifacts;
  final DomainActionState interaction;
}

/// Applies map-independent unit actions without depending on a state container.
abstract final class UnitActionCommandResolver {
  static UnitActionCommandResult cancelUnitAction({
    required List<GameUnit> units,
    required List<WorldArtifact> artifacts,
    required DomainActionState interaction,
    required CancelUnitActionCommand command,
    required String actorPlayerId,
  }) {
    final controlled = _controlledUnit(units, command.unitId, actorPlayerId);
    if (controlled.reason case final reason?) {
      return _reject(units, artifacts, interaction, reason);
    }
    final unit = controlled.unit!;
    final pendingTurnSkip = interaction.pendingAction is PendingUnitTurnSkip
        ? interaction.pendingAction as PendingUnitTurnSkip
        : null;
    final restoreMovementUnits = pendingTurnSkip?.unitId == unit.id
        ? pendingTurnSkip!.restoreMovementUnits
        : null;
    final nextMovementUnits =
        restoreMovementUnits ??
        UnitManualMovementRules.availableMovementUnits(unit);
    final updatedUnit = unit
        .copyWithMovementUnits(nextMovementUnits)
        .copyWithQueuedPath(null)
        .copyWithWorkerJob(null)
        .copyWithCityFoundingJob(null)
        .copyWithWorkerAssignment(null)
        .copyWithExcavatingArtifact(null)
        .copyWithMerchantTradeRoute(null)
        .copyWithPosture(UnitPosture.active);

    return UnitActionCommandResult._accepted(
      units: _replaceUnit(units, updatedUnit),
      artifacts: _cancelArtifactExcavation(artifacts, unit),
      interaction: DomainActionUnitRules.clearOwnedByUnit(interaction, unit.id),
    );
  }

  static UnitActionCommandResult skipUnitTurn({
    required List<GameUnit> units,
    required List<WorldArtifact> artifacts,
    required DomainActionState interaction,
    required SkipUnitTurnCommand command,
    required String actorPlayerId,
  }) {
    final controlled = _controlledUnit(units, command.unitId, actorPlayerId);
    if (controlled.reason case final reason?) {
      return _reject(units, artifacts, interaction, reason);
    }
    final unit = controlled.unit!;
    final updatedUnit = unit
        .copyWith(movementPoints: 0)
        .copyWithQueuedPath(null)
        .copyWithPosture(UnitPosture.active);
    final updatedInteraction = interaction.copyWith(
      cityFoundingDraft: interaction.cityFoundingDraft?.unitId == unit.id
          ? null
          : interaction.cityFoundingDraft,
      pendingAction: PendingUnitTurnSkip(
        ownerPlayerId: unit.ownerPlayerId,
        unitId: unit.id,
        restoreMovementUnits: unit.movementUnits,
      ),
    );

    return UnitActionCommandResult._accepted(
      units: _replaceUnit(units, updatedUnit),
      artifacts: artifacts,
      interaction: updatedInteraction == interaction
          ? interaction
          : updatedInteraction,
    );
  }

  static UnitActionCommandResult fortifyUnit({
    required List<GameUnit> units,
    required List<WorldArtifact> artifacts,
    required DomainActionState interaction,
    required FortifyUnitCommand command,
    required String actorPlayerId,
  }) {
    final controlled = _controlledUnit(units, command.unitId, actorPlayerId);
    if (controlled.reason case final reason?) {
      return _reject(units, artifacts, interaction, reason);
    }
    final unit = controlled.unit!;
    if (unit.isWorking) {
      return _reject(units, artifacts, interaction, 'unit_busy');
    }

    return UnitActionCommandResult._accepted(
      units: _replaceUnit(units, UnitFortificationRules.fortify(unit)),
      artifacts: artifacts,
      interaction: DomainActionUnitRules.clearOwnedByUnit(interaction, unit.id),
    );
  }

  static _ControlledUnit _controlledUnit(
    List<GameUnit> units,
    String unitId,
    String actorPlayerId,
  ) {
    final unit = units.byId(unitId);
    if (unit == null) return (unit: null, reason: 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return (unit: null, reason: 'unit_not_controlled');
    }
    return (unit: unit, reason: null);
  }

  static UnitActionCommandResult _reject(
    List<GameUnit> units,
    List<WorldArtifact> artifacts,
    DomainActionState interaction,
    String reason,
  ) {
    return UnitActionCommandResult._rejected(
      units: units,
      artifacts: artifacts,
      interaction: interaction,
      reason: reason,
    );
  }

  static List<GameUnit> _replaceUnit(List<GameUnit> units, GameUnit updated) {
    if (units.byId(updated.id) == updated) return units;
    return List.unmodifiable([
      for (final unit in units)
        if (unit.id == updated.id) updated else unit,
    ]);
  }

  static List<WorldArtifact> _cancelArtifactExcavation(
    List<WorldArtifact> artifacts,
    GameUnit unit,
  ) {
    final artifactId = unit.excavatingArtifactId;
    if (artifactId == null) return artifacts;
    final hasExcavation = artifacts.any(
      (artifact) =>
          artifact.id == artifactId && artifact.location.isBeingExcavated,
    );
    if (!hasExcavation) return artifacts;
    return List.unmodifiable([
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
    ]);
  }
}

typedef _ControlledUnit = ({GameUnit? unit, String? reason});
