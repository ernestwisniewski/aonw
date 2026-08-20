part of 'unit_marker_layer_test.dart';

void _runUnitMarkerLifecycleScenarios() {
  testWithFlameGame(
    'records a loaded selected unit render path deterministically',
    (game) async {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF3366CC,
        unitType: GameUnitType.commander,
        selected: true,
        healthFraction: 0.5,
      );
      await game.ensureAdd(marker);
      final recorder = PictureRecorder();

      marker.render(Canvas(recorder));

      final picture = recorder.endRecording();
      addTearDown(picture.dispose);
      expect(picture.approximateBytesUsed, greaterThan(0));
      expect(marker.spriteRenderSizeForTesting, isNotNull);
      expect(marker.paintsIdentityBadgeForTesting, isTrue);
      expect(marker.paintsHealthBarForTesting, isTrue);
      await game.ensureRemove(marker);
    },
  );
}
