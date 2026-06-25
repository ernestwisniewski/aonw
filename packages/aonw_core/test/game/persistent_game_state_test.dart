import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentGameState', () {
    test('round-trips persistent game slices', () {
      final state = PersistentGameState(
        playerColors: const {'player_1': 0xFF4a7fc4},
        playerCountries: const {'player_1': PlayerCountry.japan},
        playerGold: const {'player_1': 12},
        units: [GameUnit.startingCommander(ownerPlayerId: 'player_1')],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 2, row: 3),
          ),
        ],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 2, row: 4),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
        runtimeState: GameRuntimeState(
          submittedPlayerIds: const {'player_1'},
          intendedAttacks: const [
            IntendedAttack(
              attackerUnitId: 'warrior_1',
              defenderCol: 4,
              defenderRow: 5,
              declaredAtTick: 7,
              declaringPlayerId: 'player_1',
            ),
          ],
          turnStartedAt: DateTime.utc(2026, 4, 27, 12),
        ),
      );

      final restored = PersistentGameState.fromJson(state.toJson());

      expect(restored, state);
      expect(restored.countryForPlayer('player_1'), PlayerCountry.japan);
      expect(restored.units.single.ownerPlayerId, 'player_1');
      expect(restored.cities.single.center, const CityHex(col: 2, row: 3));
      expect(restored.fieldImprovements.single.type, FieldImprovementType.farm);
      expect(
        restored.runtimeState.turnStartedAt,
        DateTime.utc(2026, 4, 27, 12),
      );
    });

    test('defaults missing optional slices', () {
      final state = PersistentGameState.fromJson(const {});

      expect(state.playerColors, isEmpty);
      expect(state.playerCountries, isEmpty);
      expect(state.countryForPlayer('missing'), PlayerCountry.poland);
      expect(state.units, isEmpty);
      expect(state.fogOfWar, FogOfWarState.empty);
      expect(state.research, ResearchState.empty);
      expect(state.runtimeState, GameRuntimeState.empty);
    });

    test('can strip local client interaction from runtime state', () {
      final state = PersistentGameState(
        units: [GameUnit.startingCommander(ownerPlayerId: 'player_1')],
        runtimeState: GameRuntimeState(
          cityFoundingDraft: CityFoundingDraft(
            unitId: 'settler_1',
            ownerPlayerId: 'player_1',
            center: const CityHex(col: 0, row: 0),
          ),
          pendingAction: const PendingResearchSelection(
            ownerPlayerId: 'player_1',
          ),
          submittedPlayerIds: const {'player_1'},
        ),
      );

      final stripped = state.withoutClientInteractionState();

      expect(stripped.units, state.units);
      expect(stripped.runtimeState.cityFoundingDraft, isNull);
      expect(stripped.runtimeState.pendingAction, isNull);
      expect(stripped.runtimeState.submittedPlayerIds, {'player_1'});
    });

    test('reports malformed list fields with field name', () {
      expect(
        () => PersistentGameState.fromJson({'units': 'bad'}),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'PersistentGameState.units',
          ),
        ),
      );
    });
  });
}
