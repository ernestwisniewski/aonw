part of 'game_effect_dispatcher_test.dart';

class _FakeUnitMarkerLayer extends UnitMarkerLayer {
  _FakeUnitMarkerLayer()
    : super(mapData: _map(), colorForPlayer: (_) => 0xFF0000FF);
}

void _registerGameEffectDispatcherFollowOnlyTests() {
  test(
    'tracks a visible unit without first focusing when only follow is enabled',
    () async {
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController();
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final particleParent = Component();
      addTearDown(animationController.dispose);
      String? completedUnitId;
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
        combatHexAlertLayer: CombatHexAlertLayer(),
        particleParent: particleParent,
        alertParent: particleParent,
        reduceMotion: () => false,
        focusCameraForUnitMovementForUnit: (_) => false,
        followCameraForUnitMovementForUnit: (_) => true,
        onUnitMovementCameraComplete: (unitId) async {
          completedUnitId = unitId;
        },
        onRendererStateChanged: () {},
      );

      await dispatcher.handleEffect(
        const AnimateUnitMoveEffect(
          unitId: 'unit_1',
          fromCol: 0,
          fromRow: 0,
          steps: [
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      );

      expect(cameraController.lastSmooth, isNull);
      expect(cameraController.followCallCount, 1);
      expect(cameraController.stopFollowCallCount, 1);
      expect(completedUnitId, 'unit_1');
    },
  );
}
