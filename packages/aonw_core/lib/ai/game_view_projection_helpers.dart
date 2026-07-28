part of 'game_view.dart';

List<GameCity> _rememberedEnemyCities(
  _GameViewProjection source,
  FogVisibilityQuery visibility,
) => [
  for (final city in source.cities)
    if (city.ownerPlayerId != source.forPlayerId &&
        visibility.canRememberStaticAt(city.center.col, city.center.row))
      city,
];

bool _isOwnImprovement(
  FieldImprovement improvement,
  List<GameCity> ownCities,
  Set<String> ownCityIds,
) {
  final builtByCityId = improvement.builtByCityId;
  if (builtByCityId != null) return ownCityIds.contains(builtByCityId);
  return ownCities.any((city) => city.controlsHex(improvement.hex));
}

bool _canSeeArtifact(
  WorldArtifact artifact, {
  required List<GameCity> cities,
  required List<GameUnit> units,
  required Set<String> ownCityIds,
  required Set<String> ownUnitIds,
  required FogVisibilityQuery visibility,
}) {
  final location = artifact.location;
  switch (location.kind) {
    case WorldArtifactLocationKind.map:
    case WorldArtifactLocationKind.excavation:
      return _canSeeMappedArtifact(location, visibility);
    case WorldArtifactLocationKind.carried:
      return _canSeeCarriedArtifact(
        location,
        units: units,
        ownUnitIds: ownUnitIds,
        visibility: visibility,
      );
    case WorldArtifactLocationKind.stored:
      return _canSeeStoredArtifact(
        location,
        cities: cities,
        ownCityIds: ownCityIds,
        visibility: visibility,
      );
  }
}

bool _canSeeMappedArtifact(
  WorldArtifactLocation location,
  FogVisibilityQuery visibility,
) {
  final col = location.col;
  final row = location.row;
  return col != null && row != null && visibility.canSeeDynamicAt(col, row);
}

bool _canSeeCarriedArtifact(
  WorldArtifactLocation location, {
  required List<GameUnit> units,
  required Set<String> ownUnitIds,
  required FogVisibilityQuery visibility,
}) {
  final unitId = location.unitId;
  if (unitId == null) return false;
  if (ownUnitIds.contains(unitId)) return true;
  final unit = units.byId(unitId);
  return unit != null && visibility.canSeeDynamicAt(unit.col, unit.row);
}

bool _canSeeStoredArtifact(
  WorldArtifactLocation location, {
  required List<GameCity> cities,
  required Set<String> ownCityIds,
  required FogVisibilityQuery visibility,
}) {
  final cityId = location.cityId;
  if (cityId == null) return false;
  if (ownCityIds.contains(cityId)) return true;
  final city = cities.byId(cityId);
  return city != null &&
      visibility.canSeeDynamicAt(city.center.col, city.center.row);
}
