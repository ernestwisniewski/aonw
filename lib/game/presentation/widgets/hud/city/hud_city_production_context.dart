import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_modes.dart';

class HudCityProductionContext {
  final GameCity? city;
  final int productionPerTurn;

  const HudCityProductionContext({
    required this.city,
    required this.productionPerTurn,
  });

  factory HudCityProductionContext.from({
    required HudPanelModes modes,
    required GameSelection? selection,
  }) {
    return HudCityProductionContext(
      city: modes.cityBuildings ? selection?.city : null,
      productionPerTurn:
          selection?.cityEconomy?.netYield.production ??
          selection?.cityYield?.production ??
          1,
    );
  }
}
