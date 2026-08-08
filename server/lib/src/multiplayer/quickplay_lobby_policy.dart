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
  const QuickplayLobbyPolicy({this.countdown = const Duration(seconds: 30)});

  final Duration countdown;

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
}
