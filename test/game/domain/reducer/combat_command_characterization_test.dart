import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('combat command characterization', () {
    test(
      'documents counter-modifier drift between local instant and turn combat',
      () {
        final map = _combatMap(
          targetTerrains: const [TerrainType.forest, TerrainType.hills],
        );
        final attacker = _unit(
          id: 'attacker',
          ownerPlayerId: 'player_1',
          type: GameUnitType.cavalry,
          col: 0,
        );
        final defender = _unit(
          id: 'defender',
          ownerPlayerId: 'player_2',
          type: GameUnitType.archer,
          col: 1,
        );
        final result = _resolveBoth(
          map: map,
          ruleset: _ruleset(),
          units: [attacker, defender],
        );

        final localOutcome = result.local.events
            .whereType<CombatResolvedEvent>()
            .single
            .outcome;
        final authoritativeOutcome = result.authoritative.events
            .whereType<CombatResolvedEvent>()
            .single
            .outcome;
        final localCounterLabels = _counterLabels(localOutcome);
        final authoritativeCounterLabels = _counterLabels(authoritativeOutcome);

        expect(localCounterLabels, isEmpty);
        expect(authoritativeCounterLabels, {
          'counter.archerDefensiveTerrain.defense',
          'counter.cavalryRoughAttack.attack',
        });
        expect(localOutcome, isNot(authoritativeOutcome));
      },
    );

    test('documents attacker-death event-order drift', () {
      final combat = CombatRuleset.standard.copyWith(
        varianceRange: 0,
        unitBaseStats: const {
          GameUnitType.warrior: CombatStats(
            attack: 1,
            defense: 1,
            hp: 1,
            range: 1,
            mobility: 1,
          ),
          GameUnitType.heavyInfantry: CombatStats(
            attack: 20,
            defense: 20,
            hp: 20,
            range: 1,
            mobility: 1,
          ),
        },
      );
      final result = _resolveBoth(
        map: _combatMap(),
        ruleset: _ruleset(combat: combat),
        units: [
          _unit(
            id: 'attacker',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
          ),
          _unit(
            id: 'defender',
            ownerPlayerId: 'player_2',
            type: GameUnitType.heavyInfantry,
            col: 1,
          ),
        ],
      );

      expect(result.local.events.map((event) => event.runtimeType), [
        UnitAttackedEvent,
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
        UnitKilledEvent,
      ]);
      expect(result.authoritative.events.map((event) => event.runtimeType), [
        UnitAttackedEvent,
        CombatResolvedEvent,
        UnitKilledEvent,
        UnitGainedExperienceEvent,
      ]);
      expect(
        result.local.events.whereType<UnitKilledEvent>().single.unitId,
        'attacker',
      );
      expect(
        result.authoritative.events.whereType<UnitKilledEvent>().single.unitId,
        'attacker',
      );
    });

    test('documents lethal-city warmonger event-order drift', () {
      final combat = CombatRuleset.standard.copyWith(
        varianceRange: 0,
        cityBaseStats: const CombatStats(
          attack: 0,
          defense: 0,
          hp: 1,
          range: 1,
          mobility: 0,
        ),
        unitBaseStats: const {
          GameUnitType.warrior: CombatStats(
            attack: 20,
            defense: 10,
            hp: 10,
            range: 1,
            mobility: 1,
          ),
        },
      );
      final result = _resolveBoth(
        map: _combatMap(),
        ruleset: _ruleset(combat: combat),
        units: [
          _unit(
            id: 'attacker',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city',
            ownerPlayerId: 'player_2',
            name: 'City',
            center: CityHex(col: 1, row: 0),
            hitPoints: 1,
          ),
        ],
        diplomacy: DiplomacyState(
          contactKeys: const {'player_1|player_3', 'player_2|player_3'},
        ),
      );

      expect(result.local.events.map((event) => event.runtimeType), [
        CityAttackedEvent,
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
        CityCapturedEvent,
        DiplomaticScoreChangedEvent,
      ]);
      expect(result.authoritative.events.map((event) => event.runtimeType), [
        CityAttackedEvent,
        CombatResolvedEvent,
        DiplomaticScoreChangedEvent,
        UnitGainedExperienceEvent,
        CityCapturedEvent,
      ]);
      expect(result.local.state.cities.single.ownerPlayerId, 'player_1');
      expect(
        result.authoritative.state.cities.single.ownerPlayerId,
        'player_1',
      );
    });

    test(
      'simultaneous mode replaces only the same attacker intent and stays UI-only',
      () {
        final map = _combatMap();
        final attacker = _unit(
          id: 'attacker',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
        );
        final defender = _unit(
          id: 'defender',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 1,
        );
        const unrelated = IntendedAttack(
          attackerUnitId: 'other_attacker',
          defenderCol: 7,
          defenderRow: 7,
          declaredAtTick: 3,
          declaringPlayerId: 'player_2',
        );
        const superseded = IntendedAttack(
          attackerUnitId: 'attacker',
          defenderCol: 2,
          defenderRow: 0,
          declaredAtTick: 4,
          declaringPlayerId: 'player_1',
        );
        final state = GameState(
          activePlayerId: 'player_1',
          units: [attacker, defender],
          fogOfWar: _visibleFog(),
          intendedAttacks: const [superseded, unrelated],
          interaction: const GameInteractionState(
            pendingAction: PendingAttackTargeting(
              ownerPlayerId: 'player_1',
              attackerUnitId: 'attacker',
            ),
          ),
        );
        final ruleset = _ruleset(
          combat: CombatRuleset.standard.copyWith(
            varianceRange: 0,
            resolutionMode: CombatResolutionMode.simultaneous,
          ),
        );

        final result = GameStateReducer(mapData: map, ruleset: ruleset).reduce(
          state,
          const AttackHexCommand('attacker', 1, 0),
          context: const GameCommandContext(
            actorPlayerId: 'player_1',
            combatSeedTurn: 7,
            commandTick: 13,
          ),
        );

        expect(result.events, isEmpty);
        expect(result.uiEffects, isEmpty);
        expect(result.state.units, state.units);
        expect(result.state.pendingAction, isNull);
        expect(result.state.intendedAttacks, const [
          unrelated,
          IntendedAttack(
            attackerUnitId: 'attacker',
            defenderCol: 1,
            defenderRow: 0,
            declaredAtTick: 13,
            declaringPlayerId: 'player_1',
          ),
        ]);
      },
    );

    test('instant mode owns one command animation outside domain events', () {
      final attacker = _unit(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
      );
      final defender = _unit(
        id: 'defender',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 1,
      );
      final state = GameState(
        activePlayerId: 'player_1',
        units: [attacker, defender],
        fogOfWar: _visibleFog(),
        interaction: const GameInteractionState(
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'attacker',
          ),
        ),
      );

      final result =
          GameStateReducer(mapData: _combatMap(), ruleset: _ruleset()).reduce(
            state,
            const AttackHexCommand('attacker', 1, 0),
            context: const GameCommandContext(
              actorPlayerId: 'player_1',
              combatSeedTurn: 7,
              commandTick: 13,
            ),
          );

      expect(result.state.pendingAction, isNull);
      expect(result.events.whereType<CombatResolvedEvent>(), hasLength(1));
      final effect = result.uiEffects
          .whereType<PlayCombatAnimationEffect>()
          .single;
      final outcome = result.events
          .whereType<CombatResolvedEvent>()
          .single
          .outcome;
      expect(
        (
          effect.attackerUnitId,
          effect.defenderUnitId,
          effect.attackerKilled,
          effect.defenderKilled,
        ),
        (
          'attacker',
          'defender',
          outcome.attackerKilled,
          outcome.defenderKilled,
        ),
      );
    });
  });
}

