part of 'hud_action_deck.dart';

final class _HudManualAutoTarget {
  const _HudManualAutoTarget._(this.kind, this.id);

  factory _HudManualAutoTarget.unit(String id) {
    return _HudManualAutoTarget._(_HudManualAutoTargetKind.unit, id);
  }

  factory _HudManualAutoTarget.city(String id) {
    return _HudManualAutoTarget._(_HudManualAutoTargetKind.city, id);
  }

  final _HudManualAutoTargetKind kind;
  final String id;

  String get storageKey => '${kind.storagePrefix}:$id';

  static _HudManualAutoTarget? parse(String storageKey) {
    final separator = storageKey.indexOf(':');
    if (separator <= 0) return null;

    final id = storageKey.substring(separator + 1);
    return switch (storageKey.substring(0, separator)) {
      'unit' => _HudManualAutoTarget.unit(id),
      'city' => _HudManualAutoTarget.city(id),
      _ => null,
    };
  }

  static _HudManualAutoTarget? resolve({
    required GameState state,
    required String activePlayerId,
    required _HudUnitOrderPredicate unitNeedsManualOrder,
  }) {
    final cityFoundingDraft = state.cityFoundingDraft;
    if (cityFoundingDraft != null &&
        cityFoundingDraft.ownerPlayerId == activePlayerId) {
      return _HudManualAutoTarget.unit(cityFoundingDraft.unitId);
    }

    final pendingTarget = _fromPendingAction(
      state.pendingAction,
      activePlayerId,
    );
    if (pendingTarget != null) return pendingTarget;

    final selectedUnit = state.selectedUnit;
    if (state.movePreview != null &&
        selectedUnit != null &&
        selectedUnit.ownerPlayerId == activePlayerId) {
      return _HudManualAutoTarget.unit(selectedUnit.id);
    }

    if (selectedUnit != null &&
        selectedUnit.ownerPlayerId == activePlayerId &&
        unitNeedsManualOrder(selectedUnit)) {
      return _HudManualAutoTarget.unit(selectedUnit.id);
    }

    final selectedCity = state.selection?.city;
    if (selectedCity != null &&
        selectedCity.ownerPlayerId == activePlayerId &&
        selectedCity.productionQueue == null) {
      return _HudManualAutoTarget.city(selectedCity.id);
    }

    return null;
  }

  static _HudManualAutoTarget? _fromPendingAction(
    PendingPlayerAction? pendingAction,
    String activePlayerId,
  ) {
    if (pendingAction == null ||
        pendingAction.ownerPlayerId != activePlayerId) {
      return null;
    }

    return switch (pendingAction) {
      PendingAttackTargeting(:final attackerUnitId) =>
        _HudManualAutoTarget.unit(attackerUnitId),
      PendingWorkerActionSelection(:final unitId) => _HudManualAutoTarget.unit(
        unitId,
      ),
      PendingMerchantTradeRouteSelection(:final unitId) =>
        _HudManualAutoTarget.unit(unitId),
      PendingMerchantMoveToCitySelection(:final unitId) =>
        _HudManualAutoTarget.unit(unitId),
      PendingCommanderMergeSelection(:final commanderUnitId) =>
        _HudManualAutoTarget.unit(commanderUnitId),
      PendingCityWorkedHexSelection(:final cityId) => _HudManualAutoTarget.city(
        cityId,
      ),
      PendingCityExpansionSelection(:final cityId) => _HudManualAutoTarget.city(
        cityId,
      ),
      PendingResearchSelection() || PendingUnitTurnSkip() => null,
    };
  }

  bool stillNeedsOrder({
    required GameState state,
    required String activePlayerId,
    required _HudUnitOrderPredicate unitNeedsManualOrder,
  }) {
    return switch (kind) {
      _HudManualAutoTargetKind.unit => state.units.any(
        (unit) =>
            unit.id == id &&
            unit.ownerPlayerId == activePlayerId &&
            unitNeedsManualOrder(unit),
      ),
      _HudManualAutoTargetKind.city => state.cities.any(
        (city) =>
            city.id == id &&
            city.ownerPlayerId == activePlayerId &&
            city.productionQueue == null,
      ),
    };
  }
}

enum _HudManualAutoTargetKind {
  unit('unit'),
  city('city');

  const _HudManualAutoTargetKind(this.storagePrefix);

  final String storagePrefix;
}
