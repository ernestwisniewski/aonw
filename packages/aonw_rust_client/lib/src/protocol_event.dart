import 'package:aonw_rust_client/src/protocol_city_view.dart';
import 'package:aonw_rust_client/src/protocol_coordinate.dart';
import 'package:aonw_rust_client/src/protocol_diplomacy.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_map.dart';
import 'package:aonw_rust_client/src/protocol_outcome.dart';
import 'package:aonw_rust_client/src/protocol_pending_action.dart';
import 'package:aonw_rust_client/src/protocol_player_view.dart';
import 'package:aonw_rust_client/src/protocol_values.dart';

enum AonwClientEventKind {
  artifactExcavationStarted,
  artifactCarried,
  artifactStored,
  cityFounded,
  cityBuiltBuilding,
  cityProducedUnit,
  cityBuiltWonder,
  wonderProductionRefunded,
  technologyResearched,
  researchPointsGained,
  cityClaimedHex,
  stabilityBandChanged,
  mapObjectiveSecured,
  dominationThresholdReached,
  matchEnded,
  unitAttacked,
  cityAttacked,
  combatResolved,
  diplomaticScoreChanged,
  diplomaticProposalSent,
  diplomaticProposalResponded,
  diplomaticProposalExpired,
  diplomaticMessageSent,
  diplomaticMessageResponded,
  diplomaticPromiseBroken,
  diplomaticRelationChanged,
  unitGainedExperience,
  unitKilled,
  unitRetreated,
  cityCaptured,
  cityDestroyed,
  unitMoved,
  autoExplorePlanned,
  merchantRouteAssigned,
  merchantTravelQueued,
  troopDetached,
  turnEnded,
  allPlayersSubmitted,
  playerTimedOut,
  playerKicked,
  workerCompletedJob,
}

sealed class AonwClientEvent {
  const AonwClientEvent(this.kind);

  factory AonwClientEvent.fromJson(Object? source) {
    final value = readObject(source, 'client event');
    final type = readString(value['type'], 'client event type');
    return switch (type) {
      'unitMoved' => AonwUnitMovedEvent.fromJson(value),
      'turnEnded' => AonwTurnEndedEvent.fromJson(value),
      'allPlayersSubmitted' => AonwAllPlayersSubmittedEvent.fromJson(value),
      'playerTimedOut' => AonwPlayerTimedOutEvent.fromJson(value),
      'playerKicked' => AonwPlayerKickedEvent.fromJson(value),
      'matchEnded' => AonwMatchEndedEvent.fromJson(value),
      _ => _knownEvent(value, type),
    };
  }

  final AonwClientEventKind kind;
}

final class AonwPresentationEvent extends AonwClientEvent {
  const AonwPresentationEvent(super.kind);
}

final class AonwUnitMovedEvent extends AonwClientEvent {
  const AonwUnitMovedEvent({
    required this.unitId,
    required this.from,
    required this.to,
  }) : super(AonwClientEventKind.unitMoved);

  factory AonwUnitMovedEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'from',
      'to',
    }, 'unit moved event');
    return AonwUnitMovedEvent(
      unitId: readString(value['unitId'], 'moved unit id'),
      from: AonwCoordinate.fromJson(value['from']),
      to: AonwCoordinate.fromJson(value['to']),
    );
  }

  final String unitId;
  final AonwCoordinate from;
  final AonwCoordinate to;
}

final class AonwTurnEndedEvent extends AonwClientEvent {
  const AonwTurnEndedEvent({required this.playerId})
    : super(AonwClientEventKind.turnEnded);

  factory AonwTurnEndedEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'playerId'}, 'turn ended event');
    return AonwTurnEndedEvent(
      playerId: readString(value['playerId'], 'turn player id'),
    );
  }

  final String playerId;
}

final class AonwAllPlayersSubmittedEvent extends AonwClientEvent {
  AonwAllPlayersSubmittedEvent({
    required this.turn,
    required List<String> playerIds,
  }) : playerIds = List.unmodifiable(playerIds),
       super(AonwClientEventKind.allPlayersSubmitted);

  factory AonwAllPlayersSubmittedEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'turn',
      'playerIds',
    }, 'all players submitted event');
    return AonwAllPlayersSubmittedEvent(
      turn: readUnsigned(value['turn'], 'submitted turn'),
      playerIds: _strings(value['playerIds'], 'submitted player ids'),
    );
  }

  final int turn;
  final List<String> playerIds;
}

final class AonwPlayerTimedOutEvent extends AonwClientEvent {
  const AonwPlayerTimedOutEvent({required this.turn, required this.playerId})
    : super(AonwClientEventKind.playerTimedOut);

  factory AonwPlayerTimedOutEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'turn',
      'playerId',
    }, 'player timed out event');
    return AonwPlayerTimedOutEvent(
      turn: readUnsigned(value['turn'], 'timeout turn'),
      playerId: readString(value['playerId'], 'timed out player id'),
    );
  }

  final int turn;
  final String playerId;
}

final class AonwPlayerKickedEvent extends AonwClientEvent {
  const AonwPlayerKickedEvent({
    required this.turn,
    required this.playerId,
    required this.reason,
    required this.timeoutStreak,
  }) : super(AonwClientEventKind.playerKicked);

  factory AonwPlayerKickedEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'turn',
      'playerId',
      'reason',
      'timeoutStreak',
    }, 'player kicked event');
    return AonwPlayerKickedEvent(
      turn: readUnsigned(value['turn'], 'kick turn'),
      playerId: readString(value['playerId'], 'kicked player id'),
      reason: readString(value['reason'], 'kick reason'),
      timeoutStreak: readInt(value['timeoutStreak'], 'timeout streak'),
    );
  }

  final int turn;
  final String playerId;
  final String reason;
  final int timeoutStreak;
}

final class AonwMatchEndedEvent extends AonwClientEvent {
  const AonwMatchEndedEvent({required this.turn, required this.outcome})
    : super(AonwClientEventKind.matchEnded);

  factory AonwMatchEndedEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'turn', 'outcome'}, 'match ended event');
    return AonwMatchEndedEvent(
      turn: readUnsigned(value['turn'], 'match end turn'),
      outcome: AonwGameOutcome.fromJson(value['outcome']),
    );
  }

  final int turn;
  final AonwGameOutcome outcome;
}

AonwClientEvent _knownEvent(Map<String, Object?> value, String type) {
  final kind = AonwClientEventKind.values
      .where((kind) => kind.name == type)
      .firstOrNull;
  if (kind == null) throw FormatException('Unknown AoNW client event $type.');
  _validateKnownEvent(value, kind);
  return AonwPresentationEvent(kind);
}

