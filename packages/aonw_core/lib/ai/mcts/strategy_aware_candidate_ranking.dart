import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';

enum CandidatePriority { opening, war, settler, defense, cityRole, fallback }

const blockedCandidateScore = -900.0;

final class CommandRanking {
  final CandidatePriority priority;
  final double score;

  const CommandRanking(this.priority, this.score);
}

final class RankedCandidate {
  final CommandMctsAction action;
  final int index;
  final CommandRanking ranking;

  const RankedCandidate({
    required this.action,
    required this.index,
    required this.ranking,
  });
}

List<RankedCandidate> selectRankedCandidates(
  List<RankedCandidate> ranked, {
  required StrategicMode mode,
  required int candidateLimit,
}) {
  final sorted = [...ranked]..sort(compareRankedCandidates);
  final quotas = _slotQuotas(mode, candidateLimit);
  final selected = <RankedCandidate>[];
  final selectedIndexes = <int>{};

  for (final priority in CandidatePriority.values) {
    final quota = quotas[priority] ?? 0;
    if (quota <= 0) continue;
    var taken = 0;
    for (final candidate in sorted) {
      if (candidate.ranking.priority != priority) continue;
      if (!selectedIndexes.add(candidate.index)) continue;
      selected.add(candidate);
      taken++;
      if (selected.length >= candidateLimit || taken >= quota) break;
    }
    if (selected.length >= candidateLimit) return selected;
  }

  for (final candidate in sorted) {
    if (!selectedIndexes.add(candidate.index)) continue;
    selected.add(candidate);
    if (selected.length >= candidateLimit) break;
  }

  return selected;
}

int compareRankedCandidates(RankedCandidate a, RankedCandidate b) {
  final priority = a.ranking.priority.index.compareTo(b.ranking.priority.index);
  if (priority != 0) return priority;
  final score = b.ranking.score.compareTo(a.ranking.score);
  if (score != 0) return score;
  return a.index.compareTo(b.index);
}

int expandedCandidateLimit(int candidateLimit) {
  if (candidateLimit <= 0) return 0;
  final expanded = candidateLimit * 3;
  return expanded > candidateLimit ? expanded : candidateLimit;
}

Map<CandidatePriority, int> _slotQuotas(StrategicMode mode, int limit) {
  if (limit <= 0) return const {};
  final weights = switch (mode) {
    StrategicMode.military => const {
      CandidatePriority.opening: 4,
      CandidatePriority.war: 5,
      CandidatePriority.settler: 2,
      CandidatePriority.defense: 4,
      CandidatePriority.cityRole: 3,
      CandidatePriority.fallback: 6,
    },
    StrategicMode.expand => const {
      CandidatePriority.opening: 5,
      CandidatePriority.war: 2,
      CandidatePriority.settler: 6,
      CandidatePriority.defense: 3,
      CandidatePriority.cityRole: 4,
      CandidatePriority.fallback: 4,
    },
    StrategicMode.recover => const {
      CandidatePriority.opening: 4,
      CandidatePriority.war: 2,
      CandidatePriority.settler: 2,
      CandidatePriority.defense: 6,
      CandidatePriority.cityRole: 4,
      CandidatePriority.fallback: 6,
    },
    StrategicMode.techRush => const {
      CandidatePriority.opening: 4,
      CandidatePriority.war: 2,
      CandidatePriority.settler: 2,
      CandidatePriority.defense: 3,
      CandidatePriority.cityRole: 6,
      CandidatePriority.fallback: 7,
    },
    StrategicMode.consolidate => const {
      CandidatePriority.opening: 4,
      CandidatePriority.war: 4,
      CandidatePriority.settler: 3,
      CandidatePriority.defense: 3,
      CandidatePriority.cityRole: 4,
      CandidatePriority.fallback: 6,
    },
  };

  final quotas = <CandidatePriority, int>{};
  var assigned = 0;
  for (final entry in weights.entries) {
    final quota = entry.value * limit ~/ 24;
    quotas[entry.key] = quota;
    assigned += quota;
  }

  for (final priority in _modePriorityOrder(mode)) {
    if (assigned >= limit) break;
    quotas[priority] = (quotas[priority] ?? 0) + 1;
    assigned++;
  }

  return quotas;
}

List<CandidatePriority> _modePriorityOrder(StrategicMode mode) {
  return switch (mode) {
    StrategicMode.military => const [
      CandidatePriority.opening,
      CandidatePriority.war,
      CandidatePriority.defense,
      CandidatePriority.cityRole,
      CandidatePriority.settler,
      CandidatePriority.fallback,
    ],
    StrategicMode.expand => const [
      CandidatePriority.opening,
      CandidatePriority.settler,
      CandidatePriority.cityRole,
      CandidatePriority.defense,
      CandidatePriority.war,
      CandidatePriority.fallback,
    ],
    StrategicMode.recover => const [
      CandidatePriority.opening,
      CandidatePriority.defense,
      CandidatePriority.cityRole,
      CandidatePriority.fallback,
      CandidatePriority.war,
      CandidatePriority.settler,
    ],
    StrategicMode.techRush => const [
      CandidatePriority.opening,
      CandidatePriority.cityRole,
      CandidatePriority.defense,
      CandidatePriority.settler,
      CandidatePriority.war,
      CandidatePriority.fallback,
    ],
    StrategicMode.consolidate => const [
      CandidatePriority.opening,
      CandidatePriority.war,
      CandidatePriority.settler,
      CandidatePriority.defense,
      CandidatePriority.cityRole,
      CandidatePriority.fallback,
    ],
  };
}
