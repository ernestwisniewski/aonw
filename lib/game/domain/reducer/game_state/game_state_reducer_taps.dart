part of 'game_state_reducer.dart';

abstract final class _GameStateTapReducer {
  static GameStateTransition handleTileTapped(
    GameState state,
    TileTappedCommand command,
    ReducerEnvironment environment,
  ) {
    return _pendingTileTap(state, command, environment) ??
        _movementTargetingTileTap(state, command, environment) ??
        _selectTappedTile(state, command, environment);
  }

  static GameStateTransition handleCityTapped(
    GameState state,
    CityTappedCommand command,
    ReducerEnvironment environment,
  ) {
    final city = state.cities.where((c) => c.id == command.cityId).firstOrNull;
    if (city == null) return GameStateTransition(state: state);

    final pendingAction = state.pendingAction;
    return switch (pendingAction) {
      PendingAttackTargeting() => _selectCityAttackTarget(
        state,
        city,
        pendingAction,
        environment,
      ),
      PendingMerchantTradeRouteSelection() => _assignMerchantRoute(
        state,
        command,
        pendingAction,
        environment,
      ),
      PendingMerchantMoveToCitySelection() => _moveMerchantToCity(
        state,
        command,
        pendingAction,
        environment,
      ),
      null => _selectTappedCity(state, city, environment),
      _ => GameStateTransition(state: state),
    };
  }

  static GameStateTransition handleUnitSelected(
    GameState state,
    SelectUnitCommand command,
    ReducerEnvironment environment,
  ) {
    final pendingAction = state.pendingAction;
    if (pendingAction is PendingAttackTargeting) {
      final target = state.units
          .where((unit) => unit.id == command.unitId)
          .firstOrNull;
      if (_canSelectUnitAsAttackTarget(target, pendingAction)) {
        return CombatReducer.selectAttackTargetWithEnvironment(
          state,
          AttackHexCommand(
            pendingAction.attackerUnitId,
            target!.col,
            target.row,
          ),
          environment,
        );
      }
    }

    return environment.selectUnit(state, command);
  }

  static GameStateTransition _selectTappedTile(
    GameState state,
    TileTappedCommand command,
    ReducerEnvironment environment,
  ) {
    return environment.handleSelectionTileTapped(state, command);
  }

  static GameStateTransition _selectTappedCity(
    GameState state,
    GameCity city,
    ReducerEnvironment environment,
  ) {
    return environment.handleSelectionCityTapped(state, city);
  }

  static GameStateTransition? _pendingTileTap(
    GameState state,
    TileTappedCommand command,
    ReducerEnvironment environment,
  ) {
    final pendingAction = state.pendingAction;
    return switch (pendingAction) {
      PendingCityWorkedHexSelection() => _toggleWorkedHex(
        state,
        command,
        pendingAction,
        environment,
      ),
      PendingCityExpansionSelection() => _selectExpansionHex(
        state,
        command,
        pendingAction,
        environment,
      ),
      PendingAttackTargeting() => _selectTileAttackTarget(
        state,
        command,
        pendingAction,
        environment,
      ),
      PendingWorkerActionSelection() => _workerActionTileTap(
        state,
        pendingAction,
        command,
        environment,
      ),
      PendingResearchSelection() => GameStateTransition(
        state: _selectInspectionTileDuringResearch(
          state,
          command,
          environment.mapData,
        ),
      ),
      null when state.cityFoundingDraft != null => _cityFoundingDraftTileTap(
        state,
        command,
        environment.mapData,
      ),
      null => null,
      _ => GameStateTransition(state: state),
    };
  }

  static GameStateTransition _toggleWorkedHex(
    GameState state,
    TileTappedCommand command,
    PendingCityWorkedHexSelection pendingAction,
    ReducerEnvironment environment,
  ) {
    return environment.toggleWorkedHex(
      state,
      ToggleWorkedHexCommand(pendingAction.cityId, command.col, command.row),
    );
  }

  static GameStateTransition _selectExpansionHex(
    GameState state,
    TileTappedCommand command,
    PendingCityExpansionSelection pendingAction,
    ReducerEnvironment environment,
  ) {
    return environment.selectCityExpansionHex(
      state,
      SelectCityExpansionHexCommand(
        pendingAction.cityId,
        command.col,
        command.row,
      ),
    );
  }

  static GameStateTransition _selectTileAttackTarget(
    GameState state,
    TileTappedCommand command,
    PendingAttackTargeting pendingAction,
    ReducerEnvironment environment,
  ) {
    return CombatReducer.selectAttackTargetWithEnvironment(
      state,
      AttackHexCommand(pendingAction.attackerUnitId, command.col, command.row),
      environment,
    );
  }

  static GameStateTransition _workerActionTileTap(
    GameState state,
    PendingWorkerActionSelection pendingAction,
    TileTappedCommand command,
    ReducerEnvironment environment,
  ) {
    final mapData = environment.mapData;
    final tileData = mapData.tileAt(command.col, command.row);
    if (tileData == null) return GameStateTransition(state: state);
    if (!state.activePlayerVisibility.canInspectTile(tileData)) {
      return GameStateTransition(state: state);
    }

    final worker = state.units
        .where((unit) => unit.id == pendingAction.unitId)
        .firstOrNull;
    if (!_canRetargetWorkerAction(state, worker, environment.context)) {
      return GameStateTransition(state: state);
    }

    final workerTile = mapData.tileAt(worker!.col, worker.row);
    final workState = state.copyWithInteraction(
      moveCommandActive: true,
      selection: GameSelection.unit(worker, tile: workerTile),
    );
    return MovementReducer.handleMoveTargetTileWithEnvironment(
      workState,
      tileData,
      environment,
    );
  }

