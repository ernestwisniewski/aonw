import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class InteractionReducer {
  static GameState startCityWorkedHexSelection(
    GameState state,
    StartCityWorkedHexSelectionCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final city = state.cities
        .where((city) => city.id == command.cityId)
        .firstOrNull;
    if (city == null ||
        city.controlledHexes.isEmpty ||
        !context.canControlCity(state, city)) {
      return state;
    }

    var next = _clearTransientModes(state);
    next = next.copyWith(
      pendingAction: PendingCityWorkedHexSelection(
        ownerPlayerId: city.ownerPlayerId,
        cityId: city.id,
      ),
    );
    return next;
  }

  static GameState cancelCityWorkedHexSelection(
    GameState state,
    CancelCityWorkedHexSelectionCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingCityWorkedHexSelection) return state;
    if (pending.cityId != command.cityId) return state;
    return state.copyWith(pendingAction: null);
  }

  static GameState startCityExpansionSelection(
    GameState state,
    StartCityExpansionSelectionCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final city = state.cities
        .where((city) => city.id == command.cityId)
        .firstOrNull;
    if (city == null || !context.canControlCity(state, city)) {
      return state;
    }

    var next = _clearTransientModes(state);
    next = next.copyWith(
      pendingAction: PendingCityExpansionSelection(
        ownerPlayerId: city.ownerPlayerId,
        cityId: city.id,
      ),
    );
    return next;
  }

  static GameState cancelCityExpansionSelection(
    GameState state,
    CancelCityExpansionSelectionCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingCityExpansionSelection) return state;
    if (pending.cityId != command.cityId) return state;
    return state.copyWith(pendingAction: null);
  }

  static GameState startWorkerActionSelection(
    GameState state,
    StartWorkerActionSelectionCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final unit = _findUnit(state, command.unitId);
    if (unit == null ||
        unit.type != GameUnitType.worker ||
        unit.workerJob != null ||
        !context.canControlUnit(state, unit)) {
      return state;
    }

    var next = _clearTransientModes(state);
    next = next.copyWith(
      pendingAction: PendingWorkerActionSelection(
        ownerPlayerId: unit.ownerPlayerId,
        unitId: unit.id,
      ),
    );
    return next;
  }

  static GameState selectWorkerImprovement(
    GameState state,
    SelectWorkerImprovementCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingWorkerActionSelection) return state;
    if (pending.unitId != command.unitId) return state;
    return state.copyWith(
      pendingAction: pending.copyWith(improvementType: command.improvementType),
    );
  }

  static GameState cancelWorkerActionSelection(
    GameState state,
    CancelWorkerActionSelectionCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingWorkerActionSelection) return state;
    if (pending.unitId != command.unitId) return state;
    return state.copyWith(pendingAction: null);
  }

  static GameState startAttackTargeting(
    GameState state,
    StartAttackTargetingCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final unit = _findUnit(state, command.attackerUnitId);
    if (unit == null || !context.canControlUnit(state, unit)) return state;

    var next = _clearTransientModes(state);
    next = next.copyWith(
      pendingAction: PendingAttackTargeting(
        ownerPlayerId: unit.ownerPlayerId,
        attackerUnitId: unit.id,
      ),
    );
    return next;
  }

  static GameState cancelAttackTargeting(
    GameState state,
    CancelAttackTargetingCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingAttackTargeting) return state;
    if (pending.attackerUnitId != command.attackerUnitId) return state;
    return state.copyWith(pendingAction: null);
  }

  static GameState startCommanderMergeSelection(
    GameState state,
    StartCommanderMergeSelectionCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final commander = _findUnit(state, command.commanderUnitId);
    if (commander == null || commander.type != GameUnitType.commander) {
      return state;
    }
    if (!context.canControlUnit(state, commander)) return state;

    var next = _clearTransientModes(state);
    next = next.copyWith(
      pendingAction: PendingCommanderMergeSelection(
        ownerPlayerId: commander.ownerPlayerId,
        commanderUnitId: commander.id,
      ),
    );
    return next;
  }

  static GameState cancelCommanderMergeSelection(
    GameState state,
    CancelCommanderMergeSelectionCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingCommanderMergeSelection) return state;
    if (pending.commanderUnitId != command.commanderUnitId) return state;
    return state.copyWith(pendingAction: null);
  }

  static GameState _clearTransientModes(GameState state) {
    var next = state.copyWith(moveCommandActive: false);
    next = next.copyWith(movePreview: null);
    next = next.copyWith(cityFoundingDraft: null);
    return next;
  }

  static GameUnit? _findUnit(GameState state, String unitId) {
    return state.units.where((unit) => unit.id == unitId).firstOrNull;
  }
}
