part of 'map_coordinator.dart';

extension MapCoordinatorActions on MapCoordinator {
  void inspectSelectedCity(String cityId) {
    final current = _state;
    if (current is! GameSessionReady) return;
    final city = current.recipient.cityById(cityId);
    if (city == null) return;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          selected: city.center,
          clearSelectedUnit: true,
          clearReachable: true,
          clearRoute: true,
          clearActionDeck: true,
          clearUnitLogistics: true,
          clearCombat: true,
          city: city.ownedDetails == null
              ? CityState(cityId: cityId)
              : CityState.loadingCity(cityId),
        ),
      ),
    );
    if (city.ownedDetails != null) {
      _cities.inspect(
        cityId: cityId,
        readState: () => _state,
        publish: _setState,
        isDisposed: () => _disposed,
      );
    }
  }

  void openCityFounding() {
    final state = _state;
    if (state is! GameSessionReady) return;
    final unitId = state.interaction.selectedUnitId;
    if (unitId == null) return;
    _cities.openFounding(
      founderUnitId: unitId,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void toggleCityFoundingHex(MapHexCoordinate coordinate) {
    _cities.toggleFoundingHex(
      coordinate: coordinate,
      readState: () => _state,
      publish: _setState,
    );
  }

  void confirmCityFounding() {
    _cities.confirmFounding(
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void executeCityAction(CityActionView action) {
    _cities.execute(
      action: action,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

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
