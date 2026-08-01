import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat/city_conquest_action.dart';
import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/util/wire_json.dart';

/// Exhaustive JSON codec for the [DomainCommand] sealed hierarchy.
///
/// Used for multiplayer transport — each command is encoded as a flat JSON map
/// with a `type` discriminator field plus command-specific payload fields.
abstract final class DomainCommandCodec {
  /// Serializes [command] to a JSON-compatible map.
  ///
  /// The `type` key holds a stable string discriminator.
  /// The switch expression is exhaustive over the sealed class, so adding a new
  /// subtype without updating this method will cause a compile-time error.
  static Map<String, dynamic> toJson(DomainCommand command) {
    return switch (command) {
      MoveUnitCommand(:final unitId, :final targetCol, :final targetRow) => {
        'type': 'MoveUnit',
        'unitId': unitId,
        'targetCol': targetCol,
        'targetRow': targetRow,
      },
      CancelUnitActionCommand(:final unitId) => {
        'type': 'CancelUnitAction',
        'unitId': unitId,
      },
      SkipUnitTurnCommand(:final unitId) => {
        'type': 'SkipUnitTurn',
        'unitId': unitId,
      },
      FortifyUnitCommand(:final unitId) => {
        'type': 'FortifyUnit',
        'unitId': unitId,
      },
      AutoExploreUnitCommand(:final unitId) => {
        'type': 'AutoExploreUnit',
        'unitId': unitId,
      },
      AssignMerchantTradeRouteCommand(
        :final unitId,
        :final destinationCityId,
      ) =>
        {
          'type': 'AssignMerchantTradeRoute',
          'unitId': unitId,
          'destinationCityId': destinationCityId,
        },
      MoveMerchantToCityCommand(:final unitId, :final destinationCityId) => {
        'type': 'MoveMerchantToCity',
        'unitId': unitId,
        'destinationCityId': destinationCityId,
      },
      StartArtifactExcavationCommand(:final unitId) => {
        'type': 'StartArtifactExcavation',
        'unitId': unitId,
      },
      StoreArtifactInCityCommand(:final unitId, :final cityId) => {
        'type': 'StoreArtifactInCity',
        'unitId': unitId,
        'cityId': ?cityId,
      },
      TradeArtifactCommand(
        :final playerId,
        :final targetPlayerId,
        :final offeredArtifactId,
        :final requestedArtifactId,
        :final offeredGold,
        :final requestedGold,
      ) =>
        {
          'type': 'TradeArtifact',
          'playerId': playerId,
          'targetPlayerId': targetPlayerId,
          'offeredArtifactId': offeredArtifactId,
          'requestedArtifactId': ?requestedArtifactId,
          if (offeredGold != 0) 'offeredGold': offeredGold,
          if (requestedGold != 0) 'requestedGold': requestedGold,
        },
      FoundCityCommand(:final founderId, :final controlledHexes) => {
        'type': 'FoundCity',
        'founderId': founderId,
        'controlledHexes': controlledHexes.map((hex) => hex.toJson()).toList(),
      },
      StartBuildingCommand(:final cityId, :final buildingType) => {
        'type': 'StartBuilding',
        'cityId': cityId,
        'buildingType': buildingType.name,
      },
      StartUnitProductionCommand(:final cityId, :final unitType) => {
        'type': 'StartUnitProduction',
        'cityId': cityId,
        'unitType': unitType.name,
      },
      StartCityProjectCommand(:final cityId, :final projectType) => {
        'type': 'StartCityProject',
        'cityId': cityId,
        'projectType': projectType.name,
      },
      StartWonderCommand(:final cityId, :final wonderType) => {
        'type': 'StartWonder',
        'cityId': cityId,
        'wonderType': wonderType.name,
      },
      SetCitySpecializationCommand(:final cityId, :final specialization) => {
        'type': 'SetCitySpecialization',
        'cityId': cityId,
        'specialization': specialization.name,
      },
      RushProductionCommand(:final cityId) => {
        'type': 'RushProduction',
        'cityId': cityId,
      },
      SelectTechnologyCommand(:final playerId, :final technologyId) => {
        'type': 'SelectTechnology',
        'playerId': playerId,
        'technologyId': technologyId.name,
      },
      DetachTroopCommand(:final unitId, :final troopType) => {
        'type': 'DetachTroop',
        'unitId': unitId,
        'troopType': troopType.name,
      },
      EndTurnCommand(:final playerId) => {
        'type': 'EndTurn',
        'playerId': playerId,
      },
      SubmitTurnCommand(:final playerId) => {
        'type': 'SubmitTurn',
        'playerId': playerId,
      },
      ToggleWorkedHexCommand(:final cityId, :final col, :final row) => {
        'type': 'ToggleWorkedHex',
        'cityId': cityId,
        'col': col,
        'row': row,
      },
      SelectCityExpansionHexCommand(:final cityId, :final col, :final row) => {
        'type': 'SelectCityExpansionHex',
        'cityId': cityId,
        'col': col,
        'row': row,
      },
      SelectWorkerImprovementCommand(:final unitId, :final improvementType) => {
        'type': 'SelectWorkerImprovement',
        'unitId': unitId,
        'improvementType': improvementType.name,
      },
      ConfirmWorkerImprovementCommand(:final unitId, :final improvementType) =>
        {
          'type': 'ConfirmWorkerImprovement',
          'unitId': unitId,
          if (improvementType != null) 'improvementType': improvementType.name,
        },
      CancelWorkerJobCommand(:final unitId) => {
        'type': 'CancelWorkerJob',
        'unitId': unitId,
      },
      AssignWorkerToHexCommand(:final unitId) => {
        'type': 'AssignWorkerToHex',
        'unitId': unitId,
      },
      CancelWorkerAssignmentCommand(:final unitId) => {
        'type': 'CancelWorkerAssignment',
        'unitId': unitId,
      },
      AttackHexCommand(
        :final attackerUnitId,
        :final defenderCol,
        :final defenderRow,
        :final cityConquestAction,
      ) =>
        {
          'type': 'AttackHex',
          'attackerUnitId': attackerUnitId,
          'defenderCol': defenderCol,
          'defenderRow': defenderRow,
          if (cityConquestAction != CityConquestAction.capture)
            'cityConquestAction': cityConquestAction.name,
        },
      SendDiplomaticProposalCommand(
        :final playerId,
        :final targetPlayerId,
        :final kind,
        :final proposalId,
        :final goldPayment,
      ) =>
        {
          'type': 'SendDiplomaticProposal',
          'playerId': playerId,
          'targetPlayerId': targetPlayerId,
          'kind': kind.name,
          'proposalId': ?proposalId,
          if (goldPayment > 0) 'goldPayment': goldPayment,
        },
      RespondDiplomaticProposalCommand(
        :final playerId,
        :final proposalId,
        :final accepted,
      ) =>
        {
          'type': 'RespondDiplomaticProposal',
          'playerId': playerId,
          'proposalId': proposalId,
          'accepted': accepted,
        },
      DeclareWarCommand(:final playerId, :final targetPlayerId) => {
        'type': 'DeclareWar',
        'playerId': playerId,
        'targetPlayerId': targetPlayerId,
      },
      SendGoldGiftCommand(
        :final playerId,
        :final targetPlayerId,
        :final amount,
      ) =>
        {
          'type': 'SendGoldGift',
          'playerId': playerId,
          'targetPlayerId': targetPlayerId,
          'amount': amount,
        },
      OpenResourceTradeCommand(
        :final playerId,
        :final targetPlayerId,
        :final resource,
        :final goldPerTurn,
        :final durationTurns,
        :final agreementId,
      ) =>
        {
          'type': 'OpenResourceTrade',
          'playerId': playerId,
          'targetPlayerId': targetPlayerId,
          'resource': resource.name,
          'goldPerTurn': goldPerTurn,
          'durationTurns': durationTurns,
          'agreementId': ?agreementId,
        },
      OpenResourceExchangeCommand(
        :final playerId,
        :final targetPlayerId,
        :final offeredResource,
        :final requestedResource,
        :final durationTurns,
        :final agreementId,
      ) =>
        {
          'type': 'OpenResourceExchange',
          'playerId': playerId,
          'targetPlayerId': targetPlayerId,
          'offeredResource': offeredResource.name,
          'requestedResource': requestedResource.name,
          'durationTurns': durationTurns,
          'agreementId': ?agreementId,
        },
      SendDiplomaticMessageCommand(
        :final playerId,
        :final targetPlayerId,
        :final topic,
        :final messageId,
      ) =>
        {
          'type': 'SendDiplomaticMessage',
          'playerId': playerId,
          'targetPlayerId': targetPlayerId,
          'topic': topic.name,
          'messageId': ?messageId,
        },
      RespondDiplomaticMessageCommand(
        :final playerId,
        :final messageId,
        :final response,
      ) =>
        {
          'type': 'RespondDiplomaticMessage',
          'playerId': playerId,
          'messageId': messageId,
          'response': response.name,
        },
    };
  }

