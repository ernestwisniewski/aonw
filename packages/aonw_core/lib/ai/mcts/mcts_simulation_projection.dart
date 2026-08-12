import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsSimulationProjection {
  const MctsSimulationProjection._();

  static DomainState domainStateFromView(
    GameView view, {
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
    required ResearchState research,
  }) {
    final canonicalDomain = view.engineSnapshot?.domain;
    return DomainState.snapshot(
      turn: canonicalDomain?.turn ?? view.turn,
      matchRules: canonicalDomain?.matchRules ?? MatchRules.standard,
      participants:
          canonicalDomain?.participants ??
          [
            Player(
              id: view.forPlayerId,
              name: view.forPlayerId,
              colorValue: Player.palette.first,
            ),
          ],
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
      diplomacy: view.diplomacy,
      mapObjectiveHoldStatesByObjectiveId:
          view.mapObjectiveHoldStatesByObjectiveId,
      resourceTradeAgreements: view.resourceTradeAgreements,
      strategicResources:
          canonicalDomain?.strategicResources ??
          _ownStrategicResourceAccounts(view),
      wonderRegistry: view.wonderRegistry,
    );
  }

  static GameView viewFromDomainState(
    DomainState state, {
    required GameView previousView,
    required CanonicalGameSnapshot engineSnapshot,
  }) {
    return GameView.fromDomainState(
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

StrategicResourceAccounts _ownStrategicResourceAccounts(GameView view) {
  if (view.ownStrategicResources.onHand.isEmpty) {
    return StrategicResourceAccounts.empty;
  }
  return StrategicResourceAccounts(
    byPlayerId: {view.forPlayerId: view.ownStrategicResources},
  );
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
