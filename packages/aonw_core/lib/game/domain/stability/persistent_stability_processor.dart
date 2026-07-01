import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/stability/stability_breakdown.dart';
import 'package:aonw_core/game/domain/stability/stability_calculator.dart';
import 'package:aonw_core/game/domain/stability/stability_input_builder.dart';
import 'package:aonw_core/game/domain/stability/stability_inputs.dart';
import 'package:aonw_core/game/domain/stability/stability_modifier.dart';
import 'package:aonw_core/game/domain/stability/stability_policy.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:aonw_core/game/domain/stability/war_weariness_rules.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class PersistentStabilityTurnResult {
  const PersistentStabilityTurnResult({
    required this.state,
    this.inputsByPlayerId = const {},
    this.breakdownsByPlayerId = const {},
  });

  final PersistentGameState state;
  final Map<String, StabilityInputs> inputsByPlayerId;
  final Map<String, StabilityBreakdown> breakdownsByPlayerId;
}

abstract final class PersistentStabilityProcessor {
  static PersistentStabilityTurnResult advanceForPlayers({
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required MapData mapData,
    StabilityRuleset ruleset = StabilityRuleset.standard,
    Iterable<GameEvent> turnEvents = const [],
  }) {
    final knownPlayerIds = StabilityInputBuilder.orderedKnownPlayerIds(
      state,
      playerIds,
    );
    if (knownPlayerIds.isEmpty) {
      return PersistentStabilityTurnResult(state: state);
    }

    // The war-weariness stock advances only for the players actually taking a
    // turn, so a peaceful rival is not decayed once per every other player's
    // end-turn. Every non-advancing player's stored value is preserved.
    final advancingPlayerIds = {
      for (final playerId in playerIds)
        if (playerId.isNotEmpty) playerId,
    };
    final eventCounts = _WarWearinessEventCounts.from(turnEvents);
    final warWeariness = <String, int>{...state.playerWarWeariness};
    for (final playerId in advancingPlayerIds) {
      final next = WarWearinessRules.next(
        current: state.playerWarWeariness[playerId] ?? 0,
        atWar: _isAtWar(state, playerId),
        attacksThisTurn: eventCounts.attacksByPlayerId[playerId] ?? 0,
        citiesLost: eventCounts.citiesLostByPlayerId[playerId] ?? 0,
        signedPeace: eventCounts.signedPeacePlayerIds.contains(playerId),
        ruleset: ruleset,
      );
      if (next > 0) {
        warWeariness[playerId] = next;
      } else {
        warWeariness.remove(playerId);
      }
    }

    // Stability net is refreshed for every known player so the cache stays
    // complete for the HUD and AI.
    final inputsByPlayerId = StabilityInputBuilder.forPlayers(
      state: state,
      playerIds: knownPlayerIds,
      mapData: mapData,
      ruleset: ruleset,
      warWearinessByPlayerId: warWeariness,
    );
    final breakdownsByPlayerId = <String, StabilityBreakdown>{};
    final stabilityNet = <String, int>{};
    for (final entry in inputsByPlayerId.entries) {
      final breakdown = StabilityCalculator.calculate(
        inputs: entry.value,
        ruleset: ruleset,
      );
      breakdownsByPlayerId[entry.key] = breakdown;
      // Cache the standing-adjusted net so the band reflects the relative-band
      // (U4) rule. Raw components remain in [breakdownsByPlayerId].
      final relativeStanding = StabilityPolicy.relativeStandingFor(
        controlPercent: entry.value.controlPercent,
        playerCount: entry.value.playerCount,
      );
      stabilityNet[entry.key] = StabilityPolicy.effectiveNet(
        breakdown.net,
        relativeStanding: relativeStanding,
        ruleset: ruleset,
      );
    }

    return PersistentStabilityTurnResult(
      state: state.copyWith(
        playerWarWeariness: Map.unmodifiable(warWeariness),
        playerStabilityNet: Map.unmodifiable(stabilityNet),
      ),
      inputsByPlayerId: Map.unmodifiable(inputsByPlayerId),
      breakdownsByPlayerId: Map.unmodifiable(breakdownsByPlayerId),
    );
  }

