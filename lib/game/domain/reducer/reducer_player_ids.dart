import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';

Set<String> knownPlayerIds(GameState state) => {
  ...state.playerColors.keys,
  ...state.playerCountries.keys,
  ...state.fogOfWar.playerIds,
  if (state.activePlayerId.isNotEmpty) state.activePlayerId,
  for (final unit in state.units) unit.ownerPlayerId,
  for (final city in state.cities) city.ownerPlayerId,
};

GameState withDiscoveredDiplomaticContacts(
  GameState state, {
  Iterable<String>? playerIds,
}) {
  final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
    diplomacy: state.diplomacy,
    fogOfWar: state.fogOfWar,
    units: state.units,
    cities: state.cities,
    playerIds: playerIds ?? knownPlayerIds(state),
  );
  if (identical(diplomacy, state.diplomacy) || diplomacy == state.diplomacy) {
    return state;
  }
  return state.copyWith(diplomacy: diplomacy);
}
