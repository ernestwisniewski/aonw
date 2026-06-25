import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/protocol.dart';

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
    final type = _requiredString(json, 'GameEvent', 'type');
    return switch (type) {
      'CityFounded' => CityFoundedEvent(
        cityId: _requiredString(json, type, 'cityId'),
        ownerPlayerId: _requiredString(json, type, 'ownerPlayerId'),
      ),
      'CityBuiltBuilding' => CityBuiltBuildingEvent(
        cityId: _requiredString(json, type, 'cityId'),
        buildingType: _requiredEnum(
          json,
          type,
          'buildingType',
          CityBuildingType.values,
        ),
      ),
      'CityProducedUnit' => CityProducedUnitEvent(
        cityId: _requiredString(json, type, 'cityId'),
        unitType: _requiredEnum(json, type, 'unitType', GameUnitType.values),
        producedUnitId: _requiredString(json, type, 'producedUnitId'),
      ),
      'CityClaimedHex' => CityClaimedHexEvent(
        cityId: _requiredString(json, type, 'cityId'),
        col: _requiredInt(json, type, 'col'),
        row: _requiredInt(json, type, 'row'),
      ),
      'UnitMoved' => UnitMovedEvent(
        unitId: _requiredString(json, type, 'unitId'),
        fromCol: _requiredInt(json, type, 'fromCol'),
        fromRow: _requiredInt(json, type, 'fromRow'),
        toCol: _requiredInt(json, type, 'toCol'),
        toRow: _requiredInt(json, type, 'toRow'),
      ),
      'UnitGainedExperience' => UnitGainedExperienceEvent(
        unitId: _requiredString(json, type, 'unitId'),
        ownerPlayerId: _requiredString(json, type, 'ownerPlayerId'),
        amount: _requiredInt(json, type, 'amount'),
        totalExperience: _requiredInt(json, type, 'totalExperience'),
        rank: _requiredEnum(json, type, 'rank', UnitVeterancyRank.values),
        promoted: _requiredBool(json, type, 'promoted'),
      ),
      'UnitAttacked' => UnitAttackedEvent(
        attackerUnitId: _requiredString(json, type, 'attackerUnitId'),
        attackerOwnerPlayerId: _requiredString(
          json,
          type,
          'attackerOwnerPlayerId',
        ),
        defenderUnitId: _requiredString(json, type, 'defenderUnitId'),
        defenderOwnerPlayerId: _requiredString(
          json,
          type,
          'defenderOwnerPlayerId',
        ),
      ),
      'CombatResolved' => CombatResolvedEvent(
        attackerUnitId: _requiredString(json, type, 'attackerUnitId'),
        defenderUnitId: _requiredString(json, type, 'defenderUnitId'),
        outcome: CombatOutcomeSerializer.fromJson(
          _requiredMap(json['outcome'], '$type.outcome'),
        ),
      ),
      'UnitKilled' => UnitKilledEvent(
        unitId: _requiredString(json, type, 'unitId'),
        ownerPlayerId: _requiredString(json, type, 'ownerPlayerId'),
        attackerUnitId: _optionalString(json, type, 'attackerUnitId'),
      ),
      'UnitRetreated' => UnitRetreatedEvent(
        unitId: _requiredString(json, type, 'unitId'),
        ownerPlayerId: _requiredString(json, type, 'ownerPlayerId'),
        fromCol: _requiredInt(json, type, 'fromCol'),
        fromRow: _requiredInt(json, type, 'fromRow'),
        toCol: _requiredInt(json, type, 'toCol'),
        toRow: _requiredInt(json, type, 'toRow'),
      ),
      'CityCaptured' => CityCapturedEvent(
        cityId: _requiredString(json, type, 'cityId'),
        previousOwnerPlayerId: _requiredString(
          json,
          type,
          'previousOwnerPlayerId',
        ),
        newOwnerPlayerId: _requiredString(json, type, 'newOwnerPlayerId'),
      ),
      'CityDestroyed' => CityDestroyedEvent(
        cityId: _requiredString(json, type, 'cityId'),
        previousOwnerPlayerId: _requiredString(
          json,
          type,
          'previousOwnerPlayerId',
        ),
        attackerOwnerPlayerId: _requiredString(
          json,
          type,
          'attackerOwnerPlayerId',
        ),
      ),
      'TurnEnded' => TurnEndedEvent(
        playerId: _requiredString(json, type, 'playerId'),
      ),
      'WorkerCompletedJob' => WorkerCompletedJobEvent(
        unitId: _requiredString(json, type, 'unitId'),
      ),
      'DominationThresholdReached' => DominationThresholdReachedEvent(
        playerId: _requiredString(json, type, 'playerId'),
        controlPercent: _requiredDouble(json, type, 'controlPercent'),
        requiredControlPercent: _requiredDouble(
          json,
          type,
          'requiredControlPercent',
        ),
        holdTurns: _requiredInt(json, type, 'holdTurns'),
        requiredHoldTurns: _requiredInt(json, type, 'requiredHoldTurns'),
      ),
      'ResearchPointsGained' => ResearchPointsGainedEvent(
        playerId: _requiredString(json, type, 'playerId'),
        points: _requiredInt(json, type, 'points'),
      ),
      'TechnologyResearched' => TechnologyResearchedEvent(
        playerId: _requiredString(json, type, 'playerId'),
        technologyId: _requiredEnum(
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
        playerId: _requiredString(json, type, 'playerId'),
        objectiveId: _requiredString(json, type, 'objectiveId'),
        objectiveType: _requiredEnum(
          json,
          type,
          'objectiveType',
          MapObjectiveType.values,
        ),
        col: _requiredInt(json, type, 'col'),
        row: _requiredInt(json, type, 'row'),
        holdTurns: _requiredInt(json, type, 'holdTurns'),
        requiredHoldTurns: _requiredInt(json, type, 'requiredHoldTurns'),
        victoryPoints: _requiredInt(json, type, 'victoryPoints'),
        goldPerTurn: _requiredInt(json, type, 'goldPerTurn'),
      ),
      'CivilizationMet' => CivilizationMetEvent(
        playerId: _requiredString(json, type, 'playerId'),
        metPlayerId: _requiredString(json, type, 'metPlayerId'),
      ),
      'DiplomaticProposalSent' => DiplomaticProposalSentEvent(
        proposalId: _requiredString(json, type, 'proposalId'),
        fromPlayerId: _requiredString(json, type, 'fromPlayerId'),
        toPlayerId: _requiredString(json, type, 'toPlayerId'),
        kind: _requiredEnum(json, type, 'kind', DiplomaticProposalKind.values),
        expiresOnTurn: _requiredInt(json, type, 'expiresOnTurn'),
      ),
      'DiplomaticProposalResponded' => DiplomaticProposalRespondedEvent(
        proposalId: _requiredString(json, type, 'proposalId'),
        fromPlayerId: _requiredString(json, type, 'fromPlayerId'),
        toPlayerId: _requiredString(json, type, 'toPlayerId'),
        kind: _requiredEnum(json, type, 'kind', DiplomaticProposalKind.values),
        accepted: _requiredBool(json, type, 'accepted'),
      ),
      'DiplomaticProposalExpired' => DiplomaticProposalExpiredEvent(
        proposalId: _requiredString(json, type, 'proposalId'),
        fromPlayerId: _requiredString(json, type, 'fromPlayerId'),
        toPlayerId: _requiredString(json, type, 'toPlayerId'),
        kind: _requiredEnum(json, type, 'kind', DiplomaticProposalKind.values),
      ),
      'DiplomaticRelationChanged' => DiplomaticRelationChangedEvent(
        playerAId: _requiredString(json, type, 'playerAId'),
        playerBId: _requiredString(json, type, 'playerBId'),
        oldStatus: _requiredEnum(
          json,
          type,
          'oldStatus',
          DiplomaticRelationStatus.values,
        ),
        newStatus: _requiredEnum(
          json,
          type,
          'newStatus',
          DiplomaticRelationStatus.values,
        ),
        reason: _requiredEnum(
          json,
          type,
          'reason',
          DiplomaticRelationChangeReason.values,
        ),
        expiresOnTurn: _optionalInt(json, type, 'expiresOnTurn'),
      ),
      'DiplomaticMessageSent' => DiplomaticMessageSentEvent(
        messageId: _requiredString(json, type, 'messageId'),
        fromPlayerId: _requiredString(json, type, 'fromPlayerId'),
        toPlayerId: _requiredString(json, type, 'toPlayerId'),
        topic: _requiredEnum(
          json,
          type,
          'topic',
          DiplomaticMessageTopic.values,
        ),
        category: _requiredEnum(
          json,
          type,
          'category',
          DiplomaticMessageCategory.values,
        ),
        expiresOnTurn: _requiredInt(json, type, 'expiresOnTurn'),
      ),
      'DiplomaticMessageResponded' => DiplomaticMessageRespondedEvent(
        messageId: _requiredString(json, type, 'messageId'),
        fromPlayerId: _requiredString(json, type, 'fromPlayerId'),
        toPlayerId: _requiredString(json, type, 'toPlayerId'),
        topic: _requiredEnum(
          json,
          type,
          'topic',
          DiplomaticMessageTopic.values,
        ),
        response: _requiredEnum(
          json,
          type,
          'response',
          DiplomaticMessageResponse.values,
        ),
        relationDelta: _requiredInt(json, type, 'relationDelta'),
        relationScoreAfter: _requiredInt(json, type, 'relationScoreAfter'),
        promiseDueTurn: _optionalInt(json, type, 'promiseDueTurn'),
      ),
      'DiplomaticScoreChanged' => DiplomaticScoreChangedEvent(
        playerAId: _requiredString(json, type, 'playerAId'),
        playerBId: _requiredString(json, type, 'playerBId'),
        delta: _requiredInt(json, type, 'delta'),
        scoreAfter: _requiredInt(json, type, 'scoreAfter'),
        reason: _requiredEnum(
          json,
          type,
          'reason',
          DiplomaticScoreChangeReason.values,
        ),
        sourceId: _optionalString(json, type, 'sourceId'),
      ),
      'DiplomaticPromiseBroken' => DiplomaticPromiseBrokenEvent(
        messageId: _requiredString(json, type, 'messageId'),
        playerAId: _requiredString(json, type, 'playerAId'),
        playerBId: _requiredString(json, type, 'playerBId'),
        delta: _requiredInt(json, type, 'delta'),
        scoreAfter: _requiredInt(json, type, 'scoreAfter'),
      ),
      SystemEventWire.commandRejectedType => CommandRejectedEvent(
        reason: _requiredString(json, type, 'reason'),
      ),
      SystemEventWire.allPlayersSubmittedType => AllPlayersSubmittedEvent(
        turn: _requiredInt(json, type, 'turn'),
        playerIds: _requiredStringList(json, type, 'playerIds'),
      ),
      SystemEventWire.playerTimedOutType => PlayerTimedOutEvent(
        turn: _requiredInt(json, type, 'turn'),
        playerId: _requiredString(json, type, 'playerId'),
      ),
      SystemEventWire.turnAutoResolvedType => TurnAutoResolvedEvent(
        turn: _requiredInt(json, type, 'turn'),
        playerId: _requiredString(json, type, 'playerId'),
        unitOrderCount: _requiredInt(json, type, 'unitOrderCount'),
        cityProductionCount: _requiredInt(json, type, 'cityProductionCount'),
        researchSelected: _requiredBool(json, type, 'researchSelected'),
      ),
      SystemEventWire.playerKickedType => PlayerKickedEvent(
        turn: _requiredInt(json, type, 'turn'),
        playerId: _requiredString(json, type, 'playerId'),
        reason: _requiredString(json, type, 'reason'),
        timeoutStreak: _requiredInt(json, type, 'timeoutStreak'),
      ),
      _ => throw ArgumentError('Unknown GameEvent type: $type'),
    };
  }

  static String _requiredString(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value is String && value.isNotEmpty) return value;
    throw ArgumentError.value(
      value,
      '$type.$field',
      'Expected a non-empty String',
    );
  }

  static int _requiredInt(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value is int) return value;
    throw ArgumentError.value(value, '$type.$field', 'Expected an int');
  }

  static int? _optionalInt(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value == null) return null;
    if (value is int) return value;
    throw ArgumentError.value(value, '$type.$field', 'Expected an int or null');
  }

  static double _requiredDouble(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value is num) return value.toDouble();
    throw ArgumentError.value(value, '$type.$field', 'Expected a number');
  }

  static bool _requiredBool(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value is bool) return value;
    throw ArgumentError.value(value, '$type.$field', 'Expected a bool');
  }

  static List<String> _requiredStringList(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value is! List) {
      throw ArgumentError.value(value, '$type.$field', 'Expected a list');
    }
    return [
      for (final entry in value)
        if (entry is String && entry.isNotEmpty)
          entry
        else
          throw ArgumentError.value(
            entry,
            '$type.$field',
            'Expected a list of non-empty strings',
          ),
    ];
  }

  static String? _optionalString(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    throw ArgumentError.value(
      value,
      '$type.$field',
      'Expected a non-empty String or null',
    );
  }

  static StrategicResourceDiscoveredEvent _strategicResourceDiscoveredFromJson(
    Map<String, dynamic> json,
    String type,
  ) {
    final controlledCount = _requiredInt(json, type, 'controlledCount');
    final rivalControlledCount = _requiredInt(
      json,
      type,
      'rivalControlledCount',
    );
    final unclaimedCount = _requiredInt(json, type, 'unclaimedCount');
    final pressure =
        _optionalEnum(
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
      playerId: _requiredString(json, type, 'playerId'),
      resourceType: _requiredEnum(
        json,
        type,
        'resourceType',
        ResourceType.values,
      ),
      controlledCount: controlledCount,
      rivalControlledCount: rivalControlledCount,
      unclaimedCount: unclaimedCount,
      pressure: pressure,
      nearestUnclaimedCol: _optionalInt(json, type, 'nearestUnclaimedCol'),
      nearestUnclaimedRow: _optionalInt(json, type, 'nearestUnclaimedRow'),
    );
  }

  static Map<String, dynamic> _requiredMap(Object? value, String name) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ArgumentError.value(value, name, 'Expected a JSON object');
  }

  static T _requiredEnum<T extends Enum>(
    Map<String, dynamic> json,
    String type,
    String field,
    Iterable<T> values,
  ) {
    final name = _requiredString(json, type, field);
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw ArgumentError.value(name, '$type.$field', 'Unknown value');
  }

  static T? _optionalEnum<T extends Enum>(
    Map<String, dynamic> json,
    String type,
    String field,
    Iterable<T> values,
  ) {
    final name = _optionalString(json, type, field);
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw ArgumentError.value(name, '$type.$field', 'Unknown value');
  }
}
