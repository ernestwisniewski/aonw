import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/stability/stability_band.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_core/util/wire_json.dart';

/// JSON serialization / deserialization for the [GameEvent] sealed hierarchy.
///
/// Used for multiplayer transport — each event is encoded as a flat JSON map
/// with a `type` discriminator field plus event-specific payload fields.
abstract final class GameEventSerializer {
  /// Serializes [event] to a JSON-compatible map.
  ///
  /// The `type` key holds a stable string discriminator.
  /// The switch expression is exhaustive over the sealed class, so adding a new
  /// subtype without updating this method will cause a compile-time error.
  static Map<String, dynamic> toJson(GameEvent event) => switch (event) {
    CityFoundedEvent(:final cityId, :final ownerPlayerId) => {
      'type': 'CityFounded',
      'cityId': cityId,
      'ownerPlayerId': ownerPlayerId,
    },
    CityBuiltBuildingEvent(:final cityId, :final buildingType) => {
      'type': 'CityBuiltBuilding',
      'cityId': cityId,
      'buildingType': buildingType.name,
    },
    CityProducedUnitEvent(
      :final cityId,
      :final unitType,
      :final producedUnitId,
    ) =>
      {
        'type': 'CityProducedUnit',
        'cityId': cityId,
        'unitType': unitType.name,
        'producedUnitId': producedUnitId,
      },
    CityClaimedHexEvent(:final cityId, :final col, :final row) => {
      'type': 'CityClaimedHex',
      'cityId': cityId,
      'col': col,
      'row': row,
    },
    UnitMovedEvent(
      :final unitId,
      :final fromCol,
      :final fromRow,
      :final toCol,
      :final toRow,
    ) =>
      {
        'type': 'UnitMoved',
        'unitId': unitId,
        'fromCol': fromCol,
        'fromRow': fromRow,
        'toCol': toCol,
        'toRow': toRow,
      },
    UnitGainedExperienceEvent(
      :final unitId,
      :final ownerPlayerId,
      :final amount,
      :final totalExperience,
      :final rank,
      :final promoted,
    ) =>
      {
        'type': 'UnitGainedExperience',
        'unitId': unitId,
        'ownerPlayerId': ownerPlayerId,
        'amount': amount,
        'totalExperience': totalExperience,
        'rank': rank.name,
        'promoted': promoted,
      },
    UnitAttackedEvent(
      :final attackerUnitId,
      :final attackerOwnerPlayerId,
      :final defenderUnitId,
      :final defenderOwnerPlayerId,
    ) =>
      {
        'type': 'UnitAttacked',
        'attackerUnitId': attackerUnitId,
        'attackerOwnerPlayerId': attackerOwnerPlayerId,
        'defenderUnitId': defenderUnitId,
        'defenderOwnerPlayerId': defenderOwnerPlayerId,
      },
    CombatResolvedEvent(
      :final attackerUnitId,
      :final defenderUnitId,
      :final outcome,
    ) =>
      {
        'type': 'CombatResolved',
        'attackerUnitId': attackerUnitId,
        'defenderUnitId': defenderUnitId,
        'outcome': CombatOutcomeSerializer.toJson(outcome),
      },
    UnitKilledEvent(
      :final unitId,
      :final ownerPlayerId,
      :final attackerUnitId,
    ) =>
      {
        'type': 'UnitKilled',
        'unitId': unitId,
        'ownerPlayerId': ownerPlayerId,
        'attackerUnitId': ?attackerUnitId,
      },
    UnitRetreatedEvent(
      :final unitId,
      :final ownerPlayerId,
      :final fromCol,
      :final fromRow,
      :final toCol,
      :final toRow,
    ) =>
      {
        'type': 'UnitRetreated',
        'unitId': unitId,
        'ownerPlayerId': ownerPlayerId,
        'fromCol': fromCol,
        'fromRow': fromRow,
        'toCol': toCol,
        'toRow': toRow,
      },
    CityCapturedEvent(
      :final cityId,
      :final previousOwnerPlayerId,
      :final newOwnerPlayerId,
    ) =>
      {
        'type': 'CityCaptured',
        'cityId': cityId,
        'previousOwnerPlayerId': previousOwnerPlayerId,
        'newOwnerPlayerId': newOwnerPlayerId,
      },
    CityDestroyedEvent(
      :final cityId,
      :final previousOwnerPlayerId,
      :final attackerOwnerPlayerId,
    ) =>
      {
        'type': 'CityDestroyed',
        'cityId': cityId,
        'previousOwnerPlayerId': previousOwnerPlayerId,
        'attackerOwnerPlayerId': attackerOwnerPlayerId,
      },
    TurnEndedEvent(:final playerId) => {
      'type': 'TurnEnded',
      'playerId': playerId,
    },
    StabilityBandChangedEvent(
      :final playerId,
      :final previousBand,
      :final newBand,
      :final net,
    ) =>
      {
        'type': 'StabilityBandChanged',
        'playerId': playerId,
        'previousBand': previousBand.name,
        'newBand': newBand.name,
        'net': net,
      },
    WorkerCompletedJobEvent(:final unitId) => {
      'type': 'WorkerCompletedJob',
      'unitId': unitId,
    },
    DominationThresholdReachedEvent(
      :final playerId,
      :final controlPercent,
      :final requiredControlPercent,
      :final holdTurns,
      :final requiredHoldTurns,
    ) =>
      {
        'type': 'DominationThresholdReached',
        'playerId': playerId,
        'controlPercent': controlPercent,
        'requiredControlPercent': requiredControlPercent,
        'holdTurns': holdTurns,
        'requiredHoldTurns': requiredHoldTurns,
      },
    ResearchPointsGainedEvent(:final playerId, :final points) => {
      'type': 'ResearchPointsGained',
      'playerId': playerId,
      'points': points,
    },
    TechnologyResearchedEvent(:final playerId, :final technologyId) => {
      'type': 'TechnologyResearched',
      'playerId': playerId,
      'technologyId': technologyId.name,
    },
    StrategicResourceDiscoveredEvent(
      :final playerId,
      :final resourceType,
      :final controlledCount,
      :final rivalControlledCount,
      :final unclaimedCount,
      :final pressure,
      :final nearestUnclaimedCol,
      :final nearestUnclaimedRow,
    ) =>
      {
        'type': 'StrategicResourceDiscovered',
        'playerId': playerId,
        'resourceType': resourceType.name,
        'controlledCount': controlledCount,
        'rivalControlledCount': rivalControlledCount,
        'unclaimedCount': unclaimedCount,
        'pressure': pressure.name,
        'nearestUnclaimedCol': ?nearestUnclaimedCol,
        'nearestUnclaimedRow': ?nearestUnclaimedRow,
      },
    MapObjectiveSecuredEvent(
      :final playerId,
      :final objectiveId,
      :final objectiveType,
      :final col,
      :final row,
      :final holdTurns,
      :final requiredHoldTurns,
      :final victoryPoints,
      :final goldPerTurn,
    ) =>
      {
        'type': 'MapObjectiveSecured',
        'playerId': playerId,
        'objectiveId': objectiveId,
        'objectiveType': objectiveType.name,
        'col': col,
        'row': row,
        'holdTurns': holdTurns,
        'requiredHoldTurns': requiredHoldTurns,
        'victoryPoints': victoryPoints,
        'goldPerTurn': goldPerTurn,
      },
    CivilizationMetEvent(:final playerId, :final metPlayerId) => {
      'type': 'CivilizationMet',
      'playerId': playerId,
      'metPlayerId': metPlayerId,
    },
    DiplomaticProposalSentEvent(
      :final proposalId,
      :final fromPlayerId,
      :final toPlayerId,
      :final kind,
      :final expiresOnTurn,
    ) =>
      {
        'type': 'DiplomaticProposalSent',
        'proposalId': proposalId,
        'fromPlayerId': fromPlayerId,
        'toPlayerId': toPlayerId,
        'kind': kind.name,
        'expiresOnTurn': expiresOnTurn,
      },
    DiplomaticProposalRespondedEvent(
      :final proposalId,
      :final fromPlayerId,
      :final toPlayerId,
      :final kind,
      :final accepted,
    ) =>
      {
        'type': 'DiplomaticProposalResponded',
        'proposalId': proposalId,
        'fromPlayerId': fromPlayerId,
        'toPlayerId': toPlayerId,
        'kind': kind.name,
        'accepted': accepted,
      },
    DiplomaticProposalExpiredEvent(
      :final proposalId,
      :final fromPlayerId,
      :final toPlayerId,
      :final kind,
    ) =>
      {
        'type': 'DiplomaticProposalExpired',
        'proposalId': proposalId,
        'fromPlayerId': fromPlayerId,
        'toPlayerId': toPlayerId,
        'kind': kind.name,
      },
    DiplomaticRelationChangedEvent(
      :final playerAId,
      :final playerBId,
      :final oldStatus,
      :final newStatus,
      :final reason,
      :final expiresOnTurn,
    ) =>
      {
        'type': 'DiplomaticRelationChanged',
        'playerAId': playerAId,
        'playerBId': playerBId,
        'oldStatus': oldStatus.name,
        'newStatus': newStatus.name,
        'reason': reason.name,
        'expiresOnTurn': ?expiresOnTurn,
      },
    DiplomaticMessageSentEvent(
      :final messageId,
      :final fromPlayerId,
      :final toPlayerId,
      :final topic,
      :final category,
      :final expiresOnTurn,
    ) =>
      {
        'type': 'DiplomaticMessageSent',
        'messageId': messageId,
        'fromPlayerId': fromPlayerId,
        'toPlayerId': toPlayerId,
        'topic': topic.name,
        'category': category.name,
        'expiresOnTurn': expiresOnTurn,
      },
    DiplomaticMessageRespondedEvent(
      :final messageId,
      :final fromPlayerId,
      :final toPlayerId,
      :final topic,
      :final response,
      :final relationDelta,
      :final relationScoreAfter,
      :final promiseDueTurn,
    ) =>
      {
        'type': 'DiplomaticMessageResponded',
        'messageId': messageId,
        'fromPlayerId': fromPlayerId,
        'toPlayerId': toPlayerId,
        'topic': topic.name,
        'response': response.name,
        'relationDelta': relationDelta,
        'relationScoreAfter': relationScoreAfter,
        'promiseDueTurn': ?promiseDueTurn,
      },
    DiplomaticScoreChangedEvent(
      :final playerAId,
      :final playerBId,
      :final delta,
      :final scoreAfter,
      :final reason,
      :final sourceId,
    ) =>
      {
        'type': 'DiplomaticScoreChanged',
        'playerAId': playerAId,
        'playerBId': playerBId,
        'delta': delta,
        'scoreAfter': scoreAfter,
        'reason': reason.name,
        'sourceId': ?sourceId,
      },
    DiplomaticPromiseBrokenEvent(
      :final messageId,
      :final playerAId,
      :final playerBId,
      :final delta,
      :final scoreAfter,
    ) =>
      {
        'type': 'DiplomaticPromiseBroken',
        'messageId': messageId,
        'playerAId': playerAId,
        'playerBId': playerBId,
        'delta': delta,
        'scoreAfter': scoreAfter,
      },
    CommandRejectedEvent(:final reason) => SystemEventWire.commandRejected(
      reason: reason,
    ),
    AllPlayersSubmittedEvent(:final turn, :final playerIds) =>
      SystemEventWire.allPlayersSubmitted(turn: turn, playerIds: playerIds),
    PlayerTimedOutEvent(:final turn, :final playerId) =>
      SystemEventWire.playerTimedOut(turn: turn, playerId: playerId),
    TurnAutoResolvedEvent(
      :final turn,
      :final playerId,
      :final unitOrderCount,
      :final cityProductionCount,
      :final researchSelected,
    ) =>
      SystemEventWire.turnAutoResolved(
        turn: turn,
        playerId: playerId,
        unitOrderCount: unitOrderCount,
        cityProductionCount: cityProductionCount,
        researchSelected: researchSelected,
      ),
    PlayerKickedEvent(
      :final turn,
      :final playerId,
      :final reason,
      :final timeoutStreak,
    ) =>
      SystemEventWire.playerKicked(
        turn: turn,
        playerId: playerId,
        reason: reason,
        timeoutStreak: timeoutStreak,
      ),
  };

