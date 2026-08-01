part of 'game_command_serialization.dart';

DomainCommand _decodeDomainCommand(Map<String, dynamic> json) {
  final type = requiredStringField(json, 'DomainCommand', 'type');
  return _decodeUnitCommand(json, type) ??
      _decodeMerchantCommand(json, type) ??
      _decodeArtifactCommand(json, type) ??
      _decodeCityProductionCommand(json, type) ??
      _decodeCityControlCommand(json, type) ??
      _decodeTurnResearchCommand(json, type) ??
      _decodeWorkerCombatCommand(json, type) ??
      _decodeDiplomaticProposalCommand(json, type) ??
      _decodeDiplomaticTradeCommand(json, type) ??
      _decodeDiplomaticMessageCommand(json, type) ??
      (throw ArgumentError('Unknown DomainCommand type: "$type"'));
}

DomainCommand? _decodeUnitCommand(Map<String, dynamic> json, String type) {
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
    _ => null,
  };
}

DomainCommand? _decodeMerchantCommand(Map<String, dynamic> json, String type) {
  return switch (type) {
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
    _ => null,
  };
}

DomainCommand? _decodeArtifactCommand(Map<String, dynamic> json, String type) {
  return switch (type) {
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
    _ => null,
  };
}

DomainCommand? _decodeCityProductionCommand(
  Map<String, dynamic> json,
  String type,
) {
  return switch (type) {
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
    'RushProduction' => RushProductionCommand(
      requiredStringField(json, type, 'cityId'),
    ),
    _ => null,
  };
}

DomainCommand? _decodeCityControlCommand(
  Map<String, dynamic> json,
  String type,
) {
  return switch (type) {
    'FoundCity' => FoundCityCommand(
      requiredStringField(json, type, 'founderId'),
      controlledHexes: _cityHexList(json, type, 'controlledHexes'),
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
    _ => null,
  };
}

DomainCommand? _decodeTurnResearchCommand(
  Map<String, dynamic> json,
  String type,
) {
  return switch (type) {
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
    _ => null,
  };
}

DomainCommand? _decodeWorkerCombatCommand(
  Map<String, dynamic> json,
  String type,
) {
  return switch (type) {
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
    _ => null,
  };
}

DomainCommand? _decodeDiplomaticProposalCommand(
  Map<String, dynamic> json,
  String type,
) {
  return switch (type) {
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
    _ => null,
  };
}

DomainCommand? _decodeDiplomaticTradeCommand(
  Map<String, dynamic> json,
  String type,
) {
  return switch (type) {
    'OpenResourceTrade' => OpenResourceTradeCommand(
      playerId: requiredStringField(json, type, 'playerId'),
      targetPlayerId: requiredStringField(json, type, 'targetPlayerId'),
      resource: requiredEnumField(json, type, 'resource', ResourceType.values),
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
    _ => null,
  };
}

DomainCommand? _decodeDiplomaticMessageCommand(
  Map<String, dynamic> json,
  String type,
) {
  return switch (type) {
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
    _ => null,
  };
}

List<CityHex> _cityHexList(
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
