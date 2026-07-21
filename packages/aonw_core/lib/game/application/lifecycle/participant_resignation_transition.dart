import 'package:aonw_core/game/domain/outcome/game_outcome.dart';
import 'package:aonw_core/game/domain/outcome/game_outcome_resolver.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/state/match_session_state.dart';

/// The lifecycle decision produced after a participant resigns.
enum ParticipantResignationDisposition {
  unchanged,
  running,
  finished,
  abandoned,
}

/// Why a resignation leaves no playable match behind.
enum ParticipantResignationAbandonmentReason {
  allPlayersResigned,
  noAlivePlayersAfterResignation,
}

/// Persistence-neutral result of applying a participant resignation.
final class ParticipantResignationResult {
  const ParticipantResignationResult._({
    required this.session,
    required this.disposition,
    this.outcome,
    this.abandonmentReason,
  });

  final MatchSessionState session;
  final ParticipantResignationDisposition disposition;
  final GameOutcome? outcome;
  final ParticipantResignationAbandonmentReason? abandonmentReason;

  bool get changed =>
      disposition != ParticipantResignationDisposition.unchanged;
}

/// Applies the canonical session transition caused by a player resignation.
///
/// The ordered human roster is supplied by the application boundary because
/// account ownership and AI seats are not domain-rule concerns.
abstract final class ParticipantResignationTransition {
  static ParticipantResignationResult apply({
    required DomainState domain,
    required MatchSessionState session,
    required String actorPlayerId,
    required Iterable<String> orderedHumanPlayerIds,
  }) {
    if (actorPlayerId.isEmpty) {
      throw ArgumentError.value(
        actorPlayerId,
        'actorPlayerId',
        'Must not be empty',
      );
    }
    if (session.isKicked(actorPlayerId)) {
      return ParticipantResignationResult._(
        session: session,
        disposition: ParticipantResignationDisposition.unchanged,
      );
    }

    final nextSession = _sessionAfterResignation(session, actorPlayerId);
    final remainingHumanPlayerIds = [
      for (final playerId in orderedHumanPlayerIds)
        if (!nextSession.isKicked(playerId)) playerId,
    ];
    return _resolveLifecycle(
      domain: domain,
      session: nextSession,
      remainingHumanPlayerIds: remainingHumanPlayerIds,
    );
  }

  static MatchSessionState _sessionAfterResignation(
    MatchSessionState session,
    String actorPlayerId,
  ) {
    return session.copyWith(
      turnStatesByPlayerId: {
        ...session.turnStatesByPlayerId,
        if (session.turnStatesByPlayerId.containsKey(actorPlayerId))
          actorPlayerId: PlayerTurnState.finished,
      },
      submittedPlayerIds: session.submittedPlayerIds.difference({
        actorPlayerId,
      }),
      afkPlayerIds: {...session.afkPlayerIds, actorPlayerId},
      kickedPlayerIds: {...session.kickedPlayerIds, actorPlayerId},
    );
  }

  static ParticipantResignationResult _resolveLifecycle({
    required DomainState domain,
    required MatchSessionState session,
    required List<String> remainingHumanPlayerIds,
  }) {
    final alivePlayerIds = const GameOutcomeResolver().alivePlayerIds(
      playerIds: remainingHumanPlayerIds,
      units: domain.units,
      cities: domain.cities,
    );

    if (alivePlayerIds.length == 1) {
      return ParticipantResignationResult._(
        session: session,
        disposition: ParticipantResignationDisposition.finished,
        outcome: GameOutcome.resignation(alivePlayerIds.single),
      );
    }
    if (alivePlayerIds.isEmpty) {
      return ParticipantResignationResult._(
        session: session,
        disposition: ParticipantResignationDisposition.abandoned,
        abandonmentReason: remainingHumanPlayerIds.isEmpty
            ? ParticipantResignationAbandonmentReason.allPlayersResigned
            : ParticipantResignationAbandonmentReason
                  .noAlivePlayersAfterResignation,
      );
    }
    return ParticipantResignationResult._(
      session: session,
      disposition: ParticipantResignationDisposition.running,
    );
  }
}
