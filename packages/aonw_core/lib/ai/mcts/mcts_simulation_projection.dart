import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsSimulationProjection {
  const MctsSimulationProjection._();

  static PersistentGameState persistentStateFromView(
    GameView view, {
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
    required ResearchState research,
  }) {
    final canonicalDomain = view.engineSnapshot?.domain;
    return PersistentGameState.snapshot(
      playerColors: canonicalDomain?.playerColors ?? const {},
      playerCountries: canonicalDomain?.playerCountries ?? const {},
      playerGold: _withPlayerValue(
        canonicalDomain?.playerGold,
        playerId: view.forPlayerId,
        value: view.ownGold,
      ),
      playerWarWeariness: _withPlayerValue(
        canonicalDomain?.playerWarWeariness,
        playerId: view.forPlayerId,
        value: view.ownWarWeariness,
      ),
      playerStabilityNet: _withPlayerValue(
        canonicalDomain?.playerStabilityNet,
        playerId: view.forPlayerId,
        value: view.ownStabilityNet,
      ),
      units: units.toList(growable: false),
      cities: cities.toList(growable: false),
      artifacts: view.artifacts,
      fieldImprovements: view.ownImprovements,
      fogOfWar: view.visibility.state,
      research: research,
      runtimeState: GameRuntimeState.snapshot(
        diplomacy: view.diplomacy,
        mapObjectiveHoldStatesByObjectiveId:
            view.mapObjectiveHoldStatesByObjectiveId,
        resourceTradeAgreements: view.resourceTradeAgreements,
      ),
      wonderRegistry: view.wonderRegistry,
    );
  }

  static GameView viewFromPersistentState(
    PersistentGameState state, {
    required GameView previousView,
    required CanonicalGameSnapshot engineSnapshot,
  }) {
    return GameView.fromPersistentState(
      state,
      forPlayerId: previousView.forPlayerId,
      turn: previousView.turn,
      mapData: previousView.mapData,
      ruleset: previousView.ruleset,
      engineSnapshot: engineSnapshot,
      activeHostilePlayerIds: previousView.activeHostilePlayerIds,
      recentHostilePlayerIds: previousView.recentHostilePlayerIds,
      pressureTargetPlayerIds: previousView.pressureTargetPlayerIds,
      defaultNeutralPlayerIds: previousView.defaultNeutralPlayerIds,
      pendingCityAttackThreats: previousView.pendingCityAttackThreats,
      ignoreFogOfWar: !previousView.visibility.isEnabled,
    );
  }
}

Map<String, int> _withPlayerValue(
  Map<String, int>? canonicalValues, {
  required String playerId,
  required int value,
}) {
  final values = {...?canonicalValues};
  if (values.containsKey(playerId) || value != 0) {
    values[playerId] = value;
  }
  return values;
}
