import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'worker_command_resolver_parity_test_support.dart';

void main() {
  group('worker command persistent/domain adapter parity', () {
    test('select clears matching pending and preserves city draft', () {
      final states = _workerStates(interaction: _matchingInteraction());

      final results = _selectBoth(states);

      _expectAcceptedParity(states, results);
      _expectMatchingPendingCleared(states, results);
      expect(
        results.persistent.state.units.first.workerJob?.improvementType,
        FieldImprovementType.farm,
      );
      expect(results.persistent.state.units.first.workerJob?.totalTurns, 2);
    });

    test('select accepted interaction no-op preserves slice identities', () {
      final states = _workerStates(interaction: _unrelatedInteraction());

      final results = _selectBoth(states);

      _expectAcceptedParity(states, results);
      _expectInteractionIdentityPreserved(states, results);
      expect(
        results.domain.interaction.pendingAction,
        states.interaction.pendingAction,
      );
    });

    test('confirm consumes a matching pending selection with exact parity', () {
      final states = _workerStates(interaction: _matchingInteraction());

      final results = _confirmBoth(
        states,
        command: const ConfirmWorkerImprovementCommand(_workerId),
      );

      _expectAcceptedParity(states, results);
      _expectMatchingPendingCleared(states, results);
      expect(
        results.persistent.state.units.first.workerJob?.improvementType,
        FieldImprovementType.farm,
      );
    });

    test('self-contained confirm preserves unrelated pending by identity', () {
      final states = _workerStates(interaction: _unrelatedInteraction());

      final results = _confirmBoth(
        states,
        command: const ConfirmWorkerImprovementCommand(
          _workerId,
          improvementType: FieldImprovementType.farm,
        ),
      );

      _expectAcceptedParity(states, results);
      _expectInteractionIdentityPreserved(states, results);
    });

    test('cancel job preserves matching pending and city draft', () {
      final worker = _worker(
        queuedPath: _queuedPath(),
        workerJob: const WorkerJob(
          targetHex: CityHex(col: 1, row: 0),
          improvementType: FieldImprovementType.farm,
          remainingTurns: 1,
          totalTurns: 3,
        ),
      );
      final states = _workerStates(
        units: [worker, _guard()],
        interaction: _matchingInteraction(),
      );

      final results = _cancelJobBoth(states);

      _expectAcceptedParity(states, results);
      _expectInteractionIdentityPreserved(states, results);
      expect(results.persistent.state.units.first.workerJob, isNull);
      expect(results.persistent.state.units.first.queuedPath, isNull);
    });

    test('assign clears matching pending and preserves city draft', () {
      final states = _workerStates(
        fieldImprovements: const [_farm],
        interaction: _matchingInteraction(),
      );

      final results = _assignBoth(states);

      _expectAcceptedParity(states, results);
      _expectMatchingPendingCleared(states, results);
      expect(
        results.persistent.state.units.first.workerAssignment,
        const WorkerAssignment(targetHex: CityHex(col: 1, row: 0)),
      );
    });

    test('assign accepted interaction no-op preserves slice identities', () {
      final states = _workerStates(
        fieldImprovements: const [_farm],
        interaction: _unrelatedInteraction(),
      );

      final results = _assignBoth(states);

      _expectAcceptedParity(states, results);
      _expectInteractionIdentityPreserved(states, results);
    });

    test('cancel assignment preserves unrelated pending and city draft', () {
      final worker = _worker(
        queuedPath: _queuedPath(),
        workerAssignment: const WorkerAssignment(
          targetHex: CityHex(col: 1, row: 0),
        ),
      );
      final states = _workerStates(
        units: [worker, _guard()],
        interaction: _unrelatedInteraction(),
      );

      final results = _cancelAssignmentBoth(states);

      _expectAcceptedParity(states, results);
      _expectInteractionIdentityPreserved(states, results);
      expect(results.persistent.state.units.first.workerAssignment, isNull);
      expect(results.persistent.state.units.first.queuedPath, isNull);
    });

    test('all five reject paths preserve complete boundary identities', () {
      final interaction = PersistedInteractionState(
        cityFoundingDraft: _cityDraft(),
        pendingAction: const PendingResearchSelection(ownerPlayerId: _playerId),
      );
      final states = _workerStates(units: [_guard()], interaction: interaction);
      final cases = <({String reason, _WorkerAdapterResults results})>[
        (reason: 'worker_not_found', results: _selectBoth(states)),
        (
          reason: 'worker_improvement_not_selected',
          results: _confirmBoth(
            states,
            command: const ConfirmWorkerImprovementCommand(_workerId),
          ),
        ),
        (reason: 'worker_not_found', results: _cancelJobBoth(states)),
        (reason: 'worker_not_found', results: _assignBoth(states)),
        (reason: 'worker_not_found', results: _cancelAssignmentBoth(states)),
      ];

      for (final testCase in cases) {
        _expectRejectedIdentity(
          states,
          testCase.results,
          reason: testCase.reason,
        );
      }
    });
  });
}
