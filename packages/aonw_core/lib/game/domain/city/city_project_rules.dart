import 'package:aonw_core/game/domain/city/city_project_type.dart';

final class CityProjectOutput {
  const CityProjectOutput({required this.type, required this.amount});

  final CityProjectType type;
  final int amount;

  int get gold => type == CityProjectType.wealth ? amount : 0;

  int get science => type == CityProjectType.research ? amount : 0;

  @override
  bool operator ==(Object other) {
    return other is CityProjectOutput &&
        other.type == type &&
        other.amount == amount;
  }

  @override
  int get hashCode => Object.hash(type, amount);
}

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
