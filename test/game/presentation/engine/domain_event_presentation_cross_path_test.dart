import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('six presentation paths share movement and combat schedule exactly', () {
    final fixture = _fixture();
    const identity = PresentationBatchIdentity(
      sourceId: 'match_1',
      eventOffset: 17,
    );
    final batches = {
      for (final path in const [
        'local',
        'ack',
        'observer',
        'reconnect',
        'replay',
        'hidden-ai',
      ])
        path: DomainEventPresentationProjector.projectObservedBatch(
          identity: identity,
          interactionEffects: const [],
          events: fixture.events,
          visibleMovementExecutions: fixture.executions,
          previousState: fixture.before,
          state: fixture.after,
        ),
    };
    final expected = batches['local']!.domainEffects.map(_snapshot).toList();

    for (final entry in batches.entries) {
      expect(
        entry.value.domainEffects.map(_snapshot),
        expected,
        reason: entry.key,
      );
    }
    expect(
      expected.map((item) => item.$2),
      orderedEquals(List.generate(expected.length, (index) => index)),
    );
    expect(expected.first.$3, Duration.zero);
    expect(
      batches['local']!.domainEffects
          .where((item) => item.effect is PlayCombatAnimationEffect)
          .single
          .effect,
      isA<PlayCombatAnimationEffect>()
          .having((effect) => effect.attackerUnitId, 'attacker', 'attacker')
          .having((effect) => effect.attackerFromCol, 'attacker col', 1),
    );

    final effects = batches['local']!.domainEffects;
    final combatIndex = effects.indexWhere(
      (item) => item.effect is PlayCombatAnimationEffect,
    );
    final retreatIndex = effects.indexWhere(
      (item) =>
          item.effect is ShowFloatingTextEffect &&
          (item.effect as ShowFloatingTextEffect).delay ==
              const Duration(milliseconds: 180),
    );
    expect(combatIndex, greaterThan(0));
    expect(retreatIndex, greaterThan(combatIndex));
  });

  test('cached ACK and reconnect batch animate once and older batch never', () {
    final fixture = _fixture();
    final cursor = ProjectedGameEffectCursor();

    ProjectedGameEffectBatch batch(int offset) {
      return DomainEventPresentationProjector.projectObservedBatch(
        identity: PresentationBatchIdentity(
          sourceId: 'match_1',
          eventOffset: offset,
        ),
        interactionEffects: const [],
        events: fixture.events,
        visibleMovementExecutions: fixture.executions,
        previousState: fixture.before,
        state: fixture.after,
      );
    }

    final acknowledged = batch(17);
    expect(cursor.consume(acknowledged.domainEffects), isNotEmpty);
    expect(cursor.consume(acknowledged.domainEffects), isEmpty);
    expect(cursor.consume(batch(16).domainEffects), isEmpty);
  });

  test('six presentation paths share artifact lifecycle schedule exactly', () {
    const identity = PresentationBatchIdentity(
      sourceId: 'match_1',
      eventOffset: 18,
    );
    const events = <GameEvent>[
      ArtifactExcavationStartedEvent(
        artifactId: 'artifact_1',
        ownerPlayerId: 'player_1',
        unitId: 'worker_1',
        col: 2,
        row: 3,
      ),
      ArtifactCarriedEvent(
        artifactId: 'artifact_1',
        ownerPlayerId: 'player_1',
        unitId: 'worker_1',
        col: 4,
        row: 5,
      ),
      ArtifactStoredEvent(
        artifactId: 'artifact_1',
        ownerPlayerId: 'player_1',
        unitId: 'worker_1',
        cityId: 'city_1',
        col: 6,
        row: 7,
      ),
    ];
    final batches = {
      for (final path in const [
        'local',
        'ack',
        'observer',
        'reconnect',
        'replay',
        'hidden-ai',
      ])
        path: DomainEventPresentationProjector.projectObservedBatch(
          identity: identity,
          interactionEffects: const [],
          events: events,
          visibleMovementExecutions: const [],
          previousState: const GameState(),
          state: const GameState(),
        ),
    };
    final expected = batches['local']!.domainEffects.map(_snapshot).toList();

    expect(expected, hasLength(6));
    expect(
      expected.map((item) => item.$2),
      orderedEquals(List.generate(expected.length, (index) => index)),
    );
    expect(expected.first.$3, Duration.zero);
    for (final entry in batches.entries) {
      expect(
        entry.value.domainEffects.map(_snapshot),
        expected,
        reason: entry.key,
      );
    }
    expect(
      batches['local']!.domainEffects.map((effect) => effect.animationId),
      const [
        'match_1:18:SpawnParticleBurstEffect:SpawnParticleBurstEffect:0',
        'match_1:18:ShowFloatingTextEffect:ShowFloatingTextEffect:1',
        'match_1:18:SpawnParticleBurstEffect:SpawnParticleBurstEffect:2',
        'match_1:18:ShowFloatingTextEffect:ShowFloatingTextEffect:3',
        'match_1:18:SpawnParticleBurstEffect:SpawnParticleBurstEffect:4',
        'match_1:18:ShowFloatingTextEffect:ShowFloatingTextEffect:5',
      ],
    );
    expect(
      batches['local']!.domainEffects
          .where((projected) => projected.effect is SpawnParticleBurstEffect)
          .map(
            (projected) => (
              (projected.effect as SpawnParticleBurstEffect).col,
              (projected.effect as SpawnParticleBurstEffect).row,
            ),
          ),
      const [(2, 3), (4, 5), (6, 7)],
    );
  });
}

({
  GameState before,
  GameState after,
  List<GameEvent> events,
  List<MovementCommandExecution> executions,
})
_fixture() {
  final attacker = GameUnit.produced(
    id: 'attacker',
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    col: 0,
    row: 0,
  );
  final defender = GameUnit.produced(
    id: 'defender',
    ownerPlayerId: 'player_2',
    type: GameUnitType.warrior,
    col: 2,
    row: 0,
  );
  final outcome = CombatOutcome(
    attackerUnitId: attacker.id,
    defenderUnitId: defender.id,
    attackerHpAfter: 8,
    defenderHpAfter: 2,
    attackerKilled: false,
    defenderKilled: false,
    defenderRetreated: true,
    steps: [AttackStep(damage: 4), RetaliationStep(damage: 2)],
  );
  return (
    before: GameState(units: [attacker, defender]),
    after: GameState(
      units: [
        attacker.copyWith(col: 1, hitPoints: 8),
        defender.copyWith(col: 3),
      ],
    ),
    events: [
      UnitMovedEvent(
        unitId: attacker.id,
        fromCol: 0,
        fromRow: 0,
        toCol: 1,
        toRow: 0,
      ),
      CombatResolvedEvent(
        attackerUnitId: attacker.id,
        defenderUnitId: defender.id,
        outcome: outcome,
      ),
      UnitRetreatedEvent(
        unitId: defender.id,
        ownerPlayerId: defender.ownerPlayerId,
        fromCol: 2,
        fromRow: 0,
        toCol: 3,
        toRow: 0,
      ),
    ],
    executions: [
      MovementCommandExecution(
        unitId: attacker.id,
        fromCol: 0,
        fromRow: 0,
        steps: const [
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      ),
    ],
  );
}

(String, int, Duration, String) _snapshot(ProjectedGameEffect projected) => (
  projected.animationId,
  projected.ordinal,
  projected.startOffset,
  projected.effect.runtimeType.toString(),
);
