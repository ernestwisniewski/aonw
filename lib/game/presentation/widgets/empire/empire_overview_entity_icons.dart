part of 'empire_overview_entity_groups.dart';

GameIconData _iconForUnit(GameUnitType type) {
  return switch (type) {
    GameUnitType.commander => GameIcons.army,
    GameUnitType.warrior => GameIcons.warrior,
    GameUnitType.archer => GameIcons.archer,
    GameUnitType.settler => GameIcons.settler,
    GameUnitType.worker => GameIcons.production,
    GameUnitType.merchant => GameIcons.commerce,
    GameUnitType.scout => GameIcons.visibility,
    GameUnitType.spearman => GameIcons.attack,
    GameUnitType.cavalry => GameIcons.move,
    GameUnitType.catapult => GameIcons.production,
    GameUnitType.heavyInfantry => GameIcons.defense,
    GameUnitType.fieldCannon => GameIcons.attack,
    GameUnitType.rifleman => GameIcons.archer,
    GameUnitType.tank => GameIcons.defense,
    GameUnitType.scoutShip => GameIcons.visibility,
    GameUnitType.warship => GameIcons.attack,
    GameUnitType.reconPlane => GameIcons.visibility,
  };
}
