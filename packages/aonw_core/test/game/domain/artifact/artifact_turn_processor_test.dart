import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ArtifactTurnProcessor parity', () {
    test('matches the persistent wrapper through excavation completion', () {
      final input = _excavationInput(remainingTurns: 2);
      final pending = _advanceBoth(input);

      expect(pending.neutral.changed, isTrue);
      expect(pending.neutral.artifacts.first.location.remainingTurns, 1);
      expect(pending.neutral.units.first.excavatingArtifactId, 'artifact_1');
      expect(pending.neutral.units.last, input.units.last);

      final completed = _advanceBoth(
        PersistentGameState(
          units: pending.neutral.units,
          artifacts: pending.neutral.artifacts,
        ),
      );
      final unit = completed.neutral.units.first;
      final artifact = completed.neutral.artifacts.first;

      expect(completed.neutral.changed, isTrue);
      expect(unit.excavatingArtifactId, isNull);
      expect(unit.carriedArtifactId, artifact.id);
      expect(artifact.location.isCarried, isTrue);
      expect(artifact.location.unitId, unit.id);
      expect(() => completed.neutral.units.clear(), throwsUnsupportedError);
      expect(() => completed.neutral.artifacts.clear(), throwsUnsupportedError);
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

      final result = _advanceBoth(
        PersistentGameState(units: [unit], artifacts: const [artifact]),
      );

      expect(result.neutral.changed, isTrue);
      expect(result.neutral.units.single.excavatingArtifactId, isNull);
      expect(result.neutral.artifacts.single.location.isOnMap, isTrue);
      expect(result.neutral.artifacts.single.location.col, 0);
      expect(result.neutral.artifacts.single.location.row, 0);
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
        final persistent = PersistentArtifactTurnProcessor.advanceForPlayers(
          state: input,
          playerIds: const ['', ''],
        );

        expect(neutral.changed, isFalse);
        expect(identical(neutral.units, input.units), isTrue);
        expect(identical(neutral.artifacts, input.artifacts), isTrue);
        expect(persistent.changed, isFalse);
        expect(identical(persistent.state, input), isTrue);
      },
    );
  });
}

({ArtifactTurnResult neutral, PersistentArtifactTurnResult persistent})
_advanceBoth(PersistentGameState input) {
  final neutral = ArtifactTurnProcessor.advanceForPlayers(
    units: input.units,
    artifacts: input.artifacts,
    playerIds: const ['p1', 'p1', ''],
  );
  final persistent = PersistentArtifactTurnProcessor.advanceForPlayers(
    state: input,
    playerIds: const ['p1', 'p1', ''],
  );

  expect(neutral.changed, persistent.changed);
  expect(neutral.units, persistent.state.units);
  expect(neutral.artifacts, persistent.state.artifacts);
  return (neutral: neutral, persistent: persistent);
}

PersistentGameState _excavationInput({required int remainingTurns}) {
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
  return PersistentGameState(
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