  /// Deserializes a [DomainCommand] from [json] using the `type` discriminator.
  ///
  /// Throws [ArgumentError] if the `type` value is unrecognised.
  static DomainCommand fromJson(Map<String, dynamic> json) {
    final type = requiredStringField(json, 'DomainCommand', 'type');
    return switch (type) {
      'MoveUnit' => MoveUnitCommand(
        requiredStringField(json, type, 'unitId'),
        requiredIntField(json, type, 'targetCol'),
        requiredIntField(json, type, 'targetRow'),
      ),
      'CancelUnitAction' => CancelUnitActionCommand(
        requiredStringField(json, type, 'unitId'),
      ),
      'SkipUnitTurn' || 'SleepUnit' => SkipUnitTurnCommand(
        requiredStringField(json, type, 'unitId'),
      ),
      'FortifyUnit' => FortifyUnitCommand(
        requiredStringField(json, type, 'unitId'),
      ),
      'AutoExploreUnit' => AutoExploreUnitCommand(
        requiredStringField(json, type, 'unitId'),
      ),
      'AssignMerchantTradeRoute' => AssignMerchantTradeRouteCommand(
        requiredStringField(json, type, 'unitId'),
        requiredStringField(json, type, 'destinationCityId'),
      ),
      'MoveMerchantToCity' => MoveMerchantToCityCommand(
        requiredStringField(json, type, 'unitId'),
        requiredStringField(json, type, 'destinationCityId'),
      ),
      'StartArtifactExcavation' => StartArtifactExcavationCommand(
        requiredStringField(json, type, 'unitId'),
      ),
      'StoreArtifactInCity' => StoreArtifactInCityCommand(
        requiredStringField(json, type, 'unitId'),
        cityId: optionalStringField(json, type, 'cityId'),
      ),
      'TradeArtifact' => TradeArtifactCommand(
        playerId: requiredStringField(json, type, 'playerId'),
        targetPlayerId: requiredStringField(json, type, 'targetPlayerId'),
        offeredArtifactId: requiredStringField(json, type, 'offeredArtifactId'),
        requestedArtifactId: optionalStringField(
          json,
          type,
          'requestedArtifactId',
        ),
        offeredGold: optionalIntField(json, type, 'offeredGold') ?? 0,
        requestedGold: optionalIntField(json, type, 'requestedGold') ?? 0,
      ),
      'FoundCity' => FoundCityCommand(
        requiredStringField(json, type, 'founderId'),
        controlledHexes: _cityHexList(json, type, 'controlledHexes'),
      ),
      'StartBuilding' => StartBuildingCommand(
        requiredStringField(json, type, 'cityId'),
        requiredEnumField(json, type, 'buildingType', CityBuildingType.values),
      ),
      'StartUnitProduction' => StartUnitProductionCommand(
        requiredStringField(json, type, 'cityId'),
        requiredEnumField(json, type, 'unitType', GameUnitType.values),
      ),
      'StartCityProject' => StartCityProjectCommand(
        requiredStringField(json, type, 'cityId'),
        requiredEnumField(json, type, 'projectType', CityProjectType.values),
      ),
      'StartWonder' => StartWonderCommand(
        requiredStringField(json, type, 'cityId'),
        requiredEnumField(json, type, 'wonderType', WonderType.values),
      ),
      'SetCitySpecialization' => SetCitySpecializationCommand(
        requiredStringField(json, type, 'cityId'),
        requiredEnumField(
          json,
          type,
          'specialization',
          CitySpecializationType.values,
        ),
      ),
      'RushProduction' => RushProductionCommand(
        requiredStringField(json, type, 'cityId'),
      ),
      'SelectTechnology' => SelectTechnologyCommand(
        requiredStringField(json, type, 'playerId'),
        requiredEnumField(json, type, 'technologyId', TechnologyId.values),
      ),
      'DetachTroop' => DetachTroopCommand(
        requiredStringField(json, type, 'unitId'),
        requiredEnumField(json, type, 'troopType', TroopType.values),
      ),
      'EndTurn' => EndTurnCommand(requiredStringField(json, type, 'playerId')),
      'SubmitTurn' => SubmitTurnCommand(
        requiredStringField(json, type, 'playerId'),
      ),
      'ToggleWorkedHex' => ToggleWorkedHexCommand(
        requiredStringField(json, type, 'cityId'),
        requiredIntField(json, type, 'col'),
        requiredIntField(json, type, 'row'),
      ),
      'SelectCityExpansionHex' => SelectCityExpansionHexCommand(
        requiredStringField(json, type, 'cityId'),
        requiredIntField(json, type, 'col'),
        requiredIntField(json, type, 'row'),
      ),
      'SelectWorkerImprovement' => SelectWorkerImprovementCommand(
        requiredStringField(json, type, 'unitId'),
        requiredEnumField(
          json,
          type,
          'improvementType',
          FieldImprovementType.values,
        ),
      ),
      'ConfirmWorkerImprovement' => ConfirmWorkerImprovementCommand(
        requiredStringField(json, type, 'unitId'),
        improvementType: optionalEnumField(
          json,
          type,
          'improvementType',
          FieldImprovementType.values,
        ),
      ),
      'CancelWorkerJob' => CancelWorkerJobCommand(
        requiredStringField(json, type, 'unitId'),
      ),
      'AssignWorkerToHex' => AssignWorkerToHexCommand(
        requiredStringField(json, type, 'unitId'),
      ),
      'CancelWorkerAssignment' => CancelWorkerAssignmentCommand(
        requiredStringField(json, type, 'unitId'),
      ),
      'AttackHex' => AttackHexCommand(
        requiredStringField(json, type, 'attackerUnitId'),
        requiredIntField(json, type, 'defenderCol'),
        requiredIntField(json, type, 'defenderRow'),
        cityConquestAction:
            optionalEnumField(
              json,
              type,
              'cityConquestAction',
              CityConquestAction.values,
            ) ??
            CityConquestAction.capture,
      ),
      'SendDiplomaticProposal' => SendDiplomaticProposalCommand(
        playerId: requiredStringField(json, type, 'playerId'),
        targetPlayerId: requiredStringField(json, type, 'targetPlayerId'),
        kind: requiredEnumField(
          json,
          type,
          'kind',
          DiplomaticProposalKind.values,
        ),
        proposalId: optionalStringField(json, type, 'proposalId'),
        goldPayment: optionalIntField(json, type, 'goldPayment') ?? 0,
      ),
      'RespondDiplomaticProposal' => RespondDiplomaticProposalCommand(
        playerId: requiredStringField(json, type, 'playerId'),
        proposalId: requiredStringField(json, type, 'proposalId'),
        accepted: requiredBoolField(json, type, 'accepted'),
      ),
      'DeclareWar' => DeclareWarCommand(
        playerId: requiredStringField(json, type, 'playerId'),
        targetPlayerId: requiredStringField(json, type, 'targetPlayerId'),
      ),
      'SendGoldGift' => SendGoldGiftCommand(
        playerId: requiredStringField(json, type, 'playerId'),
        targetPlayerId: requiredStringField(json, type, 'targetPlayerId'),
        amount: requiredIntField(json, type, 'amount'),
      ),
      'OpenResourceTrade' => OpenResourceTradeCommand(
        playerId: requiredStringField(json, type, 'playerId'),
        targetPlayerId: requiredStringField(json, type, 'targetPlayerId'),
        resource: requiredEnumField(
          json,
          type,
          'resource',
          ResourceType.values,
        ),
        goldPerTurn: requiredIntField(json, type, 'goldPerTurn'),
        durationTurns: requiredIntField(json, type, 'durationTurns'),
        agreementId: optionalStringField(json, type, 'agreementId'),
      ),
      'OpenResourceExchange' => OpenResourceExchangeCommand(
        playerId: requiredStringField(json, type, 'playerId'),
        targetPlayerId: requiredStringField(json, type, 'targetPlayerId'),
        offeredResource: requiredEnumField(
          json,
          type,
          'offeredResource',
          ResourceType.values,
        ),
        requestedResource: requiredEnumField(
          json,
          type,
          'requestedResource',
          ResourceType.values,
        ),
        durationTurns: requiredIntField(json, type, 'durationTurns'),
        agreementId: optionalStringField(json, type, 'agreementId'),
      ),
      'SendDiplomaticMessage' => SendDiplomaticMessageCommand(
        playerId: requiredStringField(json, type, 'playerId'),
        targetPlayerId: requiredStringField(json, type, 'targetPlayerId'),
        topic: requiredEnumField(
          json,
          type,
          'topic',
          DiplomaticMessageTopic.values,
        ),
        messageId: optionalStringField(json, type, 'messageId'),
      ),
      'RespondDiplomaticMessage' => RespondDiplomaticMessageCommand(
        playerId: requiredStringField(json, type, 'playerId'),
        messageId: requiredStringField(json, type, 'messageId'),
        response: requiredEnumField(
          json,
          type,
          'response',
          DiplomaticMessageResponse.values,
        ),
      ),
      _ => throw ArgumentError('Unknown DomainCommand type: "$type"'),
    };
  }

  static List<CityHex> _cityHexList(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value == null) return const [];
    if (value is! List) {
      throw ArgumentError.value(value, '$type.$field', 'Expected a JSON list');
    }
    return [
      for (final entry in value)
        if (entry is Map<String, dynamic>)
          CityHex.fromJson(entry)
        else if (entry is Map<Object?, Object?>)
          CityHex.fromJson(Map<String, dynamic>.from(entry))
        else
          throw ArgumentError.value(
            entry,
            '$type.$field[]',
            'Expected a JSON object',
          ),
    ];
  }
}
