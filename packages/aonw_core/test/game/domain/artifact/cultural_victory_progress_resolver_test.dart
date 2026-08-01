import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

GameCity _city(String id, String ownerPlayerId) {
  return GameCity(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: const CityHex(col: 0, row: 0),
  );
}

List<WorldArtifact> _storedCollection({required String cityId, int count = 6}) {
  return [
    for (final type in WorldArtifactType.values.take(count))
      WorldArtifact(
        id: 'stored_${type.name}',
        type: type,
        location: WorldArtifactLocation.stored(cityId: cityId),
      ),
  ];
}

void main() {
  group('CulturalVictoryProgressCalculator', () {
    test('counts distinct stored types only in own cities', () {
      final state = DomainState.snapshot(
        cities: [_city('own', 'p1'), _city('foreign', 'p2')],
        artifacts: [
          ..._storedCollection(cityId: 'own', count: 2),
          const WorldArtifact(
            id: 'duplicate_type',
            type: WorldArtifactType.ancientImperialCrown,
            location: WorldArtifactLocation.stored(cityId: 'own'),
          ),
          const WorldArtifact(
            id: 'foreign_city',
            type: WorldArtifactType.templeReliquary,
            location: WorldArtifactLocation.stored(cityId: 'foreign'),
          ),
          const WorldArtifact(
            id: 'carried',
            type: WorldArtifactType.queensMirror,
            location: WorldArtifactLocation.carried(unitId: 'unit_1'),
          ),
        ],
      );

      expect(
        CulturalVictoryProgressCalculator.storedArtifactCountFor(
          playerId: 'p1',
          artifacts: state.artifacts,
          cities: state.cities,
        ),
        2,
      );
      expect(
        CulturalVictoryProgressCalculator.hasFullStoredCollection(
          playerId: 'p1',
          state: state,
          requiredArtifactCount: 2,
        ),
        isTrue,
      );
      expect(
        CulturalVictoryProgressCalculator.hasFullStoredCollection(
          playerId: 'p1',
          state: state,
        ),
        isFalse,
      );
    });

    test('advanceHoldTurns increments holders and drops the rest', () {
      final state = DomainState.snapshot(
        cities: [_city('own', 'p1')],
        artifacts: _storedCollection(cityId: 'own'),
      );

      final next = CulturalVictoryProgressCalculator.advanceHoldTurns(
        playerIds: const ['p1', 'p2', ''],
        state: state,
        previousHoldTurnsByPlayerId: const {'p1': 2, 'p2': 4},
      );

      expect(next, const {'p1': 3});
    });

    test('progressForPlayer reports collection and hold state', () {
      final state = DomainState.snapshot(
        cities: [_city('own', 'p1')],
        artifacts: _storedCollection(cityId: 'own'),
      );

      final progress = CulturalVictoryProgressCalculator.progressForPlayer(
        playerId: 'p1',
        state: state,
      );

      expect(progress.playerId, 'p1');
      expect(progress.storedArtifactCount, 6);
      expect(progress.hasFullCollection, isTrue);
      expect(progress.holdTurns, 0);
      expect(progress.victoryReady, isFalse);
      expect(
        progress.remainingHoldTurns,
        CulturalVictoryProgressCalculator.requiredHoldTurns,
      );
    });

    test('progress getters clamp remaining hold turns at zero', () {
      final progress =
          CulturalVictoryProgressCalculator.progressForPlayerFromCollections(
            playerId: 'p1',
            artifacts: _storedCollection(cityId: 'own'),
            cities: [_city('own', 'p1')],
            holdTurnsByPlayerId: const {'p1': 9},
          );

      expect(progress.victoryReady, isTrue);
      expect(progress.remainingHoldTurns, 0);
    });

    test('winnerCandidate requires a held full collection', () {
      final state = DomainState.snapshot(
        cities: [_city('own', 'p1')],
        artifacts: _storedCollection(cityId: 'own'),
      );

      expect(
        CulturalVictoryProgressCalculator.winnerCandidate(
          playerIds: const ['p1', 'p2'],
          state: state,
        ),
        isNull,
      );
      expect(
        CulturalVictoryProgressCalculator.winnerCandidateFromCollections(
          playerIds: const ['p1', 'p2'],
          artifacts: state.artifacts,
          cities: state.cities,
          holdTurnsByPlayerId: const {'p1': 5},
        ),
        'p1',
      );
    });

    test('winnerCandidate breaks hold ties toward null', () {
      final cities = [_city('one', 'p1'), _city('two', 'p2')];
      final artifacts = [
        ..._storedCollection(cityId: 'one'),
        for (final artifact in _storedCollection(cityId: 'two'))
          WorldArtifact(
            id: 'second_${artifact.id}',
            type: artifact.type,
            location: artifact.location,
          ),
      ];

      expect(
        CulturalVictoryProgressCalculator.winnerCandidateFromCollections(
          playerIds: const ['p1', 'p2'],
          artifacts: artifacts,
          cities: cities,
          holdTurnsByPlayerId: const {'p1': 5, 'p2': 5},
        ),
        isNull,
      );
      expect(
        CulturalVictoryProgressCalculator.winnerCandidateFromCollections(
          playerIds: const ['p1', 'p2'],
          artifacts: artifacts,
          cities: cities,
          holdTurnsByPlayerId: const {'p1': 5, 'p2': 6},
        ),
        'p2',
      );
    });
  });
}
