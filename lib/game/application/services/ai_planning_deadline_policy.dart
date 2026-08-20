enum AiPlanningDeadlinePolicy {
  unbounded,
  networkTurn;

  static const networkTurnDuration = Duration(seconds: 115);

  DateTime? resolve({
    required DateTime savedAt,
    required DateTime? turnStartedAt,
  }) {
    return switch (this) {
      AiPlanningDeadlinePolicy.unbounded => null,
      AiPlanningDeadlinePolicy.networkTurn =>
        (turnStartedAt ?? savedAt).toUtc().add(networkTurnDuration),
    };
  }
}
