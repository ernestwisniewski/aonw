import 'package:aonw_core/game/domain/outcome/game_outcome.dart';
import 'package:aonw_core/game/domain/outcome/game_outcome_resolver.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';

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
    required this.domain,
    required this.disposition,
    this.outcome,
    this.abandonmentReason,
  });

  final DomainState domain;
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
    if (domain.isKicked(actorPlayerId)) {
      return ParticipantResignationResult._(
        domain: domain,
        disposition: ParticipantResignationDisposition.unchanged,
      );
    }

    final nextDomain = _domainAfterResignation(domain, actorPlayerId);
    final remainingHumanPlayerIds = [
      for (final playerId in orderedHumanPlayerIds)
        if (!nextDomain.isKicked(playerId)) playerId,
    ];
    return _resolveLifecycle(
      domain: nextDomain,
      remainingHumanPlayerIds: remainingHumanPlayerIds,
    );
  }

  static DomainState _domainAfterResignation(
    DomainState domain,
    String actorPlayerId,
  ) {
    return domain.copyWith(
      turnStatesByPlayerId: {
        ...domain.turnStatesByPlayerId,
        if (domain.turnStatesByPlayerId.containsKey(actorPlayerId))
          actorPlayerId: PlayerTurnState.finished,
      },
      submittedPlayerIds: domain.submittedPlayerIds.difference({actorPlayerId}),
      afkPlayerIds: {...domain.afkPlayerIds, actorPlayerId},
      kickedPlayerIds: {...domain.kickedPlayerIds, actorPlayerId},
    );
  }

  static ParticipantResignationResult _resolveLifecycle({
    required DomainState domain,
    required List<String> remainingHumanPlayerIds,
  }) {
    final alivePlayerIds = const GameOutcomeResolver().alivePlayerIds(
      playerIds: remainingHumanPlayerIds,
      units: domain.units,
      cities: domain.cities,
    );

    if (alivePlayerIds.length == 1) {
      return ParticipantResignationResult._(
        domain: domain,
        disposition: ParticipantResignationDisposition.finished,
        outcome: GameOutcome.resignation(alivePlayerIds.single),
      );
    }
    if (alivePlayerIds.isEmpty) {
      return ParticipantResignationResult._(
        domain: domain,
        disposition: ParticipantResignationDisposition.abandoned,
        abandonmentReason: remainingHumanPlayerIds.isEmpty
            ? ParticipantResignationAbandonmentReason.allPlayersResigned
            : ParticipantResignationAbandonmentReason
                  .noAlivePlayersAfterResignation,
      );
    }
    return ParticipantResignationResult._(
      domain: domain,
      disposition: ParticipantResignationDisposition.running,
    );
  }
}
