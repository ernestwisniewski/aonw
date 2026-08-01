import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'worker_command_resolver_test_support.dart';

void main() {
  group('WorkerCommandResolver.selectWorkerImprovement', () {
    test('starts authoritatively without preview using the explicit pace', () {
      final worker = _worker();
      final guard = _unit(id: 'guard');
      final units = [worker, guard];
      final interaction = DomainActionState(
        pendingAction: const PendingCityExpansionSelection(
          ownerPlayerId: _playerId,
          cityId: 'city_1',
        ),
      );

      final result = _select(
        units: units,
        interaction: interaction,
        paceBalance: PaceBalance.standard60,
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.units, units), isFalse);
      expect(identical(result.units.last, guard), isTrue);
      expect(identical(result.interaction, interaction), isTrue);
      final updated = result.units.first;
      expect(updated.movementPoints, 0);
      expect(updated.workerAssignment, isNull);
      expect(updated.workerJob?.targetHex, const CityHex(col: 1, row: 0));
      expect(updated.workerJob?.improvementType, FieldImprovementType.farm);
      expect(updated.workerJob?.remainingTurns, 2);
      expect(updated.workerJob?.totalTurns, 2);
      expect(identical(units.first, worker), isTrue);
      expect(worker.workerJob, isNull);
      expect(
        () => result.units.add(_unit(id: 'extra')),
        throwsUnsupportedError,
      );
    });

    test('clears a matching pending action but preserves city draft', () {
      final interaction = _workerInteraction();
      final draft = interaction.cityFoundingDraft;

      final result = _select(interaction: interaction);

      expect(result.accepted, isTrue);
      expect(identical(result.interaction, interaction), isFalse);
      expect(result.interaction.pendingAction, isNull);
      expect(identical(result.interaction.cityFoundingDraft, draft), isTrue);
    });

    test('preserves foreign and unrelated pending actions by identity', () {
      final interactions = [
        DomainActionState(
          pendingAction: const PendingWorkerActionSelection(
            ownerPlayerId: _otherPlayerId,
            unitId: _workerId,
            improvementType: FieldImprovementType.farm,
          ),
        ),
        DomainActionState(
          pendingAction: const PendingWorkerActionSelection(
            ownerPlayerId: _playerId,
            unitId: 'other_worker',
            improvementType: FieldImprovementType.farm,
          ),
        ),
      ];

      for (final interaction in interactions) {
        final result = _select(interaction: interaction);

        expect(result.accepted, isTrue);
        expect(identical(result.interaction, interaction), isTrue);
      }
    });

    test('preserves exact rejection precedence and input identity', () {
      final interaction = _workerInteraction();
      final missing = <GameUnit>[];
      _expectRejected(
        _select(
          units: missing,
          research: ResearchState.empty,
          interaction: interaction,
        ),
        units: missing,
        interaction: interaction,
        reason: 'worker_not_found',
      );

      final foreign = [_worker(ownerPlayerId: _otherPlayerId)];
      _expectRejected(
        _select(
          units: foreign,
          research: ResearchState.empty,
          interaction: interaction,
        ),
        units: foreign,
        interaction: interaction,
        reason: 'worker_not_controlled',
      );

      final locked = [_worker()];
      _expectRejected(
        _select(
          units: locked,
          research: ResearchState.empty,
          interaction: interaction,
        ),
        units: locked,
        interaction: interaction,
        reason: 'worker_improvement_unavailable',
      );
    });
  });

  group('WorkerCommandResolver.confirmWorkerImprovement', () {
    test('starts the pending improvement and clears matching interaction', () {
      final interaction = _workerInteraction();
      final draft = interaction.cityFoundingDraft;

      final result = _confirm(interaction: interaction);

      expect(result.accepted, isTrue);
      expect(
        result.units.single.workerJob?.improvementType,
        FieldImprovementType.farm,
      );
      expect(result.units.single.workerJob?.remainingTurns, 3);
      expect(result.interaction.pendingAction, isNull);
      expect(identical(result.interaction.cityFoundingDraft, draft), isTrue);
    });

    test('accepts a self-contained command without pending interaction', () {
      final interaction = DomainActionState(
        pendingAction: const PendingCityExpansionSelection(
          ownerPlayerId: _playerId,
          cityId: 'city_1',
        ),
      );

      final result = _confirm(
        interaction: interaction,
        command: const ConfirmWorkerImprovementCommand(
          _workerId,
          improvementType: FieldImprovementType.farm,
        ),
      );

      expect(result.accepted, isTrue);
      expect(identical(result.interaction, interaction), isTrue);
      expect(
        result.units.single.workerJob?.improvementType,
        FieldImprovementType.farm,
      );
    });

    test('preserves exact rejection precedence and input identity', () {
      final foreignPendingWithoutSelection = DomainActionState(
        pendingAction: const PendingWorkerActionSelection(
          ownerPlayerId: _otherPlayerId,
          unitId: _workerId,
        ),
      );
      final noSelectionUnits = <GameUnit>[];
      _expectRejected(
        _confirm(
          units: noSelectionUnits,
          interaction: foreignPendingWithoutSelection,
        ),
        units: noSelectionUnits,
        interaction: foreignPendingWithoutSelection,
        reason: 'worker_improvement_not_selected',
      );

      final foreignPending = DomainActionState(
        pendingAction: const PendingWorkerActionSelection(
          ownerPlayerId: _otherPlayerId,
          unitId: _workerId,
          improvementType: FieldImprovementType.farm,
        ),
      );
      final actionControlUnits = <GameUnit>[];
      _expectRejected(
        _confirm(units: actionControlUnits, interaction: foreignPending),
        units: actionControlUnits,
        interaction: foreignPending,
        reason: 'worker_action_not_controlled',
      );

      const explicit = ConfirmWorkerImprovementCommand(
        _workerId,
        improvementType: FieldImprovementType.farm,
      );
      final missing = <GameUnit>[];
      _expectRejected(
        _confirm(units: missing, command: explicit),
        units: missing,
        interaction: DomainActionState.empty,
        reason: 'worker_not_found',
      );

      final foreign = [_worker(ownerPlayerId: _otherPlayerId)];
      _expectRejected(
        _confirm(
          units: foreign,
          command: explicit,
          research: ResearchState.empty,
        ),
        units: foreign,
        interaction: DomainActionState.empty,
        reason: 'worker_not_controlled',
      );

      final locked = [_worker()];
      _expectRejected(
        _confirm(
          units: locked,
          command: explicit,
          research: ResearchState.empty,
        ),
        units: locked,
        interaction: DomainActionState.empty,
        reason: 'worker_improvement_unavailable',
      );
    });
  });

  group('WorkerCommandResolver.cancelWorkerJob', () {
    test('cancels the job without changing persisted interaction', () {
      final queuedPath = QueuedMovePath(
        targetCol: 2,
        targetRow: 0,
        steps: [
          const UnitMovementStep(
            col: 1,
            row: 0,
            enterCost: 0,
            cumulativeCost: 0,
          ),
        ],
      );
      final worker = _worker()
          .copyWithQueuedPath(queuedPath)
          .copyWithWorkerJob(
            const WorkerJob(
              targetHex: CityHex(col: 1, row: 0),
              improvementType: FieldImprovementType.farm,
              remainingTurns: 1,
              totalTurns: 3,
            ),
          );
      final units = [worker];
      final interaction = _workerInteraction();

      final result = WorkerCommandResolver.cancelWorkerJob(
        units: units,
        interaction: interaction,
        command: const CancelWorkerJobCommand(_workerId),
        actorPlayerId: _playerId,
      );

      expect(result.accepted, isTrue);
      expect(result.units.single.workerJob, isNull);
      expect(result.units.single.queuedPath, isNull);
      expect(identical(result.interaction, interaction), isTrue);
      expect(worker.workerJob, isNotNull);
      expect(() => result.units.clear(), throwsUnsupportedError);
    });

    test('preserves exact rejection precedence and input identity', () {
      final interaction = _workerInteraction();
      final missing = <GameUnit>[];
      _expectRejected(
        WorkerCommandResolver.cancelWorkerJob(
          units: missing,
          interaction: interaction,
          command: const CancelWorkerJobCommand(_workerId),
          actorPlayerId: _playerId,
        ),
        units: missing,
        interaction: interaction,
        reason: 'worker_not_found',
      );

      final foreign = [_worker(ownerPlayerId: _otherPlayerId)];
      _expectRejected(
        WorkerCommandResolver.cancelWorkerJob(
          units: foreign,
          interaction: interaction,
          command: const CancelWorkerJobCommand(_workerId),
          actorPlayerId: _playerId,
        ),
        units: foreign,
        interaction: interaction,
        reason: 'worker_not_controlled',
      );

      final inactive = [_worker()];
      _expectRejected(
        WorkerCommandResolver.cancelWorkerJob(
          units: inactive,
          interaction: interaction,
          command: const CancelWorkerJobCommand(_workerId),
          actorPlayerId: _playerId,
        ),
        units: inactive,
        interaction: interaction,
        reason: 'worker_job_not_active',
      );
    });
  });

  group('WorkerCommandResolver.assignWorkerToHex', () {
    test('assigns worker and clears only matching pending interaction', () {
      final worker = _worker();
      final guard = _unit(id: 'guard');
      final units = [worker, guard];
      final interaction = _workerInteraction();
      final draft = interaction.cityFoundingDraft;

      final result = _assign(units: units, interaction: interaction);

      expect(result.accepted, isTrue);
      expect(identical(result.units, units), isFalse);
      expect(identical(result.units.last, guard), isTrue);
      expect(result.units.first.movementPoints, 0);
      expect(
        result.units.first.workerAssignment,
        const WorkerAssignment(targetHex: CityHex(col: 1, row: 0)),
      );
      expect(result.interaction.pendingAction, isNull);
      expect(identical(result.interaction.cityFoundingDraft, draft), isTrue);
      expect(worker.workerAssignment, isNull);
      expect(() => result.units.removeLast(), throwsUnsupportedError);
    });

    test('preserves unrelated interaction by identity', () {
      final interaction = DomainActionState(
        pendingAction: const PendingWorkerActionSelection(
          ownerPlayerId: _playerId,
          unitId: 'other_worker',
          improvementType: FieldImprovementType.farm,
        ),
      );

      final result = _assign(interaction: interaction);

      expect(result.accepted, isTrue);
      expect(identical(result.interaction, interaction), isTrue);
    });

    test('preserves exact rejection precedence and input identity', () {
      final interaction = _workerInteraction();
      final missing = <GameUnit>[];
      _expectRejected(
        _assign(units: missing, interaction: interaction),
        units: missing,
        interaction: interaction,
        reason: 'worker_not_found',
      );

      final foreign = [_worker(ownerPlayerId: _otherPlayerId)];
      _expectRejected(
        _assign(
          units: foreign,
          interaction: interaction,
          fieldImprovements: const [],
        ),
        units: foreign,
        interaction: interaction,
        reason: 'worker_not_controlled',
      );

      final unavailable = [_worker()];
      _expectRejected(
        _assign(
          units: unavailable,
          interaction: interaction,
          fieldImprovements: const [],
        ),
        units: unavailable,
        interaction: interaction,
        reason: 'worker_assignment_unavailable',
      );
    });
  });

  group('WorkerCommandResolver.cancelWorkerAssignment', () {
    test('cancels assignment without changing persisted interaction', () {
      final queuedPath = QueuedMovePath(
        targetCol: 2,
        targetRow: 0,
        steps: [
          const UnitMovementStep(
            col: 1,
            row: 0,
            enterCost: 0,
            cumulativeCost: 0,
          ),
        ],
      );
      final worker = _worker()
          .copyWithQueuedPath(queuedPath)
          .copyWithWorkerAssignment(
            const WorkerAssignment(targetHex: CityHex(col: 1, row: 0)),
          );
      final units = [worker];
      final interaction = _workerInteraction();

      final result = WorkerCommandResolver.cancelWorkerAssignment(
        units: units,
        interaction: interaction,
        command: const CancelWorkerAssignmentCommand(_workerId),
        actorPlayerId: _playerId,
      );

      expect(result.accepted, isTrue);
      expect(result.units.single.workerAssignment, isNull);
      expect(result.units.single.queuedPath, isNull);
      expect(identical(result.interaction, interaction), isTrue);
      expect(worker.workerAssignment, isNotNull);
    });

    test('preserves exact rejection precedence and input identity', () {
      final interaction = _workerInteraction();
      final missing = <GameUnit>[];
      _expectRejected(
        WorkerCommandResolver.cancelWorkerAssignment(
          units: missing,
          interaction: interaction,
          command: const CancelWorkerAssignmentCommand(_workerId),
          actorPlayerId: _playerId,
        ),
        units: missing,
        interaction: interaction,
        reason: 'worker_not_found',
      );

      final foreign = [_worker(ownerPlayerId: _otherPlayerId)];
      _expectRejected(
        WorkerCommandResolver.cancelWorkerAssignment(
          units: foreign,
          interaction: interaction,
          command: const CancelWorkerAssignmentCommand(_workerId),
          actorPlayerId: _playerId,
        ),
        units: foreign,
        interaction: interaction,
        reason: 'worker_not_controlled',
      );

      final inactive = [_worker()];
      _expectRejected(
        WorkerCommandResolver.cancelWorkerAssignment(
          units: inactive,
          interaction: interaction,
          command: const CancelWorkerAssignmentCommand(_workerId),
          actorPlayerId: _playerId,
        ),
        units: inactive,
        interaction: interaction,
        reason: 'worker_assignment_not_active',
      );
    });
  });
}
