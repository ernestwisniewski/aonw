import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCommand', () {
    group('construction and field access', () {
      test('TileTappedCommand stores col and row', () {
        const cmd = TileTappedCommand(3, 5);
        expect(cmd.col, 3);
        expect(cmd.row, 5);
      });

      test('CityTappedCommand stores cityId', () {
        const cmd = CityTappedCommand('city-1');
        expect(cmd.cityId, 'city-1');
      });

      test('MoveUnitCommand stores unitId, targetCol, targetRow', () {
        const cmd = MoveUnitCommand('unit-42', 7, 9);
        expect(cmd.unitId, 'unit-42');
        expect(cmd.targetCol, 7);
        expect(cmd.targetRow, 9);
      });

      test('CancelUnitActionCommand stores unitId', () {
        const cmd = CancelUnitActionCommand('unit-7');
        expect(cmd.unitId, 'unit-7');
      });

      test('SkipUnitTurnCommand stores unitId', () {
        const cmd = SkipUnitTurnCommand('unit-7');
        expect(cmd.unitId, 'unit-7');
      });

      test('FortifyUnitCommand stores unitId', () {
        const cmd = FortifyUnitCommand('unit-7');
        expect(cmd.unitId, 'unit-7');
      });

      test('AutoExploreUnitCommand stores unitId', () {
        const cmd = AutoExploreUnitCommand('unit-7');
        expect(cmd.unitId, 'unit-7');
      });

      test('FoundCityCommand stores founderId', () {
        const cmd = FoundCityCommand(
          'settler-1',
          controlledHexes: [CityHex(col: 1, row: 0)],
        );
        expect(cmd.founderId, 'settler-1');
        expect(cmd.controlledHexes, [const CityHex(col: 1, row: 0)]);
      });

      test('StartBuildingCommand stores cityId and buildingType', () {
        const cmd = StartBuildingCommand('city-2', CityBuildingType.granary);
        expect(cmd.cityId, 'city-2');
        expect(cmd.buildingType, CityBuildingType.granary);
      });

      test('StartUnitProductionCommand stores cityId and unitType', () {
        const cmd = StartUnitProductionCommand('city-2', GameUnitType.warrior);
        expect(cmd.cityId, 'city-2');
        expect(cmd.unitType, GameUnitType.warrior);
      });

      test('StartCityProjectCommand stores cityId and projectType', () {
        const cmd = StartCityProjectCommand('city-2', CityProjectType.wealth);
        expect(cmd.cityId, 'city-2');
        expect(cmd.projectType, CityProjectType.wealth);
      });

      test('SetCitySpecializationCommand stores cityId and specialization', () {
        const cmd = SetCitySpecializationCommand(
          'city-2',
          CitySpecializationType.industry,
        );
        expect(cmd.cityId, 'city-2');
        expect(cmd.specialization, CitySpecializationType.industry);
      });

      test('RushProductionCommand stores cityId', () {
        const cmd = RushProductionCommand('city-2');
        expect(cmd.cityId, 'city-2');
      });

      test('SelectTechnologyCommand stores playerId and technologyId', () {
        const cmd = SelectTechnologyCommand('player-1', TechnologyId.mining);
        expect(cmd.playerId, 'player-1');
        expect(cmd.technologyId, TechnologyId.mining);
      });

      test('CancelResearchSelectionCommand stores playerId', () {
        const cmd = CancelResearchSelectionCommand('player-1');
        expect(cmd.playerId, 'player-1');
      });

      test('DetachTroopCommand stores unitId and troopType', () {
        const cmd = DetachTroopCommand('unit-7', TroopType.warrior);
        expect(cmd.unitId, 'unit-7');
        expect(cmd.troopType, TroopType.warrior);
      });

      test('EndTurnCommand stores playerId', () {
        const cmd = EndTurnCommand('player-1');
        expect(cmd.playerId, 'player-1');
      });

      test('SubmitTurnCommand stores playerId', () {
        const cmd = SubmitTurnCommand('player-1');
        expect(cmd.playerId, 'player-1');
      });

      test('ResetUnitMovementCommand stores optional playerId', () {
        const allPlayers = ResetUnitMovementCommand();
        const singlePlayer = ResetUnitMovementCommand(playerId: 'player-1');
        expect(allPlayers.playerId, isNull);
        expect(singlePlayer.playerId, 'player-1');
      });

      test('SetActivePlayerCommand stores playerId and canAct', () {
        const cmd = SetActivePlayerCommand('player-2', canAct: true);
        expect(cmd.playerId, 'player-2');
        expect(cmd.canAct, isTrue);

        const cmd2 = SetActivePlayerCommand('player-3', canAct: false);
        expect(cmd2.canAct, isFalse);
      });

      test('ToggleMoveTargetingCommand can be constructed', () {
        const cmd = ToggleMoveTargetingCommand();
        expect(cmd, isA<GameCommand>());
      });

      test('StartCityFoundingCommand can be constructed', () {
        const cmd = StartCityFoundingCommand();
        expect(cmd, isA<GameCommand>());
      });

      test('CancelCityFoundingCommand can be constructed', () {
        const cmd = CancelCityFoundingCommand();
        expect(cmd, isA<GameCommand>());
      });

      test('StartCityWorkedHexSelectionCommand stores cityId', () {
        const cmd = StartCityWorkedHexSelectionCommand('city-7');
        expect(cmd.cityId, 'city-7');
      });

      test('CancelCityWorkedHexSelectionCommand stores cityId', () {
        const cmd = CancelCityWorkedHexSelectionCommand('city-7');
        expect(cmd.cityId, 'city-7');
      });

      test('StartCityExpansionSelectionCommand stores cityId', () {
        const cmd = StartCityExpansionSelectionCommand('city-7');
        expect(cmd.cityId, 'city-7');
      });

      test('CancelCityExpansionSelectionCommand stores cityId', () {
        const cmd = CancelCityExpansionSelectionCommand('city-7');
        expect(cmd.cityId, 'city-7');
      });

      test('SelectCityExpansionHexCommand stores cityId and coordinates', () {
        const cmd = SelectCityExpansionHexCommand('city-7', 1, 2);
        expect(cmd.cityId, 'city-7');
        expect(cmd.col, 1);
        expect(cmd.row, 2);
      });

      test('ToggleWorkedHexCommand stores cityId and coordinates', () {
        const cmd = ToggleWorkedHexCommand('city-7', 1, 2);
        expect(cmd.cityId, 'city-7');
        expect(cmd.col, 1);
        expect(cmd.row, 2);
      });

      test('StartWorkerActionSelectionCommand stores unitId', () {
        const cmd = StartWorkerActionSelectionCommand('unit-7');
        expect(cmd.unitId, 'unit-7');
      });

      test('SelectWorkerImprovementCommand stores unitId and improvement', () {
        const cmd = SelectWorkerImprovementCommand(
          'unit-7',
          FieldImprovementType.farm,
        );
        expect(cmd.unitId, 'unit-7');
        expect(cmd.improvementType, FieldImprovementType.farm);
      });

      test('ConfirmWorkerImprovementCommand stores unitId', () {
        const cmd = ConfirmWorkerImprovementCommand('unit-7');
        expect(cmd.unitId, 'unit-7');
      });

      test('CancelWorkerActionSelectionCommand stores unitId', () {
        const cmd = CancelWorkerActionSelectionCommand('unit-7');
        expect(cmd.unitId, 'unit-7');
      });

      test('CancelWorkerJobCommand stores unitId', () {
        const cmd = CancelWorkerJobCommand('unit-7');
        expect(cmd.unitId, 'unit-7');
      });

      test('AssignWorkerToHexCommand stores unitId', () {
        const cmd = AssignWorkerToHexCommand('unit-7');
        expect(cmd.unitId, 'unit-7');
      });

      test('CancelWorkerAssignmentCommand stores unitId', () {
        const cmd = CancelWorkerAssignmentCommand('unit-7');
        expect(cmd.unitId, 'unit-7');
      });

      test('StartAttackTargetingCommand stores attackerUnitId', () {
        const cmd = StartAttackTargetingCommand('unit-7');
        expect(cmd.attackerUnitId, 'unit-7');
      });

      test('CancelAttackTargetingCommand stores attackerUnitId', () {
        const cmd = CancelAttackTargetingCommand('unit-7');
        expect(cmd.attackerUnitId, 'unit-7');
      });

      test('AttackHexCommand stores attackerUnitId and defender hex', () {
        const cmd = AttackHexCommand('unit-7', 3, 4);
        expect(cmd.attackerUnitId, 'unit-7');
        expect(cmd.defenderCol, 3);
        expect(cmd.defenderRow, 4);
      });

      test('StartCommanderMergeSelectionCommand stores commanderUnitId', () {
        const cmd = StartCommanderMergeSelectionCommand('commander-7');
        expect(cmd.commanderUnitId, 'commander-7');
      });

      test('CancelCommanderMergeSelectionCommand stores commanderUnitId', () {
        const cmd = CancelCommanderMergeSelectionCommand('commander-7');
        expect(cmd.commanderUnitId, 'commander-7');
      });

      test('SelectTileCommand stores col and row', () {
        const cmd = SelectTileCommand(1, 2);
        expect(cmd.col, 1);
        expect(cmd.row, 2);
      });

      test('SelectUnitCommand stores unitId', () {
        const cmd = SelectUnitCommand('unit-99');
        expect(cmd.unitId, 'unit-99');
      });

      test('SelectCityCommand stores cityId', () {
        const cmd = SelectCityCommand('city-5');
        expect(cmd.cityId, 'city-5');
      });

      test('FocusNextPendingActionCommand stores playerId', () {
        const cmd = FocusNextPendingActionCommand(
          'player-1',
          preferredObjectiveAdvice: GameObjectiveAdvice.improveField,
        );
        expect(cmd.playerId, 'player-1');
        expect(cmd.preferredObjectiveAdvice, GameObjectiveAdvice.improveField);
      });

      test('FocusTurnStartActionCommand stores playerId', () {
        const cmd = FocusTurnStartActionCommand('player-1');
        expect(cmd.playerId, 'player-1');
      });
    });
    group('exhaustiveness — all subtypes are GameCommand', () {
      // Collect one instance of each subtype.
      final List<GameCommand> allSubtypes = [
        const TileTappedCommand(0, 0),
        const CityTappedCommand('c'),
        const MoveUnitCommand('u', 0, 0),
        const CancelUnitActionCommand('u'),
        const SkipUnitTurnCommand('u'),
        const FortifyUnitCommand('u'),
        const AutoExploreUnitCommand('u'),
        const StartMerchantTradeRouteSelectionCommand('u'),
        const CancelMerchantTradeRouteSelectionCommand('u'),
        const AssignMerchantTradeRouteCommand('u', 'c'),
        const StartMerchantMoveToCitySelectionCommand('u'),
        const CancelMerchantMoveToCitySelectionCommand('u'),
        const MoveMerchantToCityCommand('u', 'c'),
        const FoundCityCommand('f'),
        const StartBuildingCommand('c', CityBuildingType.granary),
        const StartUnitProductionCommand('c', GameUnitType.warrior),
        const StartCityProjectCommand('c', CityProjectType.wealth),
        const SetCitySpecializationCommand(
          'c',
          CitySpecializationType.industry,
        ),
        const RushProductionCommand('c'),
        const SelectTechnologyCommand('p', TechnologyId.agriculture),
        const CancelResearchSelectionCommand('p'),
        const DetachTroopCommand('u', TroopType.warrior),
        const EndTurnCommand('p'),
        const SubmitTurnCommand('p'),
        const SendDiplomaticProposalCommand(
          playerId: 'p',
          targetPlayerId: 'q',
          kind: DiplomaticProposalKind.friendship,
        ),
        const RespondDiplomaticProposalCommand(
          playerId: 'p',
          proposalId: 'proposal-1',
          accepted: true,
        ),
        const SendDiplomaticMessageCommand(
          playerId: 'p',
          targetPlayerId: 'q',
          topic: DiplomaticMessageTopic.troopsNearCities,
        ),
        const RespondDiplomaticMessageCommand(
          playerId: 'p',
          messageId: 'message-1',
          response: DiplomaticMessageResponse.neutral,
        ),
        const DeclareWarCommand(playerId: 'p', targetPlayerId: 'q'),
        const SendGoldGiftCommand(
          playerId: 'p',
          targetPlayerId: 'q',
          amount: 5,
        ),
        const OpenResourceTradeCommand(
          playerId: 'p',
          targetPlayerId: 'q',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          durationTurns: 8,
        ),
        const OpenResourceExchangeCommand(
          playerId: 'p',
          targetPlayerId: 'q',
          offeredResource: ResourceType.iron,
          requestedResource: ResourceType.horses,
          durationTurns: 8,
        ),
        const ResetUnitMovementCommand(),
        const SetActivePlayerCommand('p', canAct: true),
        const ToggleMoveTargetingCommand(),
        const StartCityFoundingCommand(),
        const CancelCityFoundingCommand(),
        const StartCityWorkedHexSelectionCommand('c'),
        const CancelCityWorkedHexSelectionCommand('c'),
        const StartCityExpansionSelectionCommand('c'),
        const CancelCityExpansionSelectionCommand('c'),
        const SelectCityExpansionHexCommand('c', 1, 2),
        const ToggleWorkedHexCommand('c', 1, 2),
        const StartWorkerActionSelectionCommand('u'),
        const SelectWorkerImprovementCommand('u', FieldImprovementType.farm),
        const ConfirmWorkerImprovementCommand('u'),
        const CancelWorkerActionSelectionCommand('u'),
        const CancelWorkerJobCommand('u'),
        const AssignWorkerToHexCommand('u'),
        const CancelWorkerAssignmentCommand('u'),
        const StartArtifactExcavationCommand('u'),
        const StoreArtifactInCityCommand('u'),
        const TradeArtifactCommand(
          playerId: 'p',
          targetPlayerId: 'q',
          offeredArtifactId: 'artifact.heroSword',
        ),
        const StartAttackTargetingCommand('u'),
        const CancelAttackTargetingCommand('u'),
        const AttackHexCommand('u', 1, 2),
        const StartCommanderMergeSelectionCommand('commander'),
        const CancelCommanderMergeSelectionCommand('commander'),
        const SelectTileCommand(0, 0),
        const SelectUnitCommand('u'),
        const SelectCityCommand('c'),
        const FocusNextPendingActionCommand('p'),
        const FocusTurnStartActionCommand('p'),
      ];

      test('there are exactly 63 subtype instances', () {
        expect(allSubtypes, hasLength(63));
      });

      test('every subtype is a GameCommand', () {
        for (final cmd in allSubtypes) {
          expect(
            cmd,
            isA<GameCommand>(),
            reason: '${cmd.runtimeType} should be a GameCommand',
          );
        }
      });

      test('switch over sealed class is exhaustive (compile-time check)', () {
        // If a new subtype is added without updating this switch, the Dart
        // analyzer will flag a non-exhaustive switch error.
        const GameCommand cmd = TileTappedCommand(0, 0);
        final String label = switch (cmd) {
          TileTappedCommand() => 'TileTapped',
          CityTappedCommand() => 'CityTapped',
          MoveUnitCommand() => 'MoveUnit',
          CancelUnitActionCommand() => 'CancelUnitAction',
          SkipUnitTurnCommand() => 'SkipUnitTurn',
          FortifyUnitCommand() => 'FortifyUnit',
          AutoExploreUnitCommand() => 'AutoExploreUnit',
          StartMerchantTradeRouteSelectionCommand() =>
            'StartMerchantTradeRouteSelection',
          CancelMerchantTradeRouteSelectionCommand() =>
            'CancelMerchantTradeRouteSelection',
          AssignMerchantTradeRouteCommand() => 'AssignMerchantTradeRoute',
          StartMerchantMoveToCitySelectionCommand() =>
            'StartMerchantMoveToCitySelection',
          CancelMerchantMoveToCitySelectionCommand() =>
            'CancelMerchantMoveToCitySelection',
          MoveMerchantToCityCommand() => 'MoveMerchantToCity',
          FoundCityCommand() => 'FoundCity',
          StartBuildingCommand() => 'StartBuilding',
          StartUnitProductionCommand() => 'StartUnitProduction',
          StartCityProjectCommand() => 'StartCityProject',
          SetCitySpecializationCommand() => 'SetCitySpecialization',
          RushProductionCommand() => 'RushProduction',
          SelectTechnologyCommand() => 'SelectTechnology',
          CancelResearchSelectionCommand() => 'CancelResearchSelection',
          DetachTroopCommand() => 'DetachTroop',
          EndTurnCommand() => 'EndTurn',
          SubmitTurnCommand() => 'SubmitTurn',
          SendDiplomaticProposalCommand() => 'SendDiplomaticProposal',
          RespondDiplomaticProposalCommand() => 'RespondDiplomaticProposal',
          SendDiplomaticMessageCommand() => 'SendDiplomaticMessage',
          RespondDiplomaticMessageCommand() => 'RespondDiplomaticMessage',
          DeclareWarCommand() => 'DeclareWar',
          SendGoldGiftCommand() => 'SendGoldGift',
          OpenResourceTradeCommand() => 'OpenResourceTrade',
          OpenResourceExchangeCommand() => 'OpenResourceExchange',
          ResetUnitMovementCommand() => 'ResetUnitMovement',
          SetActivePlayerCommand() => 'SetActivePlayer',
          ToggleMoveTargetingCommand() => 'ToggleMoveTargeting',
          StartCityFoundingCommand() => 'StartCityFounding',
          CancelCityFoundingCommand() => 'CancelCityFounding',
          StartCityWorkedHexSelectionCommand() => 'StartCityWorkedHexSelection',
          CancelCityWorkedHexSelectionCommand() =>
            'CancelCityWorkedHexSelection',
          StartCityExpansionSelectionCommand() => 'StartCityExpansionSelection',
          CancelCityExpansionSelectionCommand() =>
            'CancelCityExpansionSelection',
          SelectCityExpansionHexCommand() => 'SelectCityExpansionHex',
          ToggleWorkedHexCommand() => 'ToggleWorkedHex',
          StartWorkerActionSelectionCommand() => 'StartWorkerActionSelection',
          SelectWorkerImprovementCommand() => 'SelectWorkerImprovement',
          ConfirmWorkerImprovementCommand() => 'ConfirmWorkerImprovement',
          CancelWorkerActionSelectionCommand() => 'CancelWorkerActionSelection',
          CancelWorkerJobCommand() => 'CancelWorkerJob',
          AssignWorkerToHexCommand() => 'AssignWorkerToHex',
          CancelWorkerAssignmentCommand() => 'CancelWorkerAssignment',
          StartArtifactExcavationCommand() => 'StartArtifactExcavation',
          StoreArtifactInCityCommand() => 'StoreArtifactInCity',
          TradeArtifactCommand() => 'TradeArtifact',
          StartAttackTargetingCommand() => 'StartAttackTargeting',
          CancelAttackTargetingCommand() => 'CancelAttackTargeting',
          AttackHexCommand() => 'AttackHex',
          StartCommanderMergeSelectionCommand() =>
            'StartCommanderMergeSelection',
          CancelCommanderMergeSelectionCommand() =>
            'CancelCommanderMergeSelection',
          SelectTileCommand() => 'SelectTile',
          SelectUnitCommand() => 'SelectUnit',
          SelectCityCommand() => 'SelectCity',
          FocusNextPendingActionCommand() => 'FocusNextPendingAction',
          FocusTurnStartActionCommand() => 'FocusTurnStartAction',
        };
        expect(label, 'TileTapped');
      });
    });
    group('value equality', () {
      test('TileTappedCommand: same values are equal', () {
        expect(
          const TileTappedCommand(1, 2),
          equals(const TileTappedCommand(1, 2)),
        );
      });

      test('TileTappedCommand: different col is not equal', () {
        expect(
          const TileTappedCommand(1, 2),
          isNot(equals(const TileTappedCommand(9, 2))),
        );
      });

      test('TileTappedCommand: different row is not equal', () {
        expect(
          const TileTappedCommand(1, 2),
          isNot(equals(const TileTappedCommand(1, 9))),
        );
      });

      test('CityTappedCommand: same cityId is equal', () {
        expect(
          const CityTappedCommand('x'),
          equals(const CityTappedCommand('x')),
        );
      });

      test('CityTappedCommand: different cityId is not equal', () {
        expect(
          const CityTappedCommand('x'),
          isNot(equals(const CityTappedCommand('y'))),
        );
      });

      test('MoveUnitCommand: same values are equal', () {
        expect(
          const MoveUnitCommand('u', 1, 2),
          equals(const MoveUnitCommand('u', 1, 2)),
        );
      });

      test('MoveUnitCommand: different unitId is not equal', () {
        expect(
          const MoveUnitCommand('u', 1, 2),
          isNot(equals(const MoveUnitCommand('v', 1, 2))),
        );
      });

      test('CancelUnitActionCommand: same unitId is equal', () {
        expect(
          const CancelUnitActionCommand('u'),
          equals(const CancelUnitActionCommand('u')),
        );
      });

      test('SkipUnitTurnCommand: same unitId is equal', () {
        expect(
          const SkipUnitTurnCommand('u'),
          equals(const SkipUnitTurnCommand('u')),
        );
      });

      test('FortifyUnitCommand: same unitId is equal', () {
        expect(
          const FortifyUnitCommand('u'),
          equals(const FortifyUnitCommand('u')),
        );
      });

      test('FoundCityCommand: same founderId is equal', () {
        expect(
          const FoundCityCommand(
            'f',
            controlledHexes: [CityHex(col: 1, row: 0)],
          ),
          equals(
            const FoundCityCommand(
              'f',
              controlledHexes: [CityHex(col: 1, row: 0)],
            ),
          ),
        );
      });

      test('FoundCityCommand: different controlledHexes is not equal', () {
        expect(
          const FoundCityCommand(
            'f',
            controlledHexes: [CityHex(col: 1, row: 0)],
          ),
          isNot(
            equals(
              const FoundCityCommand(
                'f',
                controlledHexes: [CityHex(col: 0, row: 1)],
              ),
            ),
          ),
        );
      });

      test('StartBuildingCommand: same values are equal', () {
        expect(
          const StartBuildingCommand('c', CityBuildingType.granary),
          equals(const StartBuildingCommand('c', CityBuildingType.granary)),
        );
      });

      test('StartBuildingCommand: different buildingType is not equal', () {
        expect(
          const StartBuildingCommand('c', CityBuildingType.granary),
          isNot(
            equals(const StartBuildingCommand('c', CityBuildingType.waterMill)),
          ),
        );
      });

      test('StartUnitProductionCommand: same values are equal', () {
        expect(
          const StartUnitProductionCommand('c', GameUnitType.archer),
          equals(const StartUnitProductionCommand('c', GameUnitType.archer)),
        );
      });

      test('StartUnitProductionCommand: different unitType is not equal', () {
        expect(
          const StartUnitProductionCommand('c', GameUnitType.archer),
          isNot(
            equals(const StartUnitProductionCommand('c', GameUnitType.warrior)),
          ),
        );
      });

      test('StartCityProjectCommand: same values are equal', () {
        expect(
          const StartCityProjectCommand('c', CityProjectType.wealth),
          equals(const StartCityProjectCommand('c', CityProjectType.wealth)),
        );
      });

      test('StartCityProjectCommand: different projectType is not equal', () {
        expect(
          const StartCityProjectCommand('c', CityProjectType.wealth),
          isNot(
            equals(
              const StartCityProjectCommand('c', CityProjectType.research),
            ),
          ),
        );
      });

      test('SetCitySpecializationCommand: same values are equal', () {
        expect(
          const SetCitySpecializationCommand(
            'c',
            CitySpecializationType.industry,
          ),
          equals(
            const SetCitySpecializationCommand(
              'c',
              CitySpecializationType.industry,
            ),
          ),
        );
      });

      test(
        'SetCitySpecializationCommand: different specialization differs',
        () {
          expect(
            const SetCitySpecializationCommand(
              'c',
              CitySpecializationType.industry,
            ),
            isNot(
              equals(
                const SetCitySpecializationCommand(
                  'c',
                  CitySpecializationType.science,
                ),
              ),
            ),
          );
        },
      );

      test('RushProductionCommand: same cityId is equal', () {
        expect(
          const RushProductionCommand('c'),
          equals(const RushProductionCommand('c')),
        );
      });

      test('SelectTechnologyCommand: same values are equal', () {
        expect(
          const SelectTechnologyCommand('p', TechnologyId.agriculture),
          equals(const SelectTechnologyCommand('p', TechnologyId.agriculture)),
        );
      });

      test('SelectTechnologyCommand: different technologyId is not equal', () {
        expect(
          const SelectTechnologyCommand('p', TechnologyId.agriculture),
          isNot(
            equals(const SelectTechnologyCommand('p', TechnologyId.mining)),
          ),
        );
      });

      test('CancelResearchSelectionCommand: same playerId is equal', () {
        expect(
          const CancelResearchSelectionCommand('p'),
          equals(const CancelResearchSelectionCommand('p')),
        );
      });

      test('DetachTroopCommand: same values are equal', () {
        expect(
          const DetachTroopCommand('u', TroopType.warrior),
          equals(const DetachTroopCommand('u', TroopType.warrior)),
        );
      });

      test('DetachTroopCommand: different troopType is not equal', () {
        expect(
          const DetachTroopCommand('u', TroopType.warrior),
          isNot(equals(const DetachTroopCommand('u', TroopType.archer))),
        );
      });

      test('EndTurnCommand: same playerId is equal', () {
        expect(const EndTurnCommand('p'), equals(const EndTurnCommand('p')));
      });

      test('EndTurnCommand: different playerId is not equal', () {
        expect(
          const EndTurnCommand('p'),
          isNot(equals(const EndTurnCommand('q'))),
        );
      });

      test('SubmitTurnCommand: same playerId is equal', () {
        expect(
          const SubmitTurnCommand('p'),
          equals(const SubmitTurnCommand('p')),
        );
      });

      test('SubmitTurnCommand: different playerId is not equal', () {
        expect(
          const SubmitTurnCommand('p'),
          isNot(equals(const SubmitTurnCommand('q'))),
        );
      });

      test('ResetUnitMovementCommand: same playerId is equal', () {
        expect(
          const ResetUnitMovementCommand(playerId: 'p'),
          equals(const ResetUnitMovementCommand(playerId: 'p')),
        );
      });

      test('ResetUnitMovementCommand: different playerId is not equal', () {
        expect(
          const ResetUnitMovementCommand(playerId: 'p'),
          isNot(equals(const ResetUnitMovementCommand(playerId: 'q'))),
        );
      });

      test('ResetUnitMovementCommand: null and scoped commands differ', () {
        expect(
          const ResetUnitMovementCommand(),
          isNot(equals(const ResetUnitMovementCommand(playerId: 'p'))),
        );
      });

      test('SetActivePlayerCommand: same values are equal', () {
        expect(
          const SetActivePlayerCommand('p', canAct: true),
          equals(const SetActivePlayerCommand('p', canAct: true)),
        );
      });

      test('SetActivePlayerCommand: different canAct is not equal', () {
        expect(
          const SetActivePlayerCommand('p', canAct: true),
          isNot(equals(const SetActivePlayerCommand('p', canAct: false))),
        );
      });

      test('ToggleMoveTargetingCommand: all instances are equal', () {
        expect(
          const ToggleMoveTargetingCommand(),
          equals(const ToggleMoveTargetingCommand()),
        );
      });

      test('StartCityFoundingCommand: all instances are equal', () {
        expect(
          const StartCityFoundingCommand(),
          equals(const StartCityFoundingCommand()),
        );
      });

      test('CancelCityFoundingCommand: all instances are equal', () {
        expect(
          const CancelCityFoundingCommand(),
          equals(const CancelCityFoundingCommand()),
        );
      });

      test('StartCityWorkedHexSelectionCommand: same cityId is equal', () {
        expect(
          const StartCityWorkedHexSelectionCommand('c'),
          equals(const StartCityWorkedHexSelectionCommand('c')),
        );
      });

      test('CancelCityWorkedHexSelectionCommand: same cityId is equal', () {
        expect(
          const CancelCityWorkedHexSelectionCommand('c'),
          equals(const CancelCityWorkedHexSelectionCommand('c')),
        );
      });

      test('StartCityExpansionSelectionCommand: same cityId is equal', () {
        expect(
          const StartCityExpansionSelectionCommand('c'),
          equals(const StartCityExpansionSelectionCommand('c')),
        );
      });

      test('CancelCityExpansionSelectionCommand: same cityId is equal', () {
        expect(
          const CancelCityExpansionSelectionCommand('c'),
          equals(const CancelCityExpansionSelectionCommand('c')),
        );
      });

      test('SelectCityExpansionHexCommand: same payload is equal', () {
        expect(
          const SelectCityExpansionHexCommand('c', 1, 2),
          equals(const SelectCityExpansionHexCommand('c', 1, 2)),
        );
      });

      test('ToggleWorkedHexCommand: same payload is equal', () {
        expect(
          const ToggleWorkedHexCommand('c', 1, 2),
          equals(const ToggleWorkedHexCommand('c', 1, 2)),
        );
      });

      test('SelectWorkerImprovementCommand: same payload is equal', () {
        expect(
          const SelectWorkerImprovementCommand('u', FieldImprovementType.farm),
          equals(
            const SelectWorkerImprovementCommand(
              'u',
              FieldImprovementType.farm,
            ),
          ),
        );
      });

      test('ConfirmWorkerImprovementCommand: same unitId is equal', () {
        expect(
          const ConfirmWorkerImprovementCommand('u'),
          equals(const ConfirmWorkerImprovementCommand('u')),
        );
      });

      test('CancelWorkerJobCommand: same unitId is equal', () {
        expect(
          const CancelWorkerJobCommand('u'),
          equals(const CancelWorkerJobCommand('u')),
        );
      });

      test('AssignWorkerToHexCommand: same unitId is equal', () {
        expect(
          const AssignWorkerToHexCommand('u'),
          equals(const AssignWorkerToHexCommand('u')),
        );
      });

      test('CancelWorkerAssignmentCommand: same unitId is equal', () {
        expect(
          const CancelWorkerAssignmentCommand('u'),
          equals(const CancelWorkerAssignmentCommand('u')),
        );
      });

      test('StartAttackTargetingCommand: same attackerUnitId is equal', () {
        expect(
          const StartAttackTargetingCommand('u'),
          equals(const StartAttackTargetingCommand('u')),
        );
      });

      test('AttackHexCommand: same attacker and defender hex are equal', () {
        expect(
          const AttackHexCommand('u', 1, 2),
          equals(const AttackHexCommand('u', 1, 2)),
        );
      });

      test('AttackHexCommand: different defender hex is not equal', () {
        expect(
          const AttackHexCommand('u', 1, 2),
          isNot(equals(const AttackHexCommand('u', 2, 2))),
        );
      });

      test(
        'StartCommanderMergeSelectionCommand: same commanderUnitId is equal',
        () {
          expect(
            const StartCommanderMergeSelectionCommand('commander'),
            equals(const StartCommanderMergeSelectionCommand('commander')),
          );
        },
      );

      test('SelectTileCommand: same values are equal', () {
        expect(
          const SelectTileCommand(3, 4),
          equals(const SelectTileCommand(3, 4)),
        );
      });

      test('SelectTileCommand: different values are not equal', () {
        expect(
          const SelectTileCommand(3, 4),
          isNot(equals(const SelectTileCommand(3, 5))),
        );
      });

      test('SelectUnitCommand: same unitId is equal', () {
        expect(
          const SelectUnitCommand('u'),
          equals(const SelectUnitCommand('u')),
        );
      });

      test('SelectCityCommand: same cityId is equal', () {
        expect(
          const SelectCityCommand('c'),
          equals(const SelectCityCommand('c')),
        );
      });

      test('FocusNextPendingActionCommand: same playerId is equal', () {
        expect(
          const FocusNextPendingActionCommand('p'),
          equals(const FocusNextPendingActionCommand('p')),
        );
      });

      test(
        'FocusNextPendingActionCommand: different playerId is not equal',
        () {
          expect(
            const FocusNextPendingActionCommand('p'),
            isNot(equals(const FocusNextPendingActionCommand('q'))),
          );
        },
      );

      test(
        'FocusNextPendingActionCommand: different preferred advice is not equal',
        () {
          expect(
            const FocusNextPendingActionCommand(
              'p',
              preferredObjectiveAdvice: GameObjectiveAdvice.improveField,
            ),
            isNot(
              equals(
                const FocusNextPendingActionCommand(
                  'p',
                  preferredObjectiveAdvice: GameObjectiveAdvice.trainUnit,
                ),
              ),
            ),
          );
        },
      );

      test('FocusTurnStartActionCommand: same playerId is equal', () {
        expect(
          const FocusTurnStartActionCommand('p'),
          equals(const FocusTurnStartActionCommand('p')),
        );
      });

      test('FocusTurnStartActionCommand: different playerId is not equal', () {
        expect(
          const FocusTurnStartActionCommand('p'),
          isNot(equals(const FocusTurnStartActionCommand('q'))),
        );
      });

      test('different command types with same data are not equal', () {
        // e.g. SelectUnitCommand and SelectCityCommand both take a String
        // but must not be equal to each other.
        expect(
          const SelectUnitCommand('x'),
          isNot(equals(const SelectCityCommand('x'))),
        );
      });
      test('equal commands have equal hashCodes', () {
        expect(
          const TileTappedCommand(1, 2).hashCode,
          equals(const TileTappedCommand(1, 2).hashCode),
        );
        expect(
          const ToggleMoveTargetingCommand().hashCode,
          equals(const ToggleMoveTargetingCommand().hashCode),
        );
      });
    });
  });
}
