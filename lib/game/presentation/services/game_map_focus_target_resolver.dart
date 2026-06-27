import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/unit.dart';

class GameMapFocusTarget {
  final int col;
  final int row;

  const GameMapFocusTarget({required this.col, required this.row});

  factory GameMapFocusTarget.unit(GameUnit unit) {
    return GameMapFocusTarget(col: unit.col, row: unit.row);
  }

  factory GameMapFocusTarget.city(GameCity city) {
    return GameMapFocusTarget(col: city.center.col, row: city.center.row);
  }
}

class GameMapFocusTargetResolver {
  final GameState? state;

  const GameMapFocusTargetResolver(this.state);

  GameMapFocusTarget? unitTarget(String unitId) {
    final unit = unitById(unitId);
    return unit == null ? null : GameMapFocusTarget.unit(unit);
  }

  GameMapFocusTarget? cityTarget(String cityId) {
    final city = cityById(cityId);
    return city == null ? null : GameMapFocusTarget.city(city);
  }

  GameMapFocusTarget? playerStartTarget(String playerId) {
    final unit = firstOwnedUnit(playerId);
    if (unit != null) return GameMapFocusTarget.unit(unit);

    final city = firstOwnedCity(playerId);
    return city == null ? null : GameMapFocusTarget.city(city);
  }

  GameCity? firstOwnedCity(String playerId) {
    final state = this.state;
    if (state == null || playerId.isEmpty) return null;
    for (final city in state.cities) {
      if (city.ownerPlayerId == playerId) return city;
    }
    return null;
  }

  GameUnit? firstOwnedUnit(String playerId) {
    final state = this.state;
    if (state == null || playerId.isEmpty) return null;
    for (final unit in state.units) {
      if (unit.ownerPlayerId == playerId) return unit;
    }
    return null;
  }

  GameUnit? unitById(String unitId) {
    final state = this.state;
    return state == null || unitId.isEmpty ? null : state.unitById(unitId);
  }

  GameCity? cityById(String cityId) {
    final state = this.state;
    return state == null || cityId.isEmpty ? null : state.cityById(cityId);
  }
}
