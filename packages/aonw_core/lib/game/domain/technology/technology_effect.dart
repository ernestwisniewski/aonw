import 'package:aonw_core/map/domain/terrain_type.dart';

sealed class TechnologyEffect {
  const TechnologyEffect();
}

class StrategicResourceProductionBonus extends TechnologyEffect {
  final ResourceType resourceType;
  final int production;

  const StrategicResourceProductionBonus({
    required this.resourceType,
    required this.production,
  });

  @override
  bool operator ==(Object other) =>
      other is StrategicResourceProductionBonus &&
      other.resourceType == resourceType &&
      other.production == production;

  @override
  int get hashCode => Object.hash(resourceType, production);
}

class GlobalGoldMultiplier extends TechnologyEffect {
  final double multiplier;

  const GlobalGoldMultiplier(this.multiplier);

  @override
  bool operator ==(Object other) =>
      other is GlobalGoldMultiplier && other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(GlobalGoldMultiplier, multiplier);
}

class CityDefenseBonus extends TechnologyEffect {
  final int amount;

  const CityDefenseBonus(this.amount);

  @override
  bool operator ==(Object other) =>
      other is CityDefenseBonus && other.amount == amount;

  @override
  int get hashCode => Object.hash(CityDefenseBonus, amount);
}

class ArmyProductionMultiplier extends TechnologyEffect {
  final double multiplier;

  const ArmyProductionMultiplier(this.multiplier);

  @override
  bool operator ==(Object other) =>
      other is ArmyProductionMultiplier && other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(ArmyProductionMultiplier, multiplier);
}

class ArmyStrengthMultiplier extends TechnologyEffect {
  final double multiplier;

  const ArmyStrengthMultiplier(this.multiplier);

  @override
  bool operator ==(Object other) =>
      other is ArmyStrengthMultiplier && other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(ArmyStrengthMultiplier, multiplier);
}

class ArmyCombatStatsBonus extends TechnologyEffect {
  final int attack;
  final int defense;
  final int hp;

  const ArmyCombatStatsBonus({this.attack = 0, this.defense = 0, this.hp = 0});

  @override
  bool operator ==(Object other) =>
      other is ArmyCombatStatsBonus &&
      other.attack == attack &&
      other.defense == defense &&
      other.hp == hp;

  @override
  int get hashCode => Object.hash(ArmyCombatStatsBonus, attack, defense, hp);
}

class MaxCityPopulationBonus extends TechnologyEffect {
  final int amount;

  const MaxCityPopulationBonus(this.amount);

  @override
  bool operator ==(Object other) =>
      other is MaxCityPopulationBonus && other.amount == amount;

  @override
  int get hashCode => Object.hash(MaxCityPopulationBonus, amount);
}

class MaxControlledHexesBonus extends TechnologyEffect {
  final int amount;

  const MaxControlledHexesBonus(this.amount);

  @override
  bool operator ==(Object other) =>
      other is MaxControlledHexesBonus && other.amount == amount;

  @override
  int get hashCode => Object.hash(MaxControlledHexesBonus, amount);
}

class CityScienceBonus extends TechnologyEffect {
  final int amount;

  const CityScienceBonus(this.amount);

  @override
  bool operator ==(Object other) =>
      other is CityScienceBonus && other.amount == amount;

  @override
  int get hashCode => Object.hash(CityScienceBonus, amount);
}
