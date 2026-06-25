import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class DiplomacyTurnResolution {
  const DiplomacyTurnResolution({
    required this.diplomacy,
    this.events = const [],
  });

  final DiplomacyState diplomacy;
  final List<GameEvent> events;
}

abstract final class DiplomacyTurnResolver {
  static DiplomacyTurnResolution resolve({
    required DiplomacyState diplomacy,
    required int turn,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    var next = diplomacy;
    final events = <GameEvent>[];

    for (final proposal in diplomacy.expiredProposals(turn)) {
      next = next.removeProposal(proposal.id);
      events.add(
        DiplomaticProposalExpiredEvent(
          proposalId: proposal.id,
          fromPlayerId: proposal.fromPlayerId,
          toPlayerId: proposal.toPlayerId,
          kind: proposal.kind,
        ),
      );
    }

    for (final message in diplomacy.expiredMessages(turn)) {
      next = next.removeMessage(message.id);
    }

    for (final relation in diplomacy.expiredTruces(turn)) {
      next = next.setStatus(
        relation.playerAId,
        relation.playerBId,
        DiplomaticRelationStatus.neutral,
        turn: turn,
        reason: DiplomaticRelationChangeReason.truceExpired,
      );
      events.add(
        DiplomaticRelationChangedEvent(
          playerAId: relation.playerAId,
          playerBId: relation.playerBId,
          oldStatus: DiplomaticRelationStatus.truce,
          newStatus: DiplomaticRelationStatus.neutral,
          reason: DiplomaticRelationChangeReason.truceExpired,
        ),
      );
    }

    final unitList = units.toList(growable: false);
    final cityList = cities.toList(growable: false);
    for (final promise in diplomacy.promisesDue(turn)) {
      if (!_promiseBroken(promise, units: unitList, cities: cityList)) {
        continue;
      }
      final marked = promise.copyWith(promiseBroken: true);
      next = next
          .updateMessage(marked)
          .adjustRelationScore(
            promise.fromPlayerId,
            promise.toPlayerId,
            DiplomacyState.defaultPromiseBrokenPenalty,
            turn: turn,
            reason: DiplomaticScoreChangeReason.promiseBroken,
            sourceId: promise.id,
          );
      final relation = next.relationBetween(
        promise.fromPlayerId,
        promise.toPlayerId,
      );
      events.addAll([
        DiplomaticPromiseBrokenEvent(
          messageId: promise.id,
          playerAId: relation.playerAId,
          playerBId: relation.playerBId,
          delta: DiplomacyState.defaultPromiseBrokenPenalty,
          scoreAfter: relation.relationScore,
        ),
        DiplomaticScoreChangedEvent(
          playerAId: relation.playerAId,
          playerBId: relation.playerBId,
          delta: DiplomacyState.defaultPromiseBrokenPenalty,
          scoreAfter: relation.relationScore,
          reason: DiplomaticScoreChangeReason.promiseBroken,
          sourceId: promise.id,
        ),
      ]);
    }

    return DiplomacyTurnResolution(diplomacy: next, events: events);
  }

  static bool _promiseBroken(
    DiplomaticMessage promise, {
    required List<GameUnit> units,
    required List<GameCity> cities,
  }) {
    if (!promise.topic.canCreateWithdrawalPromise) return false;
    final promisedByPlayerId = promise.toPlayerId;
    final protectedPlayerId = promise.fromPlayerId;
    final protectedCities = [
      for (final city in cities)
        if (city.ownerPlayerId == protectedPlayerId) city,
    ];
    if (protectedCities.isEmpty) return false;

    for (final unit in units) {
      if (unit.ownerPlayerId != promisedByPlayerId) continue;
      final unitHex = HexCoordinate(col: unit.col, row: unit.row);
      for (final city in protectedCities) {
        final cityHex = HexCoordinate(
          col: city.center.col,
          row: city.center.row,
        );
        if (HexDistance.between(unitHex, cityHex) <= 2) return true;
      }
    }
    return false;
  }
}
