part of 'reducer_parity_accepted_semantics.dart';

String? validateAcceptedArtifactCommand({
  required DomainCommand command,
  required DomainState before,
  required DomainState after,
  required List<GameEvent> events,
}) {
  final stateFailure = switch (command) {
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
  if (stateFailure != null) return stateFailure;
  if (events.length != 1) {
    return 'must emit exactly one canonical artifact lifecycle event';
  }
  final event = events.single;
  return switch (command) {
    final StartArtifactExcavationCommand command =>
      _validateArtifactExcavationEvent(command, before, event),
    final StoreArtifactInCityCommand command => _validateArtifactStoreEvent(
      command,
      before,
      event,
    ),
    final TradeArtifactCommand command => _validateArtifactTradeEvent(
      command,
      before,
      event,
    ),
    _ => 'uses an unsupported artifact command',
  };
}

String? _validateArtifactExcavationEvent(
  StartArtifactExcavationCommand command,
  DomainState before,
  GameEvent event,
) {
  final unit = before.units.byId(command.unitId);
  final artifact = unit == null
      ? null
      : _artifactFixtureMapArtifactAt(before.artifacts, unit.col, unit.row);
  return event is ArtifactExcavationStartedEvent &&
          unit != null &&
          artifact != null &&
          event.artifactId == artifact.id &&
          event.ownerPlayerId == unit.ownerPlayerId &&
          event.unitId == unit.id &&
          event.col == unit.col &&
          event.row == unit.row
      ? null
      : 'must emit the exact reviewed artifact excavation event';
}

String? _validateArtifactStoreEvent(
  StoreArtifactInCityCommand command,
  DomainState before,
  GameEvent event,
) {
  final unit = before.units.byId(command.unitId);
  final city = unit == null
      ? null
      : command.cityId == null
      ? before.cities.cityAt(unit.col, unit.row)
      : before.cities.byId(command.cityId!);
  return event is ArtifactStoredEvent &&
          unit?.carriedArtifactId != null &&
          city != null &&
          event.artifactId == unit!.carriedArtifactId &&
          event.ownerPlayerId == city.ownerPlayerId &&
          event.unitId == unit.id &&
          event.cityId == city.id &&
          event.col == city.center.col &&
          event.row == city.center.row
      ? null
      : 'must emit the exact reviewed artifact storage event';
}

String? _validateArtifactTradeEvent(
  TradeArtifactCommand command,
  DomainState before,
  GameEvent event,
) {
  final targetCities = [
    for (final city in before.cities)
      if (city.ownerPlayerId == command.targetPlayerId &&
          !_artifactFixtureCityHasStoredArtifact(before.artifacts, city.id))
        city,
  ]..sort((left, right) => left.id.compareTo(right.id));
  final city = targetCities.isEmpty ? null : targetCities.first;
  return event is ArtifactStoredEvent &&
          city != null &&
          event.artifactId == command.offeredArtifactId &&
          event.ownerPlayerId == command.targetPlayerId &&
          event.unitId == null &&
          event.cityId == city.id &&
          event.col == city.center.col &&
          event.row == city.center.row
      ? null
      : 'must emit the exact reviewed artifact trade storage event';
}

String? _validateAcceptedArtifactExcavation(
  StartArtifactExcavationCommand command,
  DomainState before,
  DomainState after,
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
  DomainState before,
  DomainState after,
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
  DomainState before,
  DomainState after,
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
