import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/stability/stability_breakdown.dart';
import 'package:aonw_core/game/domain/stability/stability_calculator.dart';
import 'package:aonw_core/game/domain/stability/stability_input_builder.dart';
import 'package:aonw_core/game/domain/stability/stability_inputs.dart';
import 'package:aonw_core/game/domain/stability/stability_policy.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:aonw_core/game/domain/stability/war_weariness_rules.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/wonder/wonder_registry.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Persistence-free result of one stability phase.
final class StabilityTurnResult {
  StabilityTurnResult({
    required Map<String, int> warWearinessByPlayerId,
    required Map<String, int> stabilityNetByPlayerId,
    Map<String, StabilityInputs> inputsByPlayerId = const {},
    Map<String, StabilityBreakdown> breakdownsByPlayerId = const {},
    Iterable<GameEvent> events = const [],
  }) : warWearinessByPlayerId = Map.unmodifiable(warWearinessByPlayerId),
       stabilityNetByPlayerId = Map.unmodifiable(stabilityNetByPlayerId),
       inputsByPlayerId = Map.unmodifiable(inputsByPlayerId),
       breakdownsByPlayerId = Map.unmodifiable(breakdownsByPlayerId),
       events = List.unmodifiable(events);

  final Map<String, int> warWearinessByPlayerId;
  final Map<String, int> stabilityNetByPlayerId;
  final Map<String, StabilityInputs> inputsByPlayerId;
  final Map<String, StabilityBreakdown> breakdownsByPlayerId;
  final List<GameEvent> events;
}

/// Advances stability from explicit domain collections.
abstract final class StabilityTurnProcessor {
  static StabilityTurnResult advanceForPlayers({
    required Iterable<String> knownPlayerIds,
    required Iterable<String> playerIds,
    required Map<String, int> playerWarWearinessByPlayerId,
    required Map<String, int> playerStabilityNetByPlayerId,
    required Iterable<GameCity> cities,
    required Iterable<WorldArtifact> artifacts,
    required ResearchState research,
    required WonderRegistry wonderRegistry,
    required DiplomacyState diplomacy,
    required MapReadView mapData,
    StabilityRuleset ruleset = StabilityRuleset.standard,
    Iterable<GameEvent> turnEvents = const [],
    int? turn,
  }) {
    final players = StabilityInputBuilder.orderedKnownPlayerIdsFrom(
      knownPlayerIds: knownPlayerIds,
      playerIds: playerIds,
    );
    if (players.isEmpty) {
      return StabilityTurnResult(
        warWearinessByPlayerId: playerWarWearinessByPlayerId,
        stabilityNetByPlayerId: playerStabilityNetByPlayerId,
      );
    }
    final advancingPlayers = _advancingPlayerIds(playerIds);
    final eventCounts = _WarWearinessEventCounts.from(turnEvents);
    final warWeariness = _warWearinessAfterTurn(
      previous: playerWarWearinessByPlayerId,
      advancingPlayerIds: advancingPlayers,
      diplomacy: diplomacy,
      eventCounts: eventCounts,
      turn: turn,
      ruleset: ruleset,
    );
    final inputs = StabilityInputBuilder.forPlayersFromCollections(
      cities: cities,
      artifacts: artifacts,
      research: research,
      wonderRegistry: wonderRegistry,
      knownPlayerIds: players,
      playerIds: const [],
      mapData: mapData,
      ruleset: ruleset,
      warWearinessByPlayerId: warWeariness,
    );
    return _resultForInputs(
      inputs: inputs,
      previousStabilityNet: playerStabilityNetByPlayerId,
      warWeariness: warWeariness,
      ruleset: ruleset,
    );
  }

  static StabilityTurnResult _resultForInputs({
    required Map<String, StabilityInputs> inputs,
    required Map<String, int> previousStabilityNet,
    required Map<String, int> warWeariness,
    required StabilityRuleset ruleset,
  }) {
    final breakdowns = <String, StabilityBreakdown>{};
    final stabilityNet = <String, int>{};
    final events = <GameEvent>[];
    for (final entry in inputs.entries) {
      final breakdown = StabilityCalculator.calculate(
        inputs: entry.value,
        ruleset: ruleset,
      );
      breakdowns[entry.key] = breakdown;
      final net = _effectiveNet(entry.value, breakdown, ruleset);
      stabilityNet[entry.key] = net;
      final event = _bandChangeEvent(
        playerId: entry.key,
        previousNet: previousStabilityNet[entry.key],
        newNet: net,
        ruleset: ruleset,
      );
      if (event != null) events.add(event);
    }
    return StabilityTurnResult(
      warWearinessByPlayerId: warWeariness,
      stabilityNetByPlayerId: stabilityNet,
      inputsByPlayerId: inputs,
      breakdownsByPlayerId: breakdowns,
      events: events,
    );
  }

