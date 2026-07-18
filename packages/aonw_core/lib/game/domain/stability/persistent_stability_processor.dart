import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/stability/stability_breakdown.dart';
import 'package:aonw_core/game/domain/stability/stability_inputs.dart';
import 'package:aonw_core/game/domain/stability/stability_modifier.dart';
import 'package:aonw_core/game/domain/stability/stability_policy.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:aonw_core/game/domain/stability/stability_turn_processor.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

class PersistentStabilityTurnResult {
  const PersistentStabilityTurnResult({
    required this.state,
    this.inputsByPlayerId = const {},
    this.breakdownsByPlayerId = const {},
    this.events = const [],
  });

  final PersistentGameState state;
  final Map<String, StabilityInputs> inputsByPlayerId;
  final Map<String, StabilityBreakdown> breakdownsByPlayerId;
  final List<GameEvent> events;
}

/// Compatibility adapter for callers that still own [PersistentGameState].
abstract final class PersistentStabilityProcessor {
  static PersistentStabilityTurnResult advanceForPlayers({
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required MapReadView mapData,
    StabilityRuleset ruleset = StabilityRuleset.standard,
    Iterable<GameEvent> turnEvents = const [],
    int? turn,
  }) {
    final result = StabilityTurnProcessor.advanceForPlayers(
      knownPlayerIds: state.knownPlayerIds,
      playerIds: playerIds,
      playerWarWearinessByPlayerId: state.playerWarWeariness,
      playerStabilityNetByPlayerId: state.playerStabilityNet,
      cities: state.cities,
      artifacts: state.artifacts,
      research: state.research,
      wonderRegistry: state.wonderRegistry,
      diplomacy: state.runtimeState.diplomacy,
      mapData: mapData,
      ruleset: ruleset,
      turnEvents: turnEvents,
      turn: turn,
    );
    if (result.inputsByPlayerId.isEmpty) {
      return PersistentStabilityTurnResult(state: state);
    }
    return PersistentStabilityTurnResult(
      state: state.copyWith(
        playerWarWeariness: result.warWearinessByPlayerId,
        playerStabilityNet: result.stabilityNetByPlayerId,
      ),
      inputsByPlayerId: result.inputsByPlayerId,
      breakdownsByPlayerId: result.breakdownsByPlayerId,
      events: result.events,
    );
  }

  static StabilityModifier modifierForPlayer({
    required PersistentGameState state,
    required String playerId,
    StabilityRuleset ruleset = StabilityRuleset.standard,
  }) {
    return StabilityPolicy.modifierForNet(
      state.playerStabilityNet[playerId] ?? 0,
      ruleset: ruleset,
    );
  }
}
