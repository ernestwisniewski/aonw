import 'package:aonw_core/domain.dart';

/// Projects fog-scoped world entities and recipient-owned economy/research.
final class PlayerWorldStateProjector {
  const PlayerWorldStateProjector();

  Map<String, dynamic> project(DomainState domain, String playerId) {
    final visibility = FogVisibilityQuery(
      playerId: playerId,
      state: domain.fogOfWar,
    );
    final ownCityIds = _ownCityIds(domain, playerId);
    final ownUnitIds = _ownUnitIds(domain, playerId);
    final units = _unitsFor(domain, playerId, visibility);
    final cities = _citiesFor(domain, playerId, visibility);
    final fogOfWar = FogOfWarState(
      players: {playerId: domain.fogOfWar.fogForPlayer(playerId)},
    );
    final research = ResearchState(
      players: {playerId: domain.research.forPlayer(playerId)},
    );
    return {
      'playerColors': {...domain.playerColors},
      'playerCountries': domain.playerCountries.map(
        (id, country) => MapEntry(id, country.name),
      ),
      'playerGold': _ownIntEntry(domain.playerGold, playerId),
      'playerWarWeariness': _ownIntEntry(domain.playerWarWeariness, playerId),
      'playerStabilityNet': _ownIntEntry(domain.playerStabilityNet, playerId),
      'units': [for (final unit in units) unit.toJson()],
      'cities': [for (final city in cities) city.toJson()],
      'artifacts': _artifactsFor(
        domain,
        visibility: visibility,
        ownCityIds: ownCityIds,
        ownUnitIds: ownUnitIds,
      ),
      'fieldImprovements': _fieldImprovementsFor(
        domain,
        visibility: visibility,
        ownCityIds: ownCityIds,
      ),
      'transportNetwork': _transportNetworkFor(
        domain,
        playerId: playerId,
        visibility: visibility,
        ownCityIds: ownCityIds,
      ),
      'fogOfWar': fogOfWar.toJson(),
      'research': research.toJson(),
    };
  }
}

List<Map<String, dynamic>> _transportNetworkFor(
  DomainState state, {
  required String playerId,
  required FogVisibilityQuery visibility,
  required Set<String> ownCityIds,
}) {
  return [
    for (final segment in state.transportNetwork.segments)
      if (segment.builtByPlayerId == playerId ||
          ownCityIds.contains(segment.builtByCityId) ||
          visibility.canRememberStaticAt(segment.hex.col, segment.hex.row))
        segment.toJson(),
  ];
}

Set<String> _ownCityIds(DomainState state, String playerId) => {
  for (final city in state.cities)
    if (city.ownerPlayerId == playerId) city.id,
};

Set<String> _ownUnitIds(DomainState state, String playerId) => {
  for (final unit in state.units)
    if (unit.ownerPlayerId == playerId) unit.id,
};

List<GameUnit> _unitsFor(
  DomainState state,
  String playerId,
  FogVisibilityQuery visibility,
) {
  return [
    for (final unit in state.units)
      if (unit.ownerPlayerId == playerId)
        unit
      else if (visibility.canSeeDynamicAt(unit.col, unit.row))
        GameUnit(
          id: unit.id,
          ownerPlayerId: unit.ownerPlayerId,
          type: unit.type,
          name: unit.name,
          col: unit.col,
          row: unit.row,
          movementPoints: 0,
          workerBuildCharges: 0,
          hitPoints: unit.hitPoints,
        ),
  ];
}

List<GameCity> _citiesFor(
  DomainState state,
  String playerId,
  FogVisibilityQuery visibility,
) {
  return state.cities
      .map((city) => _cityForProjection(city, playerId, visibility))
      .nonNulls
      .toList();
}

GameCity? _cityForProjection(
  GameCity city,
  String playerId,
  FogVisibilityQuery visibility,
) {
  if (city.ownerPlayerId == playerId) return city;
  if (!visibility.canSeeDynamicAt(city.center.col, city.center.row)) {
    return null;
  }
  return GameCity.snapshot(
    id: city.id,
    ownerPlayerId: city.ownerPlayerId,
    name: city.name,
    center: city.center,
    controlledHexes: [
      for (final hex in city.controlledHexes)
        if (visibility.canSeeDynamicAt(hex.col, hex.row)) hex,
    ],
    hitPoints: city.hitPoints,
  );
}

List<Map<String, dynamic>> _artifactsFor(
  DomainState state, {
  required FogVisibilityQuery visibility,
  required Set<String> ownCityIds,
  required Set<String> ownUnitIds,
}) {
  return [
    for (final artifact in state.artifacts)
      if (_artifactVisible(
        artifact,
        visibility: visibility,
        ownCityIds: ownCityIds,
        ownUnitIds: ownUnitIds,
      ))
        artifact.toJson(),
  ];
}

List<Map<String, dynamic>> _fieldImprovementsFor(
  DomainState state, {
  required FogVisibilityQuery visibility,
  required Set<String> ownCityIds,
}) {
  final projected = <Map<String, dynamic>>[];
  for (final improvement in state.fieldImprovements) {
    if (ownCityIds.contains(improvement.builtByCityId)) {
      projected.add(improvement.toJson());
    } else if (visibility.canSeeDynamicAt(
      improvement.hex.col,
      improvement.hex.row,
    )) {
      projected.add(
        FieldImprovement(hex: improvement.hex, type: improvement.type).toJson(),
      );
    }
  }
  return projected;
}

bool _artifactVisible(
  WorldArtifact artifact, {
  required FogVisibilityQuery visibility,
  required Set<String> ownCityIds,
  required Set<String> ownUnitIds,
}) {
  final location = artifact.location;
  return switch (location.kind) {
    WorldArtifactLocationKind.map =>
      location.col != null &&
          location.row != null &&
          visibility.canSeeDynamicAt(location.col!, location.row!),
    WorldArtifactLocationKind.excavation || WorldArtifactLocationKind.carried =>
      location.unitId != null && ownUnitIds.contains(location.unitId),
    WorldArtifactLocationKind.stored =>
      location.cityId != null && ownCityIds.contains(location.cityId),
  };
}

Map<String, int> _ownIntEntry(Map<String, int> values, String playerId) {
  final value = values[playerId];
  return value == null ? const {} : {playerId: value};
}
