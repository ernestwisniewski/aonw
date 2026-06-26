import 'package:aonw_core/game/domain/unit.dart';

List<GameUnit> replaceUnit(List<GameUnit> units, GameUnit updated) {
  return [
    for (final unit in units)
      if (unit.id == updated.id) updated else unit,
  ];
}