  /// Deserializes a [GameEvent] from [json] using the `type` discriminator.
  ///
  /// Throws [ArgumentError] if the `type` value is unrecognised.
  static GameEvent fromJson(Map<String, dynamic> json) {
    final type = requiredStringField(json, 'GameEvent', 'type');
    return switch (type) {
      'CityFounded' => CityFoundedEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
      ),
      'CityBuiltBuilding' => CityBuiltBuildingEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        buildingType: requiredEnumField(
          json,
          type,
          'buildingType',
          CityBuildingType.values,
        ),
      ),
      'CityProducedUnit' => CityProducedUnitEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        unitType: requiredEnumField(
          json,
          type,
          'unitType',
          GameUnitType.values,
        ),
        producedUnitId: requiredStringField(json, type, 'producedUnitId'),
      ),
      'CityClaimedHex' => CityClaimedHexEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        col: requiredIntField(json, type, 'col'),
        row: requiredIntField(json, type, 'row'),
      ),
      'UnitMoved' => UnitMovedEvent(
        unitId: requiredStringField(json, type, 'unitId'),
        fromCol: requiredIntField(json, type, 'fromCol'),
        fromRow: requiredIntField(json, type, 'fromRow'),
        toCol: requiredIntField(json, type, 'toCol'),
        toRow: requiredIntField(json, type, 'toRow'),
      ),
      'UnitGainedExperience' => UnitGainedExperienceEvent(
        unitId: requiredStringField(json, type, 'unitId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
        amount: requiredIntField(json, type, 'amount'),
        totalExperience: requiredIntField(json, type, 'totalExperience'),
        rank: requiredEnumField(json, type, 'rank', UnitVeterancyRank.values),
        promoted: requiredBoolField(json, type, 'promoted'),
      ),
      'UnitAttacked' => UnitAttackedEvent(
        attackerUnitId: requiredStringField(json, type, 'attackerUnitId'),
        attackerOwnerPlayerId: requiredStringField(
          json,
          type,
          'attackerOwnerPlayerId',
        ),
        defenderUnitId: requiredStringField(json, type, 'defenderUnitId'),
        defenderOwnerPlayerId: requiredStringField(
          json,
          type,
          'defenderOwnerPlayerId',
        ),
      ),
      'CombatResolved' => CombatResolvedEvent(
        attackerUnitId: requiredStringField(json, type, 'attackerUnitId'),
        defenderUnitId: requiredStringField(json, type, 'defenderUnitId'),
        outcome: CombatOutcomeSerializer.fromJson(
          requiredMapValue(json['outcome'], '$type.outcome'),
        ),
      ),
      'UnitKilled' => UnitKilledEvent(
        unitId: requiredStringField(json, type, 'unitId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
        attackerUnitId: optionalStringField(json, type, 'attackerUnitId'),
      ),
      'UnitRetreated' => UnitRetreatedEvent(
        unitId: requiredStringField(json, type, 'unitId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
        fromCol: requiredIntField(json, type, 'fromCol'),
        fromRow: requiredIntField(json, type, 'fromRow'),
        toCol: requiredIntField(json, type, 'toCol'),
        toRow: requiredIntField(json, type, 'toRow'),
      ),
      'CityCaptured' => CityCapturedEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        previousOwnerPlayerId: requiredStringField(
          json,
          type,
          'previousOwnerPlayerId',
        ),
        newOwnerPlayerId: requiredStringField(json, type, 'newOwnerPlayerId'),
      ),
      'CityDestroyed' => CityDestroyedEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        previousOwnerPlayerId: requiredStringField(
          json,
          type,
          'previousOwnerPlayerId',
        ),
        attackerOwnerPlayerId: requiredStringField(
          json,
          type,
          'attackerOwnerPlayerId',
        ),
      ),
      'TurnEnded' => TurnEndedEvent(
        playerId: requiredStringField(json, type, 'playerId'),
      ),
      'StabilityBandChanged' => StabilityBandChangedEvent(
        playerId: requiredStringField(json, type, 'playerId'),
        previousBand: requiredEnumField(
          json,
          type,
          'previousBand',
          StabilityBand.values,
        ),
        newBand: requiredEnumField(json, type, 'newBand', StabilityBand.values),
        net: requiredIntField(json, type, 'net'),
      ),
      'WorkerCompletedJob' => WorkerCompletedJobEvent(
        unitId: requiredStringField(json, type, 'unitId'),
      ),
      'DominationThresholdReached' => DominationThresholdReachedEvent(
        playerId: requiredStringField(json, type, 'playerId'),
        controlPercent: requiredDoubleField(json, type, 'controlPercent'),
        requiredControlPercent: requiredDoubleField(
          json,
          type,
          'requiredControlPercent',
        ),
        holdTurns: requiredIntField(json, type, 'holdTurns'),
        requiredHoldTurns: requiredIntField(json, type, 'requiredHoldTurns'),
      ),
      'ResearchPointsGained' => ResearchPointsGainedEvent(
        playerId: requiredStringField(json, type, 'playerId'),
        points: requiredIntField(json, type, 'points'),
      ),
      'TechnologyResearched' => TechnologyResearchedEvent(
        playerId: requiredStringField(json, type, 'playerId'),
        technologyId: requiredEnumField(
          json,
          type,
          'technologyId',
          TechnologyId.values,
        ),
      ),
      'StrategicResourceDiscovered' => _strategicResourceDiscoveredFromJson(
        json,
        type,
      ),
      'MapObjectiveSecured' => MapObjectiveSecuredEvent(
        playerId: requiredStringField(json, type, 'playerId'),
        objectiveId: requiredStringField(json, type, 'objectiveId'),
        objectiveType: requiredEnumField(
          json,
          type,
          'objectiveType',
          MapObjectiveType.values,
        ),
        col: requiredIntField(json, type, 'col'),
        row: requiredIntField(json, type, 'row'),
        holdTurns: requiredIntField(json, type, 'holdTurns'),
        requiredHoldTurns: requiredIntField(json, type, 'requiredHoldTurns'),
        victoryPoints: requiredIntField(json, type, 'victoryPoints'),
        goldPerTurn: requiredIntField(json, type, 'goldPerTurn'),
      ),
      'CivilizationMet' => CivilizationMetEvent(
        playerId: requiredStringField(json, type, 'playerId'),
        metPlayerId: requiredStringField(json, type, 'metPlayerId'),
      ),
      'DiplomaticProposalSent' => DiplomaticProposalSentEvent(
        proposalId: requiredStringField(json, type, 'proposalId'),
        fromPlayerId: requiredStringField(json, type, 'fromPlayerId'),
        toPlayerId: requiredStringField(json, type, 'toPlayerId'),
        kind: requiredEnumField(
          json,
          type,
          'kind',
          DiplomaticProposalKind.values,
        ),
        expiresOnTurn: requiredIntField(json, type, 'expiresOnTurn'),
      ),
      'DiplomaticProposalResponded' => DiplomaticProposalRespondedEvent(
        proposalId: requiredStringField(json, type, 'proposalId'),
        fromPlayerId: requiredStringField(json, type, 'fromPlayerId'),
        toPlayerId: requiredStringField(json, type, 'toPlayerId'),
        kind: requiredEnumField(
          json,
          type,
          'kind',
          DiplomaticProposalKind.values,
        ),
        accepted: requiredBoolField(json, type, 'accepted'),
      ),
      'DiplomaticProposalExpired' => DiplomaticProposalExpiredEvent(
        proposalId: requiredStringField(json, type, 'proposalId'),
        fromPlayerId: requiredStringField(json, type, 'fromPlayerId'),
        toPlayerId: requiredStringField(json, type, 'toPlayerId'),
        kind: requiredEnumField(
          json,
          type,
          'kind',
          DiplomaticProposalKind.values,
        ),
      ),
      'DiplomaticRelationChanged' => DiplomaticRelationChangedEvent(
        playerAId: requiredStringField(json, type, 'playerAId'),
        playerBId: requiredStringField(json, type, 'playerBId'),
        oldStatus: requiredEnumField(
          json,
          type,
          'oldStatus',
          DiplomaticRelationStatus.values,
        ),
        newStatus: requiredEnumField(
          json,
          type,
          'newStatus',
          DiplomaticRelationStatus.values,
        ),
        reason: requiredEnumField(
          json,
          type,
          'reason',
          DiplomaticRelationChangeReason.values,
        ),
        expiresOnTurn: optionalIntField(json, type, 'expiresOnTurn'),
      ),
      'DiplomaticMessageSent' => DiplomaticMessageSentEvent(
        messageId: requiredStringField(json, type, 'messageId'),
        fromPlayerId: requiredStringField(json, type, 'fromPlayerId'),
        toPlayerId: requiredStringField(json, type, 'toPlayerId'),
        topic: requiredEnumField(
          json,
          type,
          'topic',
          DiplomaticMessageTopic.values,
        ),
        category: requiredEnumField(
          json,
          type,
          'category',
          DiplomaticMessageCategory.values,
        ),
        expiresOnTurn: requiredIntField(json, type, 'expiresOnTurn'),
      ),
      'DiplomaticMessageResponded' => DiplomaticMessageRespondedEvent(
        messageId: requiredStringField(json, type, 'messageId'),
        fromPlayerId: requiredStringField(json, type, 'fromPlayerId'),
        toPlayerId: requiredStringField(json, type, 'toPlayerId'),
        topic: requiredEnumField(
          json,
          type,
          'topic',
          DiplomaticMessageTopic.values,
        ),
        response: requiredEnumField(
          json,
          type,
          'response',
          DiplomaticMessageResponse.values,
        ),
        relationDelta: requiredIntField(json, type, 'relationDelta'),
        relationScoreAfter: requiredIntField(json, type, 'relationScoreAfter'),
        promiseDueTurn: optionalIntField(json, type, 'promiseDueTurn'),
      ),
      'DiplomaticScoreChanged' => DiplomaticScoreChangedEvent(
        playerAId: requiredStringField(json, type, 'playerAId'),
        playerBId: requiredStringField(json, type, 'playerBId'),
        delta: requiredIntField(json, type, 'delta'),
        scoreAfter: requiredIntField(json, type, 'scoreAfter'),
        reason: requiredEnumField(
          json,
          type,
          'reason',
          DiplomaticScoreChangeReason.values,
        ),
        sourceId: optionalStringField(json, type, 'sourceId'),
      ),
      'DiplomaticPromiseBroken' => DiplomaticPromiseBrokenEvent(
        messageId: requiredStringField(json, type, 'messageId'),
        playerAId: requiredStringField(json, type, 'playerAId'),
        playerBId: requiredStringField(json, type, 'playerBId'),
        delta: requiredIntField(json, type, 'delta'),
        scoreAfter: requiredIntField(json, type, 'scoreAfter'),
      ),
      SystemEventWire.commandRejectedType => CommandRejectedEvent(
        reason: requiredStringField(json, type, 'reason'),
      ),
      SystemEventWire.allPlayersSubmittedType => AllPlayersSubmittedEvent(
        turn: requiredIntField(json, type, 'turn'),
        playerIds: requiredStringListField(json, type, 'playerIds'),
      ),
      SystemEventWire.playerTimedOutType => PlayerTimedOutEvent(
        turn: requiredIntField(json, type, 'turn'),
        playerId: requiredStringField(json, type, 'playerId'),
      ),
      SystemEventWire.turnAutoResolvedType => TurnAutoResolvedEvent(
        turn: requiredIntField(json, type, 'turn'),
        playerId: requiredStringField(json, type, 'playerId'),
        unitOrderCount: requiredIntField(json, type, 'unitOrderCount'),
        cityProductionCount: requiredIntField(
          json,
          type,
          'cityProductionCount',
        ),
        researchSelected: requiredBoolField(json, type, 'researchSelected'),
      ),
      SystemEventWire.playerKickedType => PlayerKickedEvent(
        turn: requiredIntField(json, type, 'turn'),
        playerId: requiredStringField(json, type, 'playerId'),
        reason: requiredStringField(json, type, 'reason'),
        timeoutStreak: requiredIntField(json, type, 'timeoutStreak'),
      ),
      _ => throw ArgumentError('Unknown GameEvent type: $type'),
    };
  }

  static StrategicResourceDiscoveredEvent _strategicResourceDiscoveredFromJson(
    Map<String, dynamic> json,
    String type,
  ) {
    final controlledCount = requiredIntField(json, type, 'controlledCount');
    final rivalControlledCount = requiredIntField(
      json,
      type,
      'rivalControlledCount',
    );
    final unclaimedCount = requiredIntField(json, type, 'unclaimedCount');
    final pressure =
        optionalEnumField(
          json,
          type,
          'pressure',
          StrategicResourceDiscoveryPressure.values,
        ) ??
        StrategicResourceDiscoveryPressure.fromCounts(
          controlledCount: controlledCount,
          rivalControlledCount: rivalControlledCount,
          unclaimedCount: unclaimedCount,
        );
    return StrategicResourceDiscoveredEvent(
      playerId: requiredStringField(json, type, 'playerId'),
      resourceType: requiredEnumField(
        json,
        type,
        'resourceType',
        ResourceType.values,
      ),
      controlledCount: controlledCount,
      rivalControlledCount: rivalControlledCount,
      unclaimedCount: unclaimedCount,
      pressure: pressure,
      nearestUnclaimedCol: optionalIntField(json, type, 'nearestUnclaimedCol'),
      nearestUnclaimedRow: optionalIntField(json, type, 'nearestUnclaimedRow'),
    );
  }
}