void _validateKnownEvent(Map<String, Object?> value, AonwClientEventKind kind) {
  switch (kind) {
    case AonwClientEventKind.artifactExcavationStarted:
    case AonwClientEventKind.artifactCarried:
      _fields(value, {
        'type',
        'artifactId',
        'ownerPlayerId',
        'unitId',
        'coordinate',
      });
      _stringsByKey(value, {'artifactId', 'ownerPlayerId', 'unitId'});
      AonwCoordinate.fromJson(value['coordinate']);
    case AonwClientEventKind.artifactStored:
      _fields(value, {
        'type',
        'artifactId',
        'ownerPlayerId',
        'sourceUnitId',
        'cityId',
        'coordinate',
      });
      _stringsByKey(value, {'artifactId', 'ownerPlayerId', 'cityId'});
      readNullableString(value['sourceUnitId'], 'source unit id');
      AonwCoordinate.fromJson(value['coordinate']);
    case AonwClientEventKind.cityFounded:
      _fields(value, {'type', 'cityId', 'ownerPlayerId'});
      _stringsByKey(value, {'cityId', 'ownerPlayerId'});
    case AonwClientEventKind.cityBuiltBuilding:
      _fields(value, {'type', 'cityId', 'buildingType'});
      readString(value['cityId'], 'city id');
      AonwCityBuildingType.fromJson(value['buildingType']);
    case AonwClientEventKind.cityProducedUnit:
      _fields(value, {'type', 'cityId', 'unitType', 'producedUnitId'});
      _stringsByKey(value, {'cityId', 'producedUnitId'});
      AonwUnitKind.fromJson(value['unitType']);
    case AonwClientEventKind.cityBuiltWonder:
      _fields(value, {'type', 'cityId', 'ownerPlayerId', 'wonderType'});
      _stringsByKey(value, {'cityId', 'ownerPlayerId'});
      AonwWonderType.fromJson(value['wonderType']);
    case AonwClientEventKind.wonderProductionRefunded:
      _fields(value, {
        'type',
        'cityId',
        'ownerPlayerId',
        'wonderType',
        'refundedProduction',
      });
      _stringsByKey(value, {'cityId', 'ownerPlayerId'});
      AonwWonderType.fromJson(value['wonderType']);
      readInt(value['refundedProduction'], 'refunded production');
    case AonwClientEventKind.technologyResearched:
      _fields(value, {'type', 'playerId', 'technologyId'});
      readString(value['playerId'], 'research player id');
      _technology(value['technologyId']);
    case AonwClientEventKind.researchPointsGained:
      _fields(value, {'type', 'playerId', 'points'});
      readString(value['playerId'], 'research player id');
      readInt(value['points'], 'research points');
    case AonwClientEventKind.cityClaimedHex:
      _fields(value, {'type', 'cityId', 'col', 'row'});
      readString(value['cityId'], 'city id');
      readInt(value['col'], 'claimed column');
      readInt(value['row'], 'claimed row');
    case AonwClientEventKind.stabilityBandChanged:
      _fields(value, {'type', 'playerId', 'previousBand', 'newBand', 'net'});
      readString(value['playerId'], 'stability player id');
      _enum(value['previousBand'], _stabilityBands, 'previous stability band');
      _enum(value['newBand'], _stabilityBands, 'new stability band');
      readInt(value['net'], 'stability net');
    case AonwClientEventKind.mapObjectiveSecured:
      _fields(value, {
        'type',
        'playerId',
        'objectiveId',
        'objectiveType',
        'col',
        'row',
        'holdTurns',
        'requiredHoldTurns',
        'victoryPoints',
        'goldPerTurn',
      });
      _stringsByKey(value, {'playerId', 'objectiveId'});
      AonwMapObjectiveType.fromJson(value['objectiveType']);
      for (final key in {
        'holdTurns',
        'requiredHoldTurns',
        'victoryPoints',
        'goldPerTurn',
      }) {
        readUnsigned(value[key], key);
      }
      readInt(value['col'], 'objective column');
      readInt(value['row'], 'objective row');
    case AonwClientEventKind.dominationThresholdReached:
      _fields(value, {
        'type',
        'playerId',
        'controlPercent',
        'requiredControlPercent',
        'holdTurns',
        'requiredHoldTurns',
      });
      readString(value['playerId'], 'domination player id');
      _finiteNumber(value['controlPercent'], 'control percent');
      _finiteNumber(
        value['requiredControlPercent'],
        'required control percent',
      );
      readUnsigned(value['holdTurns'], 'hold turns');
      readUnsigned(value['requiredHoldTurns'], 'required hold turns');
    case AonwClientEventKind.unitAttacked:
    case AonwClientEventKind.cityAttacked:
    case AonwClientEventKind.combatResolved:
    case AonwClientEventKind.cityCaptured:
    case AonwClientEventKind.cityDestroyed:
      _combatSubject(value, subjectKey: 'attackerUnitId');
    case AonwClientEventKind.diplomaticScoreChanged:
      _fields(value, {
        'type',
        'playerAId',
        'playerBId',
        'delta',
        'scoreAfter',
        'reason',
        'sourceId',
      });
      _stringsByKey(value, {'playerAId', 'playerBId'});
      readInt(value['delta'], 'diplomatic delta');
      readInt(value['scoreAfter'], 'diplomatic score');
      _enum(value['reason'], _scoreReasons, 'diplomatic score reason');
      readNullableString(value['sourceId'], 'diplomatic source id');
    case AonwClientEventKind.diplomaticProposalSent:
    case AonwClientEventKind.diplomaticProposalExpired:
      _fields(value, {
        'type',
        'proposalId',
        'fromPlayerId',
        'toPlayerId',
        'kind',
        'expiresOnTurn',
      });
      _stringsByKey(value, {'proposalId', 'fromPlayerId', 'toPlayerId'});
      AonwDiplomaticProposalKind.fromJson(value['kind']);
      readUnsigned(value['expiresOnTurn'], 'proposal expiry');
    case AonwClientEventKind.diplomaticProposalResponded:
      _fields(value, {
        'type',
        'proposalId',
        'fromPlayerId',
        'toPlayerId',
        'kind',
        'accepted',
      });
      _stringsByKey(value, {'proposalId', 'fromPlayerId', 'toPlayerId'});
      AonwDiplomaticProposalKind.fromJson(value['kind']);
      readBool(value['accepted'], 'proposal response');
    case AonwClientEventKind.diplomaticMessageSent:
      _fields(value, {
        'type',
        'messageId',
        'fromPlayerId',
        'toPlayerId',
        'topic',
        'category',
        'expiresOnTurn',
      });
      _stringsByKey(value, {'messageId', 'fromPlayerId', 'toPlayerId'});
      AonwDiplomaticMessageTopic.fromJson(value['topic']);
      AonwDiplomaticMessageCategory.fromJson(value['category']);
      readUnsigned(value['expiresOnTurn'], 'message expiry');
    case AonwClientEventKind.diplomaticMessageResponded:
      _fields(value, {
        'type',
        'messageId',
        'fromPlayerId',
        'toPlayerId',
        'topic',
        'response',
        'relationDelta',
        'relationScoreAfter',
        'promiseDueTurn',
      });
      _stringsByKey(value, {'messageId', 'fromPlayerId', 'toPlayerId'});
      AonwDiplomaticMessageTopic.fromJson(value['topic']);
      AonwDiplomaticMessageResponse.fromJson(value['response']);
      readInt(value['relationDelta'], 'relation delta');
      readInt(value['relationScoreAfter'], 'relation score');
      _nullableUnsigned(value['promiseDueTurn'], 'promise due turn');
    case AonwClientEventKind.diplomaticPromiseBroken:
      _fields(value, {
        'type',
        'messageId',
        'playerAId',
        'playerBId',
        'delta',
        'scoreAfter',
      });
      _stringsByKey(value, {'messageId', 'playerAId', 'playerBId'});
      readInt(value['delta'], 'promise delta');
      readInt(value['scoreAfter'], 'promise score');
    case AonwClientEventKind.diplomaticRelationChanged:
      _fields(value, {
        'type',
        'playerAId',
        'playerBId',
        'oldStatus',
        'newStatus',
        'reason',
        'expiresOnTurn',
      });
      _stringsByKey(value, {'playerAId', 'playerBId'});
      AonwDiplomaticRelationStatus.fromJson(value['oldStatus']);
      AonwDiplomaticRelationStatus.fromJson(value['newStatus']);
      AonwDiplomaticRelationChangeReason.fromJson(value['reason']);
      _nullableUnsigned(value['expiresOnTurn'], 'relation expiry');
    case AonwClientEventKind.unitGainedExperience:
    case AonwClientEventKind.unitKilled:
    case AonwClientEventKind.unitRetreated:
      _fields(value, {'type', 'attackerUnitId', 'target', 'subjectUnitId'});
      _stringsByKey(value, {'attackerUnitId', 'subjectUnitId'});
      _combatTarget(value['target']);
    case AonwClientEventKind.autoExplorePlanned:
      _fields(value, {'type', 'unitId', 'target'});
      readString(value['unitId'], 'unit id');
      AonwCoordinate.fromJson(value['target']);
    case AonwClientEventKind.merchantRouteAssigned:
      _fields(value, {'type', 'unitId', 'originCityId', 'destinationCityId'});
      _stringsByKey(value, {'unitId', 'originCityId', 'destinationCityId'});
    case AonwClientEventKind.merchantTravelQueued:
      _fields(value, {'type', 'unitId', 'destinationCityId'});
      _stringsByKey(value, {'unitId', 'destinationCityId'});
    case AonwClientEventKind.troopDetached:
      _fields(value, {
        'type',
        'sourceUnitId',
        'detachedUnitId',
        'troopKind',
        'destination',
      });
      _stringsByKey(value, {'sourceUnitId', 'detachedUnitId'});
      AonwTroopKind.fromJson(value['troopKind']);
      AonwCoordinate.fromJson(value['destination']);
    case AonwClientEventKind.workerCompletedJob:
      _fields(value, {'type', 'unitId', 'target', 'completion'});
      readString(value['unitId'], 'worker unit id');
      AonwCoordinate.fromJson(value['target']);
      _workerCompletion(value['completion']);
    case AonwClientEventKind.matchEnded:
    case AonwClientEventKind.unitMoved:
    case AonwClientEventKind.turnEnded:
    case AonwClientEventKind.allPlayersSubmitted:
    case AonwClientEventKind.playerTimedOut:
    case AonwClientEventKind.playerKicked:
      throw StateError('Specialized event parser was bypassed.');
  }
}

