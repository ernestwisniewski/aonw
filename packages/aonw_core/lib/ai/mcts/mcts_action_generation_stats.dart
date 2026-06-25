class MctsActionGenerationStats {
  final int candidateCalls;
  final int terminalCandidateCalls;
  final Duration candidateGenerationElapsed;
  final int rawCandidateCount;
  final int selectedCandidateCount;
  final int sourcePlanCalls;
  final int sourcePlanSkipped;
  final Duration sourcePlanElapsed;
  final int sourcePlanCommandCount;

  const MctsActionGenerationStats({
    this.candidateCalls = 0,
    this.terminalCandidateCalls = 0,
    this.candidateGenerationElapsed = Duration.zero,
    this.rawCandidateCount = 0,
    this.selectedCandidateCount = 0,
    this.sourcePlanCalls = 0,
    this.sourcePlanSkipped = 0,
    this.sourcePlanElapsed = Duration.zero,
    this.sourcePlanCommandCount = 0,
  });

  bool get hasSamples => candidateCalls > 0 || sourcePlanCalls > 0;

  List<String> toNotes() {
    if (!hasSamples) return const [];
    return [
      'candidate calls $candidateCalls',
      'candidate elapsed ${candidateGenerationElapsed.inMilliseconds}ms',
      'source plans $sourcePlanCalls',
      'source plans skipped $sourcePlanSkipped',
      'source plan elapsed ${sourcePlanElapsed.inMilliseconds}ms',
      'source commands $sourcePlanCommandCount',
      'raw candidates $rawCandidateCount',
      'selected candidates $selectedCandidateCount',
    ];
  }

  Map<String, Object?> toMetrics() {
    if (!hasSamples) return const {};
    return {
      'mcts.candidateCalls': candidateCalls,
      'mcts.terminalCandidateCalls': terminalCandidateCalls,
      'mcts.candidateElapsedMicros': candidateGenerationElapsed.inMicroseconds,
      'mcts.rawCandidates': rawCandidateCount,
      'mcts.selectedCandidates': selectedCandidateCount,
      'mcts.sourcePlanCalls': sourcePlanCalls,
      'mcts.sourcePlanSkipped': sourcePlanSkipped,
      'mcts.sourcePlanElapsedMicros': sourcePlanElapsed.inMicroseconds,
      'mcts.sourcePlanCommands': sourcePlanCommandCount,
    };
  }
}

class MctsActionGenerationStatsCollector {
  int candidateCalls = 0;
  int terminalCandidateCalls = 0;
  Duration candidateGenerationElapsed = Duration.zero;
  int rawCandidateCount = 0;
  int selectedCandidateCount = 0;
  int sourcePlanCalls = 0;
  int sourcePlanSkipped = 0;
  Duration sourcePlanElapsed = Duration.zero;
  int sourcePlanCommandCount = 0;

  void recordCandidateCall({
    required Duration elapsed,
    required int rawCandidates,
    required int selectedCandidates,
    bool terminal = false,
  }) {
    candidateCalls += 1;
    if (terminal) terminalCandidateCalls += 1;
    candidateGenerationElapsed += elapsed;
    rawCandidateCount += rawCandidates;
    selectedCandidateCount += selectedCandidates;
  }

  void recordSourcePlan({
    required Duration elapsed,
    required int commandCount,
  }) {
    sourcePlanCalls += 1;
    sourcePlanElapsed += elapsed;
    sourcePlanCommandCount += commandCount;
  }

  void recordSourcePlanSkipped() {
    sourcePlanSkipped += 1;
  }

  MctsActionGenerationStats snapshot() {
    return MctsActionGenerationStats(
      candidateCalls: candidateCalls,
      terminalCandidateCalls: terminalCandidateCalls,
      candidateGenerationElapsed: candidateGenerationElapsed,
      rawCandidateCount: rawCandidateCount,
      selectedCandidateCount: selectedCandidateCount,
      sourcePlanCalls: sourcePlanCalls,
      sourcePlanSkipped: sourcePlanSkipped,
      sourcePlanElapsed: sourcePlanElapsed,
      sourcePlanCommandCount: sourcePlanCommandCount,
    );
  }
}
