import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_camera_controller.dart';
import 'package:aonw/game/presentation/engine/game_effect_dispatcher.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/combat_hex_alert_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/floating_text_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/particle_effects_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/unit_animation_controller.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 2,
  rows: 1,
  tiles: [
    for (var col = 0; col < 2; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
  ],
);

class _FakeCameraController extends GameCameraController {
  ({int col, int row})? lastJump;
  ({int col, int row, double duration})? lastSmooth;
  double? lastShakeIntensity;
  double? lastShakeDuration;
  bool following = false;
  int followCallCount = 0;
  int stopFollowCallCount = 0;

  _FakeCameraController() : super(camera: CameraComponent(), mapData: _map());

  @override
  void jumpToTile(int col, int row) {
    lastJump = (col: col, row: row);
  }

  @override
  Future<void> smoothToTile(
    int col,
    int row, {
    double duration = 0.48,
    Curve curve = Curves.easeInOutCubic,
  }) {
    lastSmooth = (col: col, row: row, duration: duration);
    return Future<void>.value();
  }

  @override
  void followWorldPoint(Vector2? Function() point) {
    following = true;
    followCallCount++;
  }

  @override
  void stopFollowingWorldPoint() {
    following = false;
    stopFollowCallCount++;
  }

  @override
  void shake({double intensity = 8.0, double duration = 0.28}) {
    lastShakeIntensity = intensity;
    lastShakeDuration = duration;
  }
}

class _FakeUnitMarkerLayer extends UnitMarkerLayer {
  _FakeUnitMarkerLayer()
    : super(mapData: _map(), colorForPlayer: (_) => 0xFF0000FF);
}

class _FakeUnitAnimationController extends UnitAnimationController {
  String? unitId;
  int? fromCol;
  int? fromRow;
  List<UnitMovementStep>? steps;
  String? attackerUnitId;
  String? defenderUnitId;
  bool? attackerKilled;
  bool? defenderKilled;
  Vector2? visiblePosition = Vector2.zero();

  _FakeUnitAnimationController() : super(_FakeUnitMarkerLayer());

  @override
  Vector2? unitWorldPosition(String unitId) => visiblePosition?.clone();

  @override
  Future<void> animateUnitMove({
    required String unitId,
    int? fromCol,
    int? fromRow,
    required List<UnitMovementStep> steps,
    required VoidCallback onComplete,
  }) {
    this.unitId = unitId;
    this.fromCol = fromCol;
    this.fromRow = fromRow;
    this.steps = steps;
    onComplete();
    return Future<void>.value();
  }

  @override
  Future<void> animateUnitCombat({
    required String attackerUnitId,
    required String defenderUnitId,
    required bool attackerKilled,
    required bool defenderKilled,
    required VoidCallback onComplete,
  }) {
    this.attackerUnitId = attackerUnitId;
    this.defenderUnitId = defenderUnitId;
    this.attackerKilled = attackerKilled;
    this.defenderKilled = defenderKilled;
    onComplete();
    return Future<void>.value();
  }
}

class _FakeParticleEffectsLayer extends ParticleEffectsLayer {
  SpawnParticleBurstEffect? lastEffect;
  Component? lastParent;

  @override
  ParticleSystemComponent spawnBurst({
    required Component parent,
    required SpawnParticleBurstEffect effect,
  }) {
    lastParent = parent;
    lastEffect = effect;
    return ParticleSystemComponent();
  }
}

class _FakeFloatingTextLayer extends FloatingTextLayer {
  ShowFloatingTextEffect? lastEffect;
  Component? lastParent;
  final List<ShowFloatingTextEffect> effects = [];

  @override
  FloatingTextComponent spawn({
    required Component parent,
    required ShowFloatingTextEffect effect,
  }) {
    lastParent = parent;
    lastEffect = effect;
    effects.add(effect);
    return FloatingTextComponent(
      text: effect.text,
      color: Color(effect.colorValue),
      position: Vector2.zero(),
      priority: 0,
    );
  }
}

