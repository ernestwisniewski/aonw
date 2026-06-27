import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState', () {
    group('default constructor', () {
      test('produces empty/default state', () {
        const state = GameState();
        expect(state.playerColors, isEmpty);
        expect(state.units, isEmpty);
        expect(state.cities, isEmpty);
        expect(state.fieldImprovements, isEmpty);
        expect(state.fogOfWar, equals(FogOfWarState.empty));
        expect(state.research, equals(ResearchState.empty));
        expect(state.intendedAttacks, isEmpty);
        expect(state.activePlayerId, equals(''));
        expect(state.activePlayerCanAct, isTrue);
        expect(state.selection, isNull);
        expect(state.movePreview, isNull);
        expect(state.cityFoundingDraft, isNull);
        expect(state.moveCommandActive, isFalse);
      });
    });

    group('copyWith', () {
      test('replaces specified fields', () {
        const state = GameState();
        final unit = GameUnit.startingCommander(
          ownerPlayerId: 'p1',
          col: 1,
          row: 2,
        );
        final updated = state
            .copyWith(
              activePlayerId: 'p1',
              activePlayerCanAct: true,
              units: [unit],
              intendedAttacks: const [
                IntendedAttack(
                  attackerUnitId: 'warrior_1',
                  defenderCol: 4,
                  defenderRow: 5,
                  declaredAtTick: 7,
                  declaringPlayerId: 'p1',
                ),
              ],
              research: ResearchState(
                players: {
                  'p1': PlayerResearchState(
                    activeTechnologyId: TechnologyId.agriculture,
                  ),
                },
              ),
            )
            .copyWithInteraction(moveCommandActive: true);
        expect(updated.activePlayerId, equals('p1'));
        expect(updated.activePlayerCanAct, isTrue);
        expect(updated.units, equals([unit]));
        expect(updated.intendedAttacks.single.attackerUnitId, 'warrior_1');
        expect(
          updated.research.forPlayer('p1').activeTechnologyId,
          TechnologyId.agriculture,
        );
        expect(updated.moveCommandActive, isTrue);
        // unchanged fields
        expect(updated.playerColors, isEmpty);
        expect(updated.selection, isNull);
      });

      test('leaves all fields unchanged when no arguments passed', () {
        const original = GameState(
          activePlayerId: 'p2',
          activePlayerCanAct: true,
        );
        final copy = original.copyWith();
        expect(copy, equals(original));
      });
    });

    group('copyWith selection', () {
      test('sets selection', () {
        const state = GameState();
        final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
        final sel = GameSelection.unit(unit);
        final updated = state.copyWithInteraction(selection: sel);
        expect(updated.selection, equals(sel));
      });

      test('clears selection when null passed', () {
        final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
        final sel = GameSelection.unit(unit);
        final state = const GameState().copyWithInteraction(selection: sel);
        final cleared = state.copyWithInteraction(selection: null);
        expect(cleared.selection, isNull);
      });
    });

    group('copyWith movePreview', () {
      test('sets move preview', () {
        const state = GameState();
        final plan = UnitMovementPlan(
          unitId: 'commander_p1',
          targetCol: 3,
          targetRow: 4,
          totalCost: 2,
          availableMovementPoints: 4,
          steps: const [],
        );
        final updated = state.copyWithInteraction(movePreview: plan);
        expect(updated.movePreview, equals(plan));
      });

      test('clears move preview when null passed', () {
        final plan = UnitMovementPlan(
          unitId: 'commander_p1',
          targetCol: 3,
          targetRow: 4,
          totalCost: 2,
          availableMovementPoints: 4,
          steps: const [],
        );
        final state = const GameState().copyWithInteraction(movePreview: plan);
        final cleared = state.copyWithInteraction(movePreview: null);
        expect(cleared.movePreview, isNull);
      });
    });

    group('copyWith cityFoundingDraft', () {
      test('sets city founding draft', () {
        const state = GameState();
        final draft = CityFoundingDraft(
          unitId: 'commander_p1',
          ownerPlayerId: 'p1',
          center: const CityHex(col: 0, row: 0),
        );
        final updated = state.copyWithInteraction(cityFoundingDraft: draft);
        expect(updated.cityFoundingDraft, equals(draft));
      });

      test('clears city founding draft when null passed', () {
        final draft = CityFoundingDraft(
          unitId: 'commander_p1',
          ownerPlayerId: 'p1',
          center: const CityHex(col: 0, row: 0),
        );
        final state = const GameState().copyWithInteraction(
          cityFoundingDraft: draft,
        );
        final cleared = state.copyWithInteraction(cityFoundingDraft: null);
        expect(cleared.cityFoundingDraft, isNull);
      });
    });

    group('equality', () {
      test('two default instances are equal', () {
        const a = GameState();
        const b = GameState();
        expect(a, equals(b));
      });

      test('compares all fields', () {
        const a = GameState(activePlayerId: 'p1', activePlayerCanAct: true);
        const b = GameState(activePlayerId: 'p2', activePlayerCanAct: true);
        expect(a, isNot(equals(b)));
      });

      test('same content with different unit lists is not equal', () {
        final unit1 = GameUnit.startingCommander(
          ownerPlayerId: 'p1',
          col: 0,
          row: 0,
        );
        final unit2 = GameUnit.startingCommander(
          ownerPlayerId: 'p1',
          col: 1,
          row: 1,
        );
        final a = GameState(units: [unit1]);
        final b = GameState(units: [unit2]);
        expect(a, isNot(equals(b)));
      });

      test('equal instances have same hashCode', () {
        const a = GameState(activePlayerId: 'p1');
        const b = GameState(activePlayerId: 'p1');
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('derived getters', () {
      test('selectedUnitId returns null when no selection', () {
        const state = GameState();
        expect(state.selectedUnitId, isNull);
      });

      test('selectedUnitId returns unit id when unit is selected', () {
        final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
        final sel = GameSelection.unit(unit);
        final state = GameState(
          units: [unit],
        ).copyWithInteraction(selection: sel);
        expect(state.selectedUnitId, equals(unit.id));
      });

      test('selectedUnit returns the live unit from units list', () {
        final unit = GameUnit.startingCommander(
          ownerPlayerId: 'p1',
          col: 0,
          row: 0,
        );
        final sel = GameSelection.unit(unit);
        final state = GameState(
          units: [unit],
        ).copyWithInteraction(selection: sel);
        expect(state.selectedUnit, equals(unit));
      });

      test('selectedUnit returns null when selection is not a unit', () {
        const state = GameState();
        expect(state.selectedUnit, isNull);
      });

      test('colorForPlayer returns color for known player', () {
        const state = GameState(playerColors: {'p1': 0xFFFF0000});
        expect(state.colorForPlayer('p1'), equals(0xFFFF0000));
      });

      test('colorForPlayer returns null for unknown player', () {
        const state = GameState();
        expect(state.colorForPlayer('unknown'), isNull);
      });

      test('canControlCity is true when activePlayerId is empty', () {
        const city = GameCity(
          id: 'city_p1',
          ownerPlayerId: 'p1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        );
        const state = GameState(activePlayerId: '');
        expect(state.canControlCity(city), isTrue);
      });

      test('canControlCity is true when city belongs to active player', () {
        const city = GameCity(
          id: 'city_p1',
          ownerPlayerId: 'p1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        );
        const state = GameState(activePlayerId: 'p1', activePlayerCanAct: true);
        expect(state.canControlCity(city), isTrue);
      });

      test('canControlCity is false when city belongs to different player', () {
        const city = GameCity(
          id: 'city_p2',
          ownerPlayerId: 'p2',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        );
        const state = GameState(activePlayerId: 'p1', activePlayerCanAct: true);
        expect(state.canControlCity(city), isFalse);
      });

      test('canControlCity is false when activePlayerCanAct is false', () {
        const city = GameCity(
          id: 'city_p1',
          ownerPlayerId: 'p1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        );
        const state = GameState(
          activePlayerId: 'p1',
          activePlayerCanAct: false,
        );
        expect(state.canControlCity(city), isFalse);
      });

      test(
        'canControlUnit is true when active player owns unit and can act',
        () {
          final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
          const state = GameState(
            activePlayerId: 'p1',
            activePlayerCanAct: true,
          );
          expect(state.canControlUnit(unit), isTrue);
        },
      );

      test('canControlUnit is false when player cannot act', () {
        final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
        const state = GameState(
          activePlayerId: 'p1',
          activePlayerCanAct: false,
        );
        expect(state.canControlUnit(unit), isFalse);
      });

      test('canControlUnit is false when unit belongs to different player', () {
        final unit = GameUnit.startingCommander(ownerPlayerId: 'p2');
        const state = GameState(activePlayerId: 'p1', activePlayerCanAct: true);
        expect(state.canControlUnit(unit), isFalse);
      });

      test('unitAt returns unit at given coordinates', () {
        final unit = GameUnit.startingCommander(
          ownerPlayerId: 'p1',
          col: 3,
          row: 5,
        );
        final state = GameState(units: [unit]);
        expect(state.unitAt(3, 5), equals(unit));
      });

      test('unitAt returns null when no unit at coordinates', () {
        final unit = GameUnit.startingCommander(
          ownerPlayerId: 'p1',
          col: 3,
          row: 5,
        );
        final state = GameState(units: [unit]);
        expect(state.unitAt(0, 0), isNull);
      });

      test('activePlayerVisibility returns query for active player', () {
        const fog = FogOfWarState.empty;
        const state = GameState(activePlayerId: 'p1', fogOfWar: fog);
        final query = state.activePlayerVisibility;
        expect(query.playerId, equals('p1'));
        expect(query.state, equals(fog));
      });

      group('unitsVisibleToActivePlayer', () {
        test('returns all units when fog is disabled (no active player)', () {
          final unit1 = GameUnit.startingCommander(
            ownerPlayerId: 'p1',
            col: 1,
            row: 1,
          );
          final unit2 = GameUnit.startingCommander(
            ownerPlayerId: 'p2',
            col: 2,
            row: 2,
          );
          const state = GameState(activePlayerId: '');
          final stateWithUnits = state.copyWith(units: [unit1, unit2]);
          expect(
            stateWithUnits.unitsVisibleToActivePlayer,
            equals([unit1, unit2]),
          );
        });

        test('filters to only visible units when fog is active', () {
          final unit1 = GameUnit.startingCommander(
            ownerPlayerId: 'p1',
            col: 1,
            row: 1,
          );
          final unit2 = GameUnit.startingCommander(
            ownerPlayerId: 'p2',
            col: 5,
            row: 5,
          );
          final playerFog = PlayerFogOfWar(
            playerId: 'p1',
            visibleHexes: {const HexCoordinate(col: 1, row: 1)},
          );
          final fog = FogOfWarState(players: {'p1': playerFog});
          final state = GameState(
            activePlayerId: 'p1',
            units: [unit1, unit2],
            fogOfWar: fog,
          );
          expect(state.unitsVisibleToActivePlayer, equals([unit1]));
        });

        test('keeps own units visible even when their hex is not in fog', () {
          final ownUnit = GameUnit.startingCommander(
            ownerPlayerId: 'p1',
            col: 3,
            row: 3,
          );
          final hiddenEnemy = GameUnit.startingCommander(
            ownerPlayerId: 'p2',
            col: 5,
            row: 5,
          );
          final visibleEnemy = GameUnit.startingCommander(
            ownerPlayerId: 'p2',
            col: 1,
            row: 1,
          );
          final playerFog = PlayerFogOfWar(
            playerId: 'p1',
            visibleHexes: {const HexCoordinate(col: 1, row: 1)},
          );
          final state = GameState(
            activePlayerId: 'p1',
            units: [ownUnit, hiddenEnemy, visibleEnemy],
            fogOfWar: FogOfWarState(players: {'p1': playerFog}),
          );

          expect(
            state.unitsVisibleToActivePlayer,
            equals([ownUnit, visibleEnemy]),
          );
        });
      });

      group('citiesKnownToActivePlayer', () {
        test('returns all cities when fog is disabled (no active player)', () {
          const city1 = GameCity(
            id: 'city1',
            ownerPlayerId: 'p1',
            name: 'City 1',
            center: CityHex(col: 1, row: 1),
          );
          const city2 = GameCity(
            id: 'city2',
            ownerPlayerId: 'p2',
            name: 'City 2',
            center: CityHex(col: 5, row: 5),
          );
          const state = GameState(activePlayerId: '');
          final stateWithCities = state.copyWith(cities: [city1, city2]);
          expect(
            stateWithCities.citiesKnownToActivePlayer,
            equals([city1, city2]),
          );
        });

        test('filters to only known cities when fog is active', () {
          const city1 = GameCity(
            id: 'city1',
            ownerPlayerId: 'p1',
            name: 'City 1',
            center: CityHex(col: 1, row: 1),
          );
          const city2 = GameCity(
            id: 'city2',
            ownerPlayerId: 'p2',
            name: 'City 2',
            center: CityHex(col: 5, row: 5),
          );
          final playerFog = PlayerFogOfWar(
            playerId: 'p1',
            discoveredHexes: {const HexCoordinate(col: 1, row: 1)},
          );
          final fog = FogOfWarState(players: {'p1': playerFog});
          final state = GameState(
            activePlayerId: 'p1',
            cities: [city1, city2],
            fogOfWar: fog,
          );
          expect(state.citiesKnownToActivePlayer, equals([city1]));
        });
      });
    });
  });
}
