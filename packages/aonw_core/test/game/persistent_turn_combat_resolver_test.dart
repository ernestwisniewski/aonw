import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentTurnCombatResolver', () {
    test('resolves intended attacks against defended city unit first', () {
      final attacker = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final defender = GameUnit(
        id: 'settler_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.settler,
        name: 'Settler',
        col: 1,
        row: 0,
      );
      const city = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'City 2',
        center: CityHex(col: 1, row: 0),
      );
      final state = PersistentGameState(
        units: [attacker, defender],
        cities: [city],
        runtimeState: const GameRuntimeState(
          intendedAttacks: [
            IntendedAttack(
              attackerUnitId: 'warrior_1',
              defenderCol: 1,
              defenderRow: 0,
              declaredAtTick: 7,
              declaringPlayerId: 'player_1',
            ),
          ],
        ),
      );

      final result = PersistentTurnCombatResolver.resolve(
        turn: 4,
        state: state,
        mapDefinition: _mapDefinition(),
      );

      expect(result.state.units.map((unit) => unit.id), ['warrior_1']);
      expect(result.state.units.single.movementPoints, 0);
      expect(result.state.units.single.experiencePoints, 3);
      expect(result.state.cities.single.ownerPlayerId, 'player_2');
      expect(result.state.cities.single.hitPoints, isNull);
      expect(
        result.state.runtimeState.diplomacy.statusBetween(
          'player_1',
          'player_2',
        ),
        DiplomaticRelationStatus.hostile,
      );
      expect(result.events.map((event) => event.runtimeType), [
        UnitAttackedEvent,
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
        UnitKilledEvent,
      ]);
      final experience = result.events[2] as UnitGainedExperienceEvent;
      expect(experience.unitId, 'warrior_1');
      expect(experience.amount, 3);
      expect(experience.promoted, isTrue);
      final resolved = result.events[1] as CombatResolvedEvent;
      expect(resolved.outcome.attackerUnitId, 'warrior_1');
      expect(resolved.outcome.defenderUnitId, 'settler_2');
      expect(resolved.outcome.attackerKilled, isFalse);
      expect(resolved.outcome.defenderKilled, isTrue);
      expect(resolved.outcome.steps, isNotEmpty);
    });

    test('captures unguarded city when intended attack is lethal', () {
      final attacker = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      const city = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'City 2',
        center: CityHex(col: 1, row: 0),
        hitPoints: 1,
      );
      final state = PersistentGameState(
        units: [attacker],
        cities: const [city],
        runtimeState: const GameRuntimeState(
          intendedAttacks: [
            IntendedAttack(
              attackerUnitId: 'warrior_1',
              defenderCol: 1,
              defenderRow: 0,
              declaredAtTick: 7,
              declaringPlayerId: 'player_1',
            ),
          ],
        ),
      );

      final result = PersistentTurnCombatResolver.resolve(
        turn: 4,
        state: state,
        mapDefinition: _mapDefinition(),
      );

      expect(result.state.units.single.movementPoints, 0);
      expect(result.state.units.single.experiencePoints, 3);
      expect(result.state.cities.single.ownerPlayerId, 'player_1');
      expect(result.state.cities.single.hitPoints, 8);
      expect(
        result.state.runtimeState.diplomacy.statusBetween(
          'player_1',
          'player_2',
        ),
        DiplomaticRelationStatus.war,
      );
      expect(result.events.map((event) => event.runtimeType), [
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
        CityCapturedEvent,
      ]);
    });

    test('destroys unguarded city when intended attack requests razing', () {
      final attacker = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      const city = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'City 2',
        center: CityHex(col: 1, row: 0),
        hitPoints: 1,
      );
      final state = PersistentGameState(
        units: [attacker],
        cities: const [city],
        runtimeState: const GameRuntimeState(
          intendedAttacks: [
            IntendedAttack(
              attackerUnitId: 'warrior_1',
              defenderCol: 1,
              defenderRow: 0,
              declaredAtTick: 7,
              declaringPlayerId: 'player_1',
              cityConquestAction: CityConquestAction.destroy,
            ),
          ],
        ),
      );

      final result = PersistentTurnCombatResolver.resolve(
        turn: 4,
        state: state,
        mapDefinition: _mapDefinition(),
      );

      expect(result.state.units.single.movementPoints, 0);
      expect(result.state.units.single.experiencePoints, 3);
      expect(result.state.cities, isEmpty);
      expect(
        result.state.runtimeState.diplomacy.statusBetween(
          'player_1',
          'player_2',
        ),
        DiplomaticRelationStatus.war,
      );
      expect(result.events.map((event) => event.runtimeType), [
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
        CityDestroyedEvent,
      ]);
    });

    test('city attack emits warmonger score events for shared contacts', () {
      final attacker = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      const city = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'City 2',
        center: CityHex(col: 1, row: 0),
      );
      final state = PersistentGameState(
        units: [attacker],
        cities: const [city],
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty
              .addContact('player_1', 'player_2')
              .addContact('player_1', 'player_3')
              .addContact('player_2', 'player_3'),
          intendedAttacks: const [
            IntendedAttack(
              attackerUnitId: 'warrior_1',
              defenderCol: 1,
              defenderRow: 0,
              declaredAtTick: 7,
              declaringPlayerId: 'player_1',
            ),
          ],
        ),
      );

      final result = PersistentTurnCombatResolver.resolve(
        turn: 4,
        state: state,
        mapDefinition: _mapDefinition(),
      );
      final scoreEvent = result.events
          .whereType<DiplomaticScoreChangedEvent>()
          .single;

      expect(
        result.state.runtimeState.diplomacy.relationScoreBetween(
          'player_1',
          'player_3',
        ),
        DiplomaticWarmongerReputation.cityAttackPenalty,
      );
      expect(scoreEvent.playerAId, 'player_1');
      expect(scoreEvent.playerBId, 'player_3');
      expect(scoreEvent.delta, DiplomaticWarmongerReputation.cityAttackPenalty);
      expect(scoreEvent.reason, DiplomaticScoreChangeReason.warmongerPenalty);
      expect(scoreEvent.sourceId, 'city_attack.4.warrior_1');
    });

    test('moves a low-health defender when retreat is available', () {
      final attacker = GameUnit(
        id: 'archer_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.archer,
        name: 'Archer',
        col: 0,
        row: 0,
      );
      final defender = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [attacker, defender],
        runtimeState: const GameRuntimeState(
          intendedAttacks: [
            IntendedAttack(
              attackerUnitId: 'archer_1',
              defenderCol: 1,
              defenderRow: 0,
              declaredAtTick: 1,
              declaringPlayerId: 'player_1',
            ),
          ],
        ),
      );

      final result = PersistentTurnCombatResolver.resolve(
        turn: 1,
        state: state,
        mapDefinition: _mapDefinition(cols: 3, rows: 3),
        ruleset: _retreatRuleset,
      );

      final updatedDefender = result.state.units.singleWhere(
        (unit) => unit.id == 'warrior_2',
      );
      final updatedAttacker = result.state.units.singleWhere(
        (unit) => unit.id == 'archer_1',
      );
      expect(updatedAttacker.experiencePoints, 1);
      expect(updatedDefender.hitPoints, 1);
      expect(updatedDefender.movementPoints, 0);
      expect(updatedDefender.experiencePoints, 1);
      expect(updatedDefender.occupies(1, 0), isFalse);
      expect(
        HexDistance.between(
          const HexCoordinate(col: 1, row: 0),
          HexCoordinate(col: updatedDefender.col, row: updatedDefender.row),
        ),
        1,
      );
      expect(result.events.map((event) => event.runtimeType), [
        UnitAttackedEvent,
        CombatResolvedEvent,
        UnitRetreatedEvent,
        UnitGainedExperienceEvent,
        UnitGainedExperienceEvent,
      ]);

      final resolved = result.events[1] as CombatResolvedEvent;
      expect(resolved.outcome.defenderRetreated, isTrue);
      expect(resolved.outcome.defenderKilled, isFalse);
      final retreat = result.events[2] as UnitRetreatedEvent;
      expect(retreat.fromCol, 1);
      expect(retreat.fromRow, 0);
      expect(retreat.toCol, updatedDefender.col);
      expect(retreat.toRow, updatedDefender.row);
      expect(
        result.events.whereType<UnitGainedExperienceEvent>().map(
          (event) => event.unitId,
        ),
        ['archer_1', 'warrior_2'],
      );
    });

    test('ignores hostile intent outside attacker range', () {
      final state = PersistentGameState(
        units: [
          GameUnit(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            name: 'Warrior',
            col: 0,
            row: 0,
          ),
          GameUnit(
            id: 'warrior_2',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            name: 'Warrior',
            col: 3,
            row: 3,
          ),
        ],
        runtimeState: const GameRuntimeState(
          intendedAttacks: [
            IntendedAttack(
              attackerUnitId: 'warrior_1',
              defenderCol: 3,
              defenderRow: 3,
              declaredAtTick: 1,
              declaringPlayerId: 'player_1',
            ),
          ],
        ),
      );

      final result = PersistentTurnCombatResolver.resolve(
        turn: 1,
        state: state,
      );

      expect(result.state, state);
      expect(result.events, isEmpty);
    });
  });
}

const _retreatRuleset = GameRuleset(
  city: CityRulesets.standard,
  combat: CombatRuleset(
    varianceRange: 0,
    unitBaseStats: {
      GameUnitType.archer: CombatStats(
        attack: 12,
        defense: 1,
        hp: 7,
        range: 2,
        mobility: 1,
      ),
      GameUnitType.warrior: CombatStats(
        attack: 4,
        defense: 3,
        hp: 10,
        range: 1,
        mobility: 1,
      ),
    },
  ),
  technology: TechnologyRulesets.standard,
);

MapDefinition _mapDefinition({int cols = 2, int rows = 1}) {
  return MapDefinition(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++) _tile(col, row),
    ],
  );
}

MapTileDefinition _tile(int col, int row) {
  return MapTileDefinition(
    col: col,
    row: row,
    terrains: const [TerrainType.grassland],
    resources: const [],
    height: 0,
  );
}
