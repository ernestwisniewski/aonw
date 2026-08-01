import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class HudSelectionCommands {
  static GameIntent? startAttackTargeting(GameClientState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return StartAttackTargetingCommand(unitId);
  }

  static DomainCommand? autoExploreSelectedUnit(GameClientState? state) {
    final unit = state?.selectedUnit;
    if (state == null || unit == null) return null;
    if (unit.type != GameUnitType.scout) return null;
    return AutoExploreUnitCommand(unit.id);
  }

  static GameIntent? startCityWorkedHexSelection(GameClientState? state) {
    final cityId = state?.selection?.city?.id;
    if (cityId == null) return null;
    return StartCityWorkedHexSelectionCommand(cityId);
  }

  static GameIntent? startCityExpansionSelection(GameClientState? state) {
    final cityId = state?.selection?.city?.id;
    if (cityId == null) return null;
    return StartCityExpansionSelectionCommand(cityId);
  }

  static GameIntent? startWorkerActionSelection(GameClientState? state) {
    final unit = state?.selectedUnit;
    if (unit == null || unit.type != GameUnitType.worker) return null;
    return StartWorkerActionSelectionCommand(unit.id);
  }

  static GameIntent? startMerchantTradeRouteSelection(GameClientState? state) {
    final unit = state?.selectedUnit;
    if (unit == null || unit.type != GameUnitType.merchant) return null;
    return StartMerchantTradeRouteSelectionCommand(unit.id);
  }

  static DomainCommand? assignMerchantTradeRoute(
    GameClientState? state,
    String destinationCityId,
  ) {
    final unit = state?.selectedUnit;
    if (unit == null || unit.type != GameUnitType.merchant) return null;
    return AssignMerchantTradeRouteCommand(unit.id, destinationCityId);
  }

  static GameIntent? startMerchantMoveToCitySelection(GameClientState? state) {
    final unit = state?.selectedUnit;
    if (unit == null || unit.type != GameUnitType.merchant) return null;
    return StartMerchantMoveToCitySelectionCommand(unit.id);
  }

  static DomainCommand? moveMerchantToCity(
    GameClientState? state,
    String destinationCityId,
  ) {
    final unit = state?.selectedUnit;
    if (unit == null || unit.type != GameUnitType.merchant) return null;
    return MoveMerchantToCityCommand(unit.id, destinationCityId);
  }

  static DomainCommand? cancelWorkerJob(GameClientState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return CancelWorkerJobCommand(unitId);
  }

  static DomainCommand? startArtifactExcavation(GameClientState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return StartArtifactExcavationCommand(unitId);
  }

  static DomainCommand? storeArtifactInCity(GameClientState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return StoreArtifactInCityCommand(unitId);
  }

  static DomainCommand? cancelSelectedUnitAction(GameClientState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return CancelUnitActionCommand(unitId);
  }

  static DomainCommand? skipSelectedUnitTurn(GameClientState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return SkipUnitTurnCommand(unitId);
  }

  static DomainCommand? fortifySelectedUnit(GameClientState? state) {
    final unitId = state?.selectedUnit?.id;
    if (unitId == null) return null;
    return FortifyUnitCommand(unitId);
  }
}
