import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/unit.dart';

extension GameUnitLookup on Iterable<GameUnit> {
  GameUnit? byId(String id) {
    for (final unit in this) {
      if (unit.id == id) return unit;
    }
    return null;
  }
}

extension GameCityLookup on Iterable<GameCity> {
  GameCity? byId(String id) {
    for (final city in this) {
      if (city.id == id) return city;
    }
    return null;
  }
}

extension PlayerLookup on Iterable<Player> {
  Player? byId(String id) {
    for (final player in this) {
      if (player.id == id) return player;
    }
    return null;
  }
}

extension GameSaveLookup on GameSave {
  Player? playerById(String id) => players.byId(id);
}
