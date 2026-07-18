part of 'reducer_parity_accepted_semantics.dart';

String? validateAcceptedArtifactCommand({
  required GameCommand command,
  required PersistentGameState before,
  required PersistentGameState after,
  required List<GameEvent> events,
}) {
  if (events.isNotEmpty) {
    return 'must not emit events for artifact commands';
  }
  return switch (command) {
    final StartArtifactExcavationCommand command =>
      _validateAcceptedArtifactExcavation(command, before, after),
    final StoreArtifactInCityCommand command => _validateAcceptedArtifactStore(
      command,
      before,
      after,
    ),
    final TradeArtifactCommand command => _validateAcceptedArtifactTrade(
      command,
      before,
      after,
    ),
    _ => 'uses an unsupported artifact command',
  };
}

String? _validateAcceptedArtifactExcavation(
  StartArtifactExcavationCommand command,
  PersistentGameState before,
  PersistentGameState after,
) {
  final beforeUnit = before.units.byId(command.unitId);
  final beforeArtifact = beforeUnit == null
      ? null
      : _artifactFixtureMapArtifactAt(
          before.artifacts,
          beforeUnit.col,
          beforeUnit.row,
        );
  if (beforeUnit == null || beforeArtifact == null) {
    return 'must start with a unit standing on a map artifact';
  }

  final expectedUnit = beforeUnit
      .copyWith(movementPoints: 0)
      .copyWithQueuedPath(null)
      .copyWithExcavatingArtifact(beforeArtifact.id);
  final expectedArtifact = beforeArtifact.copyWith(
    location: WorldArtifactLocation.excavation(
      unitId: beforeUnit.id,
      col: beforeUnit.col,
      row: beforeUnit.row,
      remainingTurns: 2,
    ),
  );
  final expected = before.copyWith(
    units: _replaceArtifactFixtureUnit(before.units, expectedUnit),
    artifacts: _replaceArtifactFixtureArtifact(
      before.artifacts,
      expectedArtifact,
    ),
  );
  return after == expected
      ? null
      : 'must only start the reviewed artifact excavation';
}

String? _validateAcceptedArtifactStore(
  StoreArtifactInCityCommand command,
  PersistentGameState before,
  PersistentGameState after,
) {
  final beforeUnit = before.units.byId(command.unitId);
  final artifactId = beforeUnit?.carriedArtifactId;
  final beforeArtifact = artifactId == null
      ? null
      : _artifactFixtureById(before.artifacts, artifactId);
  final city = beforeUnit == null
      ? null
      : command.cityId == null
      ? before.cities.cityAt(beforeUnit.col, beforeUnit.row)
      : before.cities.byId(command.cityId!);
  if (beforeUnit == null || beforeArtifact == null || city == null) {
    return 'must start with a carried artifact in the reviewed city';
  }

  final expectedUnit = beforeUnit.copyWithCarriedArtifact(null);
  final expectedArtifact = beforeArtifact.copyWith(
    location: WorldArtifactLocation.stored(cityId: city.id),
  );
  final expected = before.copyWith(
    units: _replaceArtifactFixtureUnit(before.units, expectedUnit),
    artifacts: _replaceArtifactFixtureArtifact(
      before.artifacts,
      expectedArtifact,
    ),
  );
  return after == expected
      ? null
      : 'must only store the reviewed carried artifact';
}

String? _validateAcceptedArtifactTrade(
  TradeArtifactCommand command,
  PersistentGameState before,
  PersistentGameState after,
) {
  final offered = _artifactFixtureById(
    before.artifacts,
    command.offeredArtifactId,
  );
  final targetCities = [
    for (final city in before.cities)
      if (city.ownerPlayerId == command.targetPlayerId &&
          !_artifactFixtureCityHasStoredArtifact(before.artifacts, city.id))
        city,
  ]..sort((left, right) => left.id.compareTo(right.id));
  if (offered == null || targetCities.isEmpty) {
    return 'must offer an artifact to a player with an empty city slot';
  }

  final expectedArtifact = offered.copyWith(
    location: WorldArtifactLocation.stored(cityId: targetCities.first.id),
  );
  final expectedGold = Map<String, int>.from(before.playerGold);
  expectedGold[command.playerId] =
      (expectedGold[command.playerId] ?? 0) - command.offeredGold;
  expectedGold[command.targetPlayerId] =
      (expectedGold[command.targetPlayerId] ?? 0) + command.offeredGold;
  final expected = before.copyWith(
    playerGold: expectedGold,
    artifacts: _replaceArtifactFixtureArtifact(
      before.artifacts,
      expectedArtifact,
    ),
  );
  return after == expected
      ? null
      : 'must transfer gold and choose the first empty target city by id';
}

WorldArtifact? _artifactFixtureMapArtifactAt(
  Iterable<WorldArtifact> artifacts,
  int col,
  int row,
) {
  for (final artifact in artifacts) {
    if (artifact.location.isOnMap &&
        artifact.location.occupiesMapTile(col, row)) {
      return artifact;
    }
  }
  return null;
}

WorldArtifact? _artifactFixtureById(
  Iterable<WorldArtifact> artifacts,
  String artifactId,
) {
  for (final artifact in artifacts) {
    if (artifact.id == artifactId) return artifact;
  }
  return null;
}

bool _artifactFixtureCityHasStoredArtifact(
  Iterable<WorldArtifact> artifacts,
  String cityId,
) {
  return artifacts.any(
    (artifact) =>
        artifact.location.isStored && artifact.location.cityId == cityId,
  );
}

List<GameUnit> _replaceArtifactFixtureUnit(
  List<GameUnit> units,
  GameUnit updated,
) {
  return [
    for (final unit in units)
      if (unit.id == updated.id) updated else unit,
  ];
}

List<WorldArtifact> _replaceArtifactFixtureArtifact(
  List<WorldArtifact> artifacts,
  WorldArtifact updated,
) {
  return [
    for (final artifact in artifacts)
      if (artifact.id == updated.id) updated else artifact,
  ];
}
