part of '../turn_auto_explore_drift_characterization_test.dart';

void _registerTurnAutoExploreContinuationCharacterizationTests() {
  group('turn auto-explore continuation kernel drift', () {
    test('turn surfaces lose diplomacy contact discovered by the kernel', () {
      final scout = _autoExploringScout(movementPoints: 1);
      final rival = GameUnit(
        id: 'hidden_rival',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Hidden rival',
        col: 3,
        row: 0,
      );
      final map = _map(cols: 4);
      final fog = _originOnlyFog();
      final input = _persistentTurnState(units: [scout, rival], fogOfWar: fog);
      final kernel = const PersistentAutoExploreCommandResolver().resolve(
        state: input,
        command: const AutoExploreUnitCommand('turn_auto_scout'),
        actorPlayerId: _playerId,
        mapData: map,
        phase: AutoExploreCommandPhase.continuation,
      );
      final turnInput = TurnMovementState(
        units: [scout, rival],
        cities: const [],
        diplomacy: DiplomacyState.empty,
        fogOfWar: fog,
      );
      final turn = TurnMovementOrchestrator.resetForPlayers(
        state: turnInput,
        context: TurnMovementContext(
          playerIds: const {_playerId},
          phaseKnownPlayerIds: const {_playerId, 'player_2'},
          mapData: map,
        ),
      );
      final persistent = PersistentTurnMovementProcessor.resetForPlayers(
        state: input,
        playerIds: const {_playerId},
        mapData: map,
      );

      expect(kernel.accepted, isTrue);
      expect(
        kernel.state.runtimeState.diplomacy.hasContact(_playerId, 'player_2'),
        isTrue,
      );
      expect(
        (
          kernel.state.units.first.col,
          kernel.state.units.first.row,
          turn.state.units.first.col,
          turn.state.units.first.row,
          persistent.state.units.first.col,
          persistent.state.units.first.row,
        ),
        (1, 0, 1, 0, 1, 0),
      );
      expect(
        persistent.state.units.map(_autoExploreTurnUnitSnapshot),
        turn.state.units.map(_autoExploreTurnUnitSnapshot),
      );
      final kernelFog = kernel.state.fogOfWar.fogForPlayer(_playerId);
      final turnFog = turn.state.fogOfWar.fogForPlayer(_playerId);
      final persistentFog = persistent.state.fogOfWar.fogForPlayer(_playerId);
      expect(turnFog.discoveredHexes, kernelFog.discoveredHexes);
      expect(turnFog.visibleHexes, kernelFog.visibleHexes);
      expect(persistentFog.discoveredHexes, kernelFog.discoveredHexes);
      expect(persistentFog.visibleHexes, kernelFog.visibleHexes);
      expect(turn.state.diplomacy, same(turnInput.diplomacy));
      expect(turn.state.diplomacy.hasContact(_playerId, 'player_2'), isFalse);
      expect(persistent.state.runtimeState, same(input.runtimeState));
      expect(
        persistent.state.runtimeState.diplomacy.hasContact(
          _playerId,
          'player_2',
        ),
        isFalse,
      );
    });
  });

  group('turn movement evidence accumulator drift', () {
    test(
      'kernel commands expose deterministic ordered event and path shape',
      () {
        final first = _autoExploringScout(
          id: 'first_scout',
          row: 0,
          movementPoints: 2,
        );
        final second = _autoExploringScout(
          id: 'second_scout',
          row: 1,
          movementPoints: 2,
        );
        final origins = {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 0, row: 1),
        };
        final evidence = _resolveKernelContinuations(
          state: _persistentTurnState(
            units: [first, second],
            fogOfWar: _fog(discovered: origins, visible: origins),
          ),
          unitIds: const ['first_scout', 'second_scout'],
          mapData: _map(cols: 6, rows: 2),
        );

        expect(evidence.eventSnapshots, const [
          'first_scout:0,0->2,0',
          'second_scout:0,1->2,1',
        ]);
        expect(evidence.executionSnapshots, const [
          'first_scout:0,0->1,0|2,0',
          'second_scout:0,1->1,0|2,1',
        ]);
        expect(evidence.state.units.map(_autoExploreTurnUnitSnapshot), [
          'first_scout:2,0;mp=0;target=3,0;steps=0,0|1,0|2,0|3,0',
          'second_scout:2,1;mp=0;target=5,0;steps=0,1|1,0|2,1|3,1|4,1|5,0',
        ]);
      },
    );

    test('turn and persistence surfaces omit the ordered evidence', () {
      final scout = _autoExploringScout(movementPoints: 0).copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 1,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      );
      final map = _map(cols: 6);
      final fog = _originOnlyFog();
      final state = TurnMovementState(
        units: [scout],
        cities: const [],
        diplomacy: DiplomacyState.empty,
        fogOfWar: fog,
      );
      final context = TurnMovementContext(
        playerIds: const {_playerId},
        phaseKnownPlayerIds: const {_playerId},
        mapData: map,
      );
      final turn = TurnMovementOrchestrator.resetForPlayers(
        state: state,
        context: context,
      );
      final persistentInput = _persistentTurnState(
        units: [scout],
        fogOfWar: fog,
      );
      final persistent = PersistentTurnMovementProcessor.resetForPlayers(
        state: persistentInput,
        playerIds: const {_playerId},
        mapData: map,
      );
      final autoOnly = _advance(
        units: [_autoExploringScout(movementPoints: 2)],
        fogOfWar: fog,
        mapData: _map(cols: 3),
      );

      expect(turn.state.units.map(_autoExploreTurnUnitSnapshot), [
        'turn_auto_scout:3,0;mp=0;target=4,0;steps=1,0|2,0|3,0|4,0',
      ]);
      expect(
        persistent.state.units.map(_autoExploreTurnUnitSnapshot),
        turn.state.units.map(_autoExploreTurnUnitSnapshot),
      );
      expect(persistent.state.runtimeState, same(persistentInput.runtimeState));
      _expectNoOrderedMovementEvidence(autoOnly);
      _expectNoOrderedMovementEvidence(turn);
      _expectNoOrderedMovementEvidence(persistent);
    });
  });
}

