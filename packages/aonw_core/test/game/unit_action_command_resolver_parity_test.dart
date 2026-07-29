import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'unit_action_command_resolver_parity_test_support.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

void main() {
  group('unit action persistent/domain adapter parity', () {
    test('cancel has exact parity across every cancellable branch', () {
      final unit = _unit(
        movementPoints: 0,
        queuedPath: _queuedPath(),
        workerJob: const WorkerJob(
          targetHex: CityHex(col: 1, row: 1),
          improvementType: FieldImprovementType.farm,
          remainingTurns: 1,
          totalTurns: 2,
        ),
        cityFoundingJob: CityFoundingJob(
          center: const CityHex(col: 1, row: 1),
          controlledHexes: const [CityHex(col: 2, row: 1)],
          remainingTurns: 1,
          totalTurns: 2,
        ),
        workerAssignment: const WorkerAssignment(
          targetHex: CityHex(col: 1, row: 1),
        ),
        merchantTradeRoute: MerchantTradeRoute(
          originCityId: 'origin',
          destinationCityId: 'destination',
          steps: const [
            UnitMovementStep(col: 2, row: 1, enterCost: 1, cumulativeCost: 1),
          ],
        ),
        excavatingArtifactId: 'artifact_1',
        posture: UnitPosture.autoExploring,
      );
      const artifact = WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.excavation(
          unitId: 'unit_1',
          col: 1,
          row: 1,
          remainingTurns: 2,
        ),
      );
      final interaction = PersistedInteractionState(
        cityFoundingDraft: _draft('unit_1'),
        pendingAction: const PendingUnitTurnSkip(
          ownerPlayerId: _playerId,
          unitId: 'unit_1',
          restoreMovementPoints: 4,
        ),
      );
      final states = _states(
        units: [
          unit,
          _unit(id: 'unit_2', col: 8),
        ],
        artifacts: const [artifact],
        interaction: interaction,
      );
      const command = CancelUnitActionCommand('unit_1');

      final persistent = const PersistentUnitActionResolver().cancelUnitAction(
        state: states.persistent,
        command: command,
        actorPlayerId: _playerId,
      );
      final domain = const DomainUnitActionCommandResolver().cancelUnitAction(
        state: states.domain,
        interaction: states.interaction,
        command: command,
        actorPlayerId: _playerId,
      );

      _expectAcceptedParity(states, persistent, domain);
      final updated = persistent.state.units.first;
      expect(updated.movementPoints, 4);
      expect(updated.queuedPath, isNull);
      expect(updated.workerJob, isNull);
      expect(updated.cityFoundingJob, isNull);
      expect(updated.workerAssignment, isNull);
      expect(updated.merchantTradeRoute, isNull);
      expect(updated.excavatingArtifactId, isNull);
      expect(updated.posture, UnitPosture.active);
      expect(
        persistent.state.artifacts.single.location,
        const WorldArtifactLocation.map(col: 1, row: 1),
      );
      expect(domain.interaction, PersistedInteractionState.empty);
    });

    test('cancel reject preserves both state boundary identities', () {
      final states = _states(units: [_unit()]);
      const command = CancelUnitActionCommand('unit_1');

      final persistent = const PersistentUnitActionResolver().cancelUnitAction(
        state: states.persistent,
        command: command,
        actorPlayerId: _otherPlayerId,
      );
      final domain = const DomainUnitActionCommandResolver().cancelUnitAction(
        state: states.domain,
        interaction: states.interaction,
        command: command,
        actorPlayerId: _otherPlayerId,
      );

      _expectRejectedIdentity(
        states,
        persistent,
        domain,
        reason: 'unit_not_controlled',
      );
    });

    test('cancel adapters share unchanged artifacts and runtime', () {
      final interaction = PersistedInteractionState(
        pendingAction: const PendingResearchSelection(ownerPlayerId: _playerId),
      );
      final states = _states(
        units: [
          _unit(excavatingArtifactId: 'artifact_map'),
          _unit(id: 'unit_2', col: 8),
        ],
        artifacts: const [_artifact],
        interaction: interaction,
      );
      const command = CancelUnitActionCommand('unit_1');

      final persistent = const PersistentUnitActionResolver().cancelUnitAction(
        state: states.persistent,
        command: command,
        actorPlayerId: _playerId,
      );
      final domain = const DomainUnitActionCommandResolver().cancelUnitAction(
        state: states.domain,
        interaction: states.interaction,
        command: command,
        actorPlayerId: _playerId,
      );

      _expectAcceptedParity(states, persistent, domain);
      expect(
        identical(persistent.state.units, states.persistent.units),
        isFalse,
      );
      expect(identical(domain.state.units, states.domain.units), isFalse);
      expect(persistent.state.units.first.excavatingArtifactId, isNull);
      expect(
        identical(persistent.state.artifacts, states.persistent.artifacts),
        isTrue,
      );
      expect(
        identical(domain.state.artifacts, states.domain.artifacts),
        isTrue,
      );
      expect(
        identical(
          persistent.state.runtimeState,
          states.persistent.runtimeState,
        ),
        isTrue,
      );
      expect(identical(domain.interaction, interaction), isTrue);
    });
  });
}
