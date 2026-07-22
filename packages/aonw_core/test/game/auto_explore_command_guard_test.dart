import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'auto_explore_command_resolver_test_support.dart';

typedef _GuardedCase = ({
  String name,
  GameUnit unit,
  String unitId,
  String actorPlayerId,
  bool canAct,
  int mapCols,
  String reason,
});

final List<_GuardedCase> _guardedCases = [
  (
    name: 'missing precedes every unit condition',
    unit: autoExploreScout(
      id: 'other',
      ownerPlayerId: autoExploreOpponentId,
      type: GameUnitType.warrior,
      col: -1,
      movementPoints: 0,
      posture: UnitPosture.fortified,
      queuedPath: autoExploreQueuedPath(),
    ),
    unitId: 'missing',
    actorPlayerId: autoExploreActorId,
    canAct: false,
    mapCols: 1,
    reason: 'unit_not_found',
  ),
  (
    name: 'canAct precedes type and availability',
    unit: autoExploreScout(
      type: GameUnitType.warrior,
      movementPoints: 0,
      posture: UnitPosture.fortified,
      queuedPath: autoExploreQueuedPath(),
    ),
    unitId: autoExploreUnitId,
    actorPlayerId: autoExploreActorId,
    canAct: false,
    mapCols: 1,
    reason: 'unit_not_controlled',
  ),
  (
    name: 'wrong actor precedes type and availability',
    unit: autoExploreScout(
      type: GameUnitType.warrior,
      movementPoints: 0,
      posture: UnitPosture.fortified,
      queuedPath: autoExploreQueuedPath(),
    ),
    unitId: autoExploreUnitId,
    actorPlayerId: autoExploreOpponentId,
    canAct: true,
    mapCols: 1,
    reason: 'unit_not_controlled',
  ),
  (
    name: 'non-scout precedes availability and exhaustion',
    unit: autoExploreScout(
      type: GameUnitType.warrior,
      movementPoints: 0,
      posture: UnitPosture.fortified,
      queuedPath: autoExploreQueuedPath(),
    ),
    unitId: autoExploreUnitId,
    actorPlayerId: autoExploreActorId,
    canAct: true,
    mapCols: 1,
    reason: 'unit_not_scout',
  ),
  (
    name: 'working precedes exhaustion and queue',
    unit: autoExploreScout(
      movementPoints: 0,
      excavatingArtifactId: 'artifact',
      queuedPath: autoExploreQueuedPath(),
    ),
    unitId: autoExploreUnitId,
    actorPlayerId: autoExploreActorId,
    canAct: true,
    mapCols: 1,
    reason: 'unit_busy',
  ),
  (
    name: 'fortified precedes exhaustion and queue',
    unit: autoExploreScout(
      movementPoints: 0,
      posture: UnitPosture.fortified,
      queuedPath: autoExploreQueuedPath(),
    ),
    unitId: autoExploreUnitId,
    actorPlayerId: autoExploreActorId,
    canAct: true,
    mapCols: 1,
    reason: 'unit_busy',
  ),
  (
    name: 'exhaustion precedes queue',
    unit: autoExploreScout(
      movementPoints: 0,
      queuedPath: autoExploreQueuedPath(),
    ),
    unitId: autoExploreUnitId,
    actorPlayerId: autoExploreActorId,
    canAct: true,
    mapCols: 1,
    reason: 'unit_exhausted',
  ),
  (
    name: 'queue precedes origin bounds',
    unit: autoExploreScout(col: -1, queuedPath: autoExploreQueuedPath()),
    unitId: autoExploreUnitId,
    actorPlayerId: autoExploreActorId,
    canAct: true,
    mapCols: 1,
    reason: 'unit_has_path',
  ),
  (
    name: 'origin bounds precede target selection',
    unit: autoExploreScout(col: -1),
    unitId: autoExploreUnitId,
    actorPlayerId: autoExploreActorId,
    canAct: true,
    mapCols: 1,
    reason: 'unit_out_of_bounds',
  ),
];

void main() {
  group('AutoExploreCommandGuard', () {
    for (final fixture in _guardedCases) {
      test(fixture.name, () {
        final interaction = ownedAutoExploreInteraction();
        final state = autoExploreState(
          scout: fixture.unit,
          interaction: interaction,
        );

        final result = resolveAutoExplore(
          state,
          autoExploreMap(cols: fixture.mapCols),
          unitId: fixture.unitId,
          actorPlayerId: fixture.actorPlayerId,
          canAct: fixture.canAct,
        );

        expect(result.accepted, isFalse);
        expect(result.reason, fixture.reason);
        expect(result.units, same(state.movement.units));
        expect(result.fogOfWar, same(state.movement.fogOfWar));
        expect(result.diplomacy, same(state.movement.diplomacy));
        expect(result.interaction, same(interaction));
        expect(result.events, isEmpty);
        expect(result.execution, isNull);
      });
    }
  });
}
