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
    return PersistentGameState(
      playerGold: {view.forPlayerId: view.ownGold},
      playerWarWeariness: {view.forPlayerId: view.ownWarWeariness},
      playerStabilityNet: {view.forPlayerId: view.ownStabilityNet},
      units: units.toList(growable: false),
      cities: cities.toList(growable: false),
      artifacts: view.artifacts,
      fieldImprovements: view.ownImprovements,
      fogOfWar: view.visibility.state,
      research: research,
      runtimeState: GameRuntimeState(
        diplomacy: view.diplomacy,
        mapObjectiveHoldStatesByObjectiveId:
            view.mapObjectiveHoldStatesByObjectiveId,
        resourceTradeAgreements: view.resourceTradeAgreements,
      ),
      wonderRegistry: view.wonderRegistry,
    );
  }
}
