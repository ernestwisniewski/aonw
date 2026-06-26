part of 'movement_reducer.dart';

abstract final class _MovementTurnResetProcessor {
  static GameStateTransition run(
    GameState state,
    MapData mapData, {
    required String? playerId,
    required FogOfWarService fogOfWarService,
  }) {
    final currentUnits = state.units;

    final resetUnits = [
      for (final unit in currentUnits)
        (playerId == null || unit.ownerPlayerId == playerId)
            ? UnitMovementTurnRules.resetForNewTurn(
                unit,
                mapData: mapData,
                allUnits: currentUnits,
              )
            : unit,
    ];

    var mpChanged = false;
    for (var i = 0; i < resetUnits.length; i++) {
      if (resetUnits[i].movementPoints != currentUnits[i].movementPoints) {
        mpChanged = true;
        break;
      }
    }

    final finalUnits = <GameUnit>[];
    final animationEffects = <AnimateUnitMoveEffect>[];
    var pathsInvalidated = false;

    for (var i = 0; i < resetUnits.length; i++) {
      final unit = resetUnits[i];

      if (playerId != null && unit.ownerPlayerId != playerId) {
        finalUnits.add(unit);
        continue;
      }

      // Pathfinding must account for units already moved earlier in this pass.
      final currentAllUnits = [...finalUnits, ...resetUnits.sublist(i)];

      final routed = MerchantTradeRouteRules.advanceUnit(
        unit: unit,
        units: currentAllUnits,
        cities: state.cities,
        mapData: mapData,
      );
      if (routed.routeInvalidated) pathsInvalidated = true;
      if (routed.unit.type == GameUnitType.merchant &&
          routed.unit.merchantTradeRoute != null) {
        finalUnits.add(routed.unit);
        if (routed.movedSteps.isNotEmpty) {
          animationEffects.add(
            AnimateUnitMoveEffect(
              unitId: unit.id,
              fromCol: unit.col,
              fromRow: unit.row,
              steps: routed.movedSteps,
            ),
          );
        }
        continue;
      }

      final validated = UnitMovementTurnRules.validateQueuedPath(
        unit: routed.unit,
        mapData: mapData,
        allUnits: currentAllUnits,
        cities: state.cities,
      );
      if (validated.queuedPath == null) {
        if (unit.queuedPath != null) pathsInvalidated = true;
        finalUnits.add(validated);
        continue;
      }

      final path = validated.queuedPath!;
      final targetTile = mapData.tileAt(path.targetCol, path.targetRow);
      if (targetTile == null) {
        finalUnits.add(validated.copyWithQueuedPath(null));
        continue;
      }

      final plan = UnitMovementPathfinder(
        mapData: mapData,
        units: currentAllUnits,
        canEnterOccupiedTile:
            ({
              required movingUnit,
              required blockingUnit,
              required col,
              required row,
            }) => MerchantTradeRouteRules.canShareOccupiedCityTile(
              movingUnit: movingUnit,
              col: col,
              row: row,
              cities: state.cities,
            ),
      ).plan(unit: validated, targetTile: targetTile);

      if (plan == null) {
        finalUnits.add(validated.copyWithQueuedPath(null));
        continue;
      }

      if (validated.isFortified) {
        finalUnits.add(validated.copyWithQueuedPath(null));
        continue;
      }

      final reachable = plan.canMoveNow;
      final destinationStep = reachable
          ? plan.steps.last
          : plan.furthestReachableStep;

      if (destinationStep == null ||
          (destinationStep.col == validated.col &&
              destinationStep.row == validated.row)) {
        finalUnits.add(validated);
        continue;
      }

      final stepsForAnimation = reachable
          ? plan.steps.skip(1).toList()
          : plan.reachableSteps.skip(1).toList();

      final moved = validated.copyWith(
        col: destinationStep.col,
        row: destinationStep.row,
        movementPoints: plan.remainingMovementPointsAfterStep(destinationStep),
      );

      final movedWithPath = reachable
          ? moved.copyWithQueuedPath(null)
          : moved.copyWithQueuedPath(path);

      finalUnits.add(movedWithPath);
      if (stepsForAnimation.isNotEmpty) {
        animationEffects.add(
          AnimateUnitMoveEffect(
            unitId: validated.id,
            fromCol: validated.col,
            fromRow: validated.row,
            steps: stepsForAnimation,
          ),
        );
      }
    }

    var workingUnits = finalUnits;
    var workingFog = state.fogOfWar;
    if (mpChanged || animationEffects.isNotEmpty || pathsInvalidated) {
      workingFog = fogOfWarService.recompute(
        current: state.fogOfWar,
        mapData: mapData,
        playerIds: knownPlayerIds(state),
        units: workingUnits,
        cities: state.cities,
      );
    }

    final autoExplore = _AutoExploreProcessor.advanceForNewTurn(
      state: withDiscoveredDiplomaticContacts(
        state.copyWith(units: workingUnits, fogOfWar: workingFog),
      ),
      mapData: mapData,
      resetPlayerId: playerId,
      fogOfWarService: fogOfWarService,
    );
    if (autoExplore.changed) {
      workingUnits = autoExplore.units;
      workingFog = autoExplore.fogOfWar;
      animationEffects.addAll(autoExplore.uiEffects);
    }

    final changed =
        mpChanged ||
        animationEffects.isNotEmpty ||
        pathsInvalidated ||
        autoExplore.changed;
    if (!changed) {
      return GameStateTransition(
        state: _refreshSelectedUnit(
          state,
          currentUnits,
          mapData,
          resetPlayerId: playerId,
        ),
      );
    }

    final next = _refreshSelectedUnit(
      MovementReducer._clearMoveTargeting(
        withDiscoveredDiplomaticContacts(
          state.copyWith(units: workingUnits, fogOfWar: workingFog),
        ),
      ),
      workingUnits,
      mapData,
      resetPlayerId: playerId,
    );

    return GameStateTransition(state: next, uiEffects: animationEffects);
  }

  static GameState _refreshSelectedUnit(
    GameState state,
    List<GameUnit> units,
    MapData mapData, {
    String? resetPlayerId,
  }) {
    var next = state;
    final selectedId = state.selectedUnitId;
    if (selectedId != null) {
      for (final unit in units) {
        if (unit.id == selectedId) {
          final tile = mapData.tileAt(unit.col, unit.row);
          next = next.copyWith(selection: GameSelection.unit(unit, tile: tile));
          final unitWasReset =
              resetPlayerId == null || unit.ownerPlayerId == resetPlayerId;
          if (unitWasReset &&
              MovementReducer._canAutoActivateMoveTargeting(next, unit)) {
            next = next.copyWith(moveCommandActive: true);
          }
          break;
        }
      }
    }

    return next;
  }
}