void _combatSubject(Map<String, Object?> value, {required String subjectKey}) {
  _fields(value, {'type', subjectKey, 'target'});
  readString(value[subjectKey], 'combat subject id');
  _combatTarget(value['target']);
}

void _combatTarget(Object? source) {
  final value = readObject(source, 'combat target');
  switch (readString(value['type'], 'combat target type')) {
    case 'unit':
      _fields(value, {'type', 'unitId'});
      readString(value['unitId'], 'target unit id');
    case 'city':
      _fields(value, {'type', 'cityId'});
      readString(value['cityId'], 'target city id');
    default:
      throw const FormatException('Unknown AoNW combat target.');
  }
}

void _workerCompletion(Object? source) {
  final value = readObject(source, 'worker completion');
  switch (readString(value['type'], 'worker completion type')) {
    case 'fieldImprovement':
      _fields(value, {'type', 'improvement'});
      AonwFieldImprovementKind.fromJson(value['improvement']);
    case 'road':
      _fields(value, {'type'});
    default:
      throw const FormatException('Unknown AoNW worker completion.');
  }
}

void _technology(Object? source) =>
    _enum(source, _technologyIds, 'technology id');

void _fields(Map<String, Object?> value, Set<String> keys) =>
    requireKeys(value, keys, 'client event');

