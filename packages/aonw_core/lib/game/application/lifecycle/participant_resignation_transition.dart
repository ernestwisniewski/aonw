import 'package:aonw_core/game/domain/outcome/game_outcome.dart';
import 'package:aonw_core/game/domain/outcome/game_outcome_resolver.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';

/// The lifecycle decision produced after a participant resigns.
enum ParticipantResignationDisposition { running, finished, abandoned }

/// Why a resignation leaves no playable match behind.
enum ParticipantResignationAbandonmentReason {
  allPlayersResigned,
  noAlivePlayersAfterResignation,
}

/// Persistence-neutral result of applying a participant resignation.
final class ParticipantResignationResult {
  const ParticipantResignationResult._({
    required this.disposition,
    this.outcome,
    this.abandonmentReason,
  });

  final ParticipantResignationDisposition disposition;
  final GameOutcome? outcome;
  final ParticipantResignationAbandonmentReason? abandonmentReason;
}

/// Resolves the lifecycle decision after the engine applied a resignation.
///
/// The ordered human roster is supplied by the application boundary because
/// account ownership and AI seats are not domain-rule concerns.
abstract final class ParticipantResignationTransition {
  static ParticipantResignationResult resolve({
    required DomainState domain,
    required Iterable<String> orderedHumanPlayerIds,
  }) {
    final remainingHumanPlayerIds = [
      for (final playerId in orderedHumanPlayerIds)
        if (!domain.isKicked(playerId)) playerId,
    ];
    return _resolveLifecycle(
      domain: domain,
      remainingHumanPlayerIds: remainingHumanPlayerIds,
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
        disposition: ParticipantResignationDisposition.finished,
        outcome: GameOutcome.resignation(alivePlayerIds.single),
      );
    }
    if (alivePlayerIds.isEmpty) {
      return ParticipantResignationResult._(
        disposition: ParticipantResignationDisposition.abandoned,
        abandonmentReason: remainingHumanPlayerIds.isEmpty
            ? ParticipantResignationAbandonmentReason.allPlayersResigned
            : ParticipantResignationAbandonmentReason
                  .noAlivePlayersAfterResignation,
      );
    }
    return const ParticipantResignationResult._(
      disposition: ParticipantResignationDisposition.running,
    );
  }
}
