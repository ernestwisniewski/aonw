import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ArtifactTurnProcessor', () {
    test('advances excavation through completion', () {
      final input = _excavationInput(remainingTurns: 2);
      final pending = _advance(input);

      expect(pending.changed, isTrue);
      expect(pending.events, isEmpty);
      expect(pending.artifacts.first.location.remainingTurns, 1);
      expect(pending.units.first.excavatingArtifactId, 'artifact_1');
      expect(pending.units.last, input.units.last);

      final completed = _advance(
        DomainState.snapshot(
          units: pending.units,
          artifacts: pending.artifacts,
        ),
      );
      final unit = completed.units.first;
      final artifact = completed.artifacts.first;

      expect(completed.changed, isTrue);
      expect(unit.excavatingArtifactId, isNull);
      expect(unit.carriedArtifactId, artifact.id);
      expect(artifact.location.isCarried, isTrue);
      expect(artifact.location.unitId, unit.id);
      expect(
        completed.events.single,
        isA<ArtifactCarriedEvent>()
            .having((event) => event.artifactId, 'artifactId', 'artifact_1')
            .having((event) => event.ownerPlayerId, 'owner', 'p1')
            .having((event) => event.unitId, 'unit', 'scout_1')
            .having((event) => (event.col, event.row), 'hex', (0, 0)),
      );
      expect(() => completed.units.clear(), throwsUnsupportedError);
      expect(() => completed.artifacts.clear(), throwsUnsupportedError);
    });

    test('matches cancellation of an invalid excavation binding', () {
      final unit = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 1,
        row: 0,
        excavatingArtifactId: 'artifact_1',
      );
      const artifact = WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.astronomersTablets,
        location: WorldArtifactLocation.excavation(
          unitId: 'scout_1',
          col: 0,
          row: 0,
          remainingTurns: 1,
        ),
      );

      final result = _advance(
        DomainState.snapshot(units: [unit], artifacts: const [artifact]),
      );

      expect(result.changed, isTrue);
      expect(result.units.single.excavatingArtifactId, isNull);
      expect(result.artifacts.single.location.isOnMap, isTrue);
      expect(result.artifacts.single.location.col, 0);
      expect(result.artifacts.single.location.row, 0);
      expect(result.events, isEmpty);
    });

    test(
      'preserves collection and state identity for an empty player scope',
      () {
        final input = _excavationInput(remainingTurns: 2);
        final neutral = ArtifactTurnProcessor.advanceForPlayers(
          units: input.units,
          artifacts: input.artifacts,
          playerIds: const ['', ''],
        );
        expect(neutral.changed, isFalse);
        expect(identical(neutral.units, input.units), isTrue);
        expect(identical(neutral.artifacts, input.artifacts), isTrue);
        expect(neutral.events, isEmpty);
      },
    );
  });
}

ArtifactTurnResult _advance(DomainState input) {
  return ArtifactTurnProcessor.advanceForPlayers(
    units: input.units,
    artifacts: input.artifacts,
    playerIds: const ['p1', 'p1', ''],
  );
}

DomainState _excavationInput({required int remainingTurns}) {
  final selected = GameUnit(
    id: 'scout_1',
    ownerPlayerId: 'p1',
    type: GameUnitType.scout,
    name: 'Scout',
    col: 0,
    row: 0,
    excavatingArtifactId: 'artifact_1',
  );
  final foreign = GameUnit(
    id: 'scout_2',
    ownerPlayerId: 'p2',
    type: GameUnitType.scout,
    name: 'Foreign scout',
    col: 1,
    row: 0,
    excavatingArtifactId: 'artifact_2',
  );
  return DomainState.snapshot(
    units: [selected, foreign],
    artifacts: [
      WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.astronomersTablets,
        location: WorldArtifactLocation.excavation(
          unitId: selected.id,
          col: selected.col,
          row: selected.row,
          remainingTurns: remainingTurns,
        ),
      ),
      WorldArtifact(
        id: 'artifact_2',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.excavation(
          unitId: foreign.id,
          col: foreign.col,
          row: foreign.row,
          remainingTurns: 1,
        ),
      ),
    ],
  );
}
