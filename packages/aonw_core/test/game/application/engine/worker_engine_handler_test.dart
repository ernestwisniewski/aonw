import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _actorId = 'player_1';
const _otherId = 'player_2';

void main() {
  group('worker engine handler', () {
    test('foreign worker rejects before improvement legality checks', () {
      final snapshot = _snapshot(units: [_worker(ownerPlayerId: _otherId)]);

      final result = _apply(
        snapshot,
        const SelectWorkerImprovementCommand(
          'worker',
          FieldImprovementType.farm,
        ),
      );

      _expectRejected(result, snapshot, 'worker_not_controlled');
    });

    test(
      'accepted improvement clears only the matching worker pending action',
      () {
        final cityDraft = CityFoundingDraft(
          unitId: 'settler',
          ownerPlayerId: _actorId,
          center: const CityHex(col: 0, row: 0),
        );
        final snapshot = _snapshot(
          units: [_worker()],
          interaction: PersistedInteractionState(
            cityFoundingDraft: cityDraft,
            pendingAction: const PendingWorkerActionSelection(
              ownerPlayerId: _actorId,
              unitId: 'worker',
            ),
          ),
        );

        final accepted = _expectAccepted(
          _apply(
            snapshot,
            const SelectWorkerImprovementCommand(
              'worker',
              FieldImprovementType.farm,
            ),
          ),
        );

        expect(
          accepted.snapshot.domain.units.single.workerJob?.improvementType,
          FieldImprovementType.farm,
        );
        expect(accepted.snapshot.interaction.pendingAction, isNull);
        expect(
          accepted.snapshot.interaction.cityFoundingDraft,
          same(snapshot.interaction.cityFoundingDraft),
        );
        _expectEnvelopePreserved(accepted.snapshot, snapshot);
      },
    );

    test('reselecting the active improvement rejects as an identity no-op', () {
      final snapshot = _snapshot(
        units: [
          _worker(
            movementPoints: 0,
            workerJob: const WorkerJob(
              targetHex: CityHex(col: 1, row: 0),
              improvementType: FieldImprovementType.farm,
              remainingTurns: 2,
              totalTurns: 2,
            ),
          ),
        ],
      );

      final result = _apply(
        snapshot,
        const SelectWorkerImprovementCommand(
          'worker',
          FieldImprovementType.farm,
        ),
      );

      _expectRejected(result, snapshot, 'worker_improvement_unavailable');
    });

    test('cancel without a job rejects with snapshot identity', () {
      final snapshot = _snapshot(units: [_worker()]);

      final result = _apply(snapshot, const CancelWorkerJobCommand('worker'));

      _expectRejected(result, snapshot, 'worker_job_not_active');
    });
  });
}

GameEngineResult _apply(CanonicalGameSnapshot snapshot, DomainCommand command) {
  return const GameEngine().apply(
    snapshot: snapshot,
    command: command,
    context: GameEngineContext(
      actorPlayerId: _actorId,
      mapView: _map,
      ruleset: GameRuleset.defaults,
      commandTick: 3,
    ),
  );
}

GameEngineAccepted _expectAccepted(GameEngineResult result) {
  expect(result, isA<GameEngineAccepted>());
  return result as GameEngineAccepted;
}

void _expectRejected(
  GameEngineResult result,
  CanonicalGameSnapshot snapshot,
  String reason,
) {
  expect(result, isA<GameEngineRejected>());
  final rejected = result as GameEngineRejected;
  expect(rejected.snapshot, same(snapshot));
  expect(rejected.reason, reason);
  expect(rejected.events, isEmpty);
}

void _expectEnvelopePreserved(
  CanonicalGameSnapshot next,
  CanonicalGameSnapshot previous,
) {
  expect(next.session, same(previous.session));
  expect(next.metadata, same(previous.metadata));
  expect(next.eventLogOffset, previous.eventLogOffset);
  expect(next.domain.participants, same(previous.domain.participants));
}

CanonicalGameSnapshot _snapshot({
  List<GameUnit> units = const [],
  PersistedInteractionState interaction = PersistedInteractionState.empty,
}) {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 3,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: _actorId, name: 'One', colorValue: 1),
        Player(id: _otherId, name: 'Two', colorValue: 2),
      ],
      units: units,
      cities: const [
        GameCity(
          id: 'city',
          ownerPlayerId: _actorId,
          name: 'City',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 0, row: 0), CityHex(col: 1, row: 0)],
        ),
      ],
      research: ResearchState(
        players: {
          _actorId: PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
          ),
        },
      ),
    ),
    session: MatchSessionState.snapshot(gameMode: GameMode.multiplayer),
    metadata: GameSnapshotMetadata(
      id: 'worker',
      schemaVersion: 3,
      name: 'Worker',
      world: const WorldReference(name: 'city', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 29),
      camera: GameSnapshotCamera.zero,
    ),
    interaction: interaction,
    eventLogOffset: 13,
  );
}

GameUnit _worker({
  String ownerPlayerId = _actorId,
  int movementPoints = 2,
  WorkerJob? workerJob,
}) {
  return GameUnit(
    id: 'worker',
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.worker,
    name: 'Worker',
    col: 1,
    row: 0,
    movementPoints: movementPoints,
    workerJob: workerJob,
  );
}

final _map = WorldMapReadView(
  WorldMap(
    cols: 2,
    rows: 1,
    tiles: [
      for (var col = 0; col < 2; col++)
        WorldTile(
          coordinate: HexCoord(col: col, row: 0),
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  ),
);
