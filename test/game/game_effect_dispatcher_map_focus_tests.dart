part of 'game_effect_dispatcher_test.dart';

void _registerGameEffectDispatcherMapFocusTests() {
  test('dispatches jump camera effects to the camera controller', () async {
    final cameraController = _FakeCameraController();
    final animationController = _FakeUnitAnimationController();
    final particleParent = Component();
    addTearDown(animationController.dispose);
    final dispatcher = GameEffectDispatcher(
      unitAnimationController: animationController,
      cameraController: cameraController,
      particleEffectsLayer: _FakeParticleEffectsLayer(),
      floatingTextLayer: _FakeFloatingTextLayer(),
      combatHexAlertLayer: CombatHexAlertLayer(),
      particleParent: particleParent,
      alertParent: particleParent,
      reduceMotion: () => false,
      followUnitMovementCamera: () => false,
      onRendererStateChanged: () {},
    );

    await dispatcher.handleEffect(const JumpCameraEffect(col: 1, row: 0));
    expect(cameraController.lastJump, (col: 1, row: 0));
  });

  test('dispatches the transient map action-target focus', () async {
    final cameraController = _FakeCameraController();
    final animationController = _FakeUnitAnimationController();
    final particleParent = Component();
    final focusLayer = ActionTargetHexFocusLayer();
    addTearDown(animationController.dispose);
    final dispatcher = GameEffectDispatcher(
      unitAnimationController: animationController,
      cameraController: cameraController,
      particleEffectsLayer: _FakeParticleEffectsLayer(),
      floatingTextLayer: _FakeFloatingTextLayer(),
      combatHexAlertLayer: CombatHexAlertLayer(),
      actionTargetHexFocusLayer: focusLayer,
      particleParent: particleParent,
      alertParent: particleParent,
      reduceMotion: () => false,
      followUnitMovementCamera: () => false,
      onRendererStateChanged: () {},
    );

    await dispatcher.handleEffect(
      const ShowActionTargetFocusEffect(unitId: 'unit_7', col: 4, row: 5),
    );
    expect(focusLayer.activeForTesting, isTrue);
    expect(focusLayer.unitIdForTesting, 'unit_7');
    expect(focusLayer.colForTesting, 4);
    expect(focusLayer.rowForTesting, 5);
  });
}
