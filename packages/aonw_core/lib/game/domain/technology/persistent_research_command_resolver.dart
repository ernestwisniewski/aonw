import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology/research_overflow_rules.dart';
import 'package:aonw_core/game/domain/technology/technology_availability_service.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/map/persistence/legacy_world_map_adapter.dart';

class PersistentResearchCommandResult {
  const PersistentResearchCommandResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final String? reason;
}

class PersistentResearchCommandResolver {
  const PersistentResearchCommandResolver();

  PersistentResearchCommandResult selectTechnology({
    required PersistentGameState state,
    required SelectTechnologyCommand command,
    required String actorPlayerId,
    WorldMap? worldMap,
    TechnologyRuleset ruleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (command.playerId != actorPlayerId) {
      return _reject(state, 'technology_player_not_controlled');
    }

    final playerResearch = state.research.forPlayer(command.playerId);
    final availability = TechnologyAvailabilityService.availabilityFor(
      technologyId: command.technologyId,
      playerResearch: playerResearch,
      ruleset: ruleset,
    );
    if (availability != TechnologyAvailability.available) {
      return _reject(state, 'technology_not_available');
    }

    final updatedPlayer = ResearchOverflowRules.applyToSelectedTechnology(
      playerId: command.playerId,
      playerResearch: playerResearch,
      technologyId: command.technologyId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapTiles: worldMap == null
          ? null
          : LegacyWorldMapAdapter.asTileLookup(worldMap),
      ruleset: ruleset,
      paceBalance: paceBalance,
    );
    final updatedResearch = state.research.updatePlayer(
      command.playerId,
      updatedPlayer,
    );

    return PersistentResearchCommandResult(
      accepted: true,
      state: state.copyWith(
        research: updatedResearch,
        runtimeState: _clearResearchPendingAction(
          state.runtimeState,
          command.playerId,
        ),
      ),
    );
  }

  PersistentResearchCommandResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentResearchCommandResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  static GameRuntimeState _clearResearchPendingAction(
    GameRuntimeState runtimeState,
    String playerId,
  ) {
    final pendingAction = runtimeState.pendingAction;
    if (pendingAction is! PendingResearchSelection ||
        pendingAction.ownerPlayerId != playerId) {
      return runtimeState;
    }
    return runtimeState.copyWith(pendingAction: null);
  }
}
