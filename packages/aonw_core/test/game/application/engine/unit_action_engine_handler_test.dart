import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';
const _context = GameEngineContext(
  actorPlayerId: _playerId,
  mapView: _EmptyMapReadView(),
  ruleset: GameRuleset.defaults,
  commandTick: 19,
);

void main() {
  group('unit action engine truth table', () {
    test('missing unit rejects with input snapshot identity', () {
      final snapshot = _snapshot();

      final result = const GameEngine().apply(
        snapshot: snapshot,
        command: const SkipUnitTurnCommand('missing'),
        context: _context,
      );

      _expectRejected(result, snapshot, 'unit_not_found');
    });

    test('foreign unit rejects with input snapshot identity', () {
      final snapshot = _snapshot(units: [_unit(ownerPlayerId: _otherPlayerId)]);

      final result = const GameEngine().apply(
        snapshot: snapshot,
        command: const SkipUnitTurnCommand('unit_1'),
        context: _context,
      );

      _expectRejected(result, snapshot, 'unit_not_controlled');
    });

    test('busy fortify rejects with input snapshot identity', () {
      final snapshot = _snapshot(
        units: [
          _unit(
            workerJob: const WorkerJob(
              targetHex: CityHex(col: 1, row: 1),
              improvementType: FieldImprovementType.farm,
              remainingTurns: 1,
              totalTurns: 2,
            ),
          ),
        ],
      );

      final result = const GameEngine().apply(
        snapshot: snapshot,
        command: const FortifyUnitCommand('unit_1'),
        context: _context,
      );

      _expectRejected(result, snapshot, 'unit_busy');
    });

    test('successful skip replaces units and interaction only', () {
      final snapshot = _snapshot(
        units: [
          _unit(
            movementPoints: 3,
            queuedPath: QueuedMovePath(
              targetCol: 2,
              targetRow: 1,
              steps: const [
                UnitMovementStep(
                  col: 2,
                  row: 1,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          ),
        ],
        interaction: PersistedInteractionState(
          cityFoundingDraft: CityFoundingDraft(
            unitId: 'unit_1',
            ownerPlayerId: _playerId,
            center: const CityHex(col: 1, row: 1),
          ),
        ),
      );

      final result = const GameEngine().apply(
        snapshot: snapshot,
        command: const SkipUnitTurnCommand('unit_1'),
        context: _context,
      );

      final accepted = _expectAcceptedBoundaryReplacement(result, snapshot);
      expect(accepted.snapshot.domain.units.single.movementPoints, 0);
      expect(accepted.snapshot.domain.units.single.queuedPath, isNull);
      expect(accepted.snapshot.interaction.cityFoundingDraft, isNull);
      expect(
        accepted.snapshot.interaction.pendingAction,
        const PendingUnitTurnSkip(
          ownerPlayerId: _playerId,
          unitId: 'unit_1',
          restoreMovementPoints: 3,
        ),
      );
    });

    test('successful fortify replaces units and preserves artifacts', () {
      final snapshot = _snapshot(units: [_unit(movementPoints: 2)]);

      final result = const GameEngine().apply(
        snapshot: snapshot,
        command: const FortifyUnitCommand('unit_1'),
        context: _context,
      );

      final accepted = _expectAcceptedBoundaryReplacement(result, snapshot);
      final fortified = accepted.snapshot.domain.units.single;
      expect(fortified.movementPoints, 0);
      expect(fortified.posture, UnitPosture.fortified);
      expect(
        identical(
          accepted.snapshot.domain.artifacts,
          snapshot.domain.artifacts,
        ),
        isTrue,
      );
    });

    test('fortify clears interaction owned by the unit', () {
      final snapshot = _snapshot(
        units: [_unit()],
        interaction: PersistedInteractionState(
          cityFoundingDraft: CityFoundingDraft(
            unitId: 'unit_1',
            ownerPlayerId: _playerId,
            center: const CityHex(col: 1, row: 1),
          ),
          pendingAction: const PendingAttackTargeting(
            ownerPlayerId: _playerId,
            attackerUnitId: 'unit_1',
          ),
        ),
      );

      final result = const GameEngine().apply(
        snapshot: snapshot,
        command: const FortifyUnitCommand('unit_1'),
        context: _context,
      );

      final accepted = _expectAcceptedBoundaryReplacement(result, snapshot);
      expect(accepted.snapshot.interaction, PersistedInteractionState.empty);
    });

    test('accepted semantic no-op retains snapshot identity', () {
      final snapshot = _snapshot(
        units: [_unit(movementPoints: 0, posture: UnitPosture.fortified)],
        interaction: PersistedInteractionState(
          pendingAction: const PendingResearchSelection(
            ownerPlayerId: _playerId,
          ),
        ),
      );

      final result = const GameEngine().apply(
        snapshot: snapshot,
        command: const FortifyUnitCommand('unit_1'),
        context: _context,
      );

      expect(result, isA<GameEngineAccepted>());
      expect(result.snapshot, same(snapshot));
      expect(result.events, isEmpty);
    });
  });
}

void _expectRejected(
  GameEngineResult result,
  CanonicalGameSnapshot snapshot,
  String reason,
) {
  expect(result, isA<GameEngineRejected>());
  expect(result.snapshot, same(snapshot));
  expect(result.events, isEmpty);
  expect((result as GameEngineRejected).reason, reason);
}

GameEngineAccepted _expectAcceptedBoundaryReplacement(
  GameEngineResult result,
  CanonicalGameSnapshot snapshot,
) {
  expect(result, isA<GameEngineAccepted>());
  final accepted = result as GameEngineAccepted;
  expect(accepted.events, isEmpty);
  expect(accepted.snapshot, isNot(same(snapshot)));
  expect(accepted.snapshot.session, same(snapshot.session));
  expect(accepted.snapshot.metadata, same(snapshot.metadata));
  expect(accepted.snapshot.eventLogOffset, snapshot.eventLogOffset);
  expect(
    accepted.snapshot.domain.participants,
    same(snapshot.domain.participants),
  );
  expect(accepted.snapshot.domain.cities, same(snapshot.domain.cities));
  return accepted;
}

CanonicalGameSnapshot _snapshot({
  List<GameUnit> units = const [],
  PersistedInteractionState interaction = PersistedInteractionState.empty,
}) {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 7,
      matchRules: MatchRules.standard,
      participants: const [
        Player(
          id: _playerId,
          name: 'One',
          colorValue: 1,
          country: PlayerCountry.poland,
        ),
        Player(
          id: _otherPlayerId,
          name: 'Two',
          colorValue: 2,
          country: PlayerCountry.france,
        ),
      ],
      playerGold: const {_playerId: 17, _otherPlayerId: 11},
      units: units,
      artifacts: const [
        WorldArtifact(
          id: 'artifact_1',
          type: WorldArtifactType.astronomersTablets,
          location: WorldArtifactLocation.map(col: 4, row: 1),
        ),
      ],
    ),
    session: MatchSessionState.snapshot(
      gameMode: GameMode.multiplayer,
      turnStatesByPlayerId: const {
        _playerId: PlayerTurnState.active,
        _otherPlayerId: PlayerTurnState.active,
      },
    ),
    metadata: GameSnapshotMetadata(
      id: 'save_1',
      schemaVersion: 3,
      name: 'Engine fixture',
      world: const WorldReference(name: 'verdantia', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 29),
      camera: GameSnapshotCamera.zero,
    ),
    interaction: interaction,
    eventLogOffset: 41,
  );
}

GameUnit _unit({
  String ownerPlayerId = _playerId,
  int movementPoints = 3,
  QueuedMovePath? queuedPath,
  WorkerJob? workerJob,
  UnitPosture posture = UnitPosture.active,
}) {
  return GameUnit(
    id: 'unit_1',
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: 1,
    row: 1,
    movementPoints: movementPoints,
    queuedPath: queuedPath,
    workerJob: workerJob,
    posture: posture,
  );
}

final class _EmptyMapReadView implements MapReadView {
  const _EmptyMapReadView();

  @override
  int get cols => 0;

  @override
  int get rows => 0;

  @override
  MapTileLookup get mapTiles => this;

  @override
  String? get mapName => null;

  @override
  Iterable<MapObjectiveDefinition> get objectives => const [];

  @override
  int get tileCount => 0;

  @override
  Iterable<Iterable<TerrainType>> get tileTerrains => const [];

  @override
  Iterable<MapTileView> get tileViews => const [];

  @override
  MapTileView? tileAt(int col, int row) => null;
}
