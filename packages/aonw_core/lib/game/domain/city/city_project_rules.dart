import 'package:aonw_core/game/domain/city/city_project_type.dart';

abstract final class CityProjectRules {
  static const int wealthProjectDivisor = 2;
  static const int researchProjectDivisor = 12;

  static int outputFor({
    required CityProjectType type,
    required int productionPerTurn,
  }) {
    final production = productionPerTurn < 0 ? 0 : productionPerTurn;
    return switch (type) {
      CityProjectType.wealth =>
        (production + wealthProjectDivisor - 1) ~/ wealthProjectDivisor,
      CityProjectType.research =>
        (production + researchProjectDivisor - 1) ~/ researchProjectDivisor,
    };
  }
}
