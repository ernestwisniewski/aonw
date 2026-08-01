part of '../turn_auto_explore_drift_characterization_test.dart';

void _registerTurnAutoExploreContinuationCharacterizationTests() {
  group('turn auto-explore continuation kernel drift', () {
    test(
      'turn surfaces preserve diplomacy contact discovered by continuation',
      () {
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
        final input = _persistentTurnState(
          units: [scout, rival],
          fogOfWar: fog,
        );
        final kernel = _resolveAutoExploreKernel(
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
          interaction: DomainActionState.empty,
        );
        final turn = TurnMovementOrchestrator.resetForPlayers(
          state: turnInput,
          context: TurnMovementContext(
            playerIds: const {_playerId},
            phaseKnownPlayerIds: const {_playerId, 'player_2'},
            mapData: map,
          ),
        );
        final persistent = DomainTurnMovementProcessor.resetForPlayers(
          state: input,
          playerIds: const {_playerId},
          mapData: map,
        );

        expect(kernel.accepted, isTrue);
        expect(
          kernel.state.diplomacy.hasContact(_playerId, 'player_2'),
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
          (1, 0, 2, 0, 2, 0),
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
        expect(turn.state.diplomacy.hasContact(_playerId, 'player_2'), isTrue);
        expect(
          persistent.state.diplomacy.hasContact(_playerId, 'player_2'),
          isTrue,
        );
      },
    );
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

    test('turn and persistence surfaces preserve ordered evidence', () {
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
        interaction: DomainActionState.empty,
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
      final persistent = DomainTurnMovementProcessor.resetForPlayers(
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
      expect(persistent.state, isNot(same(persistentInput)));
      expect(_eventSnapshots(autoOnly.events), ['turn_auto_scout:0,0->1,0']);
      expect(_executionSnapshots(autoOnly.executions), [
        'turn_auto_scout:0,0->1,0',
      ]);
      expect(_eventSnapshots(turn.events), [
        'turn_auto_scout:0,0->3,0',
        'turn_auto_scout:1,0->3,0',
      ]);
      expect(_executionSnapshots(turn.executions), [
        'turn_auto_scout:0,0->1,0',
        'turn_auto_scout:1,0->2,0|3,0',
      ]);
      expect(_eventSnapshots(persistent.events), _eventSnapshots(turn.events));
      expect(
        _executionSnapshots(persistent.executions),
        _executionSnapshots(turn.executions),
      );
      _expectImmutableEvidence(autoOnly.events, autoOnly.executions);
      _expectImmutableEvidence(turn.events, turn.executions);
      _expectImmutableEvidence(persistent.events, persistent.executions);
    });
  });
}

_TurnKernelPair _runTurnAndKernel({
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
    turn: _advance(
      units: units,
      cities: cities,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      mapData: mapData,
    ),
    kernel: _resolveAutoExploreKernel(
      state: input,
      command: AutoExploreUnitCommand(units.first.id),
      actorPlayerId: _playerId,
      mapData: mapData,
      phase: AutoExploreCommandPhase.continuation,
    ),
  );
}

DomainState _persistentTurnState({
  required List<GameUnit> units,
  required FogOfWarState fogOfWar,
  List<GameCity> cities = const [],
  DiplomacyState diplomacy = DiplomacyState.empty,
}) {
  return DomainState.snapshot(
    playerColors: const {_playerId: 0xFF112233, 'player_2': 0xFF445566},
    units: units,
    cities: cities,
    fogOfWar: fogOfWar,
    diplomacy: diplomacy,
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
  required DomainState state,
  required List<String> unitIds,
  required MapTraversalView mapData,
}) {
  var current = state;
  final events = <String>[];
  final executions = <String>[];
  for (final unitId in unitIds) {
    final result = _resolveAutoExploreKernel(
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

List<String> _eventSnapshots(Iterable<GameEvent> events) => [
  for (final event in events) _eventSnapshot(event as UnitMovedEvent),
];

List<String> _executionSnapshots(
  Iterable<MovementCommandExecution> executions,
) => [for (final execution in executions) _executionSnapshot(execution)];

void _expectImmutableEvidence(
  List<GameEvent> events,
  List<MovementCommandExecution> executions,
) {
  expect(
    () => events.add(const TurnEndedEvent(playerId: _playerId)),
    throwsUnsupportedError,
  );
  expect(() => executions.removeLast(), throwsUnsupportedError);
}

typedef _TurnKernelPair = ({
  DomainState kernelInput,
  TurnAutoExploreAdvance turn,
  _AutoExploreKernelResult kernel,
});

typedef _KernelContinuationEvidence = ({
  DomainState state,
  List<String> eventSnapshots,
  List<String> executionSnapshots,
});

typedef _AutoExploreKernelResult = ({
  bool accepted,
  DomainState state,
  List<GameEvent> events,
  MovementCommandExecution? execution,
  String? reason,
});

_AutoExploreKernelResult _resolveAutoExploreKernel({
  required DomainState state,
  required AutoExploreUnitCommand command,
  required String actorPlayerId,
  required MapTraversalView mapData,
  required AutoExploreCommandPhase phase,
}) {
  final result = const AutoExploreCommandResolver().resolve(
    state: AutoExploreCommandState(
      movement: MovementCommandState(
        units: state.units,
        cities: state.cities,
        fogOfWar: state.fogOfWar,
        diplomacy: state.diplomacy,
        playerIds: state.knownPlayerIds,
      ),
      interaction: DomainActionState(
        cityFoundingDraft: state.actions.cityFoundingDraft,
        pendingAction: state.actions.pendingAction,
      ),
    ),
    command: command,
    actorPlayerId: actorPlayerId,
    mapData: mapData,
    phase: phase,
  );
  if (!result.accepted) {
    return (
      accepted: false,
      state: state,
      events: const [],
      execution: null,
      reason: result.reason,
    );
  }
  return (
    accepted: true,
    state: state.copyWith(
      units: result.units,
      fogOfWar: result.fogOfWar,
      diplomacy: result.diplomacy,
      actions: DomainActionState(
        cityFoundingDraft: result.interaction.cityFoundingDraft,
        pendingAction: result.interaction.pendingAction,
      ),
    ),
    events: result.events,
    execution: result.execution,
    reason: null,
  );
}
