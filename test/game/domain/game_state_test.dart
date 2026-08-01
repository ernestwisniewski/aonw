import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InteractionState', () {
    test('keeps copyWith, equality, and hashCode contract in sync', () {
      final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
      final selection = GameSelection.unit(unit);
      final movePreview = UnitMovementPlan(
        unitId: unit.id,
        targetCol: 2,
        targetRow: 3,
        totalCost: 2,
        availableMovementPoints: 4,
        steps: const [],
      );
      final cityFoundingDraft = CityFoundingDraft(
        unitId: unit.id,
        ownerPlayerId: 'p1',
        center: const CityHex(col: 1, row: 1),
      );
      const pendingAction = PendingResearchSelection(ownerPlayerId: 'p1');

      final state = InteractionState(
        selection: selection,
        movePreview: movePreview,
        cityFoundingDraft: cityFoundingDraft,
        pendingAction: pendingAction,
        moveCommandActive: true,
      );
      final sameState = InteractionState(
        selection: selection,
        movePreview: movePreview,
        cityFoundingDraft: cityFoundingDraft,
        pendingAction: pendingAction,
        moveCommandActive: true,
      );

      expect(state.copyWith(), equals(state));
      expect(sameState, equals(state));
      expect(sameState.hashCode, equals(state.hashCode));
      expect(state.copyWith(selection: null).selection, isNull);
      expect(state.copyWith(movePreview: null).movePreview, isNull);
      expect(state.copyWith(cityFoundingDraft: null).cityFoundingDraft, isNull);
      expect(state.copyWith(pendingAction: null).pendingAction, isNull);
      expect(
        state.copyWith(moveCommandActive: false).moveCommandActive,
        isFalse,
      );
      expect(state.copyWith(selection: null), isNot(equals(state)));
    });

    test('clear helpers preserve expected transient state', () {
      final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
      final selection = GameSelection.unit(unit);
      final movePreview = UnitMovementPlan(
        unitId: unit.id,
        targetCol: 2,
        targetRow: 3,
        totalCost: 2,
        availableMovementPoints: 4,
        steps: const [],
      );
      final cityFoundingDraft = CityFoundingDraft(
        unitId: unit.id,
        ownerPlayerId: 'p1',
        center: const CityHex(col: 1, row: 1),
      );
      const pendingAction = PendingResearchSelection(ownerPlayerId: 'p1');
      final state = InteractionState(
        selection: selection,
        movePreview: movePreview,
        cityFoundingDraft: cityFoundingDraft,
        pendingAction: pendingAction,
        moveCommandActive: true,
      );

      final clearedTransient = state.clearTransientModes();
      expect(clearedTransient.selection, selection);
      expect(clearedTransient.movePreview, isNull);
      expect(clearedTransient.cityFoundingDraft, isNull);
      expect(clearedTransient.pendingAction, pendingAction);
      expect(clearedTransient.moveCommandActive, isFalse);

      final clearedMap = state.clearMapState(clearPendingAction: true);
      expect(clearedMap.selection, selection);
      expect(clearedMap.movePreview, isNull);
      expect(clearedMap.cityFoundingDraft, isNull);
      expect(clearedMap.pendingAction, isNull);
      expect(clearedMap.moveCommandActive, isFalse);
    });
  });

  group('GameClientState', () {
    group('default constructor', () {
      test('produces empty/default state', () {
        final state = GameClientState();
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
        final state = GameClientState();
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
        final original = GameClientState(
          activePlayerId: 'p2',
          activePlayerCanAct: true,
        );
        final copy = original.copyWith();
        expect(copy, equals(original));
      });
    });

    group('copyWith selection', () {
      test('sets selection', () {
        final state = GameClientState();
        final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
        final sel = GameSelection.unit(unit);
        final updated = state.copyWithInteraction(selection: sel);
        expect(updated.selection, equals(sel));
      });

      test('clears selection when null passed', () {
        final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
        final sel = GameSelection.unit(unit);
        final state = GameClientState().copyWithInteraction(selection: sel);
        final cleared = state.copyWithInteraction(selection: null);
        expect(cleared.selection, isNull);
      });
    });

    group('copyWith movePreview', () {
      test('sets move preview', () {
        final state = GameClientState();
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
        final state = GameClientState().copyWithInteraction(movePreview: plan);
        final cleared = state.copyWithInteraction(movePreview: null);
        expect(cleared.movePreview, isNull);
      });
    });

    group('copyWith cityFoundingDraft', () {
      test('sets city founding draft', () {
        final state = GameClientState();
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
        final state = GameClientState().copyWithInteraction(
          cityFoundingDraft: draft,
        );
        final cleared = state.copyWithInteraction(cityFoundingDraft: null);
        expect(cleared.cityFoundingDraft, isNull);
      });
    });

    group('equality', () {
      test('two default instances are equal', () {
        final a = GameClientState();
        final b = GameClientState();
        expect(a, equals(b));
      });

      test('compares all fields', () {
        final a = GameClientState(activePlayerId: 'p1');
        final b = GameClientState(activePlayerId: 'p2');
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
        final a = GameClientState(units: [unit1]);
        final b = GameClientState(units: [unit2]);
        expect(a, isNot(equals(b)));
      });

      test('equal instances have same hashCode', () {
        final a = GameClientState(activePlayerId: 'p1');
        final b = GameClientState(activePlayerId: 'p1');
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('derived getters', () {
      test('selectedUnitId returns null when no selection', () {
        final state = GameClientState();
        expect(state.selectedUnitId, isNull);
      });

      test('selectedUnitId returns unit id when unit is selected', () {
        final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
        final sel = GameSelection.unit(unit);
        final state = GameClientState(
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
        final state = GameClientState(
          units: [unit],
        ).copyWithInteraction(selection: sel);
        expect(state.selectedUnit, equals(unit));
      });

      test('selectedUnit returns null when selection is not a unit', () {
        final state = GameClientState();
        expect(state.selectedUnit, isNull);
      });

      test('colorForPlayer returns color for known player', () {
        final state = GameClientState(playerColors: {'p1': 0xFFFF0000});
        expect(state.colorForPlayer('p1'), equals(0xFFFF0000));
      });

      test('colorForPlayer returns null for unknown player', () {
        final state = GameClientState();
        expect(state.colorForPlayer('unknown'), isNull);
      });

      test('canControlCity is true when activePlayerId is empty', () {
        const city = GameCity(
          id: 'city_p1',
          ownerPlayerId: 'p1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        );
        final state = GameClientState(activePlayerId: '');
        expect(state.canControlCity(city), isTrue);
      });

      test('canControlCity is true when city belongs to active player', () {
        const city = GameCity(
          id: 'city_p1',
          ownerPlayerId: 'p1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        );
        final state = GameClientState(activePlayerId: 'p1');
        expect(state.canControlCity(city), isTrue);
      });

      test('canControlCity is false when city belongs to different player', () {
        const city = GameCity(
          id: 'city_p2',
          ownerPlayerId: 'p2',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        );
        final state = GameClientState(activePlayerId: 'p1');
        expect(state.canControlCity(city), isFalse);
      });

      test('canControlCity is false when activePlayerCanAct is false', () {
        const city = GameCity(
          id: 'city_p1',
          ownerPlayerId: 'p1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        );
        final state = GameClientState(
          activePlayerId: 'p1',
          activePlayerCanAct: false,
        );
        expect(state.canControlCity(city), isFalse);
      });

      test(
        'canControlUnit is true when active player owns unit and can act',
        () {
          final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
          final state = GameClientState(
            activePlayerId: 'p1',
            activePlayerCanAct: true,
          );
          expect(state.canControlUnit(unit), isTrue);
        },
      );

      test('canControlUnit is false when player cannot act', () {
        final unit = GameUnit.startingCommander(ownerPlayerId: 'p1');
        final state = GameClientState(
          activePlayerId: 'p1',
          activePlayerCanAct: false,
        );
        expect(state.canControlUnit(unit), isFalse);
      });

      test('canControlUnit is false when unit belongs to different player', () {
        final unit = GameUnit.startingCommander(ownerPlayerId: 'p2');
        final state = GameClientState(activePlayerId: 'p1');
        expect(state.canControlUnit(unit), isFalse);
      });

      test('unitAt returns unit at given coordinates', () {
        final unit = GameUnit.startingCommander(
          ownerPlayerId: 'p1',
          col: 3,
          row: 5,
        );
        final state = GameClientState(units: [unit]);
        expect(state.unitAt(3, 5), equals(unit));
      });

      test('unitAt returns null when no unit at coordinates', () {
        final unit = GameUnit.startingCommander(
          ownerPlayerId: 'p1',
          col: 3,
          row: 5,
        );
        final state = GameClientState(units: [unit]);
        expect(state.unitAt(0, 0), isNull);
      });

      test('cityAt returns city at given center coordinates', () {
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'p1',
          name: 'Warsaw',
          center: CityHex(col: 4, row: 6),
        );
        final state = GameClientState(cities: [city]);
        expect(state.cityAt(4, 6), equals(city));
        expect(state.cityAt(0, 0), isNull);
      });

      test('activePlayerVisibility returns query for active player', () {
        const fog = FogOfWarState.empty;
        final state = GameClientState(activePlayerId: 'p1', fogOfWar: fog);
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
          final state = GameClientState(activePlayerId: '');
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
          final state = GameClientState(
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
          final state = GameClientState(
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
          final state = GameClientState(activePlayerId: '');
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
          final state = GameClientState(
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
