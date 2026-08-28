part of 'map_coordinator.dart';

extension MapCoordinatorActions on MapCoordinator {
  void executeUnitAction(UnitActionKindView action) {
    _unitActions.execute(
      action: action,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
      onSelectionRetained: (unitId) => _logistics.load(
        unitId: unitId,
        readState: () => _state,
        publish: _setState,
        isDisposed: () => _disposed,
      ),
    );
  }

  void executeUnitLogistics(UnitLogisticsActionView action) {
    _logistics.execute(
      action: action,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void confirmCombat() {
    _combat.attack(
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void setCityConquestAction(CityConquestActionView action) {
    _combat.setCityConquestAction(
      action: action,
      readState: () => _state,
      publish: _setState,
    );
  }

  void endTurn() {
    _turns.endTurn(
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void toggleReference() {
    final current = _state;
    if (current is! GameSessionReady) return;
    _setState(_toggleReferenceState(current));
  }

  void completeTurnPresentation() {
    if (_state case final GameSessionReady current) {
      _setState(current.completeTurnPresentation());
    }
  }
}
