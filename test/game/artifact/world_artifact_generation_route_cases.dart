part of 'world_artifact_mechanics_test.dart';

void _registerWorldArtifactGenerationRouteCases() {
  test('artifact generation avoids the Verdantia coal ridge', () {
    final mapData = _loadMapData('assets/maps/verdantia/map.json');
    final ridgeCoal = mapData.tiles.singleWhere(
      (tile) =>
          tile.col == 16 &&
          tile.row == 1 &&
          tile.resources.contains(ResourceType.coal),
    );
    expect(ridgeCoal.resources, contains(ResourceType.coal));

    const players = [
      Player(id: 'p1', name: 'P1', colorValue: 0xFF000001),
      Player(id: 'p2', name: 'P2', colorValue: 0xFF000002),
    ];
    for (var seed = 1; seed <= 20; seed++) {
      final units = StartingUnits.unitsForPlayers(
        players,
        mapData: mapData,
        startPositionSeed: seed,
      );
      final artifacts = WorldArtifactGenerator.generate(
        mapData: mapData,
        startingUnits: units,
        seed: seed,
      );
      final artifactLocations = {
        for (final artifact in artifacts)
          '${artifact.location.col}:${artifact.location.row}',
      };
      expect(artifactLocations, isNot(contains('16:1')));
    }
  });

  test('generated artifacts leave carriers a route back to a start', () {
    final mapData = _loadMapData('assets/maps/myranth/map.json');
    const players = [
      Player(id: 'p1', name: 'P1', colorValue: 0xFF000001),
      Player(id: 'p2', name: 'P2', colorValue: 0xFF000002),
    ];
    final units = StartingUnits.unitsForPlayers(
      players,
      mapData: mapData,
      startPositionSeed: 18,
    );
    final artifacts = WorldArtifactGenerator.generate(
      mapData: mapData,
      startingUnits: units,
      seed: 18,
    );

    expect(artifacts, hasLength(WorldArtifactGenerator.artifactCount));
    for (final artifact in artifacts) {
      expect(
        _carrierCanReturnToAnyStart(
          mapData: mapData,
          startingUnits: units,
          artifact: artifact,
        ),
        isTrue,
        reason:
            '${artifact.type.name} at '
            '${artifact.location.col}:${artifact.location.row}',
      );
    }
  });
}

bool _carrierCanReturnToAnyStart({
  required WorldMap mapData,
  required List<GameUnit> startingUnits,
  required WorldArtifact artifact,
}) {
  for (final template in startingUnits) {
    final carrier = GameUnit(
      id: 'carrier_${template.id}',
      ownerPlayerId: template.ownerPlayerId,
      type: template.type,
      name: template.name,
      col: artifact.location.col!,
      row: artifact.location.row!,
      carriedArtifactId: artifact.id,
    );
    final maxMovement = UnitMovementBalance.maxMovementPointsFor(
      type: carrier.type,
      carriedArtifactId: carrier.carriedArtifactId,
    );
    final reachable = UnitMovementPathfinder(
      mapData: mapData,
      units: const [],
      canEnterTile: (tile) {
        final cost = UnitMovementCostRules.costToEnterTile(
          tile,
          unitType: carrier.type,
        );
        return !cost.blocked && cost.value <= maxMovement;
      },
    ).movementCostsFrom(unit: carrier);
    if (startingUnits.any(
      (start) => reachable.containsKey((col: start.col, row: start.row)),
    )) {
      return true;
    }
  }
  return false;
}
