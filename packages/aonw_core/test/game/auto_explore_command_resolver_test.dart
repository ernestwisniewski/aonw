import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'auto_explore_command_resolver_test_support.dart';

void main() {
  group('AutoExploreCommandResolver', () {
    test('stops after the preferred candidate reaches the vision bound', () {
      final calculator = _CountingFogRevealCalculator();
      final scout = autoExploreScout(col: 4, row: 4);
      final target = ScoutAutoExplorePlanner(revealCalculator: calculator)
          .targetFor(
            unit: scout,
            mapData: autoExploreMap(cols: 10, rows: 10),
            units: [scout],
            fogOfWar: FogOfWarState.empty,
          );

      expect(target, isNotNull);
      expect(calculator.calls, 1);
    });

    test('direct no-target rejection preserves every input identity', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final interaction = ownedAutoExploreInteraction();
      final state = autoExploreState(
        scout: autoExploreScout(),
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
        interaction: interaction,
      );

      final result = resolveAutoExplore(state, autoExploreMap(cols: 1));

      expect(result.accepted, isFalse);
      expect(result.reason, 'auto_explore_no_target');
      expect(result.units, same(state.movement.units));
      expect(result.fogOfWar, same(state.movement.fogOfWar));
      expect(result.diplomacy, same(state.movement.diplomacy));
      expect(result.interaction, same(interaction));
    });

    test('continuation no-target finishes posture and owned interaction', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final state = autoExploreState(
        scout: autoExploreScout(posture: UnitPosture.autoExploring),
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
        interaction: ownedAutoExploreInteraction(),
      );

      final result = resolveAutoExplore(
        state,
        autoExploreMap(cols: 1),
        phase: AutoExploreCommandPhase.continuation,
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.units.single.posture, UnitPosture.active);
      expect(result.units.single.queuedPath, isNull);
      expect(result.interaction.pendingAction, isNull);
      expect(result.interaction.cityFoundingDraft, isNull);
      expect(result.events, isEmpty);
      expect(result.execution, isNull);
    });

    test('immediate move forwards event and execution and owns outputs', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final sentinel = autoExploreScout(id: 'sentinel', col: 9, row: 9);
      final state = autoExploreState(
        scout: autoExploreScout(),
        additionalUnits: [sentinel],
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
        interaction: ownedAutoExploreInteraction(),
      );

      final result = resolveAutoExplore(state, autoExploreMap(cols: 2));

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.units.first.posture, UnitPosture.autoExploring);
      expect((result.units.first.col, result.units.first.row), (1, 0));
      expect(result.units.last, same(sentinel));
      expect(result.events.single, isA<UnitMovedEvent>());
      expect(result.execution, isNotNull);
      expect(result.execution!.unitId, autoExploreUnitId);
      expect(autoExploreStepCoordinates(result.execution!.steps), const [
        (1, 0),
      ]);
      expect(result.interaction.pendingAction, isNull);
      expect(result.interaction.cityFoundingDraft, isNull);
      expect(
        () => result.units.add(autoExploreScout(id: 'mutation')),
        throwsUnsupportedError,
      );
      expect(
        () => result.events.add(
          const UnitMovedEvent(
            unitId: 'mutation',
            fromCol: 0,
            fromRow: 0,
            toCol: 1,
            toRow: 0,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('unrelated interaction retains exact identity after movement', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final interaction = unrelatedAutoExploreInteraction();
      final state = autoExploreState(
        scout: autoExploreScout(),
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
        interaction: interaction,
      );

      final result = resolveAutoExplore(state, autoExploreMap(cols: 2));

      expect(result.accepted, isTrue);
      expect(result.interaction, same(interaction));
    });

    test('mixed interaction clears only the slice owned by the scout', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final unrelatedDraft = CityFoundingDraft(
        unitId: 'other_unit',
        ownerPlayerId: autoExploreActorId,
        center: const CityHex(col: 0, row: 0),
      );
      const ownedPending = PendingUnitTurnSkip(
        ownerPlayerId: autoExploreActorId,
        unitId: autoExploreUnitId,
        restoreMovementPoints: 5,
      );
      final interaction = DomainActionState(
        cityFoundingDraft: unrelatedDraft,
        pendingAction: ownedPending,
      );
      final state = autoExploreState(
        scout: autoExploreScout(),
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
        interaction: interaction,
      );

      final result = resolveAutoExplore(state, autoExploreMap(cols: 2));

      expect(result.accepted, isTrue);
      expect(result.interaction.pendingAction, isNull);
      expect(
        result.interaction.cityFoundingDraft,
        same(interaction.cityFoundingDraft),
      );
    });

    test('partial move queues the full route and forwards executed prefix', () {
      final known = {
        for (var col = 0; col <= 3; col++) HexCoordinate(col: col, row: 0),
      };
      final state = autoExploreState(
        scout: autoExploreScout(movementPoints: 1),
        fogOfWar: autoExploreFog(visible: known, discovered: known),
      );

      final result = resolveAutoExplore(state, autoExploreMap(cols: 5));

      expect(result.accepted, isTrue);
      final moved = result.units.first;
      expect((moved.col, moved.row, moved.movementPoints), (1, 0, 0));
      expect(
        (moved.queuedPath?.targetCol, moved.queuedPath?.targetRow),
        (4, 0),
      );
      expect(autoExploreStepCoordinates(moved.queuedPath!.steps), const [
        (0, 0),
        (1, 0),
        (2, 0),
        (3, 0),
        (4, 0),
      ]);
      expect(autoExploreStepCoordinates(result.execution!.steps), const [
        (1, 0),
      ]);
      expect(moved.posture, UnitPosture.autoExploring);
    });

    test('capacity-only terrain is not selected as an exploration target', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final interaction = ownedAutoExploreInteraction();
      final state = autoExploreState(
        scout: autoExploreScout(movementPoints: 2),
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
        interaction: interaction,
      );
      final map = autoExploreMap(
        cols: 2,
        terrainOverrides: const {
          (col: 1, row: 0): [TerrainType.snow, TerrainType.hills],
        },
      );

      final result = resolveAutoExplore(state, map);

      expect(result.accepted, isFalse);
      expect(result.reason, 'auto_explore_no_target');
      expect(result.units, same(state.movement.units));
      expect(result.fogOfWar, same(state.movement.fogOfWar));
      expect(result.diplomacy, same(state.movement.diplomacy));
      expect(result.interaction, same(interaction));
      expect(result.events, isEmpty);
      expect(result.execution, isNull);
    });

    _registerDynamicObstacleMatrix();

    test(
      'hidden unit leaves target scan unchanged but blocks full-state move',
      () {
        const origin = HexCoordinate(col: 0, row: 0);
        final fog = autoExploreFog(visible: {origin}, discovered: {origin});
        final baseline = autoExploreState(
          scout: autoExploreScout(),
          fogOfWar: fog,
        );
        final blocker = autoExploreScout(
          id: 'hidden_target_blocker',
          ownerPlayerId: autoExploreOpponentId,
          type: GameUnitType.warrior,
          col: 1,
        );
        final blocked = autoExploreState(
          scout: autoExploreScout(),
          additionalUnits: [blocker],
          fogOfWar: fog,
        );
        final map = autoExploreMap(cols: 2);

        final baselineResult = resolveAutoExplore(baseline, map);
        final blockedResult = resolveAutoExplore(blocked, map);

        expect(baselineResult.accepted, isTrue);
        expect(baselineResult.execution!.destination.col, 1);
        expect(blockedResult.accepted, isTrue);
        expect(blockedResult.reason, isNull);
        expect(
          (blockedResult.units.first.col, blockedResult.units.first.row),
          (0, 0),
        );
        expect(blockedResult.events, isEmpty);
        expect(blockedResult.execution, isNull);
      },
    );

    test('new diplomatic contact is propagated with movement output', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final hiddenOpponent = autoExploreScout(
        id: 'revealed_opponent',
        ownerPlayerId: autoExploreOpponentId,
        type: GameUnitType.warrior,
        col: 3,
      );
      final state = autoExploreState(
        scout: autoExploreScout(movementPoints: 1),
        additionalUnits: [hiddenOpponent],
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
      );

      final result = resolveAutoExplore(state, autoExploreMap(cols: 4));

      expect(result.accepted, isTrue);
      expect(result.execution, isNotNull);
      expect(
        result.diplomacy.hasContact(autoExploreActorId, autoExploreOpponentId),
        isTrue,
      );
    });

    test('continuation hidden no-op finishes instead of looping', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final blocker = autoExploreScout(
        id: 'hidden_blocker',
        ownerPlayerId: autoExploreOpponentId,
        type: GameUnitType.warrior,
        col: 1,
      );
      final state = autoExploreState(
        scout: autoExploreScout(posture: UnitPosture.autoExploring),
        additionalUnits: [blocker],
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
      );

      final result = resolveAutoExplore(
        state,
        autoExploreMap(cols: 2),
        phase: AutoExploreCommandPhase.continuation,
      );

      expect(result.accepted, isTrue);
      expect(result.units.first.posture, UnitPosture.active);
      expect(result.units.first.queuedPath, isNull);
      expect(result.events, isEmpty);
      expect(result.execution, isNull);
    });

    test('forwards the target route exclusions to movement resolution', () {
      final fixture = _reservationFixture();

      final result = resolveAutoExplore(fixture.state, fixture.map);

      expect(result.accepted, isTrue);
      expect(result.execution, isNotNull);
      expect(
        autoExploreStepCoordinates(result.execution!.steps),
        isNot(contains(const (3, 0))),
      );
      expect(
        autoExploreStepCoordinates(result.execution!.steps),
        containsAll(const [(3, 1), (4, 1)]),
      );
    });
  });
}