  static GameStateTransition _cityFoundingDraftTileTap(
    GameState state,
    TileTappedCommand command,
    MapData mapData,
  ) {
    final tileData = mapData.tileAt(command.col, command.row);
    if (tileData == null) return GameStateTransition(state: state);
    if (!state.activePlayerVisibility.canInspectTile(tileData)) {
      return GameStateTransition(state: state);
    }
    return GameStateTransition(
      state: CityFoundingReducer.toggleControlledHex(state, command, mapData),
    );
  }

  static GameStateTransition? _movementTargetingTileTap(
    GameState state,
    TileTappedCommand command,
    ReducerEnvironment environment,
  ) {
    if (!state.moveCommandActive) return null;

    final selectedUnit = state.selectedUnit;
    if (selectedUnit == null ||
        !environment.context.canControlUnit(state, selectedUnit)) {
      return null;
    }

    final tileData = environment.mapData.tileAt(command.col, command.row);
    if (tileData == null) return null;

    final moveResult = MovementReducer.handleMoveTargetTileWithEnvironment(
      state,
      tileData,
      environment,
    );
    if (_shouldSelectTappedOwnUnitAfterMoveMiss(
      state: state,
      tileData: tileData,
      moveResult: moveResult,
      context: environment.context,
    )) {
      return _selectTappedOwnUnit(state, tileData, environment);
    }

    return moveResult;
  }

  static bool _shouldSelectTappedOwnUnitAfterMoveMiss({
    required GameState state,
    required TileData tileData,
    required GameStateTransition moveResult,
    required GameCommandContext context,
  }) {
    if (!_moveResultLeftStateUntouched(state, moveResult)) return false;

    final selectedUnitId = state.selectedUnitId;
    if (selectedUnitId == null) return false;
    if (!state.activePlayerVisibility.canSeeDynamicAt(
      tileData.col,
      tileData.row,
    )) {
      return false;
    }

    final tappedUnit = state.unitAt(tileData.col, tileData.row);
    if (tappedUnit == null || tappedUnit.id == selectedUnitId) return false;

    return context.canControlUnit(state, tappedUnit);
  }

  static bool _moveResultLeftStateUntouched(
    GameState state,
    GameStateTransition moveResult,
  ) {
    return moveResult.state == state &&
        moveResult.uiEffects.isEmpty &&
        moveResult.events.isEmpty;
  }

  static GameStateTransition _selectTappedOwnUnit(
    GameState state,
    TileData tileData,
    ReducerEnvironment environment,
  ) {
    final tappedUnit = state.unitAt(tileData.col, tileData.row)!;
    return environment.selectUnit(state, SelectUnitCommand(tappedUnit.id));
  }

  static bool _canRetargetWorkerAction(
    GameState state,
    GameUnit? worker,
    GameCommandContext context,
  ) {
    return worker != null &&
        !worker.isWorking &&
        !worker.isFortified &&
        context.canControlUnit(state, worker);
  }

  static bool _canSelectUnitAsAttackTarget(
    GameUnit? target,
    PendingAttackTargeting pendingAction,
  ) {
    return target != null &&
        target.ownerPlayerId != pendingAction.ownerPlayerId;
  }

  static GameStateTransition _selectCityAttackTarget(
    GameState state,
    GameCity city,
    PendingAttackTargeting pendingAction,
    ReducerEnvironment environment,
  ) {
    if (city.ownerPlayerId == pendingAction.ownerPlayerId) {
      return GameStateTransition(state: state);
    }
    return CombatReducer.selectAttackTargetWithEnvironment(
      state,
      AttackHexCommand(
        pendingAction.attackerUnitId,
        city.center.col,
        city.center.row,
      ),
      environment,
    );
  }

  static GameStateTransition _assignMerchantRoute(
    GameState state,
    CityTappedCommand command,
    PendingMerchantTradeRouteSelection pendingAction,
    ReducerEnvironment environment,
  ) {
    return environment.assignMerchantTradeRoute(
      state,
      AssignMerchantTradeRouteCommand(pendingAction.unitId, command.cityId),
    );
  }

  static GameStateTransition _moveMerchantToCity(
    GameState state,
    CityTappedCommand command,
    PendingMerchantMoveToCitySelection pendingAction,
    ReducerEnvironment environment,
  ) {
    return environment.moveMerchantToCity(
      state,
      MoveMerchantToCityCommand(pendingAction.unitId, command.cityId),
    );
  }

  static GameState _selectInspectionTileDuringResearch(
    GameState state,
    TileTappedCommand command,
    MapData mapData,
  ) {
    final tileData = mapData.tileAt(command.col, command.row);
    if (tileData == null) return state;

    final next = _clearMapInteractionState(state);

    if (!state.activePlayerVisibility.canInspectTile(tileData)) {
      return next.copyWithInteraction(selection: null);
    }

    return next.copyWithInteraction(selection: GameSelection.tile(tileData));
  }
}
