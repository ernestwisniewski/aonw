import 'package:aonw_core/game/application/lifecycle/match_lifecycle_state.dart';

sealed class ClientObservedMatchLifecycleState {
  const ClientObservedMatchLifecycleState();

  bool get canLoadOrRun =>
      this is LoadingObservedMatchLifecycleState ||
      this is RunningObservedMatchLifecycleState;

  bool get isTerminal =>
      this is FinishedObservedMatchLifecycleState ||
      this is AbandonedObservedMatchLifecycleState;
}

final class OpenObservedMatchLifecycleState
    extends ClientObservedMatchLifecycleState {
  const OpenObservedMatchLifecycleState();
}

final class LoadingObservedMatchLifecycleState
    extends ClientObservedMatchLifecycleState {
  const LoadingObservedMatchLifecycleState();
}

final class RunningObservedMatchLifecycleState
    extends ClientObservedMatchLifecycleState {
  const RunningObservedMatchLifecycleState();
}

final class FinishedObservedMatchLifecycleState
    extends ClientObservedMatchLifecycleState {
  const FinishedObservedMatchLifecycleState();
}

final class AbandonedObservedMatchLifecycleState
    extends ClientObservedMatchLifecycleState {
  const AbandonedObservedMatchLifecycleState();
}

/// Lossless mapping between the typed application lifecycle and existing
/// persistence/player-wire string values.
final class MatchLifecycleWireAdapter {
  const MatchLifecycleWireAdapter();

  MatchLifecycleState decodeState(String value, {String? terminalReason}) {
    return switch (value) {
      'open' => const OpenMatchLifecycleState(),
      'running' => const RunningMatchLifecycleState(),
      'finished' => FinishedMatchLifecycleState(
        reason: decodeFinishedReason(
          terminalReason ??
              (throw const FormatException(
                'Finished match lifecycle requires a completion reason.',
              )),
        ),
      ),
      'abandoned' => AbandonedMatchLifecycleState(
        reason: decodeAbandonmentReason(
          terminalReason ??
              (throw const FormatException(
                'Abandoned match lifecycle requires an abandonment reason.',
              )),
        ),
      ),
      _ => throw FormatException('Unknown match lifecycle state: $value'),
    };
  }

  String encodeState(MatchLifecycleState state) {
    return switch (state) {
      OpenMatchLifecycleState() => 'open',
      RunningMatchLifecycleState() => 'running',
      FinishedMatchLifecycleState() => 'finished',
      AbandonedMatchLifecycleState() => 'abandoned',
    };
  }

  ClientObservedMatchLifecycleState decodeObservedState(String value) {
    return switch (value) {
      'open' => const OpenObservedMatchLifecycleState(),
      'loading' => const LoadingObservedMatchLifecycleState(),
      'running' => const RunningObservedMatchLifecycleState(),
      'finished' => const FinishedObservedMatchLifecycleState(),
      'abandoned' => const AbandonedObservedMatchLifecycleState(),
      _ => throw FormatException(
        'Unknown observed match lifecycle state: $value',
      ),
    };
  }

  MatchCompletionReason decodeFinishedReason(String value) {
    return switch (value) {
      'conquest' => MatchCompletionReason.conquest,
      'domination' => MatchCompletionReason.domination,
      'cultural' => MatchCompletionReason.cultural,
      'score' => MatchCompletionReason.score,
      'resignation' => MatchCompletionReason.resignation,
      'draw' => MatchCompletionReason.draw,
      _ => throw FormatException('Unknown match completion reason: $value'),
    };
  }

  String encodeFinishedReason(MatchCompletionReason reason) => reason.name;

  MatchAbandonmentReason decodeAbandonmentReason(String value) {
    return switch (value) {
      'player_resigned' => MatchAbandonmentReason.playerResigned,
      'owner_left' => MatchAbandonmentReason.ownerLeft,
      'player_left' => MatchAbandonmentReason.playerLeft,
      'quickplay_stale' => MatchAbandonmentReason.quickplayStale,
      'protocol_upgrade' => MatchAbandonmentReason.protocolUpgrade,
      'all_players_resigned' => MatchAbandonmentReason.allPlayersResigned,
      'no_alive_players_after_resignation' =>
        MatchAbandonmentReason.noAlivePlayersAfterResignation,
      'all_players_inactive' => MatchAbandonmentReason.allPlayersInactive,
      _ => throw FormatException('Unknown match abandonment reason: $value'),
    };
  }

  String encodeAbandonmentReason(MatchAbandonmentReason reason) {
    return switch (reason) {
      MatchAbandonmentReason.playerResigned => 'player_resigned',
      MatchAbandonmentReason.ownerLeft => 'owner_left',
      MatchAbandonmentReason.playerLeft => 'player_left',
      MatchAbandonmentReason.quickplayStale => 'quickplay_stale',
      MatchAbandonmentReason.protocolUpgrade => 'protocol_upgrade',
      MatchAbandonmentReason.allPlayersResigned => 'all_players_resigned',
      MatchAbandonmentReason.noAlivePlayersAfterResignation =>
        'no_alive_players_after_resignation',
      MatchAbandonmentReason.allPlayersInactive => 'all_players_inactive',
    };
  }
}
