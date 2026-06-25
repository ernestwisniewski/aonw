import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameCommandSerializer', () {
    GameCommand roundTrip(GameCommand command) {
      return GameCommandSerializer.fromJson(
        GameCommandSerializer.toJson(command),
      );
    }

    test('round-trips every command type used by transport', () {
      for (final fixture in _commandFixtures) {
        expect(
          roundTrip(fixture.command),
          fixture.command,
          reason: '${fixture.command.runtimeType} should round-trip',
        );
      }
    });

    test('encodes stable unique command type discriminators', () {
      final encodedTypes = <String>{};

      for (final fixture in _commandFixtures) {
        final json = GameCommandSerializer.toJson(fixture.command);
        expect(
          json['type'],
          fixture.type,
          reason: '${fixture.command.runtimeType} changed wire type',
        );
        encodedTypes.add(json['type'] as String);
      }

      expect(encodedTypes, _expectedCommandTypes);
    });

    test('encodes AttackHex payload used by the server reducer', () {
      expect(GameCommandSerializer.toJson(const AttackHexCommand('u', 1, 2)), {
        'type': 'AttackHex',
        'attackerUnitId': 'u',
        'defenderCol': 1,
        'defenderRow': 2,
      });
    });

    test('encodes AttackHex city conquest action when not default', () {
      const command = AttackHexCommand(
        'u',
        1,
        2,
        cityConquestAction: CityConquestAction.destroy,
      );

      expect(GameCommandSerializer.toJson(command), {
        'type': 'AttackHex',
        'attackerUnitId': 'u',
        'defenderCol': 1,
        'defenderRow': 2,
        'cityConquestAction': 'destroy',
      });
      expect(
        GameCommandSerializer.fromJson(GameCommandSerializer.toJson(command)),
        command,
      );
    });

    test('decodes SubmitTurn with transport-only fields ignored', () {
      expect(
        GameCommandSerializer.fromJson({
          'type': 'SubmitTurn',
          'playerId': 'player_1',
          'timedOut': true,
        }),
        const SubmitTurnCommand('player_1'),
      );
    });

    test('omits nullable ResetUnitMovement playerId when absent', () {
      expect(GameCommandSerializer.toJson(const ResetUnitMovementCommand()), {
        'type': 'ResetUnitMovement',
      });
    });

    test('round-trips FocusNextPendingAction preferred objective advice', () {
      const command = FocusNextPendingActionCommand(
        'player_1',
        preferredObjectiveAdvice: GameObjectiveAdvice.improveField,
      );

      expect(
        GameCommandSerializer.fromJson(GameCommandSerializer.toJson(command)),
        command,
      );
      expect(
        GameCommandSerializer.toJson(command)['preferredObjectiveAdvice'],
        'improveField',
      );
    });

    test('decodes FoundCity without controlledHexes as an empty list', () {
      expect(
        GameCommandSerializer.fromJson({
          'type': 'FoundCity',
          'founderId': 'settler_1',
        }),
        const FoundCityCommand('settler_1'),
      );
    });

    test('decodes legacy SleepUnit as SkipUnitTurn', () {
      expect(
        GameCommandSerializer.fromJson({
          'type': 'SleepUnit',
          'unitId': 'scout_1',
        }),
        const SkipUnitTurnCommand('scout_1'),
      );
    });

    test('rejects unknown command type', () {
      expect(
        () => GameCommandSerializer.fromJson({'type': 'UnknownCommand'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects missing AttackHex payload', () {
      expect(
        () => GameCommandSerializer.fromJson({
          'type': 'AttackHex',
          'attackerUnitId': 'warrior_1',
          'defenderCol': 4,
        }),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'AttackHex.defenderRow',
          ),
        ),
      );
    });

    test('rejects invalid enum payload', () {
      expect(
        () => GameCommandSerializer.fromJson({
          'type': 'StartBuilding',
          'cityId': 'city_1',
          'buildingType': 'spaceElevator',
        }),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'StartBuilding.buildingType',
          ),
        ),
      );
    });

    test('rejects invalid optional playerId payload', () {
      expect(
        () => GameCommandSerializer.fromJson({
          'type': 'ResetUnitMovement',
          'playerId': '',
        }),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'ResetUnitMovement.playerId',
          ),
        ),
      );
    });
  });
}

