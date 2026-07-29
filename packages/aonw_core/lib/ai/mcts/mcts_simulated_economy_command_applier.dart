import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_command_application.dart';
import 'package:aonw_core/ai/mcts/mcts_simulation_projection.dart';
import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsSimulatedEconomyCommandApplier {
  MctsSimulatedEconomyCommandApplier({
    required this.view,
    required this.ownUnits,
    required this.visibleEnemyUnits,
    required this.ownCities,
    required this.rememberedEnemyCities,
    required this.ownResearch,
  });

  final GameView view;
  final List<GameUnit> ownUnits;
  final List<GameUnit> visibleEnemyUnits;
  final List<GameCity> ownCities;
  final List<GameCity> rememberedEnemyCities;
  final PlayerResearchState ownResearch;

  MctsSimulatedCommandApplication applySelectTechnology(
    SelectTechnologyCommand command,
  ) {
    final result = SelectTechnologyResolver.selectTechnology(
      research: _researchState,
      cities: ownCities,
      fieldImprovements: view.ownImprovements,
      command: command,
      actorPlayerId: view.forPlayerId,
      mapTiles: view.mapData,
      ruleset: view.ruleset.technology,
      // Preserve the current MCTS approximation; pace convergence is a
      // separate, behavior-changing fix with its own characterization.
      paceBalance: PaceBalance.unlimited,
    );
    if (!result.accepted) return unchangedCommandApplication;
    final currentEngineSnapshot = view.engineSnapshot;
    final nextEngineSnapshot = currentEngineSnapshot?.copyWith(
      domain: currentEngineSnapshot.domain.copyWith(research: result.research),
    );
    return (
      nextView: GameView(
        forPlayerId: view.forPlayerId,
        turn: view.turn,
        ownUnits: view.ownUnits,
        ownCities: view.ownCities,
        artifacts: view.artifacts,
        ownGold: view.ownGold,
        ownWarWeariness: view.ownWarWeariness,
        ownStabilityNet: view.ownStabilityNet,
        research: result.research,
        ownResearch: result.research.forPlayer(view.forPlayerId),
        ownImprovements: view.ownImprovements,
        resourceTradeAgreements: view.resourceTradeAgreements,
        mapObjectiveHoldStatesByObjectiveId:
            view.mapObjectiveHoldStatesByObjectiveId,
        diplomacy: view.diplomacy,
        visibleEnemyUnits: view.visibleEnemyUnits,
        movementBlockingUnits: view.movementBlockingUnits,
        rememberedEnemyCities: view.rememberedEnemyCities,
        activeHostilePlayerIds: view.activeHostilePlayerIds,
        recentHostilePlayerIds: view.recentHostilePlayerIds,
        pressureTargetPlayerIds: view.pressureTargetPlayerIds,
        defaultNeutralPlayerIds: view.defaultNeutralPlayerIds,
        pendingCityAttackThreats: view.pendingCityAttackThreats,
        visibility: view.visibility,
        mapData: view.mapData,
        ruleset: view.ruleset,
        wonderRegistry: view.wonderRegistry,
        engineSnapshot: nextEngineSnapshot,
      ),
    );
  }

  MctsSimulatedCommandApplication applyEngineCommand(
    DomainCommand command,
    int commandTick,
  ) {
    final engineSnapshot =
        view.engineSnapshot ??
        (throw StateError(
          'MCTS city-economy commands require a canonical engine snapshot.',
        ));
    final result = const SimulationGameEngineAdapter().apply(
      snapshot: engineSnapshot,
      state: _persistentState(),
      command: command,
      actorPlayerId: view.forPlayerId,
      commandTick: commandTick,
      mapView: view.mapData,
      ruleset: view.ruleset,
    );
    if (!result.accepted) return unchangedCommandApplication;
    return _applicationFromPersistent(
      result.state,
      engineSnapshot: result.snapshot,
    );
  }

  MctsSimulatedCommandApplication get unchangedCommandApplication =>
      (nextView: view);

  ResearchState get _researchState => view.research;

  PersistentGameState _persistentState() {
    return MctsSimulationProjection.persistentStateFromView(
      view,
      units: view.movementBlockingUnits,
      cities: [...ownCities, ...rememberedEnemyCities],
      research: _researchState,
    );
  }

  MctsSimulatedCommandApplication _applicationFromPersistent(
    PersistentGameState state, {
    CanonicalGameSnapshot? engineSnapshot,
  }) {
    final nextView = MctsSimulationProjection.viewFromPersistentState(
      state,
      previousView: view,
      engineSnapshot:
          engineSnapshot ??
          (view.engineSnapshot ??
              (throw StateError(
                'MCTS simulation requires a canonical engine snapshot.',
              ))),
    );
    return (nextView: nextView);
  }
}
