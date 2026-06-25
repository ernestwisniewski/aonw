import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology/research_overflow_rules.dart';
import 'package:aonw_core/game/domain/technology/technology_availability_service.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/map/domain/map_data.dart';

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
    MapDefinition? mapDefinition,
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
      mapData: mapDefinition == null
          ? null
          : _mapDataFromDefinition(mapDefinition),
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
    return GameRuntimeState(
      cityFoundingDraft: runtimeState.cityFoundingDraft,
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
