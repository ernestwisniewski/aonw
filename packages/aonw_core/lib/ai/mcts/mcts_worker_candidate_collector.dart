import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsWorkerCandidateCollector {
  const MctsWorkerCandidateCollector();

  Iterable<GameCommand> commandsFor(GameView view) {
    if (view.ownCities.isEmpty) return const [];

    final workers = [
      for (final unit in view.ownUnits)
        if (unit.isWorker) unit,
    ]..sort((a, b) => a.id.compareTo(b.id));
    final research = _researchFor(view);
    final commands = <GameCommand>[];

    for (final worker in workers) {
      if (!_isReadyUnit(worker)) continue;

      final assignment = WorkerAssignmentRules.evaluate(
        unit: worker,
        cities: view.ownCities,
        fieldImprovements: view.ownImprovements,
        units: view.ownUnits,
        mapData: view.mapData,
      );
      if (assignment.allowed) {
        commands.add(AssignWorkerToHexCommand(worker.id));
      }

      for (final improvementType in view.ruleset.city.improvements.keys) {
        final improvement = WorkerImprovementRules.evaluate(
          unit: worker,
          improvementType: improvementType,
          cities: view.ownCities,
          fieldImprovements: view.ownImprovements,
          mapData: view.mapData,
          research: research,
          cityRuleset: view.ruleset.city,
          technologyRuleset: view.ruleset.technology,
        );
        if (!improvement.allowed) continue;
        commands.add(
          SelectWorkerImprovementCommand(worker.id, improvementType),
        );
      }
    }
    return commands;
  }

  static ResearchState _researchFor(GameView view) {
    return ResearchState(players: {view.forPlayerId: view.ownResearch});
  }

  static bool _isReadyUnit(GameUnit unit) {
    return !unit.isWorking &&
        unit.movementPoints > 0 &&
        unit.queuedPath == null;
  }
}
