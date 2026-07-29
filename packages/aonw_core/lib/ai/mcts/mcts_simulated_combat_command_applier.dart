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
      research: view.research.updatePlayer(view.forPlayerId, ownResearch),
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
    final nextView = GameView.fromPersistentState(
      result.state,
      forPlayerId: view.forPlayerId,
      turn: view.turn,
      mapData: view.mapData,
      ruleset: view.ruleset,
      engineSnapshot: result.snapshot,
      activeHostilePlayerIds: view.activeHostilePlayerIds,
      recentHostilePlayerIds: view.recentHostilePlayerIds,
      pressureTargetPlayerIds: view.pressureTargetPlayerIds,
      defaultNeutralPlayerIds: view.defaultNeutralPlayerIds,
      pendingCityAttackThreats: view.pendingCityAttackThreats,
      ignoreFogOfWar: !view.visibility.isEnabled,
    );
    return (
      nextOwnUnits: nextView.ownUnits,
      nextVisibleEnemyUnits: nextView.visibleEnemyUnits,
      nextOwnCities: nextView.ownCities,
      nextRememberedEnemyCities: nextView.rememberedEnemyCities,
      nextOwnResearch: nextView.ownResearch,
    );
  }

  MctsSimulatedCommandApplication get _unchangedCommandApplication => (
    nextOwnUnits: ownUnits,
    nextVisibleEnemyUnits: visibleEnemyUnits,
    nextOwnCities: ownCities,
    nextRememberedEnemyCities: rememberedEnemyCities,
    nextOwnResearch: ownResearch,
  );
}
