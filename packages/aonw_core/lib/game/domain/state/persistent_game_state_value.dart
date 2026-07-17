part of 'persistent_game_state.dart';

bool _samePersistentState(PersistentGameState left, PersistentGameState right) {
  return _samePersistentPlayerValues(left, right) &&
      _samePersistentEntities(left, right) &&
      _samePersistentNestedState(left, right);
}

bool _samePersistentPlayerValues(
  PersistentGameState left,
  PersistentGameState right,
) {
  return mapEquals(left.playerColors, right.playerColors) &&
      mapEquals(left.playerCountries, right.playerCountries) &&
      mapEquals(left.playerGold, right.playerGold) &&
      mapEquals(left.playerWarWeariness, right.playerWarWeariness) &&
      mapEquals(left.playerStabilityNet, right.playerStabilityNet);
}

bool _samePersistentEntities(
  PersistentGameState left,
  PersistentGameState right,
) {
  return listEquals(left.units, right.units) &&
      listEquals(left.cities, right.cities) &&
      listEquals(left.artifacts, right.artifacts) &&
      listEquals(left.fieldImprovements, right.fieldImprovements);
}

bool _samePersistentNestedState(
  PersistentGameState left,
  PersistentGameState right,
) {
  return left.fogOfWar == right.fogOfWar &&
      left.research == right.research &&
      left.runtimeState == right.runtimeState &&
      left.wonderRegistry == right.wonderRegistry;
}
