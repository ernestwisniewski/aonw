import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class HudSelectionCommands {
  static GameCommand? startAttackTargeting(GameState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return StartAttackTargetingCommand(unitId);
  }

  static GameCommand? autoExploreSelectedUnit(GameState? state, MapData _) {
    final unit = state?.selectedUnit;
    if (state == null || unit == null) return null;
    if (unit.type != GameUnitType.scout) return null;
    return AutoExploreUnitCommand(unit.id);
  }

  static GameCommand? startCityWorkedHexSelection(GameState? state) {
    final cityId = state?.selection?.city?.id;
    if (cityId == null) return null;
    return StartCityWorkedHexSelectionCommand(cityId);
  }

  static GameCommand? startCityExpansionSelection(GameState? state) {
    final cityId = state?.selection?.city?.id;
    if (cityId == null) return null;
    return StartCityExpansionSelectionCommand(cityId);
  }

  static GameCommand? startWorkerActionSelection(GameState? state) {
    final unit = state?.selectedUnit;
    if (unit == null || unit.type != GameUnitType.worker) return null;
    return StartWorkerActionSelectionCommand(unit.id);
  }

  static GameCommand? startMerchantTradeRouteSelection(GameState? state) {
    final unit = state?.selectedUnit;
    if (unit == null || unit.type != GameUnitType.merchant) return null;
    return StartMerchantTradeRouteSelectionCommand(unit.id);
  }

  static GameCommand? assignMerchantTradeRoute(
    GameState? state,
    String destinationCityId,
  ) {
    final unit = state?.selectedUnit;
    if (unit == null || unit.type != GameUnitType.merchant) return null;
    return AssignMerchantTradeRouteCommand(unit.id, destinationCityId);
  }

  static GameCommand? startMerchantMoveToCitySelection(GameState? state) {
    final unit = state?.selectedUnit;
    if (unit == null || unit.type != GameUnitType.merchant) return null;
    return StartMerchantMoveToCitySelectionCommand(unit.id);
  }

  static GameCommand? moveMerchantToCity(
    GameState? state,
    String destinationCityId,
  ) {
    final unit = state?.selectedUnit;
    if (unit == null || unit.type != GameUnitType.merchant) return null;
    return MoveMerchantToCityCommand(unit.id, destinationCityId);
  }

  static GameCommand? cancelWorkerJob(GameState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return CancelWorkerJobCommand(unitId);
  }

  static GameCommand? startArtifactExcavation(GameState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return StartArtifactExcavationCommand(unitId);
  }

  static GameCommand? storeArtifactInCity(GameState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return StoreArtifactInCityCommand(unitId);
  }

  static GameCommand? cancelSelectedUnitAction(GameState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return CancelUnitActionCommand(unitId);
  }

  static GameCommand? skipSelectedUnitTurn(GameState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return SkipUnitTurnCommand(unitId);
  }

  static GameCommand? fortifySelectedUnit(GameState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return FortifyUnitCommand(unitId);
  }
}
