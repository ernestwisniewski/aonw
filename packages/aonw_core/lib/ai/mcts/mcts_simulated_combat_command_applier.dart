import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_command_application.dart';
import 'package:aonw_core/ai/mcts/mcts_simulation_projection.dart';
import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsSimulatedCombatCommandApplier {
  const MctsSimulatedCombatCommandApplier({
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

  MctsSimulatedCommandApplication applyAttackHex(
    AttackHexCommand command,
    int commandTick,
  ) {
    final engineSnapshot =
        view.engineSnapshot ??
        (throw StateError('MCTS combat requires a canonical engine snapshot.'));
    final reviewedUnitIds = {
      for (final unit in ownUnits) unit.id,
      for (final unit in visibleEnemyUnits) unit.id,
    };
    final state = MctsSimulationProjection.persistentStateFromView(
      view,
      units: [
        ...ownUnits,
        ...visibleEnemyUnits,
        for (final blocker in view.movementBlockingUnits)
          if (!reviewedUnitIds.contains(blocker.id)) blocker,
      ],
      cities: [...ownCities, ...rememberedEnemyCities],
      research: view.research,
    );
    final result = const SimulationGameEngineAdapter().apply(
      snapshot: engineSnapshot,
      state: state,
      command: command,
      actorPlayerId: view.forPlayerId,
      commandTick: commandTick,
      mapView: view.mapData,
      ruleset: view.ruleset,
      combatVisibilityMode: view.visibility.isEnabled
          ? CombatCommandVisibilityMode.authoritative
          : CombatCommandVisibilityMode.unrestricted,
    );
    if (!result.accepted) return _unchangedCommandApplication;
    final nextView = MctsSimulationProjection.viewFromPersistentState(
      result.state,
      previousView: view,
      engineSnapshot: result.snapshot,
    );
    return (nextView: nextView);
  }

  MctsSimulatedCommandApplication get _unchangedCommandApplication =>
      (nextView: view);
}
