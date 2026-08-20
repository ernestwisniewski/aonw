part of 'city_marker_test.dart';

void _runCityMarkerLifecycleScenarios() {
  testWithFlameGame('records a loaded city render path deterministically', (
    game,
  ) async {
    final marker = CityMarker(
      position: Vector2.zero(),
      colorValue: 0xFF3366CC,
      name: 'Aurelian',
      population: 8,
      healthFraction: 0.5,
      isCapital: true,
      selected: true,
      hasStoredArtifact: true,
    );
    await game.ensureAdd(marker);
    final recorder = PictureRecorder();

    marker.render(Canvas(recorder));

    final picture = recorder.endRecording();
    addTearDown(picture.dispose);
    expect(picture.approximateBytesUsed, greaterThan(0));
    expect(marker.debugSnapshot.paintsCityHealthBar, isTrue);
    expect(marker.debugSnapshot.paintsCapitalStar, isTrue);
    expect(marker.debugSnapshot.paintsSelectedCityLabelBorder, isTrue);
    expect(marker.debugSnapshot.paintsStoredArtifactBadge, isTrue);
    await game.ensureRemove(marker);
  });
}

void _runCityMarkerOwnershipScenarios() {
  test('city label does not reserve an owner color dot', () {
    final marker = CityMarker(
      position: Vector2.zero(),
      colorValue: 0xFF3366FF,
      name: 'Aurelian',
    );

    expect(marker.debugSnapshot.labelOwnerDotRadius, 0);
    expect(marker.debugSnapshot.labelOwnerDotGap, 0);
    expect(marker.debugSnapshot.paintsCityLabelOwnerDot, isFalse);

    marker.applyVisualState(marker.visualState.copyWith(showLabel: false));

    expect(marker.debugSnapshot.paintsCityLabelOwnerDot, isFalse);
  });

  test('propagates city health bar density to existing markers', () {
    final layer = CityMarkerLayer(colorForPlayer: (_) => 0);
    final parent = Component();
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 0, row: 0),
    );

    layer.sync(parent: parent, cities: [city], selectedCityId: null);

    expect(layer.markerShowHealthBarForTesting(city.id), isTrue);
    expect(layer.markerPaintsHealthBarForTesting(city.id), isTrue);

    layer.showHealthBar = false;

    expect(layer.markerShowHealthBarForTesting(city.id), isFalse);
    expect(layer.markerPaintsHealthBarForTesting(city.id), isFalse);

    layer.sync(
      parent: parent,
      cities: [city.copyWithHitPoints(12)],
      selectedCityId: null,
      healthFractions: const {'city_1': 0.75},
    );

    expect(layer.markerShowHealthBarForTesting(city.id), isFalse);
    expect(layer.markerPaintsHealthBarForTesting(city.id), isTrue);
  });

  test('marks the first city per founding owner as capital', () {
    final layer = CityMarkerLayer(colorForPlayer: (_) => 0);
    final parent = Component();
    const playerCapital = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      foundingOwnerPlayerId: 'player_1',
      name: 'Capital',
      center: CityHex(col: 0, row: 0),
    );
    const playerSecond = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_1',
      foundingOwnerPlayerId: 'player_1',
      name: 'Second',
      center: CityHex(col: 1, row: 0),
    );
    final capturedRivalCapital = const GameCity(
      id: 'city_3',
      ownerPlayerId: 'player_2',
      name: 'Rival',
      center: CityHex(col: 2, row: 0),
    ).copyWith(ownerPlayerId: 'player_1');

    layer.sync(
      parent: parent,
      cities: [playerCapital, playerSecond, capturedRivalCapital],
      selectedCityId: null,
    );

    expect(layer.markerIsCapitalForTesting(playerCapital.id), isTrue);
    expect(layer.markerPaintsCapitalStarForTesting(playerCapital.id), isTrue);
    expect(layer.markerIsCapitalForTesting(playerSecond.id), isFalse);
    expect(layer.markerPaintsCapitalStarForTesting(playerSecond.id), isFalse);
    expect(layer.markerIsCapitalForTesting(capturedRivalCapital.id), isTrue);
    expect(
      layer.markerPaintsCapitalStarForTesting(capturedRivalCapital.id),
      isTrue,
    );
  });
}