  static StabilityModifier modifierForNet(
    int net, {
    StabilityRuleset ruleset = StabilityRuleset.standard,
  }) {
    return StabilityPolicy.modifierFor(
      StabilityPolicy.bandFor(net, ruleset: ruleset),
    );
  }

  static StabilityModifier modifierForPlayer({
    required PersistentGameState state,
    required String playerId,
    StabilityRuleset ruleset = StabilityRuleset.standard,
  }) {
    return modifierForNet(
      state.playerStabilityNet[playerId] ?? 0,
      ruleset: ruleset,
    );
  }

  static bool _isAtWar(PersistentGameState state, String playerId) {
    for (final relation in state.runtimeState.diplomacy.relations.values) {
      if (relation.status != DiplomaticRelationStatus.war) continue;
      if (relation.playerAId == playerId || relation.playerBId == playerId) {
        return true;
      }
    }
    return false;
  }
}

class _WarWearinessEventCounts {
  const _WarWearinessEventCounts({
    required this.attacksByPlayerId,
    required this.citiesLostByPlayerId,
    required this.signedPeacePlayerIds,
  });

  final Map<String, int> attacksByPlayerId;
  final Map<String, int> citiesLostByPlayerId;
  final Set<String> signedPeacePlayerIds;

  factory _WarWearinessEventCounts.from(Iterable<GameEvent> events) {
    final attacksByPlayerId = <String, int>{};
    final citiesLostByPlayerId = <String, int>{};
    final signedPeacePlayerIds = <String>{};

    for (final event in events) {
      switch (event) {
        case UnitAttackedEvent(:final attackerOwnerPlayerId):
          _increment(attacksByPlayerId, attackerOwnerPlayerId);
        case CityCapturedEvent(
          :final previousOwnerPlayerId,
          :final newOwnerPlayerId,
        ):
          _increment(citiesLostByPlayerId, previousOwnerPlayerId);
          _increment(attacksByPlayerId, newOwnerPlayerId);
        case CityDestroyedEvent(
          :final previousOwnerPlayerId,
          :final attackerOwnerPlayerId,
        ):
          _increment(citiesLostByPlayerId, previousOwnerPlayerId);
          _increment(attacksByPlayerId, attackerOwnerPlayerId);
        case DiplomaticProposalRespondedEvent(
          kind: DiplomaticProposalKind.truce,
          accepted: true,
          :final fromPlayerId,
          :final toPlayerId,
        ):
          _addPlayer(signedPeacePlayerIds, fromPlayerId);
          _addPlayer(signedPeacePlayerIds, toPlayerId);
        case DiplomaticRelationChangedEvent(
          oldStatus: DiplomaticRelationStatus.war,
          :final newStatus,
          :final playerAId,
          :final playerBId,
        ) when newStatus != DiplomaticRelationStatus.war:
          _addPlayer(signedPeacePlayerIds, playerAId);
          _addPlayer(signedPeacePlayerIds, playerBId);
        default:
          break;
      }
    }

    return _WarWearinessEventCounts(
      attacksByPlayerId: Map.unmodifiable(attacksByPlayerId),
      citiesLostByPlayerId: Map.unmodifiable(citiesLostByPlayerId),
      signedPeacePlayerIds: Set.unmodifiable(signedPeacePlayerIds),
    );
  }

  static void _increment(Map<String, int> values, String playerId) {
    if (playerId.isEmpty) return;
    values[playerId] = (values[playerId] ?? 0) + 1;
  }

  static void _addPlayer(Set<String> values, String playerId) {
    if (playerId.isNotEmpty) values.add(playerId);
  }
}
