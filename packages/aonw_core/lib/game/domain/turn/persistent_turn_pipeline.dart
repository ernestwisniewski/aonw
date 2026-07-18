import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/turn/persistent_turn_economy_processor.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class PersistentPlayerTurnResult {
  PersistentPlayerTurnResult({
    required this.state,
    Iterable<GameEvent> events = const [],
  }) : events = List.unmodifiable(events);

  final PersistentGameState state;
  final List<GameEvent> events;
}

abstract final class PersistentTurnPipeline {
  static PersistentPlayerTurnResult advancePlayer({
    required PersistentGameState state,
    required String playerId,
    required MapReadView mapView,
    GameRuleset ruleset = GameRuleset.defaults,
    FogOfWarService fogOfWarService = const FogOfWarService(),
    VictoryRules victoryRules = VictoryRules.standard,
    int? turn,
  }) {
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: state,
      playerIds: [playerId],
      mapData: mapView,
      ruleset: ruleset,
      fogOfWarService: fogOfWarService,
      mapObjectives: mapView.objectives,
      turn: turn,
    );
    final previousCulturalHoldTurns =
        economy.state.runtimeState.culturalVictoryHoldTurnsByPlayerId;
    final culturalHoldTurns = victoryRules.culturalEnabled
        ? CulturalVictoryProgressCalculator.advanceHoldTurns(
            playerIds: [playerId],
            state: economy.state,
            previousHoldTurnsByPlayerId: previousCulturalHoldTurns,
            requiredArtifactCount: victoryRules.culturalRequiredArtifacts,
          )
        : previousCulturalHoldTurns;

    return PersistentPlayerTurnResult(
      state: economy.state.copyWith(
        runtimeState: economy.state.runtimeState.copyWith(
          culturalVictoryHoldTurnsByPlayerId: culturalHoldTurns,
        ),
      ),
      events: [
        ...economy.events,
        TurnEndedEvent(playerId: playerId),
      ],
    );
  }
}