  static int _effectiveNet(
    StabilityInputs inputs,
    StabilityBreakdown breakdown,
    StabilityRuleset ruleset,
  ) {
    final standing = StabilityPolicy.relativeStandingFor(
      controlPercent: inputs.controlPercent,
      playerCount: inputs.playerCount,
    );
    return StabilityPolicy.effectiveNet(
      breakdown.net,
      relativeStanding: standing,
      ruleset: ruleset,
    );
  }

  static StabilityBandChangedEvent? _bandChangeEvent({
    required String playerId,
    required int? previousNet,
    required int newNet,
    required StabilityRuleset ruleset,
  }) {
    if (previousNet == null) return null;
    final previousBand = StabilityPolicy.bandFor(previousNet, ruleset: ruleset);
    final newBand = StabilityPolicy.bandFor(newNet, ruleset: ruleset);
    if (previousBand == newBand) return null;
    return StabilityBandChangedEvent(
      playerId: playerId,
      previousBand: previousBand,
      newBand: newBand,
      net: newNet,
    );
  }

  static Map<String, int> _warWearinessAfterTurn({
    required Map<String, int> previous,
    required Set<String> advancingPlayerIds,
    required DiplomacyState diplomacy,
    required _WarWearinessEventCounts eventCounts,
    required int? turn,
    required StabilityRuleset ruleset,
  }) {
    final nextValues = <String, int>{...previous};
    for (final playerId in advancingPlayerIds) {
      final next = WarWearinessRules.next(
        current: previous[playerId] ?? 0,
        atWar: _isAtWar(diplomacy, playerId),
        attacksThisTurn: eventCounts.attacksByPlayerId[playerId] ?? 0,
        citiesLost: eventCounts.citiesLostByPlayerId[playerId] ?? 0,
        signedPeace:
            eventCounts.signedPeacePlayerIds.contains(playerId) ||
            _signedPeaceThisTurn(diplomacy, playerId, turn),
        ruleset: ruleset,
      );
      if (next > 0) {
        nextValues[playerId] = next;
      } else {
        nextValues.remove(playerId);
      }
    }
    return Map.unmodifiable(nextValues);
  }

  static Set<String> _advancingPlayerIds(Iterable<String> playerIds) {
    return {
      for (final playerId in playerIds)
        if (playerId.isNotEmpty) playerId,
    };
  }

  static bool _isAtWar(DiplomacyState diplomacy, String playerId) {
    for (final relation in diplomacy.relations.values) {
      if (relation.status != DiplomaticRelationStatus.war) continue;
      if (relation.playerAId == playerId || relation.playerBId == playerId) {
        return true;
      }
    }
    return false;
  }

  static bool _signedPeaceThisTurn(
    DiplomacyState diplomacy,
    String playerId,
    int? turn,
  ) {
    if (turn == null) return false;
    for (final relation in diplomacy.relations.values) {
      if (relation.status != DiplomaticRelationStatus.truce ||
          relation.lastChangedTurn != turn) {
        continue;
      }
      if (relation.playerAId == playerId || relation.playerBId == playerId) {
        return true;
      }
    }
    return false;
  }
}

final class _WarWearinessEventCounts {
  const _WarWearinessEventCounts({
    required this.attacksByPlayerId,
    required this.citiesLostByPlayerId,
    required this.signedPeacePlayerIds,
  });

  final Map<String, int> attacksByPlayerId;
  final Map<String, int> citiesLostByPlayerId;
  final Set<String> signedPeacePlayerIds;

  factory _WarWearinessEventCounts.from(Iterable<GameEvent> events) {
    final attacks = <String, int>{};
    final citiesLost = <String, int>{};
    final signedPeace = <String>{};
    for (final event in events) {
      final descriptor = GameEventDomainDescriptor.forEvent(event);
      for (final playerId in descriptor.attackingPlayerIds) {
        _increment(attacks, playerId);
      }
      for (final playerId in descriptor.citiesLostPlayerIds) {
        _increment(citiesLost, playerId);
      }
      for (final playerId in descriptor.signedPeacePlayerIds) {
        if (playerId.isNotEmpty) signedPeace.add(playerId);
      }
    }
    return _WarWearinessEventCounts(
      attacksByPlayerId: Map.unmodifiable(attacks),
      citiesLostByPlayerId: Map.unmodifiable(citiesLost),
      signedPeacePlayerIds: Set.unmodifiable(signedPeace),
    );
  }

  static void _increment(Map<String, int> values, String playerId) {
    if (playerId.isEmpty) return;
    values[playerId] = (values[playerId] ?? 0) + 1;
  }
}
