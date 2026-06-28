import 'package:aonw_core/ai/ai_turn_plan.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city/city_founding.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';
import 'package:aonw_core/game/domain/movement.dart';

final class BasicStrategyPlanningSession {
  final GameView view;
  final List<GameCommand> commands = [];
  final List<String> notes = [];
  final Set<String> usedUnitIds = {};
  final Set<HexCoordinate> reservedHexes = {};

  final Stopwatch _totalStopwatch = Stopwatch()..start();
  final Map<String, Duration> _phaseTimings = {};

  BasicStrategyPlanningSession({required this.view});

  T timed<T>(String phase, T Function() action) {
    final stopwatch = Stopwatch()..start();
    final result = action();
    stopwatch.stop();
    _phaseTimings[phase] =
        (_phaseTimings[phase] ?? Duration.zero) + stopwatch.elapsed;
    return result;
  }

  void addCommands(
    Iterable<GameCommand> phaseCommands, {
    Iterable<String> additionalUsedUnitIds = const [],
    bool trackUsedUnitIds = true,
    bool reserveMoveHexes = true,
  }) {
    final materialized = phaseCommands.toList(growable: false);
    commands.addAll(materialized);
    if (trackUsedUnitIds) {
      usedUnitIds.addAll(
        BasicStrategyCommandAnalysis.unitIdsUsedBy(materialized),
      );
    }
    usedUnitIds.addAll(additionalUsedUnitIds);
    if (reserveMoveHexes) {
      reservedHexes.addAll(
        BasicStrategyCommandAnalysis.moveReservationsForCommands(
          materialized,
          view,
        ),
      );
    }
  }

  List<GameCommand> runCommandPhase(
    String phase,
    List<GameCommand> Function() action, {
    Iterable<String> additionalUsedUnitIds = const [],
    Iterable<String> Function(List<GameCommand> commands)? notesFor,
    bool trackUsedUnitIds = true,
    bool reserveMoveHexes = true,
  }) {
    final phaseCommands = timed(phase, action);
    addCommands(
      phaseCommands,
      additionalUsedUnitIds: additionalUsedUnitIds,
      trackUsedUnitIds: trackUsedUnitIds,
      reserveMoveHexes: reserveMoveHexes,
    );
    if (phaseCommands.isNotEmpty && notesFor != null) {
      notes.addAll(notesFor(phaseCommands));
    }
    return phaseCommands;
  }

  void addExplorationPlan(AiTurnPlan plan) {
    commands.addAll(plan.commands);
    final explorationNotes = plan.debug?.notes;
    if (explorationNotes != null) notes.addAll(explorationNotes);
  }

  AiTurnPlan finish({required String strategyId}) {
    _totalStopwatch.stop();
    return AiTurnPlan(
      commands: commands,
      debug: AiDebugInfo(
        strategyId: strategyId,
        notes: notes,
        metrics: {
          '$strategyId.totalMicros': _totalStopwatch.elapsedMicroseconds,
          for (final entry in _phaseTimings.entries)
            '$strategyId.${entry.key}Micros': entry.value.inMicroseconds,
        },
      ),
    );
  }
}

abstract final class BasicStrategyCommandAnalysis {
  static Set<String> unitIdsUsedBy(Iterable<GameCommand> commands) {
    return {
      for (final command in commands)
        switch (command) {
          FoundCityCommand(:final founderId) => founderId,
          AttackHexCommand(:final attackerUnitId) => attackerUnitId,
          MoveUnitCommand(:final unitId) => unitId,
          SelectWorkerImprovementCommand(:final unitId) => unitId,
          AssignWorkerToHexCommand(:final unitId) => unitId,
          CancelUnitActionCommand(:final unitId) => unitId,
          FortifyUnitCommand(:final unitId) => unitId,
          SkipUnitTurnCommand(:final unitId) => unitId,
          StartArtifactExcavationCommand(:final unitId) => unitId,
          StoreArtifactInCityCommand(:final unitId) => unitId,
          _ => null,
        },
    }.nonNulls.toSet();
  }

  static Set<String> founderUnitIds(GameView view) {
    return {
      for (final unit in view.ownUnits)
        if (CityFoundingRules.canFoundCityWith(unit)) unit.id,
    };
  }

  static Set<HexCoordinate> moveReservationsForCommands(
    Iterable<GameCommand> commands,
    GameView view,
  ) {
    final reserved = <HexCoordinate>{};
    for (final command in commands.whereType<MoveUnitCommand>()) {
      reserved.addAll(_moveReservationsForCommand(command, view));
    }
    return reserved;
  }

  static Set<HexCoordinate> _moveReservationsForCommand(
    MoveUnitCommand command,
    GameView view,
  ) {
    final reserved = {
      HexCoordinate(col: command.targetCol, row: command.targetRow),
    };
    final unit = view.ownUnits.byId(command.unitId);
    if (unit == null) return reserved;
    final targetTile = view.mapData.tileAt(
      command.targetCol,
      command.targetRow,
    );
    if (targetTile == null || unit.occupies(targetTile.col, targetTile.row)) {
      return reserved;
    }

    final pathfinder = UnitMovementPathfinder(
      mapData: view.mapData,
      units: view.movementBlockingUnits,
    );
    final plan = pathfinder.plan(unit: unit, targetTile: targetTile);
    if (plan == null) return reserved;
    if (!UnitMovementFeasibility.canEventuallyTraverse(
      unit: unit,
      plan: plan,
    )) {
      return reserved;
    }

    reserved.addAll(plan.reservedHexes);
    return reserved;
  }
}
