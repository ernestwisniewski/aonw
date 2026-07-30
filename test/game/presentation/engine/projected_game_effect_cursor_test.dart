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
        state: const GameState(),
        previousState: const GameState(),
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
        state: const GameState(),
        previousState: const GameState(),
      );
    }

    final cached = batch('intent_1');
    await renderer.applyProjectedTransition(const GameState(), cached);
    await renderer.applyProjectedTransition(const GameState(), cached);
    await renderer.applyProjectedTransition(
      const GameState(),
      batch('intent_2'),
    );

    expect(renderer.applied.whereType<JumpCameraEffect>(), hasLength(2));
  });

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
    final state = GameState(
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
        const GameState(),
        batch('match_a', 10),
      );
      renderer.activateProjectedEffectSource('match_b');
      await renderer.applyProjectedTransition(
        const GameState(),
        batch('match_b', 1),
      );
      await renderer.applyProjectedTransition(
        const GameState(),
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
      await first.applyProjectedTransition(const GameState(), batch);
      await first.applyProjectedTransition(const GameState(), batch);
      expect(first.applied, hasLength(1));

      final recreated = _RecordingRendererViewModel()
        ..activateProjectedEffectSource('match_1');
      await recreated.applyProjectedTransition(const GameState(), batch);
      recreated.resetProjectedEffectCursorForReplaySeek();
      await recreated.applyProjectedTransition(const GameState(), batch);

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
    animationId: '$sourceId:$offset:JumpCameraEffect:1,2:$ordinal',
    eventOffset: offset,
    ordinal: ordinal,
    startOffset: Duration(milliseconds: ordinal),
  );
}

final class _RecordingRendererViewModel implements RendererViewModel {
  final List<RendererEffect> applied = [];

  @override
  CameraState get cameraState => const CameraState(x: 0, y: 0, zoom: 1);

  @override
  AppLocalizations? get l10n => null;

  @override
  Future<void> applyTransition(
    GameState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) async {
    applied.addAll(effects);
  }

  @override
  void applyStateWithoutCameraFocus(GameState state, {int? currentTurn}) {}

  @override
  Future<void> handleEffect(RendererEffect effect) async {
    applied.add(effect);
  }
}
