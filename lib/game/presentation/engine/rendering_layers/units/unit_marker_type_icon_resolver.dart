import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class UnitMarkerTypeIconResolver {
  static const Map<GameUnitType, GameIconData> _icons = {
    GameUnitType.commander: GameIcons.army,
    GameUnitType.warrior: GameIcons.warrior,
    GameUnitType.archer: GameIcons.archer,
    GameUnitType.settler: GameIcons.settler,
    GameUnitType.worker: GameIcons.production,
    GameUnitType.merchant: GameIcons.commerce,
    GameUnitType.scout: GameIcons.visibility,
    GameUnitType.spearman: GameIcons.attack,
    GameUnitType.cavalry: GameIcons.move,
    GameUnitType.catapult: GameIcons.production,
    GameUnitType.heavyInfantry: GameIcons.defense,
    GameUnitType.fieldCannon: GameIcons.attack,
    GameUnitType.rifleman: GameIcons.archer,
    GameUnitType.tank: GameIcons.defense,
    GameUnitType.scoutShip: GameIcons.visibility,
    GameUnitType.warship: GameIcons.attack,
    GameUnitType.reconPlane: GameIcons.visibility,
  };

  static GameIconData iconFor(GameUnitType type) => _icons[type]!;
}
