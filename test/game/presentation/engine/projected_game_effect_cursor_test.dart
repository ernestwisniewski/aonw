import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/game/presentation/engine/renderer_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deduplicates current offset and suppresses older reconnect batches',
    () {
      final cursor = ProjectedGameEffectCursor();
      final current = _effect(offset: 8, ordinal: 0);

      expect(cursor.consume([current]), hasLength(1));
      expect(cursor.consume([current]), isEmpty);
      expect(cursor.consume([_effect(offset: 7, ordinal: 0)]), isEmpty);
      expect(cursor.retainedIdentityCount, 1);
    },
  );

  test(
    'retains identities only for the highest offset across 10000 batches',
    () {
      final cursor = ProjectedGameEffectCursor();

      for (var offset = 0; offset < 10000; offset += 1) {
        expect(
          cursor.consume([_effect(offset: offset, ordinal: 0)]),
          hasLength(1),
        );
      }

      expect(cursor.retainedIdentityCount, 1);
    },
  );

  test('buffers out-of-order batches and drains canonical sequence once', () {
    final cursor = ProjectedGameEffectCursor()
      ..activateSource('match_1', nextEventOffset: 7);
    final later = _batch(offset: 8);
    final expected = _batch(offset: 7);

    expect(cursor.consumeProjectedBatch(later), isEmpty);
    expect(cursor.pendingSequenceCount, 1);
    expect(
      cursor
          .consumeProjectedBatch(expected)
          .map((effect) => effect.eventOffset),
      [7, 8],
    );
    expect(cursor.consumeProjectedBatch(later), isEmpty);
    expect(cursor.pendingSequenceCount, 0);
  });

  test('an intentional no-animation plan closes a sequence gap', () {
    final cursor = ProjectedGameEffectCursor()
      ..activateSource('match_1', nextEventOffset: 7);
    final later = _batch(offset: 8);
    final noAnimation = ProjectedGameEffectBatch(
      identity: const PresentationBatchIdentity(
        sourceId: 'match_1',
        eventOffset: 7,
      ),
      animationPlans: [
        AnimationPlan(
          eventId: 'match_1:7:0',
          eventType: 'TurnEndedEvent',
          policy: 'turn lifecycle is state-driven',
          batchSequence: 7,
          eventSequence: 0,
          authoritativeTick: 7,
          authoritativeStartMicrosUtc: 7000000,
          startOffset: Duration.zero,
          animations: const [],
        ),
      ],
    );

    expect(cursor.consumeProjectedBatch(later), isEmpty);
    expect(
      cursor.consumeProjectedBatch(noAnimation).map((item) => item.eventOffset),
      [8],
    );
  });

  test('replay seek explicitly resets the cursor', () {
    final cursor = ProjectedGameEffectCursor();
    final effect = _effect(offset: 8, ordinal: 0);
    cursor
      ..consume([effect])
      ..resetForReplaySeek();

    expect(cursor.consume([effect]), hasLength(1));
  });

  test('explicit source switch rejects stale batches from the old source', () {
    final cursor = ProjectedGameEffectCursor();
    final sourceA = _effect(sourceId: 'match_a', offset: 10, ordinal: 0);

    expect(cursor.consume([sourceA]), hasLength(1));
    cursor.activateSource('match_b');
    expect(
      cursor.consume([_effect(sourceId: 'match_b', offset: 1, ordinal: 0)]),
      hasLength(1),
    );
    expect(cursor.consume([sourceA]), isEmpty);
  });

  test('foreign sources cannot grow cursor memory without activation', () {
    final cursor = ProjectedGameEffectCursor()..activateSource('active');

    for (var index = 0; index < 10000; index += 1) {
      expect(
        cursor.consume([
          _effect(sourceId: 'foreign_$index', offset: index, ordinal: 0),
        ]),
        isEmpty,
      );
    }

    expect(cursor.retainedIdentityCount, 0);
  });

  test('cached interaction dedupes while a new intent remains repeatable', () {
    final cursor = ProjectedGameEffectCursor()..activateSource('match_1');

    ProjectedGameEffectBatch batch(String interactionId) {
      return DomainEventPresentationProjector.projectObservedBatch(
        identity: PresentationBatchIdentity(
          sourceId: 'match_1',
          eventOffset: 8,
          interactionId: interactionId,
        ),
        interactionEffects: const [JumpCameraEffect(col: 1, row: 2)],
        events: const [],
        visibleMovementExecutions: const [],
        state: GameClientState(),
        previousState: GameClientState(),
      );
    }

    final cached = batch('intent_1');
    expect(cursor.consume(cached.projectedEffects), hasLength(1));
    expect(cursor.consume(cached.projectedEffects), isEmpty);
    expect(cursor.consume(batch('intent_2').projectedEffects), hasLength(1));
  });

  test('application boundary dedupes a cached handoff interaction', () async {
    final renderer = _RecordingRendererViewModel()
      ..activateProjectedEffectSource('match_1');

    ProjectedGameEffectBatch batch(String interactionId) {
      return DomainEventPresentationProjector.projectObservedBatch(
        identity: PresentationBatchIdentity(
          sourceId: 'match_1',
          eventOffset: 8,
          interactionId: interactionId,
        ),
        interactionEffects: const [JumpCameraEffect(col: 1, row: 2)],
        events: const [],
        visibleMovementExecutions: const [],
        state: GameClientState(),
        previousState: GameClientState(),
      );
    }

    final cached = batch('intent_1');
    await renderer.applyProjectedTransition(GameClientState(), cached);
    await renderer.applyProjectedTransition(GameClientState(), cached);
    await renderer.applyProjectedTransition(
      GameClientState(),
      batch('intent_2'),
    );

    expect(renderer.applied.whereType<JumpCameraEffect>(), hasLength(2));
  });

  test(
    'application boundary buffers state with out-of-order effects',
    () async {
      final renderer = _RecordingRendererViewModel()
        ..activateProjectedEffectSource('match_1', nextEventOffset: 7);
      final state7 = GameClientState(activePlayerId: 'player_7');
      final state8 = GameClientState(activePlayerId: 'player_8');

      await renderer.applyProjectedTransition(state8, _batch(offset: 8));
      expect(renderer.appliedStates, isEmpty);

      await renderer.applyProjectedTransition(state7, _batch(offset: 7));

      expect(renderer.appliedStates.map((state) => state.activePlayerId), [
        'player_7',
        'player_8',
      ]);
      expect(renderer.applied, hasLength(2));
    },
  );

  test('reconnect does not repeat a fortification threat animation', () {
    final fortifier = GameUnit(
      id: 'fortifier',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Fortifier',
      col: 2,
      row: 2,
      movementPoints: 0,
      posture: UnitPosture.fortified,
    );
    final enemy = GameUnit(
      id: 'enemy',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 3,
      row: 2,
    );
    final state = GameClientState(
      activePlayerId: 'player_1',
      units: [fortifier, enemy],
    );
    final batch = DomainEventPresentationProjector.projectObservedBatch(
      identity: const PresentationBatchIdentity(
        sourceId: 'match_1',
        eventOffset: 9,
      ),
      interactionEffects: const [],
      events: [
        FortifiedUnitThreatenedEvent(
          unitId: 'fortifier',
          ownerPlayerId: 'player_1',
          targets: const [
            FortifiedUnitThreatTarget(unitId: 'enemy', col: 3, row: 2),
          ],
        ),
      ],
      visibleMovementExecutions: const [],
      state: state,
      previousState: state,
      viewerPlayerId: 'player_1',
    );
    final cursor = ProjectedGameEffectCursor()..activateSource('match_1');

    expect(batch.domainEffects.map((item) => item.startOffset), const [
      Duration.zero,
      Duration.zero,
    ]);
    final firstDelivery = cursor.consume(batch.projectedEffects);
    final reconnectDelivery = cursor.consume(batch.projectedEffects);

    expect(firstDelivery, [
      isA<ShowCombatHexAlertEffect>(),
      isA<SmoothCameraEffect>(),
    ]);
    expect(reconnectDelivery, isEmpty);
  });

  test(
    'application source lifecycle rejects stale A after A B switch',
    () async {
      ProjectedGameEffectBatch batch(String sourceId, int offset) {
        return ProjectedGameEffectBatch(
          domainEffects: [
            _effect(sourceId: sourceId, offset: offset, ordinal: 0),
          ],
        );
      }

      final renderer = _RecordingRendererViewModel()
        ..activateProjectedEffectSource('match_a');
      await renderer.applyProjectedTransition(
        GameClientState(),
        batch('match_a', 10),
      );
      renderer.activateProjectedEffectSource('match_b');
      await renderer.applyProjectedTransition(
        GameClientState(),
        batch('match_b', 1),
      );
      await renderer.applyProjectedTransition(
        GameClientState(),
        batch('match_a', 10),
      );

      expect(renderer.applied, hasLength(2));
    },
  );

  test(
    'renderer recreation and replay seek have explicit lifecycles',
    () async {
      final batch = ProjectedGameEffectBatch(
        domainEffects: [_effect(offset: 8, ordinal: 0)],
      );
      final first = _RecordingRendererViewModel()
        ..activateProjectedEffectSource('match_1');
      await first.applyProjectedTransition(GameClientState(), batch);
      await first.applyProjectedTransition(GameClientState(), batch);
      expect(first.applied, hasLength(1));

      final recreated = _RecordingRendererViewModel()
        ..activateProjectedEffectSource('match_1');
      await recreated.applyProjectedTransition(GameClientState(), batch);
      recreated.resetProjectedEffectCursorForReplaySeek();
      await recreated.applyProjectedTransition(GameClientState(), batch);

      expect(recreated.applied, hasLength(2));
    },
  );
}

