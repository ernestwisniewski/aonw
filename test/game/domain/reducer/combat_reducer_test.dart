import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CombatReducer via GameStateReducer', () {
    test('AttackHexCommand resolves combat, persists HP, and emits events', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      ).copyWithInteraction(selection: GameSelection.unit(attacker));

      final result = _reducer(
        mapData,
      ).reduce(state, const AttackHexCommand('a', 1, 0));

      final updatedAttacker = result.state.units.singleWhere(
        (u) => u.id == 'a',
      );
      final updatedDefender = result.state.units.singleWhere(
        (u) => u.id == 'd',
      );
      expect(updatedAttacker.movementPoints, 0);
      expect(updatedAttacker.hitPoints, 9);
      expect(updatedAttacker.experiencePoints, 1);
      expect(updatedDefender.hitPoints, 9);
      expect(updatedDefender.experiencePoints, 1);
      expect(result.state.selectedUnit?.hitPoints, 9);
      expect(result.events[0], isA<UnitAttackedEvent>());
      expect(result.events[1], isA<CombatResolvedEvent>());
      expect(
        result.state.diplomacy.statusBetween('p1', 'p2'),
        DiplomaticRelationStatus.hostile,
      );
      expect(
        result.events.whereType<UnitGainedExperienceEvent>(),
        hasLength(2),
      );

      final resolved = result.events[1] as CombatResolvedEvent;
      expect(resolved.outcome.attackerHpAfter, 9);
      expect(resolved.outcome.defenderHpAfter, 9);
      final effect = result.uiEffects
          .whereType<PlayCombatAnimationEffect>()
          .single;
      expect(effect.attackerUnitId, 'a');
      expect(effect.defenderUnitId, 'd');
      expect(effect.attackerKilled, isFalse);
      expect(effect.defenderKilled, isFalse);
    });

    test('friendly units cannot be attacked', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        diplomacy: DiplomacyState.empty.setStatus(
          'p1',
          'p2',
          DiplomaticRelationStatus.friendly,
        ),
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const AttackHexCommand('a', 1, 0));

      expect(result.state.units, state.units);
      expect(
        result.state.diplomacy.statusBetween('p1', 'p2'),
        DiplomaticRelationStatus.friendly,
      );
      expect(result.events, isEmpty);
      final feedback = result.uiEffects.whereType<ShowHudFeedbackEffect>();
      expect(feedback.single.reason, HudFeedbackReason.attackProtectedByTreaty);
    });

    test('friendly cities cannot be attacked', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      const city = GameCity(
        id: 'city-p2',
        ownerPlayerId: 'p2',
        name: 'city',
        center: CityHex(col: 1, row: 0),
      );
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker],
        cities: const [city],
        diplomacy: DiplomacyState.empty.setStatus(
          'p1',
          'p2',
          DiplomaticRelationStatus.friendly,
        ),
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const AttackHexCommand('a', 1, 0));

      expect(result.state.cities, state.cities);
      expect(
        result.state.diplomacy.statusBetween('p1', 'p2'),
        DiplomaticRelationStatus.friendly,
      );
      expect(result.events, isEmpty);
      final feedback = result.uiEffects.whereType<ShowHudFeedbackEffect>();
      expect(feedback.single.reason, HudFeedbackReason.attackProtectedByTreaty);
    });

    test('pending attack targeting turns a tile tap into target preview', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
        interaction: const GameInteractionState(
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: 'p1',
            attackerUnitId: 'a',
          ),
        ),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const TileTappedCommand(1, 0));

      final pending = result.state.pendingAction;
      expect(pending, isA<PendingAttackTargeting>());
      expect((pending as PendingAttackTargeting).defenderCol, 1);
      expect(pending.defenderRow, 0);
      expect(result.events, isEmpty);
    });

    test(
      'pending attack targeting turns enemy city tap into target preview',
      () {
        final mapData = _map(3, 3);
        final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
        const city = GameCity(
          id: 'city-p2',
          ownerPlayerId: 'p2',
          name: 'city',
          center: CityHex(col: 1, row: 0),
        );
        final state = GameState(
          activePlayerId: 'p1',
          units: [attacker],
          cities: const [city],
          fogOfWar: _visible('p1', const [
            HexCoordinate(col: 0, row: 0),
            HexCoordinate(col: 1, row: 0),
          ]),
          interaction: GameInteractionState(
            selection: GameSelection.unit(attacker),
            pendingAction: const PendingAttackTargeting(
              ownerPlayerId: 'p1',
              attackerUnitId: 'a',
            ),
          ),
        );

        final result = _reducer(
          mapData,
        ).reduce(state, const CityTappedCommand('city-p2'));

        expect(result.state.selection?.unit?.id, 'a');
        final pending = result.state.pendingAction;
        expect(pending, isA<PendingAttackTargeting>());
        expect((pending as PendingAttackTargeting).defenderCol, 1);
        expect(pending.defenderRow, 0);
        expect(result.events, isEmpty);
      },
    );

    test(
      'pending attack targeting turns enemy unit selection into target preview',
      () {
        final mapData = _map(3, 3);
        final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
        final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
        final state = GameState(
          activePlayerId: 'p1',
          units: [attacker, defender],
          fogOfWar: _visible('p1', const [
            HexCoordinate(col: 0, row: 0),
            HexCoordinate(col: 1, row: 0),
          ]),
          interaction: GameInteractionState(
            selection: GameSelection.unit(attacker),
            pendingAction: const PendingAttackTargeting(
              ownerPlayerId: 'p1',
              attackerUnitId: 'a',
            ),
          ),
        );

        final result = _reducer(
          mapData,
        ).reduce(state, const SelectUnitCommand('d'));

        expect(result.state.selection?.unit?.id, 'a');
        final pending = result.state.pendingAction;
        expect(pending, isA<PendingAttackTargeting>());
        expect((pending as PendingAttackTargeting).defenderCol, 1);
        expect(pending.defenderRow, 0);
        expect(result.events, isEmpty);
      },
    );

    test('pending attack targeting shows feedback for protected unit', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        diplomacy: DiplomacyState.empty.setStatus(
          'p1',
          'p2',
          DiplomaticRelationStatus.friendly,
        ),
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
        interaction: GameInteractionState(
          selection: GameSelection.unit(attacker),
          pendingAction: const PendingAttackTargeting(
            ownerPlayerId: 'p1',
            attackerUnitId: 'a',
          ),
        ),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const SelectUnitCommand('d'));

      expect(result.state, state);
      expect(result.events, isEmpty);
      final feedback = result.uiEffects.whereType<ShowHudFeedbackEffect>();
      expect(feedback.single.reason, HudFeedbackReason.attackProtectedByTreaty);
    });

    test(
      'pending attack targeting confirms selected target with AttackHex',
      () {
        final mapData = _map(3, 3);
        final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
        final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
        final state = GameState(
          activePlayerId: 'p1',
          units: [attacker, defender],
          fogOfWar: _visible('p1', const [
            HexCoordinate(col: 0, row: 0),
            HexCoordinate(col: 1, row: 0),
          ]),
          interaction: GameInteractionState(
            selection: GameSelection.unit(attacker),
            pendingAction: const PendingAttackTargeting(
              ownerPlayerId: 'p1',
              attackerUnitId: 'a',
              defenderCol: 1,
              defenderRow: 0,
            ),
          ),
        );

        final result = _reducer(
          mapData,
        ).reduce(state, const AttackHexCommand('a', 1, 0));

        expect(result.state.pendingAction, isNull);
        expect(result.events.whereType<UnitAttackedEvent>(), hasLength(1));
        expect(result.events.whereType<CombatResolvedEvent>(), hasLength(1));
      },
    );

    test('pending attack targeting does not select enemy outside range', () {
      final mapData = _map(4, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 2, row: 0);
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 2, row: 0),
        ]),
        interaction: GameInteractionState(
          selection: GameSelection.unit(attacker),
          pendingAction: const PendingAttackTargeting(
            ownerPlayerId: 'p1',
            attackerUnitId: 'a',
          ),
        ),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const SelectUnitCommand('d'));

      expect(result.state, state);
      expect(result.events, isEmpty);
    });

    test('ranged attacker does not receive melee retaliation', () {
      final mapData = _map(4, 3);
      final attacker = _unit(
        id: 'a',
        ownerPlayerId: 'p1',
        type: GameUnitType.archer,
        col: 0,
        row: 0,
      );
      final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 2, row: 0);
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 2, row: 0),
        ]),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const AttackHexCommand('a', 2, 0));

      final updatedAttacker = result.state.units.singleWhere(
        (u) => u.id == 'a',
      );
      final resolved = result.events.whereType<CombatResolvedEvent>().single;
      expect(updatedAttacker.hitPoints, 7);
      expect(resolved.outcome.steps.whereType<RetaliationStep>(), isEmpty);
    });

    test('kill on defended city center clears defender before city HP', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      final defender = _unit(
        id: 'd',
        ownerPlayerId: 'p2',
        type: GameUnitType.settler,
        col: 1,
        row: 0,
      );
      const city = GameCity(
        id: 'city-p2',
        ownerPlayerId: 'p2',
        name: 'city',
        center: CityHex(col: 1, row: 0),
      );
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        cities: [city],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const AttackHexCommand('a', 1, 0));

      expect(result.state.units.where((u) => u.id == 'd'), isEmpty);
      expect(
        result.state.units.singleWhere((u) => u.id == 'a').experiencePoints,
        3,
      );
      expect(result.state.cities.single.ownerPlayerId, 'p2');
      expect(result.state.cities.single.hitPoints, isNull);
      expect(result.events.whereType<UnitKilledEvent>(), hasLength(1));
      expect(result.events.whereType<CityCapturedEvent>(), isEmpty);
      expect(
        result.events.whereType<UnitGainedExperienceEvent>().single,
        isA<UnitGainedExperienceEvent>()
            .having((event) => event.unitId, 'unitId', 'a')
            .having((event) => event.amount, 'amount', 3)
            .having((event) => event.promoted, 'promoted', true),
      );
    });

    test('attack on unguarded city damages city HP', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      const city = GameCity(
        id: 'city-p2',
        ownerPlayerId: 'p2',
        name: 'city',
        center: CityHex(col: 1, row: 0),
      );
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker],
        cities: const [city],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const AttackHexCommand('a', 1, 0));

      final updatedAttacker = result.state.units.singleWhere(
        (u) => u.id == 'a',
      );
      expect(updatedAttacker.movementPoints, 0);
      expect(updatedAttacker.experiencePoints, 1);
      expect(result.state.cities.single.ownerPlayerId, 'p2');
      expect(result.state.cities.single.hitPoints, 14);
      expect(
        result.state.diplomacy.statusBetween('p1', 'p2'),
        DiplomaticRelationStatus.war,
      );
      expect(result.events.map((event) => event.runtimeType), [
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
      ]);
      final resolved = result.events.first as CombatResolvedEvent;
      expect(resolved.defenderUnitId, 'city-p2');
      expect(resolved.outcome.defenderKilled, isFalse);
    });

    test('city attack breaks trade and applies warmonger reputation', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      const city = GameCity(
        id: 'city-p2',
        ownerPlayerId: 'p2',
        name: 'city',
        center: CityHex(col: 1, row: 0),
      );
      final state = GameState(
        activePlayerId: 'p1',
        playerColors: const {'p1': 1, 'p2': 2, 'p3': 3},
        units: [attacker],
        cities: const [city],
        diplomacy: DiplomacyState.empty
            .addContact('p1', 'p2')
            .addContact('p1', 'p3')
            .addContact('p2', 'p3'),
        resourceTradeAgreements: const [
          ResourceTradeAgreement(
            id: 'war_trade',
            exporterPlayerId: 'p2',
            importerPlayerId: 'p1',
            resource: ResourceType.horses,
            goldPerTurn: 3,
            remainingTurns: 5,
          ),
          ResourceTradeAgreement(
            id: 'observer_trade',
            exporterPlayerId: 'p3',
            importerPlayerId: 'p1',
            resource: ResourceType.iron,
            goldPerTurn: 1,
            remainingTurns: 5,
          ),
        ],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const AttackHexCommand('a', 1, 0));

      expect(result.state.resourceTradeAgreements.map((trade) => trade.id), [
        'observer_trade',
      ]);
      expect(
        result.state.diplomacy.relationScoreBetween('p1', 'p3'),
        DiplomaticWarmongerReputation.cityAttackPenalty,
      );
    });

    test('lethal attack on unguarded city captures it by default', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      const city = GameCity(
        id: 'city-p2',
        ownerPlayerId: 'p2',
        name: 'city',
        center: CityHex(col: 1, row: 0),
        hitPoints: 1,
      );
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker],
        cities: const [city],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const AttackHexCommand('a', 1, 0));

      expect(result.state.cities.single.ownerPlayerId, 'p1');
      expect(result.state.cities.single.hitPoints, 8);
      expect(result.events.map((event) => event.runtimeType), [
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
        CityCapturedEvent,
      ]);
    });

    test('unit already on enemy city center can attack the city', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 1, row: 0);
      const city = GameCity(
        id: 'city-p2',
        ownerPlayerId: 'p2',
        name: 'city',
        center: CityHex(col: 1, row: 0),
        hitPoints: 1,
      );
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker],
        cities: const [city],
        fogOfWar: _visible('p1', const [HexCoordinate(col: 1, row: 0)]),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const AttackHexCommand('a', 1, 0));

      expect(result.state.cities.single.ownerPlayerId, 'p1');
      expect(
        result.events.map((event) => event.runtimeType),
        contains(CityCapturedEvent),
      );
    });

    test('lethal attack on unguarded city can destroy it', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      const city = GameCity(
        id: 'city-p2',
        ownerPlayerId: 'p2',
        name: 'city',
        center: CityHex(col: 1, row: 0),
        hitPoints: 1,
      );
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker],
        cities: const [city],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      );

      final result = _reducer(mapData).reduce(
        state,
        const AttackHexCommand(
          'a',
          1,
          0,
          cityConquestAction: CityConquestAction.destroy,
        ),
      );

      expect(result.state.cities, isEmpty);
      expect(result.events.map((event) => event.runtimeType), [
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
        CityDestroyedEvent,
      ]);
    });

    test('low-health defender retreats to an adjacent free tile', () {
      final mapData = _map(3, 3);
      final attacker = _unit(
        id: 'a',
        ownerPlayerId: 'p1',
        type: GameUnitType.archer,
        col: 0,
        row: 0,
      );
      final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      );

      final result = _reducer(
        mapData,
        combatRuleset: _retreatCombatRuleset,
      ).reduce(state, const AttackHexCommand('a', 1, 0));

      final updatedDefender = result.state.units.singleWhere(
        (u) => u.id == 'd',
      );
      expect(updatedDefender.hitPoints, 1);
      expect(updatedDefender.movementPoints, 0);
      expect(updatedDefender.occupies(1, 0), isFalse);
      expect(
        HexDistance.between(
          const HexCoordinate(col: 1, row: 0),
          HexCoordinate(col: updatedDefender.col, row: updatedDefender.row),
        ),
        1,
      );
      expect(result.events.whereType<UnitKilledEvent>(), isEmpty);

      final resolved = result.events.whereType<CombatResolvedEvent>().single;
      expect(resolved.outcome.defenderRetreated, isTrue);
      expect(
        result.events.whereType<UnitRetreatedEvent>().single,
        isA<UnitRetreatedEvent>()
            .having((event) => event.fromCol, 'fromCol', 1)
            .having((event) => event.fromRow, 'fromRow', 0)
            .having((event) => event.toCol, 'toCol', updatedDefender.col)
            .having((event) => event.toRow, 'toRow', updatedDefender.row),
      );
    });

    test('lethal hit kills defender even when retreat tile is available', () {
      final mapData = _map(3, 3);
      final attacker = _unit(
        id: 'a',
        ownerPlayerId: 'p1',
        type: GameUnitType.archer,
        col: 0,
        row: 0,
      );
      final defender = _unit(
        id: 'd',
        ownerPlayerId: 'p2',
        col: 1,
        row: 0,
        hitPoints: 1,
      );
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
      );

      final result = _reducer(
        mapData,
        combatRuleset: _retreatCombatRuleset,
      ).reduce(state, const AttackHexCommand('a', 1, 0));

      expect(result.state.units.where((u) => u.id == 'd'), isEmpty);
      expect(result.events.whereType<UnitRetreatedEvent>(), isEmpty);
      expect(result.events.whereType<UnitKilledEvent>(), hasLength(1));

      final resolved = result.events.whereType<CombatResolvedEvent>().single;
      expect(resolved.outcome.defenderKilled, isTrue);
      expect(resolved.outcome.defenderRetreated, isFalse);
    });

    test('does not attack hidden dynamic targets', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        fogOfWar: _visible('p1', const [HexCoordinate(col: 0, row: 0)]),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const AttackHexCommand('a', 1, 0));

      expect(result.state, state);
      expect(result.events, isEmpty);
    });

    test('does not attack outside effective range', () {
      final mapData = _map(4, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 2, row: 0);
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 2, row: 0),
        ]),
      );

      final result = _reducer(
        mapData,
      ).reduce(state, const AttackHexCommand('a', 2, 0));

      expect(result.state, state);
      expect(result.events, isEmpty);
    });

    test('simultaneous combat records attack intent without resolving HP', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker, defender],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
        interaction: const GameInteractionState(
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: 'p1',
            attackerUnitId: 'a',
          ),
        ),
      );

      final result = _simultaneousReducer(mapData).reduce(
        state,
        const AttackHexCommand('a', 1, 0),
        context: const GameCommandContext(actorPlayerId: 'p1', commandTick: 12),
      );

      expect(result.events, isEmpty);
      expect(result.uiEffects, isEmpty);
      expect(result.state.units, state.units);
      expect(result.state.diplomacy, DiplomacyState.empty);
      expect(result.state.pendingAction, isNull);
      expect(result.state.intendedAttacks, [
        const IntendedAttack(
          attackerUnitId: 'a',
          defenderCol: 1,
          defenderRow: 0,
          declaredAtTick: 12,
          declaringPlayerId: 'p1',
        ),
      ]);
    });

    test('simultaneous city attack records conquest action in intent', () {
      final mapData = _map(3, 3);
      final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
      const city = GameCity(
        id: 'city-p2',
        ownerPlayerId: 'p2',
        name: 'city',
        center: CityHex(col: 1, row: 0),
      );
      final state = GameState(
        activePlayerId: 'p1',
        units: [attacker],
        cities: const [city],
        fogOfWar: _visible('p1', const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 1, row: 0),
        ]),
        interaction: const GameInteractionState(
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: 'p1',
            attackerUnitId: 'a',
          ),
        ),
      );

      final result = _simultaneousReducer(mapData).reduce(
        state,
        const AttackHexCommand(
          'a',
          1,
          0,
          cityConquestAction: CityConquestAction.destroy,
        ),
        context: const GameCommandContext(actorPlayerId: 'p1', commandTick: 12),
      );

      expect(result.events, isEmpty);
      expect(result.state.cities, state.cities);
      expect(result.state.pendingAction, isNull);
      expect(result.state.intendedAttacks, [
        const IntendedAttack(
          attackerUnitId: 'a',
          defenderCol: 1,
          defenderRow: 0,
          declaredAtTick: 12,
          declaringPlayerId: 'p1',
          cityConquestAction: CityConquestAction.destroy,
        ),
      ]);
    });
  });
}