({GameStateTransition local, PersistentCombatCommandResult authoritative})
_resolveBoth({
  required MapData map,
  required GameRuleset ruleset,
  required List<GameUnit> units,
  List<GameCity> cities = const [],
  DiplomacyState diplomacy = DiplomacyState.empty,
}) {
  const command = AttackHexCommand('attacker', 1, 0);
  final fog = _visibleFog();
  final localState = GameState(
    playerColors: const {'player_1': 1, 'player_2': 2},
    activePlayerId: 'player_1',
    units: units,
    cities: cities,
    fogOfWar: fog,
    diplomacy: diplomacy,
  );
  final persistentState = PersistentGameState(
    playerColors: const {'player_1': 1, 'player_2': 2},
    units: units,
    cities: cities,
    fogOfWar: fog,
    runtimeState: GameRuntimeState(diplomacy: diplomacy),
  );
  return (
    local: GameStateReducer(mapData: map, ruleset: ruleset).reduce(
      localState,
      command,
      context: const GameCommandContext(
        actorPlayerId: 'player_1',
        combatSeedTurn: 7,
        commandTick: 13,
      ),
    ),
    authoritative: const PersistentCombatCommandResolver().resolve(
      state: persistentState,
      command: command,
      actorPlayerId: 'player_1',
      turn: 7,
      commandTick: 13,
      mapTiles: map,
      ruleset: ruleset,
    ),
  );
}

Set<String> _counterLabels(CombatOutcome outcome) {
  return {
    for (final step in outcome.steps.whereType<ModifierAppliedStep>())
      if (step.modifier.label.startsWith('counter.')) step.modifier.label,
  };
}

GameRuleset _ruleset({CombatRuleset? combat}) {
  return GameRuleset(
    city: CityRulesets.standard,
    combat: combat ?? CombatRuleset.standard.copyWith(varianceRange: 0),
    technology: TechnologyRulesets.standard,
  );
}

GameUnit _unit({
  required String id,
  required String ownerPlayerId,
  required GameUnitType type,
  required int col,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: 0,
  );
}

FogOfWarState _visibleFog() {
  final visible = {
    const HexCoordinate(col: 0, row: 0),
    const HexCoordinate(col: 1, row: 0),
    const HexCoordinate(col: 2, row: 0),
  };
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(playerId: 'player_1', visibleHexes: visible),
      'player_2': PlayerFogOfWar(playerId: 'player_2', visibleHexes: visible),
    },
  );
}

MapData _combatMap({
  List<TerrainType> targetTerrains = const [TerrainType.grassland],
}) {
  return MapData(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        TileData(
          col: col,
          row: 0,
          height: 0,
          terrains: col == 1 ? targetTerrains : const [TerrainType.grassland],
          resources: const [],
        ),
    ],
  );
}
