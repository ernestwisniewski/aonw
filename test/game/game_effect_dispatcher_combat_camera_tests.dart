part of 'game_effect_dispatcher_test.dart';

void _registerCombatCameraTests() {
  test(
    'focuses the visible attacker before dispatching combat animation',
    () async {
      final harness = _CombatCameraHarness(
        visiblePositions: {
          'attacker': Vector2(120, 80),
          'defender': Vector2(240, 80),
        },
      );
      addTearDown(harness.animationController.dispose);

      await harness.dispatcher.handleEffect(
        const PlayCombatAnimationEffect(
          attackerUnitId: 'attacker',
          defenderUnitId: 'defender',
          attackerKilled: true,
          defenderKilled: true,
        ),
      );

      expect(harness.animationController.attackerUnitId, 'attacker');
      expect(harness.animationController.defenderUnitId, 'defender');
      expect(harness.animationController.attackerKilled, isTrue);
      expect(harness.animationController.defenderKilled, isTrue);
      expect(harness.cameraController.lastCenteredWorldPoint, Vector2(120, 80));
      expect(harness.animationController.positionRequests, ['attacker']);
      expect(harness.eventLog, ['focus', 'animate']);
      expect(harness.synced, isTrue);
    },
  );

  test(
    'focuses the visible defender when the attacker marker is hidden',
    () async {
      final harness = _CombatCameraHarness(
        visiblePositions: {
          'hidden_attacker': null,
          'visible_defender': Vector2(240, 80),
        },
      );
      addTearDown(harness.animationController.dispose);

      await harness.dispatcher.handleEffect(
        const PlayCombatAnimationEffect(
          attackerUnitId: 'hidden_attacker',
          defenderUnitId: 'visible_defender',
        ),
      );

      expect(harness.cameraController.lastCenteredWorldPoint, Vector2(240, 80));
      expect(harness.animationController.positionRequests, [
        'hidden_attacker',
        'visible_defender',
      ]);
      expect(harness.eventLog, ['focus', 'animate']);
    },
  );

  test(
    'does not move the camera when both combat markers are hidden',
    () async {
      final harness = _CombatCameraHarness(
        visiblePositions: {'hidden_attacker': null, 'hidden_defender': null},
      );
      addTearDown(harness.animationController.dispose);

      await harness.dispatcher.handleEffect(
        const PlayCombatAnimationEffect(
          attackerUnitId: 'hidden_attacker',
          defenderUnitId: 'hidden_defender',
        ),
      );

      expect(harness.cameraController.lastCenteredWorldPoint, isNull);
      expect(harness.animationController.positionRequests, [
        'hidden_attacker',
        'hidden_defender',
      ]);
      expect(harness.eventLog, ['animate']);
    },
  );
}

final class _CombatCameraHarness {
  final List<String> eventLog = [];
  late final _FakeCameraController cameraController = _FakeCameraController(
    eventLog: eventLog,
  );
  late final _FakeUnitAnimationController animationController =
      _FakeUnitAnimationController(eventLog: eventLog)
        ..visiblePositions.addAll(visiblePositions);
  late final GameEffectDispatcher dispatcher = GameEffectDispatcher(
    unitAnimationController: animationController,
    cameraController: cameraController,
    particleEffectsLayer: _FakeParticleEffectsLayer(),
    floatingTextLayer: _FakeFloatingTextLayer(),
    combatHexAlertLayer: CombatHexAlertLayer(),
    particleParent: _effectParent,
    alertParent: _effectParent,
    reduceMotion: () => false,
    followUnitMovementCamera: () => false,
    onRendererStateChanged: () => synced = true,
  );
  final Map<String, Vector2?> visiblePositions;
  final Component _effectParent = Component();
  bool synced = false;

  _CombatCameraHarness({required this.visiblePositions});
}