GameStateReducer _reducer(
  MapData mapData, {
  CombatRuleset combatRuleset = const CombatRuleset(varianceRange: 0),
}) => GameStateReducer(
  mapData: mapData,
  ruleset: GameRuleset(
    city: CityRulesets.standard,
    combat: combatRuleset,
    technology: TechnologyRulesets.standard,
  ),
);

const _retreatCombatRuleset = CombatRuleset(
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
);

GameStateReducer _simultaneousReducer(MapData mapData) => GameStateReducer(
  mapData: mapData,
  ruleset: const GameRuleset(
    city: CityRulesets.standard,
    combat: CombatRuleset(
      varianceRange: 0,
      resolutionMode: CombatResolutionMode.simultaneous,
    ),
    technology: TechnologyRulesets.standard,
  ),
);

GameUnit _unit({
  required String id,
  required String ownerPlayerId,
  GameUnitType type = GameUnitType.warrior,
  required int col,
  required int row,
  int? movementPoints,
  int? hitPoints,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: row,
    movementPoints: movementPoints,
    hitPoints: hitPoints,
  );
}

FogOfWarState _visible(String playerId, Iterable<HexCoordinate> hexes) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(
        playerId: playerId,
        visibleHexes: Set<HexCoordinate>.of(hexes),
      ),
    },
  );
}

MapData _map(int cols, int rows) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (var col = 0; col < cols; col++)
      for (var row = 0; row < rows; row++)
        TileData(
          col: col,
          row: row,
          height: 0,
          terrains: const [TerrainType.grassland],
          resources: const [],
        ),
  ],
);
