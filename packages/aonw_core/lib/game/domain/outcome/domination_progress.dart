final class DominationProgressEntry {
  const DominationProgressEntry({
    required this.playerId,
    required this.controlledTileCount,
    required this.validTileCount,
    required this.controlPercent,
    required this.requiredControlPercent,
    required this.holdTurns,
    required this.requiredHoldTurns,
  });

  final String playerId;
  final int controlledTileCount;
  final int validTileCount;
  final double controlPercent;
  final double requiredControlPercent;
  final int holdTurns;
  final int requiredHoldTurns;

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

final class DominationThreat {
  const DominationThreat({required this.entry, required this.level});

  final DominationProgressEntry entry;
  final DominationThreatLevel level;
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

final class DominationProgressSnapshot {
  const DominationProgressSnapshot({
    required this.entries,
    required this.validTileCount,
  });

  final List<DominationProgressEntry> entries;
  final int validTileCount;

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
