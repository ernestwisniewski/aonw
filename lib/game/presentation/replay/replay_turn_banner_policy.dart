class ReplayTurnBannerPolicy {
  const ReplayTurnBannerPolicy._();

  static int? turnForTransition({
    required int previousTurn,
    required int targetTurn,
    required bool animated,
    required bool forward,
  }) {
    if (!animated || !forward) return null;
    if (targetTurn <= previousTurn) return null;
    return targetTurn;
  }
}
