import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class InteractionReducer {
  static GameClientState startCityWorkedHexSelection(
    GameClientState state,
    StartCityWorkedHexSelectionCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final city = state.cityById(command.cityId);
    if (city == null ||
        city.controlledHexes.isEmpty ||
        !context.canControlCity(state, city)) {
      return state;
    }

    var next = _clearTransientModes(state);
    next = next.copyWithInteraction(
      pendingAction: PendingCityWorkedHexSelection(
        ownerPlayerId: city.ownerPlayerId,
        cityId: city.id,
      ),
    );
    return next;
  }

  static GameClientState cancelCityWorkedHexSelection(
    GameClientState state,
    CancelCityWorkedHexSelectionCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingCityWorkedHexSelection) return state;
    if (pending.cityId != command.cityId) return state;
    return state.copyWithInteraction(pendingAction: null);
  }

  static GameClientState startCityExpansionSelection(
    GameClientState state,
    StartCityExpansionSelectionCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final city = state.cityById(command.cityId);
    if (city == null || !context.canControlCity(state, city)) {
      return state;
    }

    var next = _clearTransientModes(state);
    next = next.copyWithInteraction(
      pendingAction: PendingCityExpansionSelection(
        ownerPlayerId: city.ownerPlayerId,
        cityId: city.id,
      ),
    );
    return next;
  }

  static GameClientState cancelCityExpansionSelection(
    GameClientState state,
    CancelCityExpansionSelectionCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingCityExpansionSelection) return state;
    if (pending.cityId != command.cityId) return state;
    return state.copyWithInteraction(pendingAction: null);
  }

  static GameClientState startWorkerActionSelection(
    GameClientState state,
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
    next = next.copyWithInteraction(
      pendingAction: PendingWorkerActionSelection(
        ownerPlayerId: unit.ownerPlayerId,
        unitId: unit.id,
      ),
    );
    return next;
  }

  static GameClientState selectWorkerImprovement(
    GameClientState state,
    ChooseWorkerImprovementIntent command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingWorkerActionSelection) return state;
    if (pending.unitId != command.unitId) return state;
    return state.copyWith(
      interaction: state.interaction.copyWith(
        pendingAction: pending.copyWith(
          improvementType: command.improvementType,
        ),
      ),
    );
  }

  static GameClientState cancelWorkerActionSelection(
    GameClientState state,
    CancelWorkerActionSelectionCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingWorkerActionSelection) return state;
    if (pending.unitId != command.unitId) return state;
    return state.copyWithInteraction(pendingAction: null);
  }

  static GameClientState cancelResearchSelection(
    GameClientState state,
    CancelResearchSelectionCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    if (!context.canAct ||
        (context.hasActor && context.actorPlayerId != command.playerId) ||
        (!context.hasActor &&
            state.activePlayerId.isNotEmpty &&
            (state.activePlayerId != command.playerId ||
                !state.activePlayerCanAct))) {
      return state;
    }
    final pending = state.pendingAction;
    if (pending is! PendingResearchSelection ||
        pending.ownerPlayerId != command.playerId) {
      return state;
    }
    return state.copyWithInteraction(pendingAction: null);
  }

  static GameClientState startAttackTargeting(
    GameClientState state,
    StartAttackTargetingCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final unit = _findUnit(state, command.attackerUnitId);
    if (unit == null || !context.canControlUnit(state, unit)) return state;

    var next = _clearTransientModes(state);
    next = next.copyWithInteraction(
      pendingAction: PendingAttackTargeting(
        ownerPlayerId: unit.ownerPlayerId,
        attackerUnitId: unit.id,
      ),
    );
    return next;
  }

  static GameClientState cancelAttackTargeting(
    GameClientState state,
    CancelAttackTargetingCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingAttackTargeting) return state;
    if (pending.attackerUnitId != command.attackerUnitId) return state;
    return state.copyWithInteraction(pendingAction: null);
  }

  static GameClientState startCommanderMergeSelection(
    GameClientState state,
    StartCommanderMergeSelectionCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final commander = _findUnit(state, command.commanderUnitId);
    if (commander == null || commander.type != GameUnitType.commander) {
      return state;
    }
    if (!context.canControlUnit(state, commander)) return state;

    var next = _clearTransientModes(state);
    next = next.copyWithInteraction(
      pendingAction: PendingCommanderMergeSelection(
        ownerPlayerId: commander.ownerPlayerId,
        commanderUnitId: commander.id,
      ),
    );
    return next;
  }

  static GameClientState cancelCommanderMergeSelection(
    GameClientState state,
    CancelCommanderMergeSelectionCommand command,
  ) {
    final pending = state.pendingAction;
    if (pending is! PendingCommanderMergeSelection) return state;
    if (pending.commanderUnitId != command.commanderUnitId) return state;
    return state.copyWithInteraction(pendingAction: null);
  }

  static GameClientState _clearTransientModes(GameClientState state) {
    return state.copyWith(interaction: state.interaction.clearTransientModes());
  }

  static GameUnit? _findUnit(GameClientState state, String unitId) {
    return state.unitById(unitId);
  }
}
