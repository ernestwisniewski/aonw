import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_command_application.dart';
import 'package:aonw_core/ai/mcts/mcts_simulation_projection.dart';
import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsSimulatedMovementCommandApplier {
  const MctsSimulatedMovementCommandApplier({
    required this.view,
    required this.ownUnits,
    required this.ownCities,
    required this.rememberedEnemyCities,
  });

  final GameView view;
  final List<GameUnit> ownUnits;
  final List<GameCity> ownCities;
  final List<GameCity> rememberedEnemyCities;

  MctsSimulatedCommandApplication applyMoveUnit(MoveUnitCommand command) {
    return _applyEngineMovement(command);
  }

  bool supportsUnitAction(DomainCommand command) =>
      command is CancelUnitActionCommand ||
      command is SkipUnitTurnCommand ||
      command is FortifyUnitCommand;

  MctsSimulatedCommandApplication applyUnitAction(DomainCommand command) {
    return switch (command) {
      final CancelUnitActionCommand value => _applyEngineMovement(value),
      final SkipUnitTurnCommand value => _applyEngineMovement(value),
      final FortifyUnitCommand value => _applyEngineMovement(value),
      _ => (nextView: view),
    };
  }

  MctsSimulatedCommandApplication _applyEngineMovement(DomainCommand command) {
    final engineSnapshot =
        view.engineSnapshot ??
        (throw StateError(
          'MCTS unit actions require a canonical engine snapshot.',
        ));
    final state = MctsSimulationProjection.domainStateFromView(
      view,
      units: view.movementBlockingUnits,
      cities: [...ownCities, ...rememberedEnemyCities],
      research: view.research,
    );
    final result = const SimulationGameEngineAdapter().apply(
      snapshot: engineSnapshot,
      state: state,
      command: command,
      actorPlayerId: view.forPlayerId,
      commandTick: 0,
      mapView: view.mapData,
      ruleset: view.ruleset,
      movementVisibilityMode: view.visibility.isEnabled
          ? MovementCommandVisibilityMode.authoritative
          : MovementCommandVisibilityMode.unrestricted,
    );
    if (!result.accepted ||
        !identical(result.state.artifacts, state.artifacts)) {
      return (nextView: view);
    }
    return (
      nextView: MctsSimulationProjection.viewFromDomainState(
        result.state,
        previousView: view,
        engineSnapshot: result.snapshot,
      ),
    );
  }
}
