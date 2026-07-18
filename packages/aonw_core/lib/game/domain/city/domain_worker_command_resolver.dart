import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/worker_command_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainWorkerCommandResult {
  const DomainWorkerCommandResult({
    required this.accepted,
    required this.state,
    required this.interaction,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final PersistedInteractionState interaction;
  final String? reason;
}

/// Canonical-state adapter for the state-neutral worker command resolver.
final class DomainWorkerCommandResolver {
  const DomainWorkerCommandResolver();

  DomainWorkerCommandResult selectWorkerImprovement({
    required DomainState state,
    required PersistedInteractionState interaction,
    required SelectWorkerImprovementCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return _apply(
      state,
      interaction,
      WorkerCommandResolver.selectWorkerImprovement(
        units: state.units,
        cities: state.cities,
        fieldImprovements: state.fieldImprovements,
        research: state.research,
        interaction: interaction,
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
      ),
    );
  }

  DomainWorkerCommandResult confirmWorkerImprovement({
    required DomainState state,
    required PersistedInteractionState interaction,
    required ConfirmWorkerImprovementCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return _apply(
      state,
      interaction,
      WorkerCommandResolver.confirmWorkerImprovement(
        units: state.units,
        cities: state.cities,
        fieldImprovements: state.fieldImprovements,
        research: state.research,
        interaction: interaction,
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
      ),
    );
  }

  DomainWorkerCommandResult cancelWorkerJob({
    required DomainState state,
    required PersistedInteractionState interaction,
    required CancelWorkerJobCommand command,
    required String actorPlayerId,
  }) {
    return _apply(
      state,
      interaction,
      WorkerCommandResolver.cancelWorkerJob(
        units: state.units,
        interaction: interaction,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  DomainWorkerCommandResult assignWorkerToHex({
    required DomainState state,
    required PersistedInteractionState interaction,
    required AssignWorkerToHexCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    return _apply(
      state,
      interaction,
      WorkerCommandResolver.assignWorkerToHex(
        units: state.units,
        cities: state.cities,
        fieldImprovements: state.fieldImprovements,
        interaction: interaction,
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
      ),
    );
  }

  DomainWorkerCommandResult cancelWorkerAssignment({
    required DomainState state,
    required PersistedInteractionState interaction,
    required CancelWorkerAssignmentCommand command,
    required String actorPlayerId,
  }) {
    return _apply(
      state,
      interaction,
      WorkerCommandResolver.cancelWorkerAssignment(
        units: state.units,
        interaction: interaction,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  static DomainWorkerCommandResult _apply(
    DomainState state,
    PersistedInteractionState interaction,
    WorkerCommandResult result,
  ) {
    if (!result.accepted) {
      return DomainWorkerCommandResult(
        accepted: false,
        state: state,
        interaction: interaction,
        reason: result.reason,
      );
    }
    return DomainWorkerCommandResult(
      accepted: true,
      state: identical(result.units, state.units)
          ? state
          : state.copyWith(units: result.units),
      interaction: result.interaction,
    );
  }
}
