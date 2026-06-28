import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw_core/game/domain/unit.dart';

GameIconData gameIconForUnitType(GameUnitType type) => switch (type) {
  GameUnitType.warrior => GameIcons.warrior,
  GameUnitType.archer => GameIcons.archer,
  GameUnitType.settler => GameIcons.settler,
  GameUnitType.worker => GameIcons.production,
  GameUnitType.merchant => GameIcons.commerce,
  GameUnitType.commander => GameIcons.army,
  GameUnitType.scout => GameIcons.visibility,
  GameUnitType.spearman => GameIcons.attack,
  GameUnitType.cavalry => GameIcons.move,
  GameUnitType.catapult => GameIcons.production,
  GameUnitType.heavyInfantry => GameIcons.defense,
  GameUnitType.fieldCannon => GameIcons.attack,
  GameUnitType.rifleman => GameIcons.archer,
  GameUnitType.tank => GameIcons.defense,
  GameUnitType.scoutShip => GameIcons.ship,
  GameUnitType.warship => GameIcons.ship,
  GameUnitType.reconPlane => GameIcons.visibility,
};