ProjectedGameEffect _effect({
  String sourceId = 'match_1',
  required int offset,
  required int ordinal,
}) {
  return ProjectedGameEffect(
    effect: const JumpCameraEffect(col: 1, row: 2),
    sourceId: sourceId,
    eventId: '$sourceId:$offset:0',
    animationId: '$sourceId:$offset:JumpCameraEffect:1,2:$ordinal',
    eventOffset: offset,
    eventSequence: 0,
    authoritativeTick: offset,
    authoritativeStartMicrosUtc: offset * Duration.microsecondsPerSecond,
    ordinal: ordinal,
    startOffset: Duration(milliseconds: ordinal),
    duration: Duration.zero,
  );
}

ProjectedGameEffectBatch _batch({required int offset}) {
  final effect = _effect(offset: offset, ordinal: 0);
  return ProjectedGameEffectBatch(
    identity: PresentationBatchIdentity(
      sourceId: effect.sourceId,
      eventOffset: offset,
      authoritativeTick: effect.authoritativeTick,
      authoritativeStartMicrosUtc: effect.authoritativeStartMicrosUtc,
    ),
    domainEffects: [effect],
  );
}

final class _RecordingRendererViewModel implements RendererViewModel {
  final List<RendererEffect> applied = [];
  final List<GameClientState> appliedStates = [];

  @override
  CameraState get cameraState => const CameraState(x: 0, y: 0, zoom: 1);

  @override
  AppLocalizations? get l10n => null;

  @override
  Future<void> applyTransition(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) async {
    appliedStates.add(state);
    applied.addAll(effects);
  }

  @override
  void applyStateWithoutCameraFocus(
    GameClientState state, {
    int? currentTurn,
  }) {}

  @override
  Future<void> handleEffect(RendererEffect effect) async {
    applied.add(effect);
  }
}
