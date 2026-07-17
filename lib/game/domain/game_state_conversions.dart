import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/state.dart';

extension GameStatePersistence on GameState {
  PersistentGameState toPersistentState() {
    return PersistentGameState.snapshot(
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
      wonderRegistry: wonderRegistry,
      runtimeState: runtimeState,
    );
  }

  GameState copyWithPersistentState(PersistentGameState persistent) {
    final runtime = persistent.runtimeState;
    return copyWith(
      playerColors: persistent.playerColors,
      playerCountries: persistent.playerCountries,
      playerGold: persistent.playerGold,
      playerWarWeariness: persistent.playerWarWeariness,
      playerStabilityNet: persistent.playerStabilityNet,
      units: persistent.units,
      cities: persistent.cities,
      artifacts: persistent.artifacts,
      fieldImprovements: persistent.fieldImprovements,
      fogOfWar: persistent.fogOfWar,
      research: persistent.research,
      wonderRegistry: persistent.wonderRegistry,
      diplomacy: runtime.diplomacy,
      submittedPlayerIds: runtime.submittedPlayerIds,
      timeoutStreaksByPlayerId: runtime.timeoutStreaksByPlayerId,
      afkPlayerIds: runtime.afkPlayerIds,
      kickedPlayerIds: runtime.kickedPlayerIds,
      intendedAttacks: runtime.intendedAttacks,
      resourceTradeAgreements: runtime.resourceTradeAgreements,
      dominationHoldTurnsByPlayerId: runtime.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          runtime.culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId:
          runtime.mapObjectiveHoldStatesByObjectiveId,
      turnStartedAt: runtime.turnStartedAt,
    );
  }
}