void main() {
  group('GameEffectDispatcher', () {
    test('dispatches jump camera effects to the camera controller', () async {
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController();
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final particleParent = Component();
      addTearDown(animationController.dispose);
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
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

    test(
      'skips camera focus effects rejected by map visibility policy',
      () async {
        final cameraController = _FakeCameraController();
        final animationController = _FakeUnitAnimationController();
        final particleLayer = _FakeParticleEffectsLayer();
        final floatingTextLayer = _FakeFloatingTextLayer();
        final particleParent = Component();
        addTearDown(animationController.dispose);
        final dispatcher = GameEffectDispatcher(
          unitAnimationController: animationController,
          cameraController: cameraController,
          particleEffectsLayer: particleLayer,
          floatingTextLayer: floatingTextLayer,
          combatHexAlertLayer: CombatHexAlertLayer(),
          particleParent: particleParent,
          alertParent: particleParent,
          reduceMotion: () => false,
          followUnitMovementCamera: () => false,
          canAutoFocusMapTarget: (_, _) => false,
          onRendererStateChanged: () {},
        );

        await dispatcher.handleEffect(const JumpCameraEffect(col: 1, row: 0));
        await dispatcher.handleEffect(const SmoothCameraEffect(col: 2, row: 0));

        expect(cameraController.lastJump, isNull);
        expect(cameraController.lastSmooth, isNull);
      },
    );

    test('dispatches camera shake effects to the camera controller', () async {
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController();
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final particleParent = Component();
      addTearDown(animationController.dispose);
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
        combatHexAlertLayer: CombatHexAlertLayer(),
        particleParent: particleParent,
        alertParent: particleParent,
        reduceMotion: () => false,
        followUnitMovementCamera: () => false,
        onRendererStateChanged: () {},
      );

      await dispatcher.handleEffect(
        const ShakeCameraEffect(intensity: 5, duration: 0.18),
      );

      expect(cameraController.lastShakeIntensity, 5);
      expect(cameraController.lastShakeDuration, 0.18);
    });

    test('dispatches animation effects and syncs after completion', () async {
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController();
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final particleParent = Component();
      addTearDown(animationController.dispose);
      var synced = false;
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
        combatHexAlertLayer: CombatHexAlertLayer(),
        particleParent: particleParent,
        alertParent: particleParent,
        reduceMotion: () => false,
        followUnitMovementCamera: () => false,
        onRendererStateChanged: () => synced = true,
      );
      const steps = [
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ];

      await dispatcher.handleEffect(
        const AnimateUnitMoveEffect(
          unitId: 'unit_1',
          fromCol: 0,
          fromRow: 0,
          steps: steps,
        ),
      );

      expect(animationController.unitId, 'unit_1');
      expect(animationController.fromCol, 0);
      expect(animationController.fromRow, 0);
      expect(animationController.steps, steps);
      expect(cameraController.lastSmooth, (col: 0, row: 0, duration: 0.28));
      expect(cameraController.followCallCount, 0);
      expect(cameraController.stopFollowCallCount, 0);
      expect(cameraController.following, isFalse);
      expect(synced, isTrue);
    });

    test('tracks visible unit moves when camera follow is enabled', () async {
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController();
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final particleParent = Component();
      addTearDown(animationController.dispose);
      var synced = false;
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
        combatHexAlertLayer: CombatHexAlertLayer(),
        particleParent: particleParent,
        alertParent: particleParent,
        reduceMotion: () => false,
        followUnitMovementCamera: () => true,
        onRendererStateChanged: () => synced = true,
      );
      const steps = [
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ];

      await dispatcher.handleEffect(
        const AnimateUnitMoveEffect(
          unitId: 'unit_1',
          fromCol: 0,
          fromRow: 0,
          steps: steps,
        ),
      );

      expect(cameraController.lastSmooth, (col: 0, row: 0, duration: 0.28));
      expect(cameraController.followCallCount, 1);
      expect(cameraController.stopFollowCallCount, 1);
      expect(cameraController.following, isFalse);
      expect(synced, isTrue);
    });

    test('animates rejected unit movement without moving the camera', () async {
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController();
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final particleParent = Component();
      addTearDown(animationController.dispose);
      var synced = false;
      var restored = false;
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
        combatHexAlertLayer: CombatHexAlertLayer(),
        particleParent: particleParent,
        alertParent: particleParent,
        reduceMotion: () => false,
        moveCameraForUnitMovementForUnit: (unitId) => unitId != 'enemy_1',
        onUnitMovementCameraComplete: (_) async => restored = true,
        followUnitMovementCamera: () => true,
        onRendererStateChanged: () => synced = true,
      );
      const steps = [
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ];

      await dispatcher.handleEffect(
        const AnimateUnitMoveEffect(
          unitId: 'enemy_1',
          fromCol: 0,
          fromRow: 0,
          steps: steps,
        ),
      );

      expect(animationController.unitId, 'enemy_1');
      expect(cameraController.lastSmooth, isNull);
      expect(cameraController.followCallCount, 0);
      expect(cameraController.stopFollowCallCount, 0);
      expect(restored, isFalse);
      expect(synced, isTrue);
    });

    test('notifies after a unit movement camera handoff completes', () async {
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController();
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final particleParent = Component();
      addTearDown(animationController.dispose);
      String? restoredUnitId;
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
        combatHexAlertLayer: CombatHexAlertLayer(),
        particleParent: particleParent,
        alertParent: particleParent,
        reduceMotion: () => false,
        onUnitMovementCameraComplete: (unitId) async {
          restoredUnitId = unitId;
        },
        followUnitMovementCamera: () => true,
        onRendererStateChanged: () {},
      );
      const steps = [
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ];

      await dispatcher.handleEffect(
        const AnimateUnitMoveEffect(
          unitId: 'enemy_1',
          fromCol: 0,
          fromRow: 0,
          steps: steps,
        ),
      );

      expect(cameraController.lastSmooth, (col: 0, row: 0, duration: 0.28));
      expect(cameraController.stopFollowCallCount, 1);
      expect(restoredUnitId, 'enemy_1');
    });

    test('keeps camera free when unit movement camera is disabled', () async {
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController();
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final particleParent = Component();
      addTearDown(animationController.dispose);
      var synced = false;
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
        combatHexAlertLayer: CombatHexAlertLayer(),
        particleParent: particleParent,
        alertParent: particleParent,
        reduceMotion: () => false,
        moveCameraForUnitMovement: () => false,
        followUnitMovementCamera: () => true,
        onRendererStateChanged: () => synced = true,
      );
      const steps = [
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ];

      await dispatcher.handleEffect(
        const AnimateUnitMoveEffect(
          unitId: 'unit_1',
          fromCol: 0,
          fromRow: 0,
          steps: steps,
        ),
      );

      expect(animationController.unitId, 'unit_1');
      expect(cameraController.lastSmooth, isNull);
      expect(cameraController.followCallCount, 0);
      expect(cameraController.stopFollowCallCount, 0);
      expect(synced, isTrue);
    });

    test('does not move camera for hidden unit move effects', () async {
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController()
        ..visiblePosition = null;
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final particleParent = Component();
      addTearDown(animationController.dispose);
      var synced = false;
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
        combatHexAlertLayer: CombatHexAlertLayer(),
        particleParent: particleParent,
        alertParent: particleParent,
        reduceMotion: () => false,
        followUnitMovementCamera: () => false,
        onRendererStateChanged: () => synced = true,
      );
      const steps = [
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ];

      await dispatcher.handleEffect(
        const AnimateUnitMoveEffect(
          unitId: 'hidden_enemy',
          fromCol: 0,
          fromRow: 0,
          steps: steps,
        ),
      );

      expect(animationController.unitId, 'hidden_enemy');
      expect(cameraController.lastSmooth, isNull);
      expect(cameraController.followCallCount, 0);
      expect(cameraController.stopFollowCallCount, 0);
      expect(synced, isTrue);
    });

    test(
      'dispatches combat animation effects and syncs after completion',
      () async {
        final cameraController = _FakeCameraController();
        final animationController = _FakeUnitAnimationController();
        final particleLayer = _FakeParticleEffectsLayer();
        final floatingTextLayer = _FakeFloatingTextLayer();
        final particleParent = Component();
        addTearDown(animationController.dispose);
        var synced = false;
        final dispatcher = GameEffectDispatcher(
          unitAnimationController: animationController,
          cameraController: cameraController,
          particleEffectsLayer: particleLayer,
          floatingTextLayer: floatingTextLayer,
          combatHexAlertLayer: CombatHexAlertLayer(),
          particleParent: particleParent,
          alertParent: particleParent,
          reduceMotion: () => false,
          followUnitMovementCamera: () => false,
          onRendererStateChanged: () => synced = true,
        );

        await dispatcher.handleEffect(
          const PlayCombatAnimationEffect(
            attackerUnitId: 'attacker',
            defenderUnitId: 'defender',
            defenderKilled: true,
          ),
        );

        expect(animationController.attackerUnitId, 'attacker');
        expect(animationController.defenderUnitId, 'defender');
        expect(animationController.attackerKilled, isFalse);
        expect(animationController.defenderKilled, isTrue);
        expect(synced, isTrue);
      },
    );

    test('dispatches particle burst effects to the particle layer', () async {
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController();
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final particleParent = Component();
      addTearDown(animationController.dispose);
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
        combatHexAlertLayer: CombatHexAlertLayer(),
        particleParent: particleParent,
        alertParent: particleParent,
        reduceMotion: () => false,
        followUnitMovementCamera: () => false,
        onRendererStateChanged: () {},
      );
      const effect = SpawnParticleBurstEffect(
        kind: ParticleBurstKind.hexClaimed,
        col: 2,
        row: 3,
        colorValue: 0xFF2563EB,
      );

      await dispatcher.handleEffect(effect);

      expect(particleLayer.lastParent, same(particleParent));
      expect(particleLayer.lastEffect, same(effect));
    });

    test('dispatches combat hex alerts to the alert layer', () async {
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController();
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final combatHexAlertLayer = CombatHexAlertLayer();
      final particleParent = Component();
      final alertParent = Component();
      addTearDown(animationController.dispose);
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
        combatHexAlertLayer: combatHexAlertLayer,
        particleParent: particleParent,
        alertParent: alertParent,
        onRendererStateChanged: () {},
        reduceMotion: () => true,
        followUnitMovementCamera: () => false,
      );

      await dispatcher.handleEffect(
        const ShowCombatHexAlertEffect(
          id: 'city:city_1',
          cityId: 'city_1',
          ownerPlayerId: 'player_1',
          col: 2,
          row: 3,
          kind: CombatHexAlertKind.attacked,
        ),
      );

      expect(combatHexAlertLayer.hasAlertForTesting('city_1'), isTrue);
      expect(
        combatHexAlertLayer.alertHexForTesting('city_1'),
        const CityHex(col: 2, row: 3),
      );
      expect(combatHexAlertLayer.alertPulseForTesting('city_1'), 0.55);
    });

    test(
      'dispatches floating text effects to the floating text layer',
      () async {
        final cameraController = _FakeCameraController();
        final animationController = _FakeUnitAnimationController();
        final particleLayer = _FakeParticleEffectsLayer();
        final floatingTextLayer = _FakeFloatingTextLayer();
        final particleParent = Component();
        addTearDown(animationController.dispose);
        final dispatcher = GameEffectDispatcher(
          unitAnimationController: animationController,
          cameraController: cameraController,
          particleEffectsLayer: particleLayer,
          floatingTextLayer: floatingTextLayer,
          combatHexAlertLayer: CombatHexAlertLayer(),
          particleParent: particleParent,
          alertParent: particleParent,
          reduceMotion: () => false,
          followUnitMovementCamera: () => false,
          onRendererStateChanged: () {},
        );
        const effect = ShowFloatingTextEffect(
          text: '+1 food',
          col: 2,
          row: 3,
          colorValue: 0xFF86EFAC,
        );

        await dispatcher.handleEffect(effect);

        expect(floatingTextLayer.lastParent, same(particleParent));
        expect(floatingTextLayer.lastEffect, same(effect));
      },
    );

    test(
      'schedules delayed floating text without blocking later effects',
      () async {
        final cameraController = _FakeCameraController();
        final animationController = _FakeUnitAnimationController();
        final particleLayer = _FakeParticleEffectsLayer();
        final floatingTextLayer = _FakeFloatingTextLayer();
        final particleParent = Component();
        addTearDown(animationController.dispose);
        final dispatcher = GameEffectDispatcher(
          unitAnimationController: animationController,
          cameraController: cameraController,
          particleEffectsLayer: particleLayer,
          floatingTextLayer: floatingTextLayer,
          combatHexAlertLayer: CombatHexAlertLayer(),
          particleParent: particleParent,
          alertParent: particleParent,
          reduceMotion: () => false,
          followUnitMovementCamera: () => false,
          onRendererStateChanged: () {},
        );
        const delayed = ShowFloatingTextEffect(
          text: 'KO',
          col: 2,
          row: 3,
          colorValue: 0xFFF87171,
          delay: Duration(milliseconds: 1),
        );

        await dispatcher.handleEffects([
          delayed,
          const ShakeCameraEffect(intensity: 3, duration: 0.1),
        ]);

        expect(cameraController.lastShakeIntensity, 3);
        expect(floatingTextLayer.effects, isEmpty);

        await Future<void>.delayed(const Duration(milliseconds: 5));

        expect(floatingTextLayer.effects, [same(delayed)]);
      },
    );

    test('formats city production bubbles as styled floating text', () async {
      final l10n = AppLocalizationsEn();
      final cameraController = _FakeCameraController();
      final animationController = _FakeUnitAnimationController();
      final particleLayer = _FakeParticleEffectsLayer();
      final floatingTextLayer = _FakeFloatingTextLayer();
      final particleParent = Component();
      addTearDown(animationController.dispose);
      final dispatcher = GameEffectDispatcher(
        unitAnimationController: animationController,
        cameraController: cameraController,
        particleEffectsLayer: particleLayer,
        floatingTextLayer: floatingTextLayer,
        combatHexAlertLayer: CombatHexAlertLayer(),
        particleParent: particleParent,
        alertParent: particleParent,
        reduceMotion: () => false,
        followUnitMovementCamera: () => false,
        onRendererStateChanged: () {},
        l10n: l10n,
      );

      await dispatcher.handleEffect(
        const ShowCityProductionBubbleEffect(
          target: UnitProductionTarget(GameUnitType.worker),
          col: 1,
          row: 0,
          turnsRemaining: 3,
        ),
      );

      final effect = floatingTextLayer.lastEffect!;
      expect(effect.text, 'Worker • 3 turns');
      expect(effect.col, 1);
      expect(effect.row, 0);
      expect(effect.presentation, FloatingTextPresentation.bubble);
    });
  });
}
