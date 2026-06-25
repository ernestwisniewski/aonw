import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class DominationProgressEntry {
  final String playerId;
  final int controlledTileCount;
  final int validTileCount;
  final double controlPercent;
  final double requiredControlPercent;
  final int holdTurns;
  final int requiredHoldTurns;

  const DominationProgressEntry({
    required this.playerId,
    required this.controlledTileCount,
    required this.validTileCount,
    required this.controlPercent,
    required this.requiredControlPercent,
    required this.holdTurns,
    required this.requiredHoldTurns,
  });

  bool get atThreshold =>
      validTileCount > 0 && controlPercent >= requiredControlPercent;

  double get thresholdProgress {
    if (validTileCount <= 0 || requiredControlPercent <= 0) return 0;
    return controlPercent / requiredControlPercent;
  }

  int get remainingHoldTurns {
    if (!atThreshold) return requiredHoldTurns;
    final remaining = requiredHoldTurns - holdTurns;
    return remaining <= 0 ? 0 : remaining;
  }

  bool get canWinNow => atThreshold && holdTurns >= requiredHoldTurns;
}

enum DominationThreatLevel { approachingThreshold, holdingThreshold, imminent }

class DominationThreat {
  final DominationProgressEntry entry;
  final DominationThreatLevel level;

  const DominationThreat({required this.entry, required this.level});
}

abstract final class DominationWarningPolicy {
  static DominationThreat? topOpponentThreat({
    required DominationProgressSnapshot progress,
    required String activePlayerId,
  }) {
    final opponent = progress.topOpponentFor(activePlayerId);
    if (opponent == null) return null;
    final level = levelFor(opponent);
    if (level == null) return null;
    return DominationThreat(entry: opponent, level: level);
  }

  static DominationThreatLevel? levelFor(DominationProgressEntry entry) {
    if (entry.validTileCount <= 0) return null;

    if (entry.atThreshold) {
      if (entry.remainingHoldTurns <= 1) {
        return DominationThreatLevel.imminent;
      }
      if (entry.requiredHoldTurns <= 3) {
        return DominationThreatLevel.holdingThreshold;
      }
      return null;
    }

    final nearThresholdRatio = _nearThresholdRatio(entry.requiredHoldTurns);
    if (nearThresholdRatio == null) return null;
    if (entry.thresholdProgress >= nearThresholdRatio) {
      return DominationThreatLevel.approachingThreshold;
    }
    return null;
  }

  static double? _nearThresholdRatio(int requiredHoldTurns) {
    if (requiredHoldTurns <= 2) return 0.90;
    if (requiredHoldTurns == 3) return 0.95;
    return null;
  }
}

class DominationProgressSnapshot {
  final List<DominationProgressEntry> entries;
  final int validTileCount;

  const DominationProgressSnapshot({
    required this.entries,
    required this.validTileCount,
  });

  DominationProgressEntry? entryFor(String playerId) {
    for (final entry in entries) {
      if (entry.playerId == playerId) return entry;
    }
    return null;
  }

  DominationProgressEntry? get leader {
    if (entries.isEmpty) return null;
    final sorted = [...entries]..sort(_compareEntries);
    return sorted.first;
  }

  DominationProgressEntry? topOpponentFor(String playerId) {
    final opponents = [
      for (final entry in entries)
        if (entry.playerId != playerId) entry,
    ];
    if (opponents.isEmpty) return null;
    opponents.sort(_compareEntries);
    return opponents.first;
  }

  DominationProgressEntry? winnerCandidate() {
    final candidates = [
      for (final entry in entries)
        if (entry.canWinNow) entry,
    ];
    if (candidates.isEmpty) return null;
    candidates.sort(_compareEntries);
    if (candidates.length > 1) {
      final first = candidates[0];
      final second = candidates[1];
      if (first.controlledTileCount == second.controlledTileCount &&
          first.holdTurns == second.holdTurns) {
        return null;
      }
    }
    return candidates.first;
  }
}

class DominationProgressCalculator {
  const DominationProgressCalculator();

