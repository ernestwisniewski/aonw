import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_data.dart';

abstract final class HudCityFoundingAvailability {
  static bool canStart({required GameState? state, required MapData mapData}) {
    if (state == null) return false;
    final selected = state.selectedUnit;
    if (selected == null || !state.canControlUnit(selected)) return false;
    if (selected.isWorking) return false;
    return CityFoundingRules.canStart(
      unit: selected,
      centerTile: mapData.tileAt(selected.col, selected.row),
      cities: state.cities,
    );
  }
}
