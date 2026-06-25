import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_city_production_commands.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudCityProductionCommands', () {
    test('creates production commands with city id and selected type', () {
      expect(
        HudCityProductionCommands.startBuilding(
          'city_1',
          CityBuildingType.granary,
        ),
        const StartBuildingCommand('city_1', CityBuildingType.granary),
      );
      expect(
        HudCityProductionCommands.startUnitProduction(
          'city_1',
          GameUnitType.warrior,
        ),
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
      );
      expect(
        HudCityProductionCommands.startProject(
          'city_1',
          CityProjectType.wealth,
        ),
        const StartCityProjectCommand('city_1', CityProjectType.wealth),
      );
      expect(
        HudCityProductionCommands.setSpecialization(
          'city_1',
          CitySpecializationType.industry,
        ),
        const SetCitySpecializationCommand(
          'city_1',
          CitySpecializationType.industry,
        ),
      );
      expect(
        HudCityProductionCommands.rushProduction('city_1'),
        const RushProductionCommand('city_1'),
      );
    });
  });
}
