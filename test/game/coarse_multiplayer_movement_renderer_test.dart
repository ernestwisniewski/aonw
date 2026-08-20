import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/game_renderer_flame_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'exact stream movement falls back once after an enemy leaves vision',
    () async {
      final enemy = GameUnit.produced(
        id: 'enemy',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final before = GameClientState(
        activePlayerId: 'player_1',
        fogOfWar: _fog({const HexCoordinate(col: 0, row: 0)}),
        units: [enemy],
      );
      final after = GameClientState(
        activePlayerId: 'player_1',
        fogOfWar: _fog({}),
      );
      const event = UnitMovedEvent(
        unitId: 'enemy',
        fromCol: 0,
        fromRow: 0,
        toCol: 3,
        toRow: 0,
      );
      final live = _liveMovementEvent(event);
      expect(live.movementExecutions, hasLength(2));
      final batch = DomainEventPresentationProjector.projectObservedBatch(
        identity: PresentationBatchIdentity(
          sourceId: live.wire.matchId,
          eventOffset: live.wire.offset,
        ),
        interactionEffects: const [],
        events: live.events,
        visibleMovementExecutions: live.movementExecutions,
        previousState: before,
        state: after,
      );
      final movement = batch.domainEffects.single.effect;
      expect(movement, isA<AnimateUnitMoveEffect>());
      final coarse = movement as AnimateUnitMoveEffect;
      expect((coarse.fromCol, coarse.fromRow), (0, 0));
      expect((coarse.steps.single.col, coarse.steps.single.row), (3, 0));
      expect(coarse.steps.single.cumulativeCost, 0);
      final renderer = GameRenderer(mapData: _map(), onCommand: (_) async {});
      await gameRendererFlameTester.initializeWithState(renderer, before);

      final transition = renderer.applyProjectedTransition(after, batch);
      await Future<void>.delayed(Duration.zero);

      expect(renderer.animatingUnitIdsListenable.value, contains(enemy.id));

      renderer.update(0.7);
      await transition.timeout(const Duration(seconds: 1));

      await renderer.applyProjectedTransition(after, batch);
      expect(renderer.animatingUnitIdsListenable.value, isEmpty);
    },
  );

  test('late authoritative movement starts instead of being dropped', () async {
    final enemy = GameUnit.produced(
      id: 'enemy',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    final before = GameClientState(units: [enemy]);
    final after = GameClientState(units: [enemy.copyWith(col: 1, row: 0)]);
    const authoritativeStartMicrosUtc = 1000000;
    final batch = DomainEventPresentationProjector.projectObservedBatch(
      identity: const PresentationBatchIdentity(
        sourceId: 'match_1',
        eventOffset: 7,
        authoritativeStartMicrosUtc: authoritativeStartMicrosUtc,
      ),
      interactionEffects: const [],
      events: const [
        UnitMovedEvent(
          unitId: 'enemy',
          fromCol: 0,
          fromRow: 0,
          toCol: 1,
          toRow: 0,
        ),
      ],
      visibleMovementExecutions: const [],
      previousState: before,
      state: after,
    );
    final renderer = GameRenderer(
      mapData: _map(),
      onCommand: (_) async {},
      presentationClock: const _FixedClock(
        authoritativeStartMicrosUtc + 1000000,
      ),
    );
    await gameRendererFlameTester.initializeWithState(renderer, before);

    final transition = renderer.applyProjectedTransition(after, batch);
    await Future<void>.delayed(Duration.zero);

    expect(renderer.animatingUnitIdsListenable.value, contains(enemy.id));

    renderer.update(0.7);
    await transition.timeout(const Duration(seconds: 1));
    expect(renderer.animatingUnitIdsListenable.value, isEmpty);
    expect(renderer.unitMarkerPositionForTesting(enemy.id), isNotNull);
  });

  test(
    'movement after an empty authoritative offset still interpolates',
    () async {
      final unit = GameUnit.produced(
        id: 'unit_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 0,
        row: 0,
      );
      final state6 = GameClientState(units: [unit]);
      final state7 = GameClientState(units: [unit.copyWith(col: 1)]);
      final state8 = state7;
      final state9 = GameClientState(units: [unit.copyWith(col: 2)]);
      final renderer = GameRenderer(mapData: _map(), onCommand: (_) async {})
        ..activateProjectedEffectSource('match_1', nextEventOffset: 7)
        ..applyState(state6);
      await gameRendererFlameTester.initialize(renderer);

      final firstMove = renderer.applyProjectedTransition(
        state7,
        _movementBatch(
          offset: 7,
          previousState: state6,
          state: state7,
          fromCol: 0,
          toCol: 1,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      renderer.update(0.61);
      await firstMove.timeout(const Duration(seconds: 1));

      await renderer.applyProjectedTransition(
        state8,
        ProjectedGameEffectBatch(
          identity: const PresentationBatchIdentity(
            sourceId: 'match_1',
            eventOffset: 8,
          ),
          sequenceDirective: PresentationSequenceDirective.advance,
        ),
      );

      final secondMove = renderer.applyProjectedTransition(
        state9,
        _movementBatch(
          offset: 9,
          previousState: state8,
          state: state9,
          fromCol: 1,
          toCol: 2,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final origin = UnitMarkerLayer.worldPositionFor(1, 0);
      final destination = UnitMarkerLayer.worldPositionFor(2, 0);
      expect(renderer.unitMarkerPositionForTesting(unit.id), origin);

      renderer.update(0.3);
      final midpoint = renderer.unitMarkerPositionForTesting(unit.id)!;
      expect(midpoint, isNot(origin));
      expect(midpoint, isNot(destination));
      expect(midpoint.x, inExclusiveRange(origin.x, destination.x));

      renderer.update(0.31);
      await secondMove.timeout(const Duration(seconds: 1));
      expect(renderer.unitMarkerPositionForTesting(unit.id), destination);
    },
  );
}

ProjectedGameEffectBatch _movementBatch({
  required int offset,
  required GameClientState previousState,
  required GameClientState state,
  required int fromCol,
  required int toCol,
}) {
  return DomainEventPresentationProjector.projectObservedBatch(
    identity: PresentationBatchIdentity(
      sourceId: 'match_1',
      eventOffset: offset,
    ),
    interactionEffects: const [],
    events: [
      UnitMovedEvent(
        unitId: 'unit_1',
        fromCol: fromCol,
        fromRow: 0,
        toCol: toCol,
        toRow: 0,
      ),
    ],
    visibleMovementExecutions: const [],
    previousState: previousState,
    state: state,
  );
}

final class _FixedClock extends Clock {
  const _FixedClock(this.microsUtc);

  final int microsUtc;

  @override
  DateTime now() => DateTime.fromMicrosecondsSinceEpoch(microsUtc, isUtc: true);
}

LiveServerEvent _liveMovementEvent(UnitMovedEvent event) {
  return LiveServerEvent.fromWire(
    wire: WireEvent(
      matchId: 'match_1',
      offset: 7,
      timestamp: DateTime.utc(2026, 7, 31),
      events: [
        GameEventSerializer.toJson(event),
        GameEventSerializer.toJson(
          const UnitMovedEvent(
            unitId: 'enemy',
            fromCol: 1,
            fromRow: 0,
            toCol: 3,
            toRow: 0,
          ),
        ),
      ],
      movementExecutions: WireMovementExecutionList([
        WireMovementExecution(
          unitId: 'enemy',
          fromCol: 0,
          fromRow: 0,
          steps: const [
            WireMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
        WireMovementExecution(
          unitId: 'enemy',
          fromCol: 1,
          fromRow: 0,
          steps: const [
            WireMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 1),
            WireMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 2),
          ],
        ),
      ]),
    ),
    events: [
      event,
      const UnitMovedEvent(
        unitId: 'enemy',
        fromCol: 1,
        fromRow: 0,
        toCol: 3,
        toRow: 0,
      ),
    ],
    combatAnimations: const [],
  );
}

FogOfWarState _fog(Set<HexCoordinate> visible) => FogOfWarState(
  players: {
    'player_1': PlayerFogOfWar(playerId: 'player_1', visibleHexes: visible),
  },
);

WorldMap _map() => WorldMap(
  cols: 4,
  rows: 1,
  tiles: [
    for (var col = 0; col < 4; col++)
      WorldTile(
        col: col,
        row: 0,
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
  ],
);
