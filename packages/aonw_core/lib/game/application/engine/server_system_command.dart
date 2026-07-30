sealed class ServerSystemCommand {
  const ServerSystemCommand();
}

/// Finalizes an expired simultaneous turn using the participant scope chosen
/// by the trusted server boundary.
final class FinalizeTimedOutTurn extends ServerSystemCommand {
  const FinalizeTimedOutTurn({
    required this.playerIds,
    required this.skippedPlayerIds,
  });

  final List<String> playerIds;
  final List<String> skippedPlayerIds;
}

/// Applies the existing participant-unavailable lifecycle transition.
final class KickParticipant extends ServerSystemCommand {
  const KickParticipant({
    required this.playerId,
    required this.reason,
    required this.timeoutStreak,
  });

  final String playerId;
  final String reason;
  final int timeoutStreak;
}
