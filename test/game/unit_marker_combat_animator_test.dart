import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_combat_animator.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release clears ids left by synchronous combat setup failure', () {
    final error = StateError('combat setup failed');
    final attacker = _ThrowingUnitMarker(error);
    final animator = UnitMarkerCombatAnimator(
      markerFor: (unitId) => unitId == 'attacker' ? attacker : null,
    );

    expect(
      () => animator.animate(
        attackerUnitId: 'attacker',
        defenderUnitId: 'defender',
        attackerKilled: false,
        defenderKilled: false,
        defenderRetaliated: false,
        reduceMotion: false,
        onComplete: () => fail('failed combat must not complete'),
      ),
      throwsA(same(error)),
    );
    expect(animator.animatingUnitIds, const {'attacker'});

    animator.release(const {'attacker', 'defender'});

    expect(animator.animatingUnitIds, isEmpty);
  });
}

final class _ThrowingUnitMarker extends UnitMarker {
  _ThrowingUnitMarker(this.error)
    : super(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.warrior,
      );

  final Object error;

  @override
  void playAttack() => throw error;
}
