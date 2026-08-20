import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'worker picker intents have value semantics outside the domain codec',
    () {
      const choose = ChooseWorkerImprovementIntent(
        'worker_1',
        FieldImprovementType.farm,
      );
      const sameChoose = ChooseWorkerImprovementIntent(
        'worker_1',
        FieldImprovementType.farm,
      );
      const otherChoose = ChooseWorkerImprovementIntent(
        'worker_1',
        FieldImprovementType.mine,
      );
      const confirm = ConfirmWorkerImprovementIntent('worker_1');
      const sameConfirm = ConfirmWorkerImprovementIntent('worker_1');
      const otherConfirm = ConfirmWorkerImprovementIntent('worker_2');

      expect(choose, sameChoose);
      expect(choose.hashCode, sameChoose.hashCode);
      expect(choose, isNot(otherChoose));
      expect(confirm, sameConfirm);
      expect(confirm.hashCode, sameConfirm.hashCode);
      expect(confirm, isNot(otherConfirm));
    },
  );

  test('city target intents have subtype-aware value semantics', () {
    const startWorked = StartCityWorkedHexSelectionCommand('city_1');
    const sameStartWorked = StartCityWorkedHexSelectionCommand('city_1');
    const otherCity = StartCityWorkedHexSelectionCommand('city_2');
    const cancelWorked = CancelCityWorkedHexSelectionCommand('city_1');
    const startExpansion = StartCityExpansionSelectionCommand('city_1');
    const cancelExpansion = CancelCityExpansionSelectionCommand('city_1');

    expect(startWorked, sameStartWorked);
    expect(startWorked.hashCode, sameStartWorked.hashCode);
    expect(startWorked, isNot(otherCity));
    expect(startWorked, isNot(cancelWorked));
    expect({
      startWorked,
      cancelWorked,
      startExpansion,
      cancelExpansion,
    }, hasLength(4));
  });

  test('field improvement selection intent has coordinate value semantics', () {
    const selection = SelectFieldImprovementCommand(2, 3);
    const sameSelection = SelectFieldImprovementCommand(2, 3);
    const otherColumn = SelectFieldImprovementCommand(1, 3);
    const otherRow = SelectFieldImprovementCommand(2, 4);

    expect(selection, sameSelection);
    expect(selection.hashCode, sameSelection.hashCode);
    expect(selection, isNot(otherColumn));
    expect(selection, isNot(otherRow));
  });

  group('DomainCommandCodec', () {
    DomainCommand roundTrip(DomainCommand command) {
      return DomainCommandCodec.fromJson(DomainCommandCodec.toJson(command));
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
        final json = DomainCommandCodec.toJson(fixture.command);
        expect(
          json['type'],
          fixture.type,
          reason: '${fixture.command.runtimeType} changed wire type',
        );
        encodedTypes.add(json['type'] as String);
      }

      expect(encodedTypes, _expectedCommandTypes);
    });

    test('rejects removed local lifecycle payloads', () {
      expect(
        () => DomainCommandCodec.fromJson({
          'type': 'SetActivePlayer',
          'playerId': 'p1',
          'canAct': true,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects presentation intent payloads', () {
      expect(
        () =>
            DomainCommandCodec.fromJson({'type': 'SelectUnit', 'unitId': 'u1'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects trusted system command payloads', () {
      expect(
        () => DomainCommandCodec.fromJson({
          'type': 'SetActivePlayer',
          'playerId': 'p1',
          'canAct': true,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('encodes AttackHex payload used by the server reducer', () {
      expect(DomainCommandCodec.toJson(const AttackHexCommand('u', 1, 2)), {
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

      expect(DomainCommandCodec.toJson(command), {
        'type': 'AttackHex',
        'attackerUnitId': 'u',
        'defenderCol': 1,
        'defenderRow': 2,
        'cityConquestAction': 'destroy',
      });
      expect(
        DomainCommandCodec.fromJson(DomainCommandCodec.toJson(command)),
        command,
      );
    });

    test('round-trips a self-contained worker confirmation', () {
      const command = ConfirmWorkerImprovementCommand(
        'worker_1',
        improvementType: FieldImprovementType.mine,
      );

      expect(DomainCommandCodec.toJson(command), {
        'type': 'ConfirmWorkerImprovement',
        'unitId': 'worker_1',
        'improvementType': 'mine',
      });
      expect(roundTrip(command), command);
    });

    test('decodes SubmitTurn with transport-only fields ignored', () {
      expect(
        DomainCommandCodec.fromJson({
          'type': 'SubmitTurn',
          'playerId': 'player_1',
          'timedOut': true,
        }),
        const SubmitTurnCommand('player_1'),
      );
    });

    test('decodes legacy SleepUnit as SkipUnitTurn', () {
      expect(
        DomainCommandCodec.fromJson({'type': 'SleepUnit', 'unitId': 'scout_1'}),
        const SkipUnitTurnCommand('scout_1'),
      );
    });

    test('rejects unknown command type', () {
      expect(
        () => DomainCommandCodec.fromJson({'type': 'UnknownCommand'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects missing AttackHex payload', () {
      expect(
        () => DomainCommandCodec.fromJson({
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
        () => DomainCommandCodec.fromJson({
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
  });
}

final _commandFixtures = <({DomainCommand command, String type})>[
  ..._constantCommandFixtures,
  (
    command: FoundCityCommand('settler_1', controlledHexes: const []),
    type: 'FoundCity',
  ),
];

const _constantCommandFixtures = <({DomainCommand command, String type})>[
  (command: MoveUnitCommand('scout_1', 2, 3), type: 'MoveUnit'),
  (command: CancelUnitActionCommand('scout_1'), type: 'CancelUnitAction'),
  (command: SkipUnitTurnCommand('scout_1'), type: 'SkipUnitTurn'),
  (command: FortifyUnitCommand('scout_1'), type: 'FortifyUnit'),
  (command: AutoExploreUnitCommand('scout_1'), type: 'AutoExploreUnit'),
  (command: AutomateWorkerCommand('worker_1'), type: 'AutomateWorker'),
  (command: BuildRoadCommand('worker_1'), type: 'BuildRoad'),
  (
    command: AssignMerchantTradeRouteCommand('merchant_1', 'city_2'),
    type: 'AssignMerchantTradeRoute',
  ),
  (
    command: MoveMerchantToCityCommand('merchant_1', 'city_2'),
    type: 'MoveMerchantToCity',
  ),
  (
    command: StartArtifactExcavationCommand('scout_1'),
    type: 'StartArtifactExcavation',
  ),
  (
    command: StoreArtifactInCityCommand('scout_1', cityId: 'city_1'),
    type: 'StoreArtifactInCity',
  ),
  (
    command: TradeArtifactCommand(
      playerId: 'player_1',
      targetPlayerId: 'player_2',
      offeredArtifactId: 'artifact_1',
    ),
    type: 'TradeArtifact',
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
    command: StartWonderCommand('city_1', WonderType.greatLibrary),
    type: 'StartWonder',
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
      goldPayment: 6,
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
    command: SendGoldGiftCommand(
      playerId: 'player_1',
      targetPlayerId: 'player_2',
      amount: 12,
    ),
    type: 'SendGoldGift',
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
  (
    command: SelectCityExpansionHexCommand('city_1', 1, 2),
    type: 'SelectCityExpansionHex',
  ),
  (command: ToggleWorkedHexCommand('city_1', 1, 2), type: 'ToggleWorkedHex'),
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
  (command: CancelWorkerJobCommand('worker_1'), type: 'CancelWorkerJob'),
  (command: AssignWorkerToHexCommand('worker_1'), type: 'AssignWorkerToHex'),
  (
    command: CancelWorkerAssignmentCommand('worker_1'),
    type: 'CancelWorkerAssignment',
  ),
  (command: AttackHexCommand('warrior_1', 4, 5), type: 'AttackHex'),
];

const _expectedCommandTypes = {
  'MoveUnit',
  'CancelUnitAction',
  'SkipUnitTurn',
  'FortifyUnit',
  'AutoExploreUnit',
  'AutomateWorker',
  'BuildRoad',
  'AssignMerchantTradeRoute',
  'MoveMerchantToCity',
  'StartArtifactExcavation',
  'StoreArtifactInCity',
  'TradeArtifact',
  'FoundCity',
  'StartBuilding',
  'StartUnitProduction',
  'StartCityProject',
  'StartWonder',
  'SetCitySpecialization',
  'RushProduction',
  'SelectTechnology',
  'DetachTroop',
  'EndTurn',
  'SubmitTurn',
  'SendDiplomaticProposal',
  'RespondDiplomaticProposal',
  'SendDiplomaticMessage',
  'RespondDiplomaticMessage',
  'DeclareWar',
  'SendGoldGift',
  'OpenResourceTrade',
  'OpenResourceExchange',
  'SelectCityExpansionHex',
  'ToggleWorkedHex',
  'SelectWorkerImprovement',
  'ConfirmWorkerImprovement',
  'CancelWorkerJob',
  'AssignWorkerToHex',
  'CancelWorkerAssignment',
  'AttackHex',
};
