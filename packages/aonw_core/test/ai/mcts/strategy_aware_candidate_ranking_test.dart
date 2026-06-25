import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('strategy-aware candidate ranking', () {
    test('fills mode quotas before best remaining candidates', () {
      final selected = selectRankedCandidates(
        [
          _candidate(0, CandidatePriority.fallback, 100),
          _candidate(1, CandidatePriority.war, 80),
          _candidate(2, CandidatePriority.settler, 30),
          _candidate(3, CandidatePriority.opening, 10),
          _candidate(4, CandidatePriority.cityRole, 40),
          _candidate(5, CandidatePriority.defense, 35),
        ],
        mode: StrategicMode.expand,
        candidateLimit: 4,
      )..sort(compareRankedCandidates);

      expect(selected.map((candidate) => candidate.ranking.priority), [
        CandidatePriority.opening,
        CandidatePriority.war,
        CandidatePriority.settler,
        CandidatePriority.cityRole,
      ]);
    });

    test('sorts by priority, then score, then source order', () {
      final candidates = [
        _candidate(2, CandidatePriority.war, 10),
        _candidate(1, CandidatePriority.war, 10),
        _candidate(0, CandidatePriority.opening, 1),
        _candidate(3, CandidatePriority.war, 20),
      ]..sort(compareRankedCandidates);

      expect(candidates.map((candidate) => candidate.index), [0, 3, 1, 2]);
    });
  });
}

RankedCandidate _candidate(
  int index,
  CandidatePriority priority,
  double score,
) {
  return RankedCandidate(
    action: CommandMctsAction(MoveUnitCommand('unit_$index', index, 0)),
    index: index,
    ranking: CommandRanking(priority, score),
  );
}
