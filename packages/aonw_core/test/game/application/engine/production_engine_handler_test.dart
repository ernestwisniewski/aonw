import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _actorId = 'player_1';
const _otherId = 'player_2';

void main() {
  group('production engine handler', () {
    test('foreign city rejects before production availability checks', () {
      final snapshot = _snapshot(cities: [_city(ownerPlayerId: _otherId)]);

      final result = _apply(
        snapshot,
        const StartCityProjectCommand('city', CityProjectType.wealth),
      );

      _expectRejected(result, snapshot, 'city_not_controlled');
    });

    test('project selection updates only the canonical city queue', () {
      final snapshot = _snapshot(cities: [_city()]);

      final accepted = _expectAccepted(
        _apply(
          snapshot,
          const StartCityProjectCommand('city', CityProjectType.wealth),
        ),
      );

      expect(
        accepted.snapshot.domain.cities.single.productionQueue?.target,
        const ProjectProductionTarget(CityProjectType.wealth),
      );
      expect(accepted.snapshot.domain.units, same(snapshot.domain.units));
      expect(accepted.snapshot.domain.actions, same(snapshot.domain.actions));
      _expectEnvelopePreserved(accepted.snapshot, snapshot);
    });

    test('repeated project selection is an accepted identity no-op', () {
      final snapshot = _snapshot(
        cities: [
          _city(
            productionQueue: CityProductionQueue.project(
              projectType: CityProjectType.wealth,
            ),
          ),
        ],
      );

      final accepted = _expectAccepted(
        _apply(
          snapshot,
          const StartCityProjectCommand('city', CityProjectType.wealth),
        ),
      );

      expect(accepted.snapshot, same(snapshot));
      expect(accepted.events, isEmpty);
    });

    test('rush rejection preserves snapshot identity and event order', () {
      final snapshot = _snapshot(cities: [_city()]);

      final result = _apply(snapshot, const RushProductionCommand('city'));

      _expectRejected(result, snapshot, 'production_queue_empty');
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
      commandTick: 2,
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
  expect(next.metadata, same(previous.metadata));
  expect(next.eventLogOffset, previous.eventLogOffset);
  expect(next.domain.participants, same(previous.domain.participants));
}

CanonicalGameSnapshot _snapshot({List<GameCity> cities = const []}) {
  return CanonicalGameSnapshot.snapshot(
    domain: (DomainState.snapshot(
      turn: 3,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: _actorId, name: 'One', colorValue: 1),
        Player(id: _otherId, name: 'Two', colorValue: 2),
      ],
      playerGold: const {_actorId: 100, _otherId: 50},
      cities: cities,
    )).copyWith(gameMode: GameMode.multiplayer),

    metadata: GameSnapshotMetadata(
      id: 'production',
      schemaVersion: 3,
      name: 'Production',
      world: const WorldReference(name: 'city', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 29),
      camera: GameSnapshotCamera.zero,
    ),
    eventLogOffset: 12,
  );
}

GameCity _city({
  String ownerPlayerId = _actorId,
  CityProductionQueue? productionQueue,
}) {
  return GameCity(
    id: 'city',
    ownerPlayerId: ownerPlayerId,
    name: 'City',
    center: const CityHex(col: 1, row: 1),
    controlledHexes: const [CityHex(col: 1, row: 1)],
    population: 2,
    productionQueue: productionQueue,
  );
}

final _map = WorldMap(
  cols: 3,
  rows: 3,
  tiles: [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        WorldTile.at(
          coordinate: HexCoord(col: col, row: row),
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);
