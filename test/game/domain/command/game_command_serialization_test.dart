import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainCommandCodec', () {
    DomainCommand roundTrip(DomainCommand cmd) {
      final json = DomainCommandCodec.toJson(cmd);
      return DomainCommandCodec.fromJson(json);
    }

    group('toJson — type discriminator', () {
      test('MoveUnitCommand has type field', () {
        final json = DomainCommandCodec.toJson(
          const MoveUnitCommand('u', 1, 2),
        );
        expect(json['type'], isA<String>());
        expect(json['type'], isNotEmpty);
      });

      test('every command type produces a non-empty type field', () {
        final commands = <DomainCommand>[
          const MoveUnitCommand('u', 0, 0),
          const CancelUnitActionCommand('u'),
          const SkipUnitTurnCommand('u'),
          const FortifyUnitCommand('u'),
          FoundCityCommand('f', controlledHexes: const []),
          const StartBuildingCommand('c', CityBuildingType.granary),
          const StartUnitProductionCommand('c', GameUnitType.warrior),
          const StartCityProjectCommand('c', CityProjectType.wealth),
          const SetCitySpecializationCommand(
            'c',
            CitySpecializationType.industry,
          ),
          const RushProductionCommand('c'),
          const SelectTechnologyCommand('p', TechnologyId.agriculture),
          const DetachTroopCommand('u', TroopType.warrior),
          const EndTurnCommand('p'),
          const SubmitTurnCommand('p'),
          const SelectCityExpansionHexCommand('c', 1, 2),
          const ToggleWorkedHexCommand('c', 1, 2),
          const SelectWorkerImprovementCommand('u', FieldImprovementType.farm),
          const ConfirmWorkerImprovementCommand('u'),
          const CancelWorkerJobCommand('u'),
          const AssignWorkerToHexCommand('u'),
          const CancelWorkerAssignmentCommand('u'),
          const AttackHexCommand('u', 1, 2),
        ];
        for (final cmd in commands) {
          final json = DomainCommandCodec.toJson(cmd);
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
          DomainCommandCodec.fromJson(const {
            'type': 'SleepUnit',
            'unitId': 'unit-7',
          }),
          const SkipUnitTurnCommand('unit-7'),
        );
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

      test('SelectCityExpansionHexCommand', () {
        const original = SelectCityExpansionHexCommand('city-7', 1, 2);
        expect(roundTrip(original), equals(original));
      });

      test('ToggleWorkedHexCommand', () {
        const original = ToggleWorkedHexCommand('city-7', 1, 2);
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
    });
    group('toJson payload', () {
      test('MoveUnitCommand encodes unitId, targetCol, targetRow', () {
        final json = DomainCommandCodec.toJson(
          const MoveUnitCommand('unit-7', 4, 8),
        );
        expect(json['unitId'], 'unit-7');
        expect(json['targetCol'], 4);
        expect(json['targetRow'], 8);
      });

      test('CancelUnitActionCommand encodes unitId', () {
        final json = DomainCommandCodec.toJson(
          const CancelUnitActionCommand('unit-7'),
        );
        expect(json['unitId'], 'unit-7');
      });

      test('SkipUnitTurnCommand encodes unitId', () {
        final json = DomainCommandCodec.toJson(
          const SkipUnitTurnCommand('unit-7'),
        );
        expect(json['unitId'], 'unit-7');
      });

      test('FortifyUnitCommand encodes unitId', () {
        final json = DomainCommandCodec.toJson(
          const FortifyUnitCommand('unit-7'),
        );
        expect(json['unitId'], 'unit-7');
      });

      test('AutoExploreUnitCommand encodes unitId', () {
        final json = DomainCommandCodec.toJson(
          const AutoExploreUnitCommand('unit-7'),
        );
        expect(json['unitId'], 'unit-7');
      });

      test('StartBuildingCommand encodes buildingType as name string', () {
        final json = DomainCommandCodec.toJson(
          const StartBuildingCommand('city-1', CityBuildingType.waterMill),
        );
        expect(json['cityId'], 'city-1');
        expect(json['buildingType'], 'waterMill');
      });

      test('StartUnitProductionCommand encodes unitType as name string', () {
        final json = DomainCommandCodec.toJson(
          const StartUnitProductionCommand('city-1', GameUnitType.archer),
        );
        expect(json['cityId'], 'city-1');
        expect(json['unitType'], 'archer');
      });

      test('StartCityProjectCommand encodes projectType as name string', () {
        final json = DomainCommandCodec.toJson(
          const StartCityProjectCommand('city-1', CityProjectType.research),
        );
        expect(json['cityId'], 'city-1');
        expect(json['projectType'], 'research');
      });

      test(
        'SetCitySpecializationCommand encodes specialization as name string',
        () {
          final json = DomainCommandCodec.toJson(
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
        final json = DomainCommandCodec.toJson(
          const RushProductionCommand('city-1'),
        );
        expect(json['cityId'], 'city-1');
      });

      test('SelectTechnologyCommand encodes technologyId as name string', () {
        final json = DomainCommandCodec.toJson(
          const SelectTechnologyCommand('player-1', TechnologyId.mining),
        );
        expect(json['playerId'], 'player-1');
        expect(json['technologyId'], 'mining');
      });

      test('SelectCityExpansionHexCommand encodes cityId and coordinates', () {
        final json = DomainCommandCodec.toJson(
          const SelectCityExpansionHexCommand('city-1', 1, 2),
        );
        expect(json['cityId'], 'city-1');
        expect(json['col'], 1);
        expect(json['row'], 2);
      });

      test('ToggleWorkedHexCommand encodes cityId and coordinates', () {
        final json = DomainCommandCodec.toJson(
          const ToggleWorkedHexCommand('city-1', 1, 2),
        );
        expect(json['cityId'], 'city-1');
        expect(json['col'], 1);
        expect(json['row'], 2);
      });

      test('DetachTroopCommand encodes troopType as name string', () {
        final json = DomainCommandCodec.toJson(
          const DetachTroopCommand('unit-1', TroopType.archer),
        );
        expect(json['unitId'], 'unit-1');
        expect(json['troopType'], 'archer');
      });

      test('SubmitTurnCommand encodes playerId', () {
        final json = DomainCommandCodec.toJson(
          const SubmitTurnCommand('player-1'),
        );
        expect(json['type'], 'SubmitTurn');
        expect(json['playerId'], 'player-1');
      });

      test('AttackHexCommand encodes attackerUnitId and defender hex', () {
        final json = DomainCommandCodec.toJson(
          const AttackHexCommand('unit-7', 3, 4),
        );
        expect(json['attackerUnitId'], 'unit-7');
        expect(json['defenderCol'], 3);
        expect(json['defenderRow'], 4);
        expect(json.containsKey('cityConquestAction'), isFalse);
      });

      test('AttackHexCommand encodes non-default city conquest action', () {
        final json = DomainCommandCodec.toJson(
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
          () => DomainCommandCodec.fromJson({'type': 'UnknownCommandXyz'}),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('empty type string throws ArgumentError', () {
        expect(
          () => DomainCommandCodec.fromJson({'type': ''}),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('missing type reports discriminator field', () {
        expect(
          () => DomainCommandCodec.fromJson({}),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              'DomainCommand.type',
            ),
          ),
        );
      });

      test('missing payload field reports command field', () {
        expect(
          () => DomainCommandCodec.fromJson({
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

      test('unknown enum payload reports command field', () {
        expect(
          () => DomainCommandCodec.fromJson({
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
          () => DomainCommandCodec.fromJson({
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
    });
  });
}