final class _CountingFogRevealCalculator extends FogRevealCalculator {
  int calls = 0;

  @override
  Set<HexCoordinate> visibleHexesFor({
    required MapTileLookup mapData,
    required Iterable<FogRevealSource> sources,
  }) {
    calls++;
    return super.visibleHexesFor(mapData: mapData, sources: sources);
  }
}

void _registerDynamicObstacleMatrix() {
  for (final obstacle in const ['unit', 'city']) {
    for (final knowledge in const ['hidden', 'visible', 'no-fog']) {
      test('$knowledge $obstacle does not leak a blocker-specific reason', () {
        const origin = HexCoordinate(col: 0, row: 0);
        const target = HexCoordinate(col: 1, row: 0);
        final blocker = autoExploreScout(
          id: '${knowledge}_blocker',
          ownerPlayerId: autoExploreOpponentId,
          type: GameUnitType.warrior,
          col: 1,
        );
        final city = GameCity(
          id: '${knowledge}_city',
          ownerPlayerId: autoExploreOpponentId,
          name: 'Foreign city',
          center: const CityHex(col: 1, row: 0),
        );
        final fog = switch (knowledge) {
          'hidden' => autoExploreFog(visible: {origin}, discovered: {origin}),
          'visible' => autoExploreFog(
            visible: {origin, target},
            discovered: {origin, target},
          ),
          _ => FogOfWarState.empty,
        };
        final state = autoExploreState(
          scout: autoExploreScout(),
          additionalUnits: obstacle == 'unit' ? [blocker] : const [],
          cities: obstacle == 'city' ? [city] : const [],
          fogOfWar: fog,
        );

        final result = resolveAutoExplore(state, autoExploreMap(cols: 2));

        if (knowledge == 'hidden') {
          expect(result.accepted, isTrue);
          expect(result.reason, isNull);
          expect(result.units.first.posture, UnitPosture.autoExploring);
        } else {
          expect(result.accepted, isFalse);
          expect(result.reason, 'auto_explore_no_target');
          expect(result.units, same(state.movement.units));
        }
        expect(result.events, isEmpty);
        expect(result.execution, isNull);
      });
    }
  }
}

({AutoExploreCommandState state, MapTraversalView map}) _reservationFixture() {
  final firstScout = autoExploreScout(id: 'first_scout', col: 2)
      .copyWithPosture(UnitPosture.autoExploring)
      .copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 3,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
            UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
          ],
        ),
      );
  final secondScout = autoExploreScout(col: 0, row: 1);
  final known = {
    for (var col = 0; col < 5; col++)
      for (var row = 0; row < 2; row++) HexCoordinate(col: col, row: row),
  };
  return (
    state: autoExploreState(
      scout: secondScout,
      additionalUnits: [firstScout],
      fogOfWar: autoExploreFog(visible: known, discovered: known),
    ),
    map: autoExploreMap(cols: 6, rows: 2),
  );
}
