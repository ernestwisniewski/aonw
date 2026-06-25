import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CityProjectRules', () {
    test('wealth projects convert half of production', () {
      expect(
        CityProjectRules.outputFor(
          type: CityProjectType.wealth,
          productionPerTurn: 5,
        ),
        3,
      );
      expect(
        CityProjectRules.outputFor(
          type: CityProjectType.wealth,
          productionPerTurn: -1,
        ),
        0,
      );
    });

    test('research projects convert production more slowly than wealth', () {
      expect(
        CityProjectRules.outputFor(
          type: CityProjectType.research,
          productionPerTurn: 5,
        ),
        1,
      );
      expect(
        CityProjectRules.outputFor(
          type: CityProjectType.research,
          productionPerTurn: 0,
        ),
        0,
      );
      expect(
        CityProjectRules.outputFor(
          type: CityProjectType.research,
          productionPerTurn: 9,
        ),
        1,
      );
      expect(
        CityProjectRules.outputFor(
          type: CityProjectType.research,
          productionPerTurn: 13,
        ),
        2,
      );
      expect(
        CityProjectRules.outputFor(
          type: CityProjectType.research,
          productionPerTurn: -1,
        ),
        0,
      );
    });
  });
}
