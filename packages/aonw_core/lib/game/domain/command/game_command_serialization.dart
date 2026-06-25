import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat/city_conquest_action.dart';
import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

/// JSON serialization / deserialization for the [GameCommand] sealed hierarchy.
///
/// Used for multiplayer transport — each command is encoded as a flat JSON map
/// with a `type` discriminator field plus command-specific payload fields.
abstract final class GameCommandSerializer {
  /// Serializes [command] to a JSON-compatible map.
  ///
  /// The `type` key holds a stable string discriminator.
  /// The switch expression is exhaustive over the sealed class, so adding a new
  /// subtype without updating this method will cause a compile-time error.
  static Map<String, dynamic> toJson(GameCommand command) => switch (command) {
    TileTappedCommand(:final col, :final row) => {
      'type': 'TileTapped',
      'col': col,
      'row': row,
    },
    CityTappedCommand(:final cityId) => {
      'type': 'CityTapped',
      'cityId': cityId,
    },
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
    StartMerchantTradeRouteSelectionCommand(:final unitId) => {
      'type': 'StartMerchantTradeRouteSelection',
      'unitId': unitId,
    },
    CancelMerchantTradeRouteSelectionCommand(:final unitId) => {
      'type': 'CancelMerchantTradeRouteSelection',
      'unitId': unitId,
    },
    AssignMerchantTradeRouteCommand(:final unitId, :final destinationCityId) =>
      {
        'type': 'AssignMerchantTradeRoute',
        'unitId': unitId,
        'destinationCityId': destinationCityId,
      },
    StartMerchantMoveToCitySelectionCommand(:final unitId) => {
      'type': 'StartMerchantMoveToCitySelection',
      'unitId': unitId,
    },
    CancelMerchantMoveToCitySelectionCommand(:final unitId) => {
      'type': 'CancelMerchantMoveToCitySelection',
      'unitId': unitId,
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
    CancelResearchSelectionCommand(:final playerId) => {
      'type': 'CancelResearchSelection',
      'playerId': playerId,
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
    ResetUnitMovementCommand(:final playerId) => {
      'type': 'ResetUnitMovement',
      'playerId': ?playerId,
    },
    SetActivePlayerCommand(:final playerId, :final canAct) => {
      'type': 'SetActivePlayer',
      'playerId': playerId,
      'canAct': canAct,
    },
    ToggleMoveTargetingCommand() => {'type': 'ToggleMoveTargeting'},
    StartCityFoundingCommand() => {'type': 'StartCityFounding'},
    CancelCityFoundingCommand() => {'type': 'CancelCityFounding'},
    StartCityWorkedHexSelectionCommand(:final cityId) => {
      'type': 'StartCityWorkedHexSelection',
      'cityId': cityId,
    },
    CancelCityWorkedHexSelectionCommand(:final cityId) => {
      'type': 'CancelCityWorkedHexSelection',
      'cityId': cityId,
    },
    ToggleWorkedHexCommand(:final cityId, :final col, :final row) => {
      'type': 'ToggleWorkedHex',
      'cityId': cityId,
      'col': col,
      'row': row,
    },
    StartCityExpansionSelectionCommand(:final cityId) => {
      'type': 'StartCityExpansionSelection',
      'cityId': cityId,
    },
    CancelCityExpansionSelectionCommand(:final cityId) => {
      'type': 'CancelCityExpansionSelection',
      'cityId': cityId,
    },
    SelectCityExpansionHexCommand(:final cityId, :final col, :final row) => {
      'type': 'SelectCityExpansionHex',
      'cityId': cityId,
      'col': col,
      'row': row,
    },
    StartWorkerActionSelectionCommand(:final unitId) => {
      'type': 'StartWorkerActionSelection',
      'unitId': unitId,
    },
    SelectWorkerImprovementCommand(:final unitId, :final improvementType) => {
      'type': 'SelectWorkerImprovement',
      'unitId': unitId,
      'improvementType': improvementType.name,
    },
    ConfirmWorkerImprovementCommand(:final unitId) => {
      'type': 'ConfirmWorkerImprovement',
      'unitId': unitId,
    },
    CancelWorkerActionSelectionCommand(:final unitId) => {
      'type': 'CancelWorkerActionSelection',
      'unitId': unitId,
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
    StartAttackTargetingCommand(:final attackerUnitId) => {
      'type': 'StartAttackTargeting',
      'attackerUnitId': attackerUnitId,
    },
    CancelAttackTargetingCommand(:final attackerUnitId) => {
      'type': 'CancelAttackTargeting',
      'attackerUnitId': attackerUnitId,
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
    StartCommanderMergeSelectionCommand(:final commanderUnitId) => {
      'type': 'StartCommanderMergeSelection',
      'commanderUnitId': commanderUnitId,
    },
    CancelCommanderMergeSelectionCommand(:final commanderUnitId) => {
      'type': 'CancelCommanderMergeSelection',
      'commanderUnitId': commanderUnitId,
    },
    SelectTileCommand(:final col, :final row) => {
      'type': 'SelectTile',
      'col': col,
      'row': row,
    },
    SelectUnitCommand(:final unitId) => {
      'type': 'SelectUnit',
      'unitId': unitId,
    },
    SelectCityCommand(:final cityId) => {
      'type': 'SelectCity',
      'cityId': cityId,
    },
    FocusNextPendingActionCommand(
      :final playerId,
      :final preferredObjectiveAdvice,
      :final actionIndex,
    ) =>
      {
        'type': 'FocusNextPendingAction',
        'playerId': playerId,
        if (preferredObjectiveAdvice != null)
          'preferredObjectiveAdvice': preferredObjectiveAdvice.name,
        'actionIndex': ?actionIndex,
      },
    FocusTurnStartActionCommand(:final playerId) => {
      'type': 'FocusTurnStartAction',
      'playerId': playerId,
    },
    SendDiplomaticProposalCommand(
      :final playerId,
      :final targetPlayerId,
      :final kind,
      :final proposalId,
    ) =>
      {
        'type': 'SendDiplomaticProposal',
        'playerId': playerId,
        'targetPlayerId': targetPlayerId,
        'kind': kind.name,
        'proposalId': ?proposalId,
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

  /// Deserializes a [GameCommand] from [json] using the `type` discriminator.
  ///
  /// Throws [ArgumentError] if the `type` value is unrecognised.
  static GameCommand fromJson(Map<String, dynamic> json) {
    final type = _requiredString(json, 'GameCommand', 'type');
    return switch (type) {
      'TileTapped' => TileTappedCommand(
        _requiredInt(json, type, 'col'),
        _requiredInt(json, type, 'row'),
      ),
      'CityTapped' => CityTappedCommand(_requiredString(json, type, 'cityId')),
      'MoveUnit' => MoveUnitCommand(
        _requiredString(json, type, 'unitId'),
        _requiredInt(json, type, 'targetCol'),
        _requiredInt(json, type, 'targetRow'),
      ),
      'CancelUnitAction' => CancelUnitActionCommand(
        _requiredString(json, type, 'unitId'),
      ),
      'SkipUnitTurn' ||
      'SleepUnit' => SkipUnitTurnCommand(_requiredString(json, type, 'unitId')),
      'FortifyUnit' => FortifyUnitCommand(
        _requiredString(json, type, 'unitId'),
      ),
      'AutoExploreUnit' => AutoExploreUnitCommand(
        _requiredString(json, type, 'unitId'),
      ),
      'StartMerchantTradeRouteSelection' =>
        StartMerchantTradeRouteSelectionCommand(
          _requiredString(json, type, 'unitId'),
        ),
      'CancelMerchantTradeRouteSelection' =>
        CancelMerchantTradeRouteSelectionCommand(
          _requiredString(json, type, 'unitId'),
        ),
      'AssignMerchantTradeRoute' => AssignMerchantTradeRouteCommand(
        _requiredString(json, type, 'unitId'),
        _requiredString(json, type, 'destinationCityId'),
      ),
      'StartMerchantMoveToCitySelection' =>
        StartMerchantMoveToCitySelectionCommand(
          _requiredString(json, type, 'unitId'),
        ),
      'CancelMerchantMoveToCitySelection' =>
        CancelMerchantMoveToCitySelectionCommand(
          _requiredString(json, type, 'unitId'),
        ),
      'MoveMerchantToCity' => MoveMerchantToCityCommand(
        _requiredString(json, type, 'unitId'),
        _requiredString(json, type, 'destinationCityId'),
      ),
      'StartArtifactExcavation' => StartArtifactExcavationCommand(
        _requiredString(json, type, 'unitId'),
      ),
      'StoreArtifactInCity' => StoreArtifactInCityCommand(
        _requiredString(json, type, 'unitId'),
        cityId: _optionalString(json, type, 'cityId'),
      ),
      'TradeArtifact' => TradeArtifactCommand(
        playerId: _requiredString(json, type, 'playerId'),
        targetPlayerId: _requiredString(json, type, 'targetPlayerId'),
        offeredArtifactId: _requiredString(json, type, 'offeredArtifactId'),
        requestedArtifactId: _optionalString(json, type, 'requestedArtifactId'),
        offeredGold: _optionalInt(json, type, 'offeredGold') ?? 0,
        requestedGold: _optionalInt(json, type, 'requestedGold') ?? 0,
      ),
      'FoundCity' => FoundCityCommand(
        _requiredString(json, type, 'founderId'),
        controlledHexes: _cityHexList(json, type, 'controlledHexes'),
      ),
      'StartBuilding' => StartBuildingCommand(
        _requiredString(json, type, 'cityId'),
        _requiredEnum(json, type, 'buildingType', CityBuildingType.values),
      ),
      'StartUnitProduction' => StartUnitProductionCommand(
        _requiredString(json, type, 'cityId'),
        _requiredEnum(json, type, 'unitType', GameUnitType.values),
      ),
      'StartCityProject' => StartCityProjectCommand(
        _requiredString(json, type, 'cityId'),
        _requiredEnum(json, type, 'projectType', CityProjectType.values),
      ),
      'SetCitySpecialization' => SetCitySpecializationCommand(
        _requiredString(json, type, 'cityId'),
        _requiredEnum(
          json,
          type,
          'specialization',
          CitySpecializationType.values,
        ),
      ),
      'RushProduction' => RushProductionCommand(
        _requiredString(json, type, 'cityId'),
      ),
      'SelectTechnology' => SelectTechnologyCommand(
        _requiredString(json, type, 'playerId'),
        _requiredEnum(json, type, 'technologyId', TechnologyId.values),
      ),
      'CancelResearchSelection' => CancelResearchSelectionCommand(
        _requiredString(json, type, 'playerId'),
      ),
      'DetachTroop' => DetachTroopCommand(
        _requiredString(json, type, 'unitId'),
        _requiredEnum(json, type, 'troopType', TroopType.values),
      ),
      'EndTurn' => EndTurnCommand(_requiredString(json, type, 'playerId')),
      'SubmitTurn' => SubmitTurnCommand(
        _requiredString(json, type, 'playerId'),
      ),
      'ResetUnitMovement' => ResetUnitMovementCommand(
        playerId: _optionalString(json, type, 'playerId'),
      ),
      'SetActivePlayer' => SetActivePlayerCommand(
        _requiredString(json, type, 'playerId'),
        canAct: _requiredBool(json, type, 'canAct'),
      ),
      'ToggleMoveTargeting' => const ToggleMoveTargetingCommand(),
      'StartCityFounding' => const StartCityFoundingCommand(),
      'CancelCityFounding' => const CancelCityFoundingCommand(),
      'StartCityWorkedHexSelection' => StartCityWorkedHexSelectionCommand(
        _requiredString(json, type, 'cityId'),
      ),
      'CancelCityWorkedHexSelection' => CancelCityWorkedHexSelectionCommand(
        _requiredString(json, type, 'cityId'),
      ),
      'ToggleWorkedHex' => ToggleWorkedHexCommand(
        _requiredString(json, type, 'cityId'),
        _requiredInt(json, type, 'col'),
        _requiredInt(json, type, 'row'),
      ),
      'StartCityExpansionSelection' => StartCityExpansionSelectionCommand(
        _requiredString(json, type, 'cityId'),
      ),
      'CancelCityExpansionSelection' => CancelCityExpansionSelectionCommand(
        _requiredString(json, type, 'cityId'),
      ),
      'SelectCityExpansionHex' => SelectCityExpansionHexCommand(
        _requiredString(json, type, 'cityId'),
        _requiredInt(json, type, 'col'),
        _requiredInt(json, type, 'row'),
      ),
      'StartWorkerActionSelection' => StartWorkerActionSelectionCommand(
        _requiredString(json, type, 'unitId'),
      ),
      'SelectWorkerImprovement' => SelectWorkerImprovementCommand(
        _requiredString(json, type, 'unitId'),
        _requiredEnum(
          json,
          type,
          'improvementType',
          FieldImprovementType.values,
        ),
      ),
      'ConfirmWorkerImprovement' => ConfirmWorkerImprovementCommand(
        _requiredString(json, type, 'unitId'),
      ),
      'CancelWorkerActionSelection' => CancelWorkerActionSelectionCommand(
        _requiredString(json, type, 'unitId'),
      ),
      'CancelWorkerJob' => CancelWorkerJobCommand(
        _requiredString(json, type, 'unitId'),
      ),
      'AssignWorkerToHex' => AssignWorkerToHexCommand(
        _requiredString(json, type, 'unitId'),
      ),
      'CancelWorkerAssignment' => CancelWorkerAssignmentCommand(
        _requiredString(json, type, 'unitId'),
      ),
      'StartAttackTargeting' => StartAttackTargetingCommand(
        _requiredString(json, type, 'attackerUnitId'),
      ),
      'CancelAttackTargeting' => CancelAttackTargetingCommand(
        _requiredString(json, type, 'attackerUnitId'),
      ),
      'AttackHex' => AttackHexCommand(
        _requiredString(json, type, 'attackerUnitId'),
        _requiredInt(json, type, 'defenderCol'),
        _requiredInt(json, type, 'defenderRow'),
        cityConquestAction:
            _optionalEnum(
              json,
              type,
              'cityConquestAction',
              CityConquestAction.values,
            ) ??
            CityConquestAction.capture,
      ),
      'StartCommanderMergeSelection' => StartCommanderMergeSelectionCommand(
        _requiredString(json, type, 'commanderUnitId'),
      ),
      'CancelCommanderMergeSelection' => CancelCommanderMergeSelectionCommand(
        _requiredString(json, type, 'commanderUnitId'),
      ),
      'SelectTile' => SelectTileCommand(
        _requiredInt(json, type, 'col'),
        _requiredInt(json, type, 'row'),
      ),
      'SelectUnit' => SelectUnitCommand(_requiredString(json, type, 'unitId')),
      'SelectCity' => SelectCityCommand(_requiredString(json, type, 'cityId')),
      'FocusNextPendingAction' => FocusNextPendingActionCommand(
        _requiredString(json, type, 'playerId'),
        preferredObjectiveAdvice: _optionalEnum(
          json,
          type,
          'preferredObjectiveAdvice',
          GameObjectiveAdvice.values,
        ),
        actionIndex: _optionalInt(json, type, 'actionIndex'),
      ),
      'FocusTurnStartAction' => FocusTurnStartActionCommand(
        _requiredString(json, type, 'playerId'),
      ),
      'SendDiplomaticProposal' => SendDiplomaticProposalCommand(
        playerId: _requiredString(json, type, 'playerId'),
        targetPlayerId: _requiredString(json, type, 'targetPlayerId'),
        kind: _requiredEnum(json, type, 'kind', DiplomaticProposalKind.values),
        proposalId: _optionalString(json, type, 'proposalId'),
      ),
      'RespondDiplomaticProposal' => RespondDiplomaticProposalCommand(
        playerId: _requiredString(json, type, 'playerId'),
        proposalId: _requiredString(json, type, 'proposalId'),
        accepted: _requiredBool(json, type, 'accepted'),
      ),
      'DeclareWar' => DeclareWarCommand(
        playerId: _requiredString(json, type, 'playerId'),
        targetPlayerId: _requiredString(json, type, 'targetPlayerId'),
      ),
      'OpenResourceTrade' => OpenResourceTradeCommand(
        playerId: _requiredString(json, type, 'playerId'),
        targetPlayerId: _requiredString(json, type, 'targetPlayerId'),
        resource: _requiredEnum(json, type, 'resource', ResourceType.values),
        goldPerTurn: _requiredInt(json, type, 'goldPerTurn'),
        durationTurns: _requiredInt(json, type, 'durationTurns'),
        agreementId: _optionalString(json, type, 'agreementId'),
      ),
      'OpenResourceExchange' => OpenResourceExchangeCommand(
        playerId: _requiredString(json, type, 'playerId'),
        targetPlayerId: _requiredString(json, type, 'targetPlayerId'),
        offeredResource: _requiredEnum(
          json,
          type,
          'offeredResource',
          ResourceType.values,
        ),
        requestedResource: _requiredEnum(
          json,
          type,
          'requestedResource',
          ResourceType.values,
        ),
        durationTurns: _requiredInt(json, type, 'durationTurns'),
        agreementId: _optionalString(json, type, 'agreementId'),
      ),
      'SendDiplomaticMessage' => SendDiplomaticMessageCommand(
        playerId: _requiredString(json, type, 'playerId'),
        targetPlayerId: _requiredString(json, type, 'targetPlayerId'),
        topic: _requiredEnum(
          json,
          type,
          'topic',
          DiplomaticMessageTopic.values,
        ),
        messageId: _optionalString(json, type, 'messageId'),
      ),
      'RespondDiplomaticMessage' => RespondDiplomaticMessageCommand(
        playerId: _requiredString(json, type, 'playerId'),
        messageId: _requiredString(json, type, 'messageId'),
        response: _requiredEnum(
          json,
          type,
          'response',
          DiplomaticMessageResponse.values,
        ),
      ),
      _ => throw ArgumentError('Unknown GameCommand type: "$type"'),
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

  static bool _requiredBool(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value is bool) return value;
    throw ArgumentError.value(value, '$type.$field', 'Expected a bool');
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
