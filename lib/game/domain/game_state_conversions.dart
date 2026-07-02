import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/state.dart';

/// Single conversion from the interactive [GameState] to the core
/// [PersistentGameState] consumed by `aonw_core` processors.
///
/// New persistent fields must be added here so every consumer stays in sync
/// instead of each call site copying fields by hand.
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