  DominationProgressSnapshot snapshot({
    required Iterable<String> playerIds,
    required PersistentGameState state,
    required MapData mapData,
    required VictoryRules victoryRules,
    Map<String, int>? holdTurnsByPlayerId,
  }) {
    final players = _cleanPlayerIds(playerIds);
    final validHexes = _validDominationHexes(mapData);
    final controlledByPlayer = {
      for (final playerId in players) playerId: <CityHex>{},
    };

    for (final city in state.cities) {
      final controlledHexes = controlledByPlayer[city.ownerPlayerId];
      if (controlledHexes == null) continue;
      for (final hex in city.territoryHexes) {
        if (validHexes.contains(hex)) controlledHexes.add(hex);
      }
    }

    final validTileCount = validHexes.length;
    final holds =
        holdTurnsByPlayerId ?? state.runtimeState.dominationHoldTurnsByPlayerId;
    return DominationProgressSnapshot(
      validTileCount: validTileCount,
      entries: [
        for (final playerId in players)
          _entry(
            playerId: playerId,
            controlledTileCount: controlledByPlayer[playerId]!.length,
            validTileCount: validTileCount,
            victoryRules: victoryRules,
            holdTurns: holds[playerId] ?? 0,
          ),
      ],
    );
  }

  Map<String, int> advanceHoldTurns({
    required Iterable<String> playerIds,
    required PersistentGameState state,
    required MapData mapData,
    required VictoryRules victoryRules,
    Map<String, int>? previousHoldTurnsByPlayerId,
  }) {
    if (!victoryRules.dominationEnabled) return const {};

    final progress = snapshot(
      playerIds: playerIds,
      state: state,
      mapData: mapData,
      victoryRules: victoryRules,
      holdTurnsByPlayerId:
          previousHoldTurnsByPlayerId ??
          state.runtimeState.dominationHoldTurnsByPlayerId,
    );
    final next = <String, int>{};
    for (final entry in progress.entries) {
      if (!entry.atThreshold) continue;
      next[entry.playerId] = entry.holdTurns + 1;
    }
    return Map.unmodifiable(next);
  }

  List<DominationThresholdReachedEvent> thresholdReachedEvents({
    required Iterable<String> playerIds,
    required PersistentGameState state,
    required MapData mapData,
    required VictoryRules victoryRules,
    required Map<String, int> previousHoldTurnsByPlayerId,
    required Map<String, int> nextHoldTurnsByPlayerId,
  }) {
    if (!victoryRules.dominationEnabled) return const [];

    final progress = snapshot(
      playerIds: playerIds,
      state: state,
      mapData: mapData,
      victoryRules: victoryRules,
      holdTurnsByPlayerId: nextHoldTurnsByPlayerId,
    );
    final events = <DominationThresholdReachedEvent>[];
    for (final entry in progress.entries) {
      final previousHold = previousHoldTurnsByPlayerId[entry.playerId] ?? 0;
      final nextHold = nextHoldTurnsByPlayerId[entry.playerId] ?? 0;
      if (!entry.atThreshold || previousHold > 0 || nextHold <= 0) continue;
      events.add(
        DominationThresholdReachedEvent(
          playerId: entry.playerId,
          controlPercent: entry.controlPercent,
          requiredControlPercent: entry.requiredControlPercent,
          holdTurns: entry.holdTurns,
          requiredHoldTurns: entry.requiredHoldTurns,
        ),
      );
    }
    return List.unmodifiable(events);
  }

  DominationProgressEntry _entry({
    required String playerId,
    required int controlledTileCount,
    required int validTileCount,
    required VictoryRules victoryRules,
    required int holdTurns,
  }) {
    final controlPercent = validTileCount == 0
        ? 0.0
        : controlledTileCount * 100 / validTileCount;
    return DominationProgressEntry(
      playerId: playerId,
      controlledTileCount: controlledTileCount,
      validTileCount: validTileCount,
      controlPercent: controlPercent,
      requiredControlPercent: victoryRules.dominationControlPercent,
      holdTurns: holdTurns,
      requiredHoldTurns: victoryRules.dominationHoldTurns,
    );
  }

  List<String> _cleanPlayerIds(Iterable<String> playerIds) {
    return {
      for (final playerId in playerIds)
        if (playerId.isNotEmpty) playerId,
    }.toList()..sort();
  }

  Set<CityHex> _validDominationHexes(MapData mapData) {
    return {
      for (final tile in mapData.tiles)
        if (UnitMovementCostRules.costToEnterTile(tile).passable)
          CityHex(col: tile.col, row: tile.row),
    };
  }
}

int _compareEntries(
  DominationProgressEntry left,
  DominationProgressEntry right,
) {
  final controlCompare = right.controlledTileCount.compareTo(
    left.controlledTileCount,
  );
  if (controlCompare != 0) return controlCompare;
  final holdCompare = right.holdTurns.compareTo(left.holdTurns);
  if (holdCompare != 0) return holdCompare;
  return left.playerId.compareTo(right.playerId);
}