const _commandFixtures = <({GameCommand command, String type})>[
  (command: TileTappedCommand(0, 1), type: 'TileTapped'),
  (command: CityTappedCommand('city_1'), type: 'CityTapped'),
  (command: MoveUnitCommand('scout_1', 2, 3), type: 'MoveUnit'),
  (command: CancelUnitActionCommand('scout_1'), type: 'CancelUnitAction'),
  (command: SkipUnitTurnCommand('scout_1'), type: 'SkipUnitTurn'),
  (command: FortifyUnitCommand('scout_1'), type: 'FortifyUnit'),
  (
    command: StartMerchantTradeRouteSelectionCommand('merchant_1'),
    type: 'StartMerchantTradeRouteSelection',
  ),
  (
    command: CancelMerchantTradeRouteSelectionCommand('merchant_1'),
    type: 'CancelMerchantTradeRouteSelection',
  ),
  (
    command: AssignMerchantTradeRouteCommand('merchant_1', 'city_2'),
    type: 'AssignMerchantTradeRoute',
  ),
  (
    command: StartMerchantMoveToCitySelectionCommand('merchant_1'),
    type: 'StartMerchantMoveToCitySelection',
  ),
  (
    command: CancelMerchantMoveToCitySelectionCommand('merchant_1'),
    type: 'CancelMerchantMoveToCitySelection',
  ),
  (
    command: MoveMerchantToCityCommand('merchant_1', 'city_2'),
    type: 'MoveMerchantToCity',
  ),
  (
    command: FoundCityCommand(
      'settler_1',
      controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
    ),
    type: 'FoundCity',
  ),
  (
    command: StartBuildingCommand('city_1', CityBuildingType.granary),
    type: 'StartBuilding',
  ),
  (
    command: StartUnitProductionCommand('city_1', GameUnitType.archer),
    type: 'StartUnitProduction',
  ),
  (
    command: StartCityProjectCommand('city_1', CityProjectType.research),
    type: 'StartCityProject',
  ),
  (
    command: SetCitySpecializationCommand(
      'city_1',
      CitySpecializationType.science,
    ),
    type: 'SetCitySpecialization',
  ),
  (command: RushProductionCommand('city_1'), type: 'RushProduction'),
  (
    command: SelectTechnologyCommand('player_1', TechnologyId.mining),
    type: 'SelectTechnology',
  ),
  (
    command: CancelResearchSelectionCommand('player_1'),
    type: 'CancelResearchSelection',
  ),
  (
    command: DetachTroopCommand('army_1', TroopType.archer),
    type: 'DetachTroop',
  ),
  (command: EndTurnCommand('player_1'), type: 'EndTurn'),
  (command: SubmitTurnCommand('player_1'), type: 'SubmitTurn'),
  (
    command: SendDiplomaticProposalCommand(
      playerId: 'player_1',
      targetPlayerId: 'player_2',
      kind: DiplomaticProposalKind.friendship,
      proposalId: 'proposal_1',
    ),
    type: 'SendDiplomaticProposal',
  ),
  (
    command: RespondDiplomaticProposalCommand(
      playerId: 'player_2',
      proposalId: 'proposal_1',
      accepted: true,
    ),
    type: 'RespondDiplomaticProposal',
  ),
  (
    command: SendDiplomaticMessageCommand(
      playerId: 'player_1',
      targetPlayerId: 'player_2',
      topic: DiplomaticMessageTopic.troopsNearCities,
      messageId: 'message_1',
    ),
    type: 'SendDiplomaticMessage',
  ),
  (
    command: RespondDiplomaticMessageCommand(
      playerId: 'player_2',
      messageId: 'message_1',
      response: DiplomaticMessageResponse.conciliatory,
    ),
    type: 'RespondDiplomaticMessage',
  ),
  (
    command: DeclareWarCommand(
      playerId: 'player_1',
      targetPlayerId: 'player_2',
    ),
    type: 'DeclareWar',
  ),
  (
    command: OpenResourceTradeCommand(
      playerId: 'player_1',
      targetPlayerId: 'player_2',
      resource: ResourceType.horses,
      goldPerTurn: 3,
      durationTurns: 8,
      agreementId: 'trade_1',
    ),
    type: 'OpenResourceTrade',
  ),
  (
    command: OpenResourceExchangeCommand(
      playerId: 'player_1',
      targetPlayerId: 'player_2',
      offeredResource: ResourceType.iron,
      requestedResource: ResourceType.horses,
      durationTurns: 8,
      agreementId: 'exchange_1',
    ),
    type: 'OpenResourceExchange',
  ),
  (command: ResetUnitMovementCommand(), type: 'ResetUnitMovement'),
  (
    command: ResetUnitMovementCommand(playerId: 'player_1'),
    type: 'ResetUnitMovement',
  ),
  (
    command: SetActivePlayerCommand('player_1', canAct: true),
    type: 'SetActivePlayer',
  ),
  (command: ToggleMoveTargetingCommand(), type: 'ToggleMoveTargeting'),
  (command: StartCityFoundingCommand(), type: 'StartCityFounding'),
  (command: CancelCityFoundingCommand(), type: 'CancelCityFounding'),
  (
    command: StartCityWorkedHexSelectionCommand('city_1'),
    type: 'StartCityWorkedHexSelection',
  ),
  (
    command: CancelCityWorkedHexSelectionCommand('city_1'),
    type: 'CancelCityWorkedHexSelection',
  ),
  (
    command: StartCityExpansionSelectionCommand('city_1'),
    type: 'StartCityExpansionSelection',
  ),
  (
    command: CancelCityExpansionSelectionCommand('city_1'),
    type: 'CancelCityExpansionSelection',
  ),
  (
    command: SelectCityExpansionHexCommand('city_1', 1, 2),
    type: 'SelectCityExpansionHex',
  ),
  (command: ToggleWorkedHexCommand('city_1', 1, 2), type: 'ToggleWorkedHex'),
  (
    command: StartWorkerActionSelectionCommand('worker_1'),
    type: 'StartWorkerActionSelection',
  ),
  (
    command: SelectWorkerImprovementCommand(
      'worker_1',
      FieldImprovementType.mine,
    ),
    type: 'SelectWorkerImprovement',
  ),
  (
    command: ConfirmWorkerImprovementCommand('worker_1'),
    type: 'ConfirmWorkerImprovement',
  ),
  (
    command: CancelWorkerActionSelectionCommand('worker_1'),
    type: 'CancelWorkerActionSelection',
  ),
  (command: CancelWorkerJobCommand('worker_1'), type: 'CancelWorkerJob'),
  (command: AssignWorkerToHexCommand('worker_1'), type: 'AssignWorkerToHex'),
  (
    command: CancelWorkerAssignmentCommand('worker_1'),
    type: 'CancelWorkerAssignment',
  ),
  (
    command: StartAttackTargetingCommand('warrior_1'),
    type: 'StartAttackTargeting',
  ),
  (
    command: CancelAttackTargetingCommand('warrior_1'),
    type: 'CancelAttackTargeting',
  ),
  (command: AttackHexCommand('warrior_1', 4, 5), type: 'AttackHex'),
  (
    command: StartCommanderMergeSelectionCommand('commander_1'),
    type: 'StartCommanderMergeSelection',
  ),
  (
    command: CancelCommanderMergeSelectionCommand('commander_1'),
    type: 'CancelCommanderMergeSelection',
  ),
  (command: SelectTileCommand(5, 6), type: 'SelectTile'),
  (command: SelectUnitCommand('warrior_1'), type: 'SelectUnit'),
  (command: SelectCityCommand('city_1'), type: 'SelectCity'),
  (
    command: FocusNextPendingActionCommand('player_1'),
    type: 'FocusNextPendingAction',
  ),
  (
    command: FocusTurnStartActionCommand('player_1'),
    type: 'FocusTurnStartAction',
  ),
];

