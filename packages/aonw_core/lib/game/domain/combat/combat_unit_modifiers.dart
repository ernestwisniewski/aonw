part of 'combat_modifier_collector.dart';

bool _isArmyUnit(GameUnit unit) => UnitCatalog.isMilitaryType(unit.type);

List<CombatModifier> _armyCombatStatModifiers({
  required TechnologyId technologyId,
  required int attack,
  required int defense,
  required int hp,
}) {
  return [
    if (attack != 0)
      TechnologyModifier(
        label: 'tech.${technologyId.name}.armyAttack',
        target: CombatStatTarget.attack,
        delta: attack,
      ),
    if (defense != 0)
      TechnologyModifier(
        label: 'tech.${technologyId.name}.armyDefense',
        target: CombatStatTarget.defense,
        delta: defense,
      ),
    if (hp != 0)
      TechnologyModifier(
        label: 'tech.${technologyId.name}.armyHitPoints',
        target: CombatStatTarget.hp,
        delta: hp,
      ),
  ];
}

List<CombatModifier> _troopCompositionModifiers({
  required GameUnit unit,
  required CombatRuleset ruleset,
}) {
  if (unit.type != GameUnitType.commander ||
      ruleset.mixedCommanderArmyAttackBonus == 0 ||
      unit.troopCount(TroopType.warrior) <= 0 ||
      unit.troopCount(TroopType.archer) <= 0) {
    return const [];
  }
  return [
    TroopCompositionModifier(
      label: 'troop.mixedCommanderArmy',
      target: CombatStatTarget.attack,
      delta: ruleset.mixedCommanderArmyAttackBonus,
    ),
  ];
}

List<CombatModifier> _veterancyModifiers(GameUnit unit) {
  if (!UnitVeterancyRules.canGainExperience(unit)) return const [];
  final rank = UnitVeterancyRules.rankFor(unit);
  final stats = UnitVeterancyRules.statsBonusForRank(rank);
  return _modifiersFromStats(
    stats: stats,
    labelPrefix: 'veterancy.${rank.name}',
    create: ({required label, required target, required delta}) =>
        VeterancyModifier(label: label, target: target, delta: delta),
  );
}

int _scaledDelta(int base, double multiplier) {
  if (base <= 0 || multiplier == 0) return 0;
  final delta = (base * multiplier).round();
  if (delta == 0) return multiplier > 0 ? 1 : -1;
  return delta;
}

List<CombatModifier> _modifiersFromStats({
  required CombatStats stats,
  required String labelPrefix,
  required CombatModifier Function({
    required String label,
    required CombatStatTarget target,
    required int delta,
  })
  create,
}) {
  return [
    if (stats.attack != 0)
      create(
        label: '$labelPrefix.attack',
        target: CombatStatTarget.attack,
        delta: stats.attack,
      ),
    if (stats.defense != 0)
      create(
        label: '$labelPrefix.defense',
        target: CombatStatTarget.defense,
        delta: stats.defense,
      ),
    if (stats.hp != 0)
      create(
        label: '$labelPrefix.hp',
        target: CombatStatTarget.hp,
        delta: stats.hp,
      ),
    if (stats.range != 1)
      create(
        label: '$labelPrefix.range',
        target: CombatStatTarget.range,
        delta: stats.range - 1,
      ),
    if (stats.mobility != 1)
      create(
        label: '$labelPrefix.mobility',
        target: CombatStatTarget.mobility,
        delta: stats.mobility - 1,
      ),
  ];
}
