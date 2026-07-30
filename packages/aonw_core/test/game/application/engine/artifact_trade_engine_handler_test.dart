import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _actorId = 'player_1';
const _otherId = 'player_2';

void main() {
  group('artifact trade engine handler', () {
    test('foreign unit rejects before artifact availability checks', () {
      final snapshot = _snapshot(units: [_unit(ownerPlayerId: _otherId)]);

      final result = _apply(
        snapshot,
        const StartArtifactExcavationCommand('scout'),
      );

      _expectRejected(result, snapshot, 'unit_not_controlled');
    });

    test('excavation updates only the unit and artifact slices', () {
      final snapshot = _snapshot(
        units: [_unit()],
        artifacts: const [
          WorldArtifact(
            id: 'artifact',
            type: WorldArtifactType.heroSword,
            location: WorldArtifactLocation.map(col: 1, row: 0),
          ),
        ],
      );

      final accepted = _expectAccepted(
        _apply(snapshot, const StartArtifactExcavationCommand('scout')),
      );

      expect(
        accepted.snapshot.domain.units.single.excavatingArtifactId,
        'artifact',
      );
      expect(
        accepted.snapshot.domain.artifacts.single.location,
        const WorldArtifactLocation.excavation(
          unitId: 'scout',
          col: 1,
          row: 0,
          remainingTurns: ArtifactCommandResolver.excavationTurns,
        ),
      );
      expect(accepted.snapshot.domain.cities, same(snapshot.domain.cities));
      expect(accepted.snapshot.interaction, same(snapshot.interaction));
      expect(
        accepted.events.single,
        isA<ArtifactExcavationStartedEvent>()
            .having((event) => event.artifactId, 'artifactId', 'artifact')
            .having((event) => event.ownerPlayerId, 'owner', _actorId)
            .having((event) => event.unitId, 'unit', 'scout')
            .having((event) => (event.col, event.row), 'hex', (1, 0)),
      );
      _expectEnvelopePreserved(accepted.snapshot, snapshot);
    });

    test('missing artifact rejects as an identity no-op', () {
      final snapshot = _snapshot(units: [_unit()]);

      final result = _apply(
        snapshot,
        const StartArtifactExcavationCommand('scout'),
      );

      _expectRejected(result, snapshot, 'artifact_not_found');
    });

    test('storage emits the canonical artifact destination event', () {
      final snapshot = _snapshot(
        units: [_unit().copyWithCarriedArtifact('artifact')],
        cities: const [
          GameCity(
            id: 'city',
            ownerPlayerId: _actorId,
            name: 'City',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        artifacts: const [
          WorldArtifact(
            id: 'artifact',
            type: WorldArtifactType.heroSword,
            location: WorldArtifactLocation.carried(unitId: 'scout'),
          ),
        ],
      );

      final accepted = _expectAccepted(
        _apply(
          snapshot,
          const StoreArtifactInCityCommand('scout', cityId: 'city'),
        ),
      );

      expect(
        accepted.events.single,
        isA<ArtifactStoredEvent>()
            .having((event) => event.artifactId, 'artifactId', 'artifact')
            .having((event) => event.cityId, 'city', 'city')
            .having((event) => (event.col, event.row), 'hex', (1, 0)),
      );
    });

    test(
      'resource trade rejects a forged player before availability checks',
      () {
        final snapshot = _snapshot();

        final result = _apply(
          snapshot,
          const OpenResourceTradeCommand(
            playerId: _otherId,
            targetPlayerId: _actorId,
            resource: ResourceType.iron,
            goldPerTurn: 1,
            durationTurns: 3,
          ),
        );

        _expectRejected(
          result,
          snapshot,
          'resource_trade_player_not_controlled',
        );
      },
    );
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
      commandTick: 4,
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
  List<GameCity> cities = const [],
  List<WorldArtifact> artifacts = const [],
}) {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 3,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: _actorId, name: 'One', colorValue: 1),
        Player(id: _otherId, name: 'Two', colorValue: 2),
      ],
      playerGold: const {_actorId: 20, _otherId: 20},
      units: units,
      cities: cities,
      artifacts: artifacts,
    ),
    session: MatchSessionState.snapshot(gameMode: GameMode.multiplayer),
    metadata: GameSnapshotMetadata(
      id: 'artifact',
      schemaVersion: 3,
      name: 'Artifact',
      world: const WorldReference(name: 'artifact', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 29),
      camera: GameSnapshotCamera.zero,
    ),
    eventLogOffset: 14,
  );
}

GameUnit _unit({String ownerPlayerId = _actorId}) {
  return GameUnit(
    id: 'scout',
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.scout,
    name: 'Scout',
    col: 1,
    row: 0,
    movementPoints: 2,
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
