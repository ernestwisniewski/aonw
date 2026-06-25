import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CombatModifierCollector', () {
    test('collects terrain modifiers for a defender tile', () {
      final modifiers = CombatModifierCollector.forDefender(
        unit: _unit(),
        tile: _tile(terrains: const [TerrainType.forest, TerrainType.hills]),
        defendedCity: null,
        research: PlayerResearchState.empty,
      );

      expect(
        modifiers,
        containsAll(const [
          TerrainModifier(
            label: 'terrain.forest.defense',
            target: CombatStatTarget.defense,
            delta: 1,
          ),
          TerrainModifier(
            label: 'terrain.hills.defense',
            target: CombatStatTarget.defense,
            delta: 1,
          ),
        ]),
      );
    });

    test('collects army strength technology as attack modifier', () {
      final modifiers = CombatModifierCollector.forAttacker(
        unit: _unit(),
        tile: _tile(),
        research: PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.strategy},
        ),
      );

      expect(
        modifiers,
        contains(
          const TechnologyModifier(
            label: 'tech.strategy.armyStrength',
            target: CombatStatTarget.attack,
            delta: 1,
          ),
        ),
      );
    });

    test('collects army combat stat bonuses from military technologies', () {
      final modifiers = CombatModifierCollector.forAttacker(
        unit: _unit(),
        tile: _tile(),
        research: PlayerResearchState(
          unlockedTechnologyIds: {
            TechnologyId.militaryOrganization,
            TechnologyId.tactics,
            TechnologyId.strategy,
          },
        ),
      );

      expect(
        modifiers,
        containsAll(const [
          TechnologyModifier(
            label: 'tech.militaryOrganization.armyHitPoints',
            target: CombatStatTarget.hp,
            delta: 1,
          ),
          TechnologyModifier(
            label: 'tech.tactics.armyAttack',
            target: CombatStatTarget.attack,
            delta: 1,
          ),
          TechnologyModifier(
            label: 'tech.tactics.armyDefense',
            target: CombatStatTarget.defense,
            delta: 1,
          ),
          TechnologyModifier(
            label: 'tech.strategy.armyDefense',
            target: CombatStatTarget.defense,
            delta: 1,
          ),
          TechnologyModifier(
            label: 'tech.strategy.armyHitPoints',
            target: CombatStatTarget.hp,
            delta: 2,
          ),
        ]),
      );
    });

    test('does not apply army combat stat bonuses to civilian units', () {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 1,
        row: 1,
      );

      final modifiers = CombatModifierCollector.forDefender(
        unit: worker,
        tile: _tile(),
        defendedCity: null,
        research: PlayerResearchState(
          unlockedTechnologyIds: {
            TechnologyId.militaryOrganization,
            TechnologyId.tactics,
            TechnologyId.strategy,
          },
        ),
      );

      expect(
        modifiers.where(
          (modifier) =>
              modifier is TechnologyModifier &&
              modifier.label.contains('.army'),
        ),
        isEmpty,
      );
    });

    test('military technology path scales effective warrior stats', () {
      final unit = _unit();
      final modifiers = CombatModifierCollector.forAttacker(
        unit: unit,
        tile: _tile(),
        research: PlayerResearchState(
          unlockedTechnologyIds: {
            TechnologyId.militaryOrganization,
            TechnologyId.tactics,
            TechnologyId.strategy,
          },
        ),
      );

      expect(
        UnitCombatStats.derive(unit).applyAll(modifiers),
        const CombatStats(attack: 6, defense: 5, hp: 13, range: 1, mobility: 1),
      );
    });

    test('adds veterancy modifiers for experienced combat units', () {
      final unit = _unit().copyWith(experiencePoints: 12);
      final modifiers = CombatModifierCollector.forAttacker(
        unit: unit,
        tile: _tile(),
        research: PlayerResearchState.empty,
      );

      expect(
        modifiers,
        containsAll(const [
          VeterancyModifier(
            label: 'veterancy.elite.attack',
            target: CombatStatTarget.attack,
            delta: 2,
          ),
          VeterancyModifier(
            label: 'veterancy.elite.defense',
            target: CombatStatTarget.defense,
            delta: 1,
          ),
          VeterancyModifier(
            label: 'veterancy.elite.hp',
            target: CombatStatTarget.hp,
            delta: 2,
          ),
        ]),
      );
      expect(
        UnitCombatStats.derive(unit).applyAll(modifiers),
        const CombatStats(attack: 6, defense: 4, hp: 12, range: 1, mobility: 1),
      );
    });

    test('does not apply veterancy modifiers to civilian units', () {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 1,
        row: 1,
        experiencePoints: 12,
      );

      final modifiers = CombatModifierCollector.forDefender(
        unit: worker,
        tile: _tile(),
        defendedCity: null,
        research: PlayerResearchState.empty,
      );

      expect(modifiers.whereType<VeterancyModifier>(), isEmpty);
    });

    test('applies city defense technology only to defended city combat', () {
      final research = PlayerResearchState(
        unlockedTechnologyIds: {TechnologyId.fortifications},
      );
      final attackerModifiers = CombatModifierCollector.forAttacker(
        unit: _unit(),
        tile: _tile(),
        research: research,
      );
      final defenderModifiers = CombatModifierCollector.forDefender(
        unit: _unit(),
        tile: _tile(),
        defendedCity: const GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Roma',
          center: CityHex(col: 1, row: 1),
        ),
        research: research,
      );

      expect(
        attackerModifiers.whereType<TechnologyModifier>(),
        isNot(contains(_cityDefenseTechnologyModifier)),
      );
      expect(defenderModifiers, contains(_cityDefenseTechnologyModifier));
    });

    test('adds fortification modifier for city garrison defender', () {
      final modifiers = CombatModifierCollector.forDefender(
        unit: _unit(),
        tile: _tile(),
        defendedCity: const GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Roma',
          center: CityHex(col: 1, row: 1),
        ),
        research: PlayerResearchState.empty,
      );

      expect(
        modifiers,
        contains(
          const FortificationModifier(
            label: 'city.city_1.garrison',
            target: CombatStatTarget.defense,
            delta: 1,
          ),
        ),
      );
    });

    test('adds mixed commander army composition attack modifier', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        army: const [
          ArmyTroop(type: TroopType.warrior, count: 1),
          ArmyTroop(type: TroopType.archer, count: 1),
        ],
      );

      final modifiers = CombatModifierCollector.forAttacker(
        unit: commander,
        tile: _tile(),
        research: PlayerResearchState.empty,
      );

      expect(
        modifiers,
        contains(
          const TroopCompositionModifier(
            label: 'troop.mixedCommanderArmy',
            target: CombatStatTarget.attack,
            delta: 1,
          ),
        ),
      );
    });

    test('does not add mixed army bonus for standalone units', () {
      final modifiers = CombatModifierCollector.forAttacker(
        unit: _unit(),
        tile: _tile(),
        research: PlayerResearchState.empty,
      );

      expect(modifiers.whereType<TroopCompositionModifier>(), isEmpty);
    });

    test('adds cavalry raid bonus against support units on open terrain', () {
      final modifiers = CombatModifierCollector.forAttacker(
        unit: _unit(type: GameUnitType.cavalry),
        tile: _tile(),
        defender: _unit(type: GameUnitType.worker),
        defenderTile: _tile(terrains: const [TerrainType.plains]),
        research: PlayerResearchState.empty,
      );

      expect(
        modifiers,
        contains(
          const CounterModifier(
            label: 'counter.cavalryOpenRaid.attack',
            target: CombatStatTarget.attack,
            delta: 2,
          ),
        ),
      );
    });

    test('does not add cavalry raid bonus in rough defender terrain', () {
      final modifiers = CombatModifierCollector.forAttacker(
        unit: _unit(type: GameUnitType.cavalry),
        tile: _tile(),
        defender: _unit(type: GameUnitType.worker),
        defenderTile: _tile(terrains: const [TerrainType.forest]),
        research: PlayerResearchState.empty,
      );

      expect(
        modifiers,
        isNot(
          contains(
            const CounterModifier(
              label: 'counter.cavalryOpenRaid.attack',
              target: CombatStatTarget.attack,
              delta: 2,
            ),
          ),
        ),
      );
      expect(
        modifiers,
        contains(
          const CounterModifier(
            label: 'counter.cavalryRoughAttack.attack',
            target: CombatStatTarget.attack,
            delta: -2,
          ),
        ),
      );
    });
  });
}

const _cityDefenseTechnologyModifier = TechnologyModifier(
  label: 'tech.fortifications.cityDefense',
  target: CombatStatTarget.defense,
  delta: 2,
);

GameUnit _unit({GameUnitType type = GameUnitType.warrior}) {
  return GameUnit(
    id: 'warrior_1',
    ownerPlayerId: 'player_1',
    type: type,
    name: type.defaultNameToken,
    col: 1,
    row: 1,
  );
}

TileData _tile({List<TerrainType> terrains = const [TerrainType.grassland]}) {
  return TileData(
    col: 1,
    row: 1,
    terrains: terrains,
    resources: const [],
    height: 0,
  );
}
