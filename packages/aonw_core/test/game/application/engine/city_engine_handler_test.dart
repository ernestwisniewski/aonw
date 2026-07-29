import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _actorId = 'player_1';
const _otherId = 'player_2';

void main() {
  group('city engine handler', () {
    test(
      'founding rejects a foreign settler without changing the snapshot',
      () {
        final snapshot = _snapshot(units: [_settler(ownerPlayerId: _otherId)]);

        final result = _apply(
          snapshot,
          FoundCityCommand(
            'settler',
            controlledHexes: const [
              CityHex(col: 2, row: 1),
              CityHex(col: 1, row: 2),
            ],
          ),
        );

        _expectRejected(result, snapshot, 'city_founder_not_controlled');
      },
    );

    test('founding schedules the job and clears only its draft', () {
      final draft = CityFoundingDraft(
        unitId: 'settler',
        ownerPlayerId: _actorId,
        center: const CityHex(col: 1, row: 1),
        controlledHexes: const [
          CityHex(col: 2, row: 1),
          CityHex(col: 1, row: 2),
        ],
      );
      final snapshot = _snapshot(
        units: [_settler()],
        interaction: PersistedInteractionState(
          cityFoundingDraft: draft,
          pendingAction: const PendingResearchSelection(
            ownerPlayerId: _otherId,
          ),
        ),
      );

      final accepted = _expectAccepted(
        _apply(
          snapshot,
          FoundCityCommand('settler', controlledHexes: draft.controlledHexes),
        ),
      );

      expect(accepted.snapshot.domain.units.single.cityFoundingJob, isNotNull);
      expect(accepted.snapshot.domain.units.single.movementPoints, 0);
      expect(accepted.snapshot.interaction.cityFoundingDraft, isNull);
      expect(
        accepted.snapshot.interaction.pendingAction,
        same(snapshot.interaction.pendingAction),
      );
      _expectEnvelopePreserved(accepted.snapshot, snapshot);
    });

    test('worked hex rejects a foreign city with snapshot identity', () {
      final snapshot = _snapshot(cities: [_city(ownerPlayerId: _otherId)]);

      final result = _apply(
        snapshot,
        const ToggleWorkedHexCommand('city', 2, 1),
      );

      _expectRejected(result, snapshot, 'city_not_controlled');
    });

    test('worked hex updates the canonical city only', () {
      final snapshot = _snapshot(cities: [_city()]);

      final accepted = _expectAccepted(
        _apply(snapshot, const ToggleWorkedHexCommand('city', 2, 1)),
      );

      expect(accepted.snapshot.domain.cities.single.workedHexes, const [
        CityHex(col: 2, row: 1),
      ]);
      expect(accepted.snapshot.domain.units, same(snapshot.domain.units));
      expect(accepted.snapshot.interaction, same(snapshot.interaction));
      _expectEnvelopePreserved(accepted.snapshot, snapshot);
    });

    test('repeated expansion selection is an accepted identity no-op', () {
      final snapshot = _snapshot(
        cities: [
          _city(
            controlledHexes: const [CityHex(col: 1, row: 1)],
            preferredExpansionHex: const CityHex(col: 2, row: 1),
          ),
        ],
      );

      final accepted = _expectAccepted(
        _apply(snapshot, const SelectCityExpansionHexCommand('city', 2, 1)),
      );

      expect(accepted.snapshot, same(snapshot));
      expect(accepted.events, isEmpty);
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
      commandTick: 1,
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
      cities: cities,
    ),
    session: MatchSessionState.snapshot(gameMode: GameMode.multiplayer),
    metadata: GameSnapshotMetadata(
      id: 'city',
      schemaVersion: 3,
      name: 'City',
      world: const WorldReference(name: 'city', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 29),
      camera: GameSnapshotCamera.zero,
    ),
    interaction: interaction,
    eventLogOffset: 11,
  );
}

GameUnit _settler({String ownerPlayerId = _actorId}) {
  return GameUnit(
    id: 'settler',
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.settler,
    name: 'Settler',
    col: 1,
    row: 1,
    movementPoints: 3,
  );
}

GameCity _city({
  String ownerPlayerId = _actorId,
  List<CityHex> controlledHexes = const [
    CityHex(col: 1, row: 1),
    CityHex(col: 2, row: 1),
  ],
  CityHex? preferredExpansionHex,
}) {
  return GameCity(
    id: 'city',
    ownerPlayerId: ownerPlayerId,
    name: 'City',
    center: const CityHex(col: 1, row: 1),
    controlledHexes: controlledHexes,
    population: 2,
    preferredExpansionHex: preferredExpansionHex,
  );
}

final _map = WorldMapReadView(
  WorldMap(
    cols: 4,
    rows: 4,
    tiles: [
      for (var row = 0; row < 4; row++)
        for (var col = 0; col < 4; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  ),
);
