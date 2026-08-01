import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/field_improvement_rules.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/city/worker_assignment_rules.dart';
import 'package:aonw_core/game/domain/city/worker_improvement_rules.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/worker_assignment.dart';
import 'package:aonw_core/game/domain/unit/worker_job.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Persistence-neutral result of an authoritative worker command.
///
/// Rejections and accepted semantic no-ops retain the input collection and
/// interaction identities. Changed unit collections are owned by the result
/// and cannot be mutated.
final class WorkerCommandResult {
  const WorkerCommandResult._accepted({
    required this.units,
    required this.interaction,
  }) : accepted = true,
       reason = null;

  const WorkerCommandResult._rejected({
    required this.units,
    required this.interaction,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final List<GameUnit> units;
  final DomainActionState interaction;
}

/// Applies authoritative worker rules without depending on a state container.
abstract final class WorkerCommandResolver {
  static WorkerCommandResult selectWorkerImprovement({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required DomainActionState interaction,
    required SelectWorkerImprovementCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    return _startImprovement(
      units: units,
      cities: cities,
      fieldImprovements: fieldImprovements,
      research: research,
      interaction: interaction,
      unitId: command.unitId,
      improvementType: command.improvementType,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  static WorkerCommandResult confirmWorkerImprovement({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required DomainActionState interaction,
    required ConfirmWorkerImprovementCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    final pending = interaction.pendingAction;
    final pendingImprovement =
        pending is PendingWorkerActionSelection &&
            pending.unitId == command.unitId
        ? pending.improvementType
        : null;
    final improvementType = command.improvementType ?? pendingImprovement;
    if (improvementType == null) {
      return _reject(units, interaction, 'worker_improvement_not_selected');
    }
    if (pending is PendingWorkerActionSelection &&
        pending.unitId == command.unitId &&
        pending.ownerPlayerId != actorPlayerId) {
      return _reject(units, interaction, 'worker_action_not_controlled');
    }

    return _startImprovement(
      units: units,
      cities: cities,
      fieldImprovements: fieldImprovements,
      research: research,
      interaction: interaction,
      unitId: command.unitId,
      improvementType: improvementType,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  static WorkerCommandResult cancelWorkerJob({
    required List<GameUnit> units,
    required DomainActionState interaction,
    required CancelWorkerJobCommand command,
    required String actorPlayerId,
  }) {
    final unitIndex = _unitIndexById(units, command.unitId);
    if (unitIndex == null) {
      return _reject(units, interaction, 'worker_not_found');
    }

    final worker = units[unitIndex];
    if (worker.ownerPlayerId != actorPlayerId) {
      return _reject(units, interaction, 'worker_not_controlled');
    }
    if (worker.workerJob == null) {
      return _reject(units, interaction, 'worker_job_not_active');
    }

    return _accept(
      units: units,
      unitIndex: unitIndex,
      updatedWorker: worker.copyWithWorkerJob(null).copyWithQueuedPath(null),
      interaction: interaction,
    );
  }

  static WorkerCommandResult assignWorkerToHex({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required DomainActionState interaction,
    required AssignWorkerToHexCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final unitIndex = _unitIndexById(units, command.unitId);
    if (unitIndex == null) {
      return _reject(units, interaction, 'worker_not_found');
    }

    final worker = units[unitIndex];
    if (worker.ownerPlayerId != actorPlayerId) {
      return _reject(units, interaction, 'worker_not_controlled');
    }

    final legality = WorkerAssignmentRules.evaluate(
      unit: worker,
      cities: cities,
      fieldImprovements: fieldImprovements,
      units: units,
      mapTiles: mapTiles,
    );
    if (!legality.allowed) {
      return _reject(units, interaction, 'worker_assignment_unavailable');
    }

    final targetHex = CityHex(col: worker.col, row: worker.row);
    final updatedWorker = worker
        .copyWith(movementPoints: 0)
        .copyWithQueuedPath(null)
        .copyWithWorkerAssignment(WorkerAssignment(targetHex: targetHex));
    return _accept(
      units: units,
      unitIndex: unitIndex,
      updatedWorker: updatedWorker,
      interaction: _clearMatchingWorkerPendingAction(
        interaction,
        actorPlayerId: actorPlayerId,
        unitId: worker.id,
      ),
    );
  }

  static WorkerCommandResult cancelWorkerAssignment({
    required List<GameUnit> units,
    required DomainActionState interaction,
    required CancelWorkerAssignmentCommand command,
    required String actorPlayerId,
  }) {
    final unitIndex = _unitIndexById(units, command.unitId);
    if (unitIndex == null) {
      return _reject(units, interaction, 'worker_not_found');
    }

    final worker = units[unitIndex];
    if (worker.ownerPlayerId != actorPlayerId) {
      return _reject(units, interaction, 'worker_not_controlled');
    }
    if (worker.workerAssignment == null) {
      return _reject(units, interaction, 'worker_assignment_not_active');
    }

    return _accept(
      units: units,
      unitIndex: unitIndex,
      updatedWorker: worker
          .copyWithWorkerAssignment(null)
          .copyWithQueuedPath(null),
      interaction: interaction,
    );
  }

  static WorkerCommandResult _startImprovement({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required DomainActionState interaction,
    required String unitId,
    required FieldImprovementType improvementType,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    final unitIndex = _unitIndexById(units, unitId);
    if (unitIndex == null) {
      return _reject(units, interaction, 'worker_not_found');
    }

    final worker = units[unitIndex];
    if (worker.ownerPlayerId != actorPlayerId) {
      return _reject(units, interaction, 'worker_not_controlled');
    }

    final legality = WorkerImprovementRules.evaluate(
      unit: worker,
      improvementType: improvementType,
      cities: cities,
      fieldImprovements: fieldImprovements,
      mapTiles: mapTiles,
      research: research,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
    if (!legality.allowed) {
      return _reject(units, interaction, 'worker_improvement_unavailable');
    }

    return _accept(
      units: units,
      unitIndex: unitIndex,
      updatedWorker: _workerStartingImprovement(
        worker,
        improvementType: improvementType,
        cityRuleset: cityRuleset,
        paceBalance: paceBalance,
      ),
      interaction: _clearMatchingWorkerPendingAction(
        interaction,
        actorPlayerId: actorPlayerId,
        unitId: worker.id,
      ),
    );
  }

  static GameUnit _workerStartingImprovement(
    GameUnit worker, {
    required FieldImprovementType improvementType,
    required CityRuleset cityRuleset,
    required PaceBalance paceBalance,
  }) {
    final totalTurns = FieldImprovementRules.buildTurnsFor(
      improvementType,
      ruleset: cityRuleset,
      paceBalance: paceBalance,
    );
    return worker
        .copyWith(movementPoints: 0)
        .copyWithQueuedPath(null)
        .copyWithWorkerAssignment(null)
        .copyWithWorkerJob(
          WorkerJob(
            targetHex: CityHex(col: worker.col, row: worker.row),
            improvementType: improvementType,
            remainingTurns: totalTurns,
            totalTurns: totalTurns,
          ),
        );
  }

  static WorkerCommandResult _accept({
    required List<GameUnit> units,
    required int unitIndex,
    required GameUnit updatedWorker,
    required DomainActionState interaction,
  }) {
    if (units[unitIndex] == updatedWorker) {
      return WorkerCommandResult._accepted(
        units: units,
        interaction: interaction,
      );
    }
    return WorkerCommandResult._accepted(
      units: List<GameUnit>.unmodifiable([
        for (var index = 0; index < units.length; index++)
          if (index == unitIndex) updatedWorker else units[index],
      ]),
      interaction: interaction,
    );
  }

  static WorkerCommandResult _reject(
    List<GameUnit> units,
    DomainActionState interaction,
    String reason,
  ) {
    return WorkerCommandResult._rejected(
      units: units,
      interaction: interaction,
      reason: reason,
    );
  }

  static DomainActionState _clearMatchingWorkerPendingAction(
    DomainActionState interaction, {
    required String actorPlayerId,
    required String unitId,
  }) {
    final pending = interaction.pendingAction;
    if (pending is PendingWorkerActionSelection &&
        pending.ownerPlayerId == actorPlayerId &&
        pending.unitId == unitId) {
      return interaction.copyWith(pendingAction: null);
    }
    return interaction;
  }

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var index = 0; index < units.length; index++) {
      if (units[index].id == unitId) return index;
    }
    return null;
  }
}
