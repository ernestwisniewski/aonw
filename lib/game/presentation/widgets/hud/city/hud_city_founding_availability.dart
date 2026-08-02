import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class HudCityFoundingAvailability {
  static bool canStart({
    required GameClientState? state,
    required MapTileLookup mapTiles,
  }) {
    if (state == null) return false;
    final selected = state.selectedUnit;
    if (selected == null || !state.canControlUnit(selected)) return false;
    if (selected.isWorking) return false;
    return CityFoundingRules.canStart(
      unit: selected,
      centerTile: mapTiles.tileAt(selected.col, selected.row),
      cities: state.cities,
    );
  }
}
