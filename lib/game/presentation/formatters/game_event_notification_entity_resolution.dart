part of 'game_event_notification_message.dart';

String _cityName(
  AppLocalizations l10n,
  GameClientState state,
  String cityId, [
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  return _resolvedCityName(
        l10n,
        _resolveCity(state, cityId, activityContext: activityContext),
      ) ??
      cityId;
}

String _unitName(
  AppLocalizations l10n,
  GameClientState state,
  String unitId, [
  GameClientState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  return _unitNameOrNull(l10n, state, unitId, previousState, activityContext) ??
      unitId;
}

String? _unitNameOrNull(
  AppLocalizations l10n,
  GameClientState state,
  String unitId, [
  GameClientState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  return _resolvedUnitName(
    l10n,
    _resolveUnit(
      state,
      unitId,
      previousState: previousState,
      activityContext: activityContext,
    ),
  );
}

UnitEventNotificationThumbnail? _unitThumbnail(
  GameClientState state,
  String unitId, [
  GameClientState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  return _resolvedUnitThumbnail(
    _resolveUnit(
      state,
      unitId,
      previousState: previousState,
      activityContext: activityContext,
    ),
  );
}

String? _resolvedUnitName(AppLocalizations l10n, Object? unit) {
  return switch (unit) {
    final GameActivityUnitSnapshot snapshot => _unitSnapshotName(
      l10n,
      snapshot,
    ),
    final GameUnit unit => GameDisplayNames.unit(l10n, unit),
    _ => null,
  };
}

String? _resolvedCombatUnitName(AppLocalizations l10n, Object? unit) {
  return switch (unit) {
    final GameActivityUnitSnapshot snapshot => _unitSnapshotName(
      l10n,
      snapshot,
    ),
    final GameUnit unit => GameDisplayNames.unitWithType(l10n, unit),
    _ => null,
  };
}

String? _resolvedUnitOwnerPlayerId(Object? unit) {
  return switch (unit) {
    GameActivityUnitSnapshot(:final ownerPlayerId) ||
    GameUnit(:final ownerPlayerId) => ownerPlayerId,
    _ => null,
  };
}

UnitEventNotificationThumbnail? _resolvedUnitThumbnail(Object? unit) {
  return switch (unit) {
    GameActivityUnitSnapshot(:final type) ||
    GameUnit(:final type) => UnitEventNotificationThumbnail(type),
    _ => null,
  };
}

String? _resolvedCityName(AppLocalizations l10n, Object? city) {
  return switch (city) {
    final GameActivityCitySnapshot snapshot => _citySnapshotName(
      l10n,
      snapshot,
    ),
    final GameCity city => GameDisplayNames.city(l10n, city),
    _ => null,
  };
}

String? _resolvedCityOwnerPlayerId(Object? city) {
  return switch (city) {
    GameActivityCitySnapshot(:final ownerPlayerId) ||
    GameCity(:final ownerPlayerId) => ownerPlayerId,
    _ => null,
  };
}

Object? _resolveUnit(
  GameClientState state,
  String unitId, {
  GameClientState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
  bool preferPreviousState = false,
}) {
  final unitSnapshot = activityContext.units[unitId];
  if (unitSnapshot != null) return unitSnapshot;
  return preferPreviousState
      ? previousState?.unitById(unitId) ?? state.unitById(unitId)
      : state.unitById(unitId) ?? previousState?.unitById(unitId);
}

Object? _resolveCity(
  GameClientState state,
  String cityId, {
  GameClientState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
  bool preferPreviousState = false,
}) {
  final citySnapshot = activityContext.cities[cityId];
  if (citySnapshot != null) return citySnapshot;
  return preferPreviousState
      ? previousState?.cityById(cityId) ?? state.cityById(cityId)
      : state.cityById(cityId) ?? previousState?.cityById(cityId);
}

String _unitSnapshotName(AppLocalizations l10n, GameActivityUnitSnapshot unit) {
  return GameDisplayNames.unitWithType(
    l10n,
    GameUnit(
      id: unit.id,
      ownerPlayerId: unit.ownerPlayerId,
      type: unit.type,
      name: unit.name,
      col: 0,
      row: 0,
    ),
  );
}

String _citySnapshotName(AppLocalizations l10n, GameActivityCitySnapshot city) {
  return GameDisplayNames.city(
    l10n,
    GameCity.snapshot(
      id: city.id,
      ownerPlayerId: city.ownerPlayerId,
      name: city.name,
      center: const CityHex(col: 0, row: 0),
    ),
  );
}
