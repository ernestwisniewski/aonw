import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_simulation_projection.dart';
import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

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

  List<GameUnit> applyMoveUnit(MoveUnitCommand command) {
    final movementUnits = view.movementBlockingUnits;
    final cities = [...ownCities, ...rememberedEnemyCities];
    final result =
        const MovementCommandResolver(
          fogOfWarService: _MctsNoOpFogOfWarService(),
        ).resolve(
          state: MovementCommandState(
            units: movementUnits,
            cities: cities,
            fogOfWar: view.visibility.state,
            diplomacy: view.diplomacy,
            playerIds: {
              view.forPlayerId,
              for (final unit in movementUnits) unit.ownerPlayerId,
              for (final city in cities) city.ownerPlayerId,
            },
          ),
          command: command,
          actorPlayerId: view.forPlayerId,
          mapData: view.mapData,
          visibilityMode: view.visibility.isEnabled
              ? MovementCommandVisibilityMode.authoritative
              : MovementCommandVisibilityMode.unrestricted,
        );
    if (!result.accepted || identical(result.units, movementUnits)) {
      return ownUnits;
    }
    return [
      for (final ownUnit in ownUnits) result.units.byId(ownUnit.id) ?? ownUnit,
    ];
  }

  bool supportsUnitAction(GameCommand command) =>
      command is CancelUnitActionCommand ||
      command is SkipUnitTurnCommand ||
      command is FortifyUnitCommand;

  List<GameUnit> applyUnitAction(GameCommand command) {
    return switch (command) {
      final CancelUnitActionCommand value => _applyCancelUnitAction(value),
      final SkipUnitTurnCommand value => _applyEngineUnitAction(value),
      final FortifyUnitCommand value => _applyEngineUnitAction(value),
      _ => ownUnits,
    };
  }

  List<GameUnit> _applyCancelUnitAction(CancelUnitActionCommand command) {
    // This projection only models the wake-up command emitted by the war-goal
    // planner. Full-state simulations use PersistentUnitActionResolver so they
    // can also project runtime interaction and artifact excavation changes.
    final unit = ownUnits.byId(command.unitId);
    if (unit == null ||
        !unit.isFortified ||
        unit.isWorking ||
        unit.queuedPath != null ||
        unit.merchantTradeRoute != null) {
      return ownUnits;
    }
    final result = UnitActionCommandResolver.cancelUnitAction(
      units: ownUnits,
      artifacts: view.artifacts,
      interaction: PersistedInteractionState.empty,
      command: command,
      actorPlayerId: view.forPlayerId,
    );
    if (!result.accepted || !identical(result.artifacts, view.artifacts)) {
      return ownUnits;
    }
    return result.units;
  }

  List<GameUnit> _applyEngineUnitAction(DomainCommand command) {
    final engineSnapshot =
        view.engineSnapshot ??
        (throw StateError(
          'MCTS unit actions require a canonical engine snapshot.',
        ));
    final state = MctsSimulationProjection.persistentStateFromView(
      view,
      units: ownUnits,
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
    );
    if (!result.accepted ||
        !identical(result.state.artifacts, state.artifacts)) {
      return ownUnits;
    }
    return result.state.units;
  }
}

final class _MctsNoOpFogOfWarService extends FogOfWarService {
  const _MctsNoOpFogOfWarService();

  @override
  FogOfWarState recomputeAfterUnitMove({
    required FogOfWarState current,
    required MapTileLookup mapData,
    required GameUnit previousUnit,
    required GameUnit movedUnit,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    return current;
  }
}
