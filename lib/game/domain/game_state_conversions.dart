import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/state.dart';

extension GameStatePersistence on GameState {
  PersistentGameState toPersistentState() {
    return PersistentGameState(
      playerColors: playerColors,
      playerCountries: playerCountries,
      playerGold: playerGold,
      playerWarWeariness: playerWarWeariness,
      playerStabilityNet: playerStabilityNet,
      units: units,
      cities: cities,
      artifacts: artifacts,
      fieldImprovements: fieldImprovements,
      fogOfWar: fogOfWar,
      research: research,
      runtimeState: runtimeState,
    );
  }
}
