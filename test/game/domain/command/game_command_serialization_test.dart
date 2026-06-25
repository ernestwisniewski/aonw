import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCommandSerializer', () {
    GameCommand roundTrip(GameCommand cmd) {
      final json = GameCommandSerializer.toJson(cmd);
      return GameCommandSerializer.fromJson(json);
    }

    group('toJson — type discriminator', () {
      test('TileTappedCommand has type field', () {
        final json = GameCommandSerializer.toJson(
          const TileTappedCommand(1, 2),
        );
        expect(json['type'], isA<String>());
        expect(json['type'], isNotEmpty);
      });

      test('every command type produces a non-empty type field', () {
        final commands = <GameCommand>[
          const TileTappedCommand(0, 0),
          const CityTappedCommand('c'),
          const MoveUnitCommand('u', 0, 0),
          const CancelUnitActionCommand('u'),
          const SkipUnitTurnCommand('u'),
          const FortifyUnitCommand('u'),
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
          const ResetUnitMovementCommand(),
          const ResetUnitMovementCommand(playerId: 'p'),
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
        for (final cmd in commands) {
          final json = GameCommandSerializer.toJson(cmd);
          expect(
            json['type'],
            isA<String>(),
            reason: '${cmd.runtimeType} must have a String type field',
          );
          expect(
            json['type'],
            isNotEmpty,
            reason: '${cmd.runtimeType} type field must not be empty',
          );
        }
      });
    });
    group('round-trip', () {
      test('TileTappedCommand', () {
        const original = TileTappedCommand(3, 5);
        expect(roundTrip(original), equals(original));
      });

      test('CityTappedCommand', () {
        const original = CityTappedCommand('city-42');
        expect(roundTrip(original), equals(original));
      });

      test('MoveUnitCommand', () {
        const original = MoveUnitCommand('unit-7', 4, 8);
        expect(roundTrip(original), equals(original));
      });

      test('CancelUnitActionCommand', () {
        const original = CancelUnitActionCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('SkipUnitTurnCommand', () {
        const original = SkipUnitTurnCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('FortifyUnitCommand', () {
        const original = FortifyUnitCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('AutoExploreUnitCommand', () {
        const original = AutoExploreUnitCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('legacy SleepUnit payload decodes as SkipUnitTurnCommand', () {
        expect(
          GameCommandSerializer.fromJson(const {
            'type': 'SleepUnit',
            'unitId': 'unit-7',
          }),
          const SkipUnitTurnCommand('unit-7'),
        );
      });

      test('FoundCityCommand', () {
        const original = FoundCityCommand(
          'settler-1',
          controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
        );
        expect(roundTrip(original), equals(original));
      });

      test('StartBuildingCommand — granary', () {
        const original = StartBuildingCommand(
          'city-1',
          CityBuildingType.granary,
        );
        expect(roundTrip(original), equals(original));
      });

      test('StartBuildingCommand — waterMill', () {
        const original = StartBuildingCommand(
          'city-2',
          CityBuildingType.waterMill,
        );
        expect(roundTrip(original), equals(original));
      });

      test('StartBuildingCommand — workshop', () {
        const original = StartBuildingCommand(
          'city-3',
          CityBuildingType.workshop,
        );
        expect(roundTrip(original), equals(original));
      });

      test('StartBuildingCommand — storehouse', () {
        const original = StartBuildingCommand(
          'city-4',
          CityBuildingType.storehouse,
        );
        expect(roundTrip(original), equals(original));
      });

      test('StartBuildingCommand — housing', () {
        const original = StartBuildingCommand(
          'city-5',
          CityBuildingType.housing,
        );
        expect(roundTrip(original), equals(original));
      });

      test('StartUnitProductionCommand — warrior', () {
        const original = StartUnitProductionCommand(
          'city-6',
          GameUnitType.warrior,
        );
        expect(roundTrip(original), equals(original));
      });

      test('StartUnitProductionCommand — archer', () {
        const original = StartUnitProductionCommand(
          'city-7',
          GameUnitType.archer,
        );
        expect(roundTrip(original), equals(original));
      });

      test('StartCityProjectCommand — wealth', () {
        const original = StartCityProjectCommand(
          'city-8',
          CityProjectType.wealth,
        );
        expect(roundTrip(original), equals(original));
      });

      test('StartCityProjectCommand — research', () {
        const original = StartCityProjectCommand(
          'city-9',
          CityProjectType.research,
        );
        expect(roundTrip(original), equals(original));
      });

      test('SetCitySpecializationCommand', () {
        const original = SetCitySpecializationCommand(
          'city-10',
          CitySpecializationType.science,
        );
        expect(roundTrip(original), equals(original));
      });

      test('RushProductionCommand', () {
        const original = RushProductionCommand('city-7');
        expect(roundTrip(original), equals(original));
      });

      test('SelectTechnologyCommand', () {
        const original = SelectTechnologyCommand(
          'player-1',
          TechnologyId.mining,
        );
        expect(roundTrip(original), equals(original));
      });

      test('CancelResearchSelectionCommand', () {
        const original = CancelResearchSelectionCommand('player-1');
        expect(roundTrip(original), equals(original));
      });

      test('DetachTroopCommand — warrior', () {
        const original = DetachTroopCommand('unit-1', TroopType.warrior);
        expect(roundTrip(original), equals(original));
      });

      test('DetachTroopCommand — archer', () {
        const original = DetachTroopCommand('unit-2', TroopType.archer);
        expect(roundTrip(original), equals(original));
      });

      test('DetachTroopCommand — settler', () {
        const original = DetachTroopCommand('unit-3', TroopType.settler);
        expect(roundTrip(original), equals(original));
      });

      test('EndTurnCommand', () {
        const original = EndTurnCommand('player-1');
        expect(roundTrip(original), equals(original));
      });

      test('SubmitTurnCommand', () {
        const original = SubmitTurnCommand('player-1');
        expect(roundTrip(original), equals(original));
      });

      test('ResetUnitMovementCommand — all players', () {
        const original = ResetUnitMovementCommand();
        expect(roundTrip(original), equals(original));
      });

      test('ResetUnitMovementCommand — single player', () {
        const original = ResetUnitMovementCommand(playerId: 'player-1');
        expect(roundTrip(original), equals(original));
      });

      test('SetActivePlayerCommand — canAct: true', () {
        const original = SetActivePlayerCommand('player-2', canAct: true);
        expect(roundTrip(original), equals(original));
      });

      test('SetActivePlayerCommand — canAct: false', () {
        const original = SetActivePlayerCommand('player-3', canAct: false);
        expect(roundTrip(original), equals(original));
      });

      test('ToggleMoveTargetingCommand', () {
        const original = ToggleMoveTargetingCommand();
        expect(roundTrip(original), equals(original));
      });

      test('StartCityFoundingCommand', () {
        const original = StartCityFoundingCommand();
        expect(roundTrip(original), equals(original));
      });

      test('CancelCityFoundingCommand', () {
        const original = CancelCityFoundingCommand();
        expect(roundTrip(original), equals(original));
      });

      test('StartCityWorkedHexSelectionCommand', () {
        const original = StartCityWorkedHexSelectionCommand('city-7');
        expect(roundTrip(original), equals(original));
      });

      test('CancelCityWorkedHexSelectionCommand', () {
        const original = CancelCityWorkedHexSelectionCommand('city-7');
        expect(roundTrip(original), equals(original));
      });

      test('StartCityExpansionSelectionCommand', () {
        const original = StartCityExpansionSelectionCommand('city-7');
        expect(roundTrip(original), equals(original));
      });

      test('CancelCityExpansionSelectionCommand', () {
        const original = CancelCityExpansionSelectionCommand('city-7');
        expect(roundTrip(original), equals(original));
      });

      test('SelectCityExpansionHexCommand', () {
        const original = SelectCityExpansionHexCommand('city-7', 1, 2);
        expect(roundTrip(original), equals(original));
      });

      test('ToggleWorkedHexCommand', () {
        const original = ToggleWorkedHexCommand('city-7', 1, 2);
        expect(roundTrip(original), equals(original));
      });

      test('StartWorkerActionSelectionCommand', () {
        const original = StartWorkerActionSelectionCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('SelectWorkerImprovementCommand', () {
        const original = SelectWorkerImprovementCommand(
          'unit-7',
          FieldImprovementType.mine,
        );
        expect(roundTrip(original), equals(original));
      });

      test('ConfirmWorkerImprovementCommand', () {
        const original = ConfirmWorkerImprovementCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('CancelWorkerActionSelectionCommand', () {
        const original = CancelWorkerActionSelectionCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('CancelWorkerJobCommand', () {
        const original = CancelWorkerJobCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('AssignWorkerToHexCommand', () {
        const original = AssignWorkerToHexCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('CancelWorkerAssignmentCommand', () {
        const original = CancelWorkerAssignmentCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('StartAttackTargetingCommand', () {
        const original = StartAttackTargetingCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('CancelAttackTargetingCommand', () {
        const original = CancelAttackTargetingCommand('unit-7');
        expect(roundTrip(original), equals(original));
      });

      test('AttackHexCommand', () {
        const original = AttackHexCommand('unit-7', 3, 4);
        expect(roundTrip(original), equals(original));
      });

      test('AttackHexCommand with city conquest action', () {
        const original = AttackHexCommand(
          'unit-7',
          3,
          4,
          cityConquestAction: CityConquestAction.destroy,
        );
        expect(roundTrip(original), equals(original));
      });

      test('StartCommanderMergeSelectionCommand', () {
        const original = StartCommanderMergeSelectionCommand('commander-7');
        expect(roundTrip(original), equals(original));
      });

      test('CancelCommanderMergeSelectionCommand', () {
        const original = CancelCommanderMergeSelectionCommand('commander-7');
        expect(roundTrip(original), equals(original));
      });

      test('SelectTileCommand', () {
        const original = SelectTileCommand(2, 9);
        expect(roundTrip(original), equals(original));
      });

      test('SelectUnitCommand', () {
        const original = SelectUnitCommand('unit-99');
        expect(roundTrip(original), equals(original));
      });

      test('SelectCityCommand', () {
        const original = SelectCityCommand('city-5');
        expect(roundTrip(original), equals(original));
      });

      test('FocusNextPendingActionCommand', () {
        const original = FocusNextPendingActionCommand(
          'player-x',
          preferredObjectiveAdvice: GameObjectiveAdvice.improveField,
        );
        expect(roundTrip(original), equals(original));
      });

      test('FocusTurnStartActionCommand', () {
        const original = FocusTurnStartActionCommand('player-x');
        expect(roundTrip(original), equals(original));
      });
    });
    group('toJson payload', () {
      test('TileTappedCommand encodes col and row', () {
        final json = GameCommandSerializer.toJson(
          const TileTappedCommand(3, 5),
        );
        expect(json['col'], 3);
        expect(json['row'], 5);
      });

      test(
        'FocusNextPendingActionCommand encodes preferred objective advice',
        () {
          final json = GameCommandSerializer.toJson(
            const FocusNextPendingActionCommand(
              'player-x',
              preferredObjectiveAdvice: GameObjectiveAdvice.improveField,
            ),
          );

          expect(json['preferredObjectiveAdvice'], 'improveField');
        },
      );

      test('CityTappedCommand encodes cityId', () {
        final json = GameCommandSerializer.toJson(
          const CityTappedCommand('city-42'),
        );
        expect(json['cityId'], 'city-42');
      });

      test('MoveUnitCommand encodes unitId, targetCol, targetRow', () {
        final json = GameCommandSerializer.toJson(
          const MoveUnitCommand('unit-7', 4, 8),
        );
        expect(json['unitId'], 'unit-7');
        expect(json['targetCol'], 4);
        expect(json['targetRow'], 8);
      });

      test('CancelUnitActionCommand encodes unitId', () {
        final json = GameCommandSerializer.toJson(
          const CancelUnitActionCommand('unit-7'),
        );
        expect(json['unitId'], 'unit-7');
      });

      test('SkipUnitTurnCommand encodes unitId', () {
        final json = GameCommandSerializer.toJson(
          const SkipUnitTurnCommand('unit-7'),
        );
        expect(json['unitId'], 'unit-7');
      });

      test('FortifyUnitCommand encodes unitId', () {
        final json = GameCommandSerializer.toJson(
          const FortifyUnitCommand('unit-7'),
        );
        expect(json['unitId'], 'unit-7');
      });

      test('AutoExploreUnitCommand encodes unitId', () {
        final json = GameCommandSerializer.toJson(
          const AutoExploreUnitCommand('unit-7'),
        );
        expect(json['unitId'], 'unit-7');
      });

      test('FoundCityCommand encodes founderId', () {
        final json = GameCommandSerializer.toJson(
          const FoundCityCommand(
            'settler-1',
            controlledHexes: [CityHex(col: 1, row: 0)],
          ),
        );
        expect(json['founderId'], 'settler-1');
        expect(json['controlledHexes'], [
          {'col': 1, 'row': 0},
        ]);
      });

      test('StartBuildingCommand encodes buildingType as name string', () {
        final json = GameCommandSerializer.toJson(
          const StartBuildingCommand('city-1', CityBuildingType.waterMill),
        );
        expect(json['cityId'], 'city-1');
        expect(json['buildingType'], 'waterMill');
      });

      test('StartUnitProductionCommand encodes unitType as name string', () {
        final json = GameCommandSerializer.toJson(
          const StartUnitProductionCommand('city-1', GameUnitType.archer),
        );
        expect(json['cityId'], 'city-1');
        expect(json['unitType'], 'archer');
      });

      test('StartCityProjectCommand encodes projectType as name string', () {
        final json = GameCommandSerializer.toJson(
          const StartCityProjectCommand('city-1', CityProjectType.research),
        );
        expect(json['cityId'], 'city-1');
        expect(json['projectType'], 'research');
      });

      test(
        'SetCitySpecializationCommand encodes specialization as name string',
        () {
          final json = GameCommandSerializer.toJson(
            const SetCitySpecializationCommand(
              'city-1',
              CitySpecializationType.military,
            ),
          );
          expect(json['cityId'], 'city-1');
          expect(json['specialization'], 'military');
        },
      );

      test('RushProductionCommand encodes cityId', () {
        final json = GameCommandSerializer.toJson(
          const RushProductionCommand('city-1'),
        );
        expect(json['cityId'], 'city-1');
      });

      test('SelectTechnologyCommand encodes technologyId as name string', () {
        final json = GameCommandSerializer.toJson(
          const SelectTechnologyCommand('player-1', TechnologyId.mining),
        );
        expect(json['playerId'], 'player-1');
        expect(json['technologyId'], 'mining');
      });

      test('CancelResearchSelectionCommand encodes playerId', () {
        final json = GameCommandSerializer.toJson(
          const CancelResearchSelectionCommand('player-1'),
        );
        expect(json['playerId'], 'player-1');
      });

      test('StartCityWorkedHexSelectionCommand encodes cityId', () {
        final json = GameCommandSerializer.toJson(
          const StartCityWorkedHexSelectionCommand('city-1'),
        );
        expect(json['cityId'], 'city-1');
      });

      test('SelectCityExpansionHexCommand encodes cityId and coordinates', () {
        final json = GameCommandSerializer.toJson(
          const SelectCityExpansionHexCommand('city-1', 1, 2),
        );
        expect(json['cityId'], 'city-1');
        expect(json['col'], 1);
        expect(json['row'], 2);
      });

      test('ToggleWorkedHexCommand encodes cityId and coordinates', () {
        final json = GameCommandSerializer.toJson(
          const ToggleWorkedHexCommand('city-1', 1, 2),
        );
        expect(json['cityId'], 'city-1');
        expect(json['col'], 1);
        expect(json['row'], 2);
      });

      test('DetachTroopCommand encodes troopType as name string', () {
        final json = GameCommandSerializer.toJson(
          const DetachTroopCommand('unit-1', TroopType.archer),
        );
        expect(json['unitId'], 'unit-1');
        expect(json['troopType'], 'archer');
      });

      test('SubmitTurnCommand encodes playerId', () {
        final json = GameCommandSerializer.toJson(
          const SubmitTurnCommand('player-1'),
        );
        expect(json['type'], 'SubmitTurn');
        expect(json['playerId'], 'player-1');
      });

      test('SetActivePlayerCommand encodes canAct', () {
        final json = GameCommandSerializer.toJson(
          const SetActivePlayerCommand('player-2', canAct: false),
        );
        expect(json['playerId'], 'player-2');
        expect(json['canAct'], false);
      });

      test('ResetUnitMovementCommand omits null playerId', () {
        final json = GameCommandSerializer.toJson(
          const ResetUnitMovementCommand(),
        );
        expect(json['type'], 'ResetUnitMovement');
        expect(json.containsKey('playerId'), isFalse);
      });

      test('ResetUnitMovementCommand encodes playerId when scoped', () {
        final json = GameCommandSerializer.toJson(
          const ResetUnitMovementCommand(playerId: 'player-2'),
        );
        expect(json['playerId'], 'player-2');
      });

      test('AttackHexCommand encodes attackerUnitId and defender hex', () {
        final json = GameCommandSerializer.toJson(
          const AttackHexCommand('unit-7', 3, 4),
        );
        expect(json['attackerUnitId'], 'unit-7');
        expect(json['defenderCol'], 3);
        expect(json['defenderRow'], 4);
        expect(json.containsKey('cityConquestAction'), isFalse);
      });

      test('AttackHexCommand encodes non-default city conquest action', () {
        final json = GameCommandSerializer.toJson(
          const AttackHexCommand(
            'unit-7',
            3,
            4,
            cityConquestAction: CityConquestAction.destroy,
          ),
        );
        expect(json['cityConquestAction'], 'destroy');
      });
    });
    group('fromJson — error handling', () {
      test('unknown type throws ArgumentError', () {
        expect(
          () => GameCommandSerializer.fromJson({'type': 'UnknownCommandXyz'}),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('empty type string throws ArgumentError', () {
        expect(
          () => GameCommandSerializer.fromJson({'type': ''}),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('missing type reports discriminator field', () {
        expect(
          () => GameCommandSerializer.fromJson({}),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              'GameCommand.type',
            ),
          ),
        );
      });

      test('missing payload field reports command field', () {
        expect(
          () => GameCommandSerializer.fromJson({
            'type': 'MoveUnit',
            'targetCol': 4,
            'targetRow': 8,
          }),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              'MoveUnit.unitId',
            ),
          ),
        );
      });

      test('wrong payload type reports command field', () {
        expect(
          () => GameCommandSerializer.fromJson({
            'type': 'SetActivePlayer',
            'playerId': 'p1',
            'canAct': 'yes',
          }),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              'SetActivePlayer.canAct',
            ),
          ),
        );
      });

      test('unknown enum payload reports command field', () {
        expect(
          () => GameCommandSerializer.fromJson({
            'type': 'StartBuilding',
            'cityId': 'city-1',
            'buildingType': 'futureBuilding',
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

      test('unknown project payload reports command field', () {
        expect(
          () => GameCommandSerializer.fromJson({
            'type': 'StartCityProject',
            'cityId': 'city-1',
            'projectType': 'futureProject',
          }),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              'StartCityProject.projectType',
            ),
          ),
        );
      });

      test('empty optional string reports command field', () {
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
  });
}
