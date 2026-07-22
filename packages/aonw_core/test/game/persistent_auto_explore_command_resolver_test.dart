import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'auto_explore_command_resolver_test_support.dart';

void main() {
  group('PersistentAutoExploreCommandResolver', () {
    test('adapts the kernel result including event and execution', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final sentinel = autoExploreScout(id: 'sentinel', col: 9, row: 9);
      final state = _persistentState(
        units: [autoExploreScout(), sentinel],
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
      );

      final result = _resolvePersistent(state, autoExploreMap(cols: 2));

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(result.state.units.first.posture, UnitPosture.autoExploring);
      expect(
        (result.state.units.first.col, result.state.units.first.row),
        (1, 0),
      );
      expect(result.state.units.last, same(sentinel));
      expect(result.events.single, isA<UnitMovedEvent>());
      expect(result.execution, isNotNull);
      expect(autoExploreStepCoordinates(result.execution!.steps), const [
        (1, 0),
      ]);
      expect(result.state.playerGold, same(state.playerGold));
      expect(result.state.cities, same(state.cities));
      expect(result.state.artifacts, same(state.artifacts));
      expect(
        () => result.state.units.add(autoExploreScout(id: 'mutation')),
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

    test('rejection preserves the exact persistent state identity', () {
      final state = _persistentState(units: [autoExploreScout(col: -1)]);

      final result = _resolvePersistent(state, autoExploreMap(cols: 1));

      expect(result.accepted, isFalse);
      expect(result.reason, 'unit_out_of_bounds');
      expect(result.state, same(state));
      expect(result.events, isEmpty);
      expect(result.execution, isNull);
    });

    test('unrelated interaction preserves runtime identity', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final interaction = unrelatedAutoExploreInteraction();
      final state = _persistentState(
        units: [autoExploreScout()],
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
        interaction: interaction,
      );

      final result = _resolvePersistent(state, autoExploreMap(cols: 2));

      expect(result.accepted, isTrue);
      expect(result.state.runtimeState, same(state.runtimeState));
      expect(
        result.state.runtimeState.cityFoundingDraft,
        same(state.runtimeState.cityFoundingDraft),
      );
      expect(
        result.state.runtimeState.pendingAction,
        same(state.runtimeState.pendingAction),
      );
    });

    test('owned interaction is cleared without touching runtime sentinels', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final state = _persistentState(
        units: [autoExploreScout()],
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
        interaction: ownedAutoExploreInteraction(),
      );

      final result = _resolvePersistent(state, autoExploreMap(cols: 2));

      expect(result.accepted, isTrue);
      expect(result.state.runtimeState.cityFoundingDraft, isNull);
      expect(result.state.runtimeState.pendingAction, isNull);
      expect(
        result.state.runtimeState.submittedPlayerIds,
        same(state.runtimeState.submittedPlayerIds),
      );
      expect(
        result.state.runtimeState.timeoutStreaksByPlayerId,
        same(state.runtimeState.timeoutStreaksByPlayerId),
      );
    });

    test('mixed cleanup preserves the unrelated draft identity', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final unrelatedDraft = CityFoundingDraft(
        unitId: 'other_unit',
        ownerPlayerId: autoExploreActorId,
        center: const CityHex(col: 0, row: 0),
      );
      final interaction = PersistedInteractionState(
        cityFoundingDraft: unrelatedDraft,
        pendingAction: const PendingUnitTurnSkip(
          ownerPlayerId: autoExploreActorId,
          unitId: autoExploreUnitId,
          restoreMovementPoints: 5,
        ),
      );
      final state = _persistentState(
        units: [autoExploreScout()],
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
        interaction: interaction,
      );

      final result = _resolvePersistent(state, autoExploreMap(cols: 2));

      expect(result.accepted, isTrue);
      expect(result.state.runtimeState.pendingAction, isNull);
      expect(
        result.state.runtimeState.cityFoundingDraft,
        same(state.runtimeState.cityFoundingDraft),
      );
    });

    test('continuation no-target applies the active posture', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final state = _persistentState(
        units: [autoExploreScout(posture: UnitPosture.autoExploring)],
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
      );

      final result = _resolvePersistent(
        state,
        autoExploreMap(cols: 1),
        phase: AutoExploreCommandPhase.continuation,
      );

      expect(result.accepted, isTrue);
      expect(result.state.units.single.posture, UnitPosture.active);
      expect(result.events, isEmpty);
      expect(result.execution, isNull);
    });

    test('persists diplomatic contact propagated by the kernel', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final hiddenOpponent = autoExploreScout(
        id: 'revealed_opponent',
        ownerPlayerId: autoExploreOpponentId,
        type: GameUnitType.warrior,
        col: 3,
      );
      final state = _persistentState(
        units: [autoExploreScout(movementPoints: 1), hiddenOpponent],
        fogOfWar: autoExploreFog(visible: {origin}, discovered: {origin}),
      );

      final result = _resolvePersistent(state, autoExploreMap(cols: 4));

      expect(result.accepted, isTrue);
      expect(result.execution, isNotNull);
      expect(
        result.state.runtimeState.diplomacy.hasContact(
          autoExploreActorId,
          autoExploreOpponentId,
        ),
        isTrue,
      );
      expect(
        result.state.runtimeState.diplomacy,
        isNot(same(state.runtimeState.diplomacy)),
      );
    });
  });
}

PersistentGameState _persistentState({
  required List<GameUnit> units,
  List<GameCity> cities = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
  PersistedInteractionState interaction = PersistedInteractionState.empty,
}) {
  return PersistentGameState.snapshot(
    playerColors: const {
      autoExploreActorId: 0xFF112233,
      autoExploreOpponentId: 0xFF445566,
    },
    playerGold: const {autoExploreActorId: 17},
    units: units,
    cities: cities,
    fogOfWar: fogOfWar,
    runtimeState: GameRuntimeState.snapshot(
      cityFoundingDraft: interaction.cityFoundingDraft,
      pendingAction: interaction.pendingAction,
      submittedPlayerIds: const {'sentinel'},
      timeoutStreaksByPlayerId: const {'sentinel': 2},
    ),
  );
}

PersistentAutoExploreCommandResult _resolvePersistent(
  PersistentGameState state,
  MapTraversalView map, {
  AutoExploreCommandPhase phase = AutoExploreCommandPhase.direct,
}) {
  return const PersistentAutoExploreCommandResolver().resolve(
    state: state,
    command: const AutoExploreUnitCommand(autoExploreUnitId),
    actorPlayerId: autoExploreActorId,
    mapData: map,
    phase: phase,
  );
}
