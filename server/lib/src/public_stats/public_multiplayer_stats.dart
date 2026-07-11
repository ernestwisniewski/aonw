final class PublicMultiplayerTotals {
  const PublicMultiplayerTotals({
    required this.activeSessions,
    required this.openLobbies,
    required this.matchesStarted,
    required this.matchesCompleted,
    required this.matchesAbandoned,
  });

  final int activeSessions;
  final int openLobbies;
  final int matchesStarted;
  final int matchesCompleted;
  final int matchesAbandoned;

  Map<String, Object> toJson() => {
    'activeSessions': activeSessions,
    'openLobbies': openLobbies,
    'matchesStarted': matchesStarted,
    'matchesCompleted': matchesCompleted,
    'matchesAbandoned': matchesAbandoned,
  };
}

final class PublicMultiplayerActivityPoint {
  const PublicMultiplayerActivityPoint({
    required this.date,
    required this.started,
    required this.completed,
  });

  final String date;
  final int started;
  final int completed;

  Map<String, Object> toJson() => {
    'date': date,
    'started': started,
    'completed': completed,
  };
}

final class PublicMultiplayerOutcomeCount {
  const PublicMultiplayerOutcomeCount({
    required this.condition,
    required this.count,
  });

  final String condition;
  final int count;

  Map<String, Object> toJson() => {'condition': condition, 'count': count};
}

final class PublicMultiplayerTurnDistributionPoint {
  const PublicMultiplayerTurnDistributionPoint({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  Map<String, Object> toJson() => {'label': label, 'count': count};
}

final class PublicMultiplayerTurnStats {
  const PublicMultiplayerTurnStats({
    required this.averageCompleted,
    required this.longestCompleted,
    required this.totalPlayed,
    required this.distribution,
  });

  final double averageCompleted;
  final int longestCompleted;
  final int totalPlayed;
  final List<PublicMultiplayerTurnDistributionPoint> distribution;

  Map<String, Object> toJson() => {
    'averageCompleted': averageCompleted,
    'longestCompleted': longestCompleted,
    'totalPlayed': totalPlayed,
    'distribution': [for (final point in distribution) point.toJson()],
  };
}

final class PublicMultiplayerStats {
  const PublicMultiplayerStats({
    required this.generatedAt,
    required this.windowDays,
    required this.totals,
    required this.activity,
    required this.outcomes,
    required this.turns,
  });

  static const schemaVersion = 1;

  final DateTime generatedAt;
  final int windowDays;
  final PublicMultiplayerTotals totals;
  final List<PublicMultiplayerActivityPoint> activity;
  final List<PublicMultiplayerOutcomeCount> outcomes;
  final PublicMultiplayerTurnStats turns;

  Map<String, Object> toJson() => {
    'schemaVersion': schemaVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'windowDays': windowDays,
    'totals': totals.toJson(),
    'activity': [for (final point in activity) point.toJson()],
    'outcomes': [for (final outcome in outcomes) outcome.toJson()],
    'turns': turns.toJson(),
  };
}