const _expectedCommandTypes = {
  'TileTapped',
  'CityTapped',
  'MoveUnit',
  'CancelUnitAction',
  'SkipUnitTurn',
  'FortifyUnit',
  'StartMerchantTradeRouteSelection',
  'CancelMerchantTradeRouteSelection',
  'AssignMerchantTradeRoute',
  'StartMerchantMoveToCitySelection',
  'CancelMerchantMoveToCitySelection',
  'MoveMerchantToCity',
  'FoundCity',
  'StartBuilding',
  'StartUnitProduction',
  'StartCityProject',
  'SetCitySpecialization',
  'RushProduction',
  'SelectTechnology',
  'CancelResearchSelection',
  'DetachTroop',
  'EndTurn',
  'SubmitTurn',
  'SendDiplomaticProposal',
  'RespondDiplomaticProposal',
  'SendDiplomaticMessage',
  'RespondDiplomaticMessage',
  'DeclareWar',
  'OpenResourceTrade',
  'OpenResourceExchange',
  'ResetUnitMovement',
  'SetActivePlayer',
  'ToggleMoveTargeting',
  'StartCityFounding',
  'CancelCityFounding',
  'StartCityWorkedHexSelection',
  'CancelCityWorkedHexSelection',
  'StartCityExpansionSelection',
  'CancelCityExpansionSelection',
  'SelectCityExpansionHex',
  'ToggleWorkedHex',
  'StartWorkerActionSelection',
  'SelectWorkerImprovement',
  'ConfirmWorkerImprovement',
  'CancelWorkerActionSelection',
  'CancelWorkerJob',
  'AssignWorkerToHex',
  'CancelWorkerAssignment',
  'StartAttackTargeting',
  'CancelAttackTargeting',
  'AttackHex',
  'StartCommanderMergeSelection',
  'CancelCommanderMergeSelection',
  'SelectTile',
  'SelectUnit',
  'SelectCity',
  'FocusNextPendingAction',
  'FocusTurnStartAction',
};
