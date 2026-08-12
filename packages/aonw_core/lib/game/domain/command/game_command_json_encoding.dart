part of 'game_command_serialization.dart';

Map<String, dynamic> _encodeDomainCommand(DomainCommand command) {
  return _encodeUnitCommand(command) ??
      _encodeArtifactCommand(command) ??
      _encodeCityProductionCommand(command) ??
      _encodeCityControlCommand(command) ??
      _encodeTurnResearchCommand(command) ??
      _encodeWorkerCommand(command) ??
      _encodeCombatCommand(command) ??
      _encodeDiplomaticProposalCommand(command) ??
      _encodeDiplomaticTradeCommand(command) ??
      _encodeDiplomaticMessageCommand(command) ??
      (throw StateError(
        'DomainCommand encoder inventory is incomplete for '
        '${command.runtimeType}.',
      ));
}

Map<String, dynamic>? _encodeUnitCommand(DomainCommand command) {
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
    AssignMerchantTradeRouteCommand(:final unitId, :final destinationCityId) =>
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
    _ => null,
  };
}

Map<String, dynamic>? _encodeArtifactCommand(DomainCommand command) {
  return switch (command) {
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
    _ => null,
  };
}

Map<String, dynamic>? _encodeCityProductionCommand(DomainCommand command) {
  return switch (command) {
    StartBuildingCommand(:final cityId, :final buildingType) => {
      'type': 'StartBuilding',
      'cityId': cityId,
      'buildingType': buildingType.name,
    },
    StartUnitProductionCommand(
      :final cityId,
      :final unitType,
      :final resourceOptionIndex,
    ) =>
      {
        'type': 'StartUnitProduction',
        'cityId': cityId,
        'unitType': unitType.name,
        'resourceOptionIndex': ?resourceOptionIndex,
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
    RushProductionCommand(:final cityId) => {
      'type': 'RushProduction',
      'cityId': cityId,
    },
    _ => null,
  };
}

Map<String, dynamic>? _encodeCityControlCommand(DomainCommand command) {
  return switch (command) {
    FoundCityCommand(:final founderId, :final controlledHexes) => {
      'type': 'FoundCity',
      'founderId': founderId,
      'controlledHexes': controlledHexes.map((hex) => hex.toJson()).toList(),
    },
    SetCitySpecializationCommand(:final cityId, :final specialization) => {
      'type': 'SetCitySpecialization',
      'cityId': cityId,
      'specialization': specialization.name,
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
    _ => null,
  };
}

Map<String, dynamic>? _encodeTurnResearchCommand(DomainCommand command) {
  return switch (command) {
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
    _ => null,
  };
}

Map<String, dynamic>? _encodeWorkerCommand(DomainCommand command) {
  return switch (command) {
    SelectWorkerImprovementCommand(:final unitId, :final improvementType) => {
      'type': 'SelectWorkerImprovement',
      'unitId': unitId,
      'improvementType': improvementType.name,
    },
    ConfirmWorkerImprovementCommand(:final unitId, :final improvementType) => {
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
    BuildRoadCommand(:final unitId) => {'type': 'BuildRoad', 'unitId': unitId},
    AutomateWorkerCommand(:final unitId) => {
      'type': 'AutomateWorker',
      'unitId': unitId,
    },
    _ => null,
  };
}

Map<String, dynamic>? _encodeCombatCommand(DomainCommand command) {
  return switch (command) {
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
    _ => null,
  };
}

Map<String, dynamic>? _encodeDiplomaticProposalCommand(DomainCommand command) {
  return switch (command) {
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
    _ => null,
  };
}

Map<String, dynamic>? _encodeDiplomaticTradeCommand(DomainCommand command) {
  return switch (command) {
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
    _ => null,
  };
}

Map<String, dynamic>? _encodeDiplomaticMessageCommand(DomainCommand command) {
  return switch (command) {
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
    _ => null,
  };
}
