import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'unit_action_command_resolver_test_support.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

void main() {
  group('UnitActionCommandResolver.cancelUnitAction', () {
    test('rejects in exact validation order and preserves identities', () {
      final units = <GameUnit>[];
      final artifacts = <WorldArtifact>[];
      final interaction = PersistedInteractionState(
        pendingAction: const PendingResearchSelection(ownerPlayerId: _playerId),
      );

      _expectRejected(
        UnitActionCommandResolver.cancelUnitAction(
          units: units,
          artifacts: artifacts,
          interaction: interaction,
          command: const CancelUnitActionCommand('missing'),
          actorPlayerId: _playerId,
        ),
        units: units,
        artifacts: artifacts,
        interaction: interaction,
        reason: 'unit_not_found',
      );

      units.add(_unit());
      _expectRejected(
        UnitActionCommandResolver.cancelUnitAction(
          units: units,
          artifacts: artifacts,
          interaction: interaction,
          command: const CancelUnitActionCommand('unit_1'),
          actorPlayerId: _otherPlayerId,
        ),
        units: units,
        artifacts: artifacts,
        interaction: interaction,
        reason: 'unit_not_controlled',
      );
    });

    test('clears every order, restores the artifact, and owns collections', () {
      final queuedPath = _queuedPath();
      final cityFoundingJob = CityFoundingJob(
        center: const CityHex(col: 1, row: 1),
        controlledHexes: const [CityHex(col: 2, row: 1)],
        remainingTurns: 1,
        totalTurns: 2,
      );
      final merchantRoute = MerchantTradeRoute(
        originCityId: 'origin',
        destinationCityId: 'destination',
        steps: const [
          UnitMovementStep(col: 2, row: 1, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final unit = _unit(
        movementPoints: 2,
        queuedPath: queuedPath,
        workerJob: const WorkerJob(
          targetHex: CityHex(col: 1, row: 1),
          improvementType: FieldImprovementType.farm,
          remainingTurns: 1,
          totalTurns: 2,
        ),
        cityFoundingJob: cityFoundingJob,
        workerAssignment: const WorkerAssignment(
          targetHex: CityHex(col: 1, row: 1),
        ),
        merchantTradeRoute: merchantRoute,
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
      final untouchedUnit = _unit(id: 'unit_2', col: 4);
      const untouchedArtifact = WorldArtifact(
        id: 'artifact_2',
        type: WorldArtifactType.merchantsSeal,
        location: WorldArtifactLocation.map(col: 4, row: 1),
      );
      final units = [unit, untouchedUnit];
      final artifacts = <WorldArtifact>[artifact, untouchedArtifact];
      final interaction = PersistedInteractionState(
        cityFoundingDraft: _draft('unit_1'),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: _playerId,
          attackerUnitId: 'unit_1',
        ),
      );

      final result = UnitActionCommandResolver.cancelUnitAction(
        units: units,
        artifacts: artifacts,
        interaction: interaction,
        command: const CancelUnitActionCommand('unit_1'),
        actorPlayerId: _playerId,
      );

      expect((result.accepted, result.reason), (true, null));
      expect(identical(result.units, units), isFalse);
      expect(identical(result.artifacts, artifacts), isFalse);
      final updated = result.units.first;
      expect(updated.movementPoints, 2);
      expect(updated.queuedPath, isNull);
      expect(updated.workerJob, isNull);
      expect(updated.cityFoundingJob, isNull);
      expect(updated.workerAssignment, isNull);
      expect(updated.merchantTradeRoute, isNull);
      expect(updated.excavatingArtifactId, isNull);
      expect(updated.posture, UnitPosture.active);
      expect(
        result.artifacts.first.location,
        const WorldArtifactLocation.map(col: 1, row: 1),
      );
      expect(identical(result.units.last, untouchedUnit), isTrue);
      expect(identical(result.artifacts.last, untouchedArtifact), isTrue);
      expect(result.interaction.cityFoundingDraft, isNull);
      expect(result.interaction.pendingAction, isNull);
      _expectChangedCollectionsImmutable(result);
    });

    test('shares artifacts when the excavation has no active match', () {
      final units = List<GameUnit>.unmodifiable([
        _unit(excavatingArtifactId: 'artifact_map'),
      ]);
      final artifacts = List<WorldArtifact>.unmodifiable([_mapArtifact()]);
      final interaction = PersistedInteractionState(
        pendingAction: const PendingResearchSelection(ownerPlayerId: _playerId),
      );

      final result = UnitActionCommandResolver.cancelUnitAction(
        units: units,
        artifacts: artifacts,
        interaction: interaction,
        command: const CancelUnitActionCommand('unit_1'),
        actorPlayerId: _playerId,
      );

      expect(result.accepted, isTrue);
      expect(identical(result.units, units), isFalse);
      expect(result.units.single.excavatingArtifactId, isNull);
      expect(identical(result.artifacts, artifacts), isTrue);
      expect(identical(result.interaction, interaction), isTrue);
      _expectChangedUnitsImmutable(result);
    });

    test('shares every boundary for an accepted semantic no-op', () {
      final unit = _unit();
      final units = List<GameUnit>.unmodifiable([unit]);
      final artifacts = List<WorldArtifact>.unmodifiable([_mapArtifact()]);
      final interaction = PersistedInteractionState(
        cityFoundingDraft: _draft('unit_2'),
        pendingAction: const PendingResearchSelection(ownerPlayerId: _playerId),
      );

      final result = UnitActionCommandResolver.cancelUnitAction(
        units: units,
        artifacts: artifacts,
        interaction: interaction,
        command: const CancelUnitActionCommand('unit_1'),
        actorPlayerId: _playerId,
      );

      expect((result.accepted, result.reason), (true, null));
      expect(identical(result.units, units), isTrue);
      expect(identical(result.units.single, unit), isTrue);
      expect(identical(result.artifacts, artifacts), isTrue);
      expect(identical(result.interaction, interaction), isTrue);
    });

    test('restores skipped movement before the normal movement fallback', () {
      final unit = _unit(movementPoints: 0);
      final units = [unit];
      const artifacts = <WorldArtifact>[];
      final interaction = PersistedInteractionState(
        pendingAction: const PendingUnitTurnSkip(
          ownerPlayerId: _playerId,
          unitId: 'unit_1',
          restoreMovementPoints: 4,
        ),
      );

      final result = UnitActionCommandResolver.cancelUnitAction(
        units: units,
        artifacts: artifacts,
        interaction: interaction,
        command: const CancelUnitActionCommand('unit_1'),
        actorPlayerId: _playerId,
      );

      expect(result.accepted, isTrue);
      expect(result.units.single.movementPoints, 4);
      expect(result.interaction.pendingAction, isNull);
      expect(identical(result.artifacts, artifacts), isTrue);
      _expectChangedUnitsImmutable(result);
    });

    test('wakes fortified units with fresh movement', () {
      final unit = _unit(movementPoints: 0, posture: UnitPosture.fortified);
      const artifacts = <WorldArtifact>[];
      final result = UnitActionCommandResolver.cancelUnitAction(
        units: [unit],
        artifacts: artifacts,
        interaction: PersistedInteractionState.empty,
        command: const CancelUnitActionCommand('unit_1'),
        actorPlayerId: _playerId,
      );

      expect(result.accepted, isTrue);
      expect(result.units.single.posture, UnitPosture.active);
      expect(
        result.units.single.movementPoints,
        UnitMovementBalance.maxMovementPointsFor(
          type: unit.type,
          carriedArtifactId: unit.carriedArtifactId,
        ),
      );
      expect(identical(result.artifacts, artifacts), isTrue);
      _expectChangedUnitsImmutable(result);
    });
  });

  group('UnitActionCommandResolver.skipUnitTurn', () {
    test('rejects in exact validation order and preserves identities', () {
      final units = <GameUnit>[];
      final artifacts = <WorldArtifact>[];
      final interaction = PersistedInteractionState(
        cityFoundingDraft: _draft('unit_1'),
      );

      _expectRejected(
        UnitActionCommandResolver.skipUnitTurn(
          units: units,
          artifacts: artifacts,
          interaction: interaction,
          command: const SkipUnitTurnCommand('missing'),
          actorPlayerId: _playerId,
        ),
        units: units,
        artifacts: artifacts,
        interaction: interaction,
        reason: 'unit_not_found',
      );

      units.add(_unit());
      _expectRejected(
        UnitActionCommandResolver.skipUnitTurn(
          units: units,
          artifacts: artifacts,
          interaction: interaction,
          command: const SkipUnitTurnCommand('unit_1'),
          actorPlayerId: _otherPlayerId,
        ),
        units: units,
        artifacts: artifacts,
        interaction: interaction,
        reason: 'unit_not_controlled',
      );
    });

    test('consumes movement, owns changed units, and shares artifacts', () {
      final unit = _unit(
        movementPoints: 3,
        queuedPath: _queuedPath(),
        posture: UnitPosture.autoExploring,
      );
      final untouched = _unit(id: 'unit_2', col: 4);
      final units = [unit, untouched];
      final artifacts = List<WorldArtifact>.unmodifiable([_mapArtifact()]);
      final interaction = PersistedInteractionState(
        cityFoundingDraft: _draft('unit_1'),
      );

      final result = UnitActionCommandResolver.skipUnitTurn(
        units: units,
        artifacts: artifacts,
        interaction: interaction,
        command: const SkipUnitTurnCommand('unit_1'),
        actorPlayerId: _playerId,
      );

      expect((result.accepted, result.reason), (true, null));
      expect(identical(result.units, units), isFalse);
      expect(identical(result.artifacts, artifacts), isTrue);
      expect(result.units.first.movementPoints, 0);
      expect(result.units.first.queuedPath, isNull);
      expect(result.units.first.posture, UnitPosture.active);
      expect(identical(result.units.last, untouched), isTrue);
      expect(result.interaction.cityFoundingDraft, isNull);
      expect(
        result.interaction.pendingAction,
        const PendingUnitTurnSkip(
          ownerPlayerId: _playerId,
          unitId: 'unit_1',
          restoreMovementPoints: 3,
        ),
      );
      _expectChangedUnitsImmutable(result);
    });
  });

  group('UnitActionCommandResolver.fortifyUnit', () {
    test('rejects in exact validation order and preserves identities', () {
      final units = <GameUnit>[];
      final artifacts = <WorldArtifact>[];
      final interaction = PersistedInteractionState(
        pendingAction: const PendingResearchSelection(ownerPlayerId: _playerId),
      );

      _expectFortifyRejected(
        units,
        artifacts,
        interaction,
        unitId: 'missing',
        actorPlayerId: _playerId,
        reason: 'unit_not_found',
      );
      units.add(_unit());
      _expectFortifyRejected(
        units,
        artifacts,
        interaction,
        unitId: 'unit_1',
        actorPlayerId: _otherPlayerId,
        reason: 'unit_not_controlled',
      );
      units[0] = _unit(
        workerJob: const WorkerJob(
          targetHex: CityHex(col: 1, row: 1),
          improvementType: FieldImprovementType.farm,
          remainingTurns: 1,
          totalTurns: 2,
        ),
      );
      _expectFortifyRejected(
        units,
        artifacts,
        interaction,
        unitId: 'unit_1',
        actorPlayerId: _playerId,
        reason: 'unit_busy',
      );
    });

    test('fortifies and clears interaction owned by the unit', () {
      final unit = _unit(
        movementPoints: 2,
        queuedPath: _queuedPath(),
      ).copyWithHitPoints(7);
      final units = [unit];
      final artifacts = List<WorldArtifact>.unmodifiable([_mapArtifact()]);
      final interaction = PersistedInteractionState(
        cityFoundingDraft: _draft('unit_1'),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: _playerId,
          attackerUnitId: 'unit_1',
        ),
      );

      final result = UnitActionCommandResolver.fortifyUnit(
        units: units,
        artifacts: artifacts,
        interaction: interaction,
        command: const FortifyUnitCommand('unit_1'),
        actorPlayerId: _playerId,
      );

      expect((result.accepted, result.reason), (true, null));
      expect(identical(result.units, units), isFalse);
      expect(identical(result.artifacts, artifacts), isTrue);
      expect(result.units.single.movementPoints, 0);
      expect(result.units.single.queuedPath, isNull);
      expect(result.units.single.posture, UnitPosture.fortified);
      expect(result.interaction.cityFoundingDraft, isNull);
      expect(result.interaction.pendingAction, isNull);
      _expectChangedUnitsImmutable(result);
    });

    test('preserves unrelated pending action and city draft', () {
      final units = [_unit()];
      final artifacts = List<WorldArtifact>.unmodifiable([_mapArtifact()]);
      final interaction = PersistedInteractionState(
        cityFoundingDraft: _draft('unit_2'),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: _playerId,
          attackerUnitId: 'unit_2',
        ),
      );

      final result = UnitActionCommandResolver.fortifyUnit(
        units: units,
        artifacts: artifacts,
        interaction: interaction,
        command: const FortifyUnitCommand('unit_1'),
        actorPlayerId: _playerId,
      );

      expect(result.accepted, isTrue);
      expect(identical(result.interaction, interaction), isTrue);
      expect(
        result.interaction.cityFoundingDraft,
        interaction.cityFoundingDraft,
      );
      expect(result.interaction.pendingAction, interaction.pendingAction);
      expect(identical(result.artifacts, artifacts), isTrue);
      _expectChangedUnitsImmutable(result);
    });
  });
}