_LegacyKernelPair _runLegacyAndKernel({
  required List<GameUnit> units,
  required FogOfWarState fogOfWar,
  required MapTraversalView mapData,
  List<GameCity> cities = const [],
  DiplomacyState diplomacy = DiplomacyState.empty,
}) {
  final input = _persistentTurnState(
    units: units,
    cities: cities,
    fogOfWar: fogOfWar,
    diplomacy: diplomacy,
  );
  return (
    kernelInput: input,
    legacy: _advance(
      units: units,
      cities: cities,
      fogOfWar: fogOfWar,
      mapData: mapData,
    ),
    kernel: const PersistentAutoExploreCommandResolver().resolve(
      state: input,
      command: AutoExploreUnitCommand(units.first.id),
      actorPlayerId: _playerId,
      mapData: mapData,
      phase: AutoExploreCommandPhase.continuation,
    ),
  );
}

PersistentGameState _persistentTurnState({
  required List<GameUnit> units,
  required FogOfWarState fogOfWar,
  List<GameCity> cities = const [],
  DiplomacyState diplomacy = DiplomacyState.empty,
}) {
  return PersistentGameState.snapshot(
    playerColors: const {_playerId: 0xFF112233, 'player_2': 0xFF445566},
    units: units,
    cities: cities,
    fogOfWar: fogOfWar,
    runtimeState: GameRuntimeState.snapshot(diplomacy: diplomacy),
  );
}

DiplomacyState _warDiplomacy() {
  final relation = DiplomaticRelation.between(
    playerAId: _playerId,
    playerBId: 'player_2',
    status: DiplomaticRelationStatus.war,
  );
  return DiplomacyState(
    contactKeys: {relation.key},
    relations: {relation.key: relation},
  );
}

_KernelContinuationEvidence _resolveKernelContinuations({
  required PersistentGameState state,
  required List<String> unitIds,
  required MapTraversalView mapData,
}) {
  var current = state;
  final events = <String>[];
  final executions = <String>[];
  for (final unitId in unitIds) {
    final result = const PersistentAutoExploreCommandResolver().resolve(
      state: current,
      command: AutoExploreUnitCommand(unitId),
      actorPlayerId: _playerId,
      mapData: mapData,
      phase: AutoExploreCommandPhase.continuation,
    );
    expect(result.accepted, isTrue, reason: result.reason);
    expect(result.events, everyElement(isA<UnitMovedEvent>()));
    events.addAll(result.events.cast<UnitMovedEvent>().map(_eventSnapshot));
    if (result.execution case final execution?) {
      executions.add(_executionSnapshot(execution));
    }
    current = result.state;
  }
  return (
    state: current,
    eventSnapshots: events,
    executionSnapshots: executions,
  );
}

String _eventSnapshot(UnitMovedEvent event) {
  return '${event.unitId}:${event.fromCol},${event.fromRow}->'
      '${event.toCol},${event.toRow}';
}

String _executionSnapshot(MovementCommandExecution execution) {
  final steps = execution.steps
      .map((step) => '${step.col},${step.row}')
      .join('|');
  return '${execution.unitId}:${execution.fromCol},${execution.fromRow}->$steps';
}

void _expectNoOrderedMovementEvidence(Object result) {
  final dynamic surface = result;
  // These missing getters pin the current contract gap without adding a bridge.
  // ignore: avoid_dynamic_calls
  expect(() => surface.events, throwsNoSuchMethodError);
  // ignore: avoid_dynamic_calls
  expect(() => surface.execution, throwsNoSuchMethodError);
  // ignore: avoid_dynamic_calls
  expect(() => surface.executions, throwsNoSuchMethodError);
}

typedef _LegacyKernelPair = ({
  PersistentGameState kernelInput,
  TurnAutoExploreAdvance legacy,
  PersistentAutoExploreCommandResult kernel,
});

typedef _KernelContinuationEvidence = ({
  PersistentGameState state,
  List<String> eventSnapshots,
  List<String> executionSnapshots,
});