void _stringsByKey(Map<String, Object?> value, Set<String> keys) {
  for (final key in keys) readString(value[key], key);
}

List<String> _strings(Object? value, String label) =>
    readList(value, label, (item, _) => readString(item, label));

int? _nullableUnsigned(Object? value, String label) =>
    value == null ? null : readUnsigned(value, label);

void _finiteNumber(Object? value, String label) {
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('Invalid AoNW $label.');
  }
}

void _enum(Object? source, Set<String> values, String label) {
  final value = readString(source, label);
  if (!values.contains(value))
    throw FormatException('Unknown AoNW $label $value.');
}

const _stabilityBands = {'content', 'stable', 'strained', 'unrest'};
const _scoreReasons = {
  'manual',
  'unitAttack',
  'cityAttack',
  'declarationOfWar',
  'warmongerPenalty',
  'proposalAccepted',
  'proposalRejected',
  'messageResponse',
  'commonEnemyCooperation',
  'goldGift',
  'promiseBroken',
};
const _technologyIds = {
  'agriculture',
  'woodworking',
  'mining',
  'animalHusbandry',
  'hunting',
  'fishing',
  'craftsmanship',
  'trade',
  'storage',
  'waterEngineering',
  'stoneworking',
  'militaryOrganization',
  'advancedTrade',
  'construction',
  'navigation',
  'irrigation',
  'banking',
  'engineering',
  'metallurgy',
  'horsebackRiding',
  'ironWorking',
  'coalMining',
  'machinery',
  'administration',
  'logistics',
  'shipbuilding',
  'tactics',
  'economy',
  'urbanization',
  'fortifications',
  'strategy',
  'specialization',
  'writing',
  'mathematics',
  'medicine',
  'civilService',
  'siegecraft',
  'cartography',
  'guilds',
  'law',
  'education',
  'urbanPlanning',
  'navalDoctrine',
  'steel',
  'bureaucracy',
  'nationalism',
  'scientificMethod',
  'steamPower',
  'electricity',
  'combustion',
  'flight',
  'massProduction',
  'radio',
  'nuclearPhysics',
};
