import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_command_application.dart';
import 'package:aonw_core/ai/mcts/mcts_simulation_projection.dart';
import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
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

  DomainState _persistentState() {
    return MctsSimulationProjection.domainStateFromView(
      view,
      units: view.movementBlockingUnits,
      cities: [...ownCities, ...rememberedEnemyCities],
      research: _researchState,
    );
  }

  MctsSimulatedCommandApplication _applicationFromPersistent(
    DomainState state, {
    CanonicalGameSnapshot? engineSnapshot,
  }) {
    final nextView = MctsSimulationProjection.viewFromDomainState(
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
