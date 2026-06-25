enum QuickplayLobbyAction { waitForPlayers, waitForCountdown, start }

final class QuickplayLobbyDecision {
  const QuickplayLobbyDecision._(this.action, this.autoStartAt);

  const QuickplayLobbyDecision.waitForPlayers()
    : this._(QuickplayLobbyAction.waitForPlayers, null);

  const QuickplayLobbyDecision.waitForCountdown(DateTime autoStartAt)
    : this._(QuickplayLobbyAction.waitForCountdown, autoStartAt);

  const QuickplayLobbyDecision.start()
    : this._(QuickplayLobbyAction.start, null);

  final QuickplayLobbyAction action;
  final DateTime? autoStartAt;
}

final class QuickplayLobbyPolicy {
  const QuickplayLobbyPolicy({
    this.countdown = const Duration(seconds: 30),
    this.waitingForPlayersTimeout = const Duration(minutes: 1),
  });

  final Duration countdown;
  final Duration waitingForPlayersTimeout;

  QuickplayLobbyDecision evaluate({
    required int humanPlayers,
    required int minPlayers,
    required int maxPlayers,
    required DateTime nowUtc,
    required DateTime? currentAutoStartAt,
  }) {
    if (humanPlayers >= maxPlayers) {
      return const QuickplayLobbyDecision.start();
    }
    if (humanPlayers < minPlayers) {
      return const QuickplayLobbyDecision.waitForPlayers();
    }

    final existingDeadline = currentAutoStartAt?.toUtc();
    if (existingDeadline == null) {
      return QuickplayLobbyDecision.waitForCountdown(
        nowUtc.toUtc().add(countdown),
      );
    }
    if (!nowUtc.toUtc().isBefore(existingDeadline)) {
      return const QuickplayLobbyDecision.start();
    }
    return QuickplayLobbyDecision.waitForCountdown(existingDeadline);
  }

  bool isStaleWaitingForPlayers({
    required int humanPlayers,
    required int minPlayers,
    required DateTime createdAt,
    required DateTime nowUtc,
    required DateTime? currentAutoStartAt,
  }) {
    if (humanPlayers >= minPlayers) return false;
    if (currentAutoStartAt != null) return false;
    return !createdAt
        .toUtc()
        .add(waitingForPlayersTimeout)
        .isAfter(nowUtc.toUtc());
  }
}
