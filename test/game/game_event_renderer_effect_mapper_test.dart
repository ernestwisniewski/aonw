import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_event_renderer_effect_mapper.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/combat_animation_fixtures.dart';

part 'game_event_renderer_combat_camera_tests.dart';

void main() {
  group('GameEventRendererEffectMapper', () {
    final l10n = AppLocalizationsEn();

    test('maps city founded event to a city-centered particle burst', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 2, row: 3),
      );
      final state = GameClientState(
        playerColors: {'player_1': 0xFF123456},
        cities: [city],
      );

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [
          CityFoundedEvent(cityId: 'city_1', ownerPlayerId: 'player_1'),
        ],
        state: state,
        l10n: l10n,
      );

      final effect = effects.single as SpawnParticleBurstEffect;
      expect(effect.kind, ParticleBurstKind.cityFounded);
      expect(effect.col, 2);
      expect(effect.row, 3);
      expect(effect.colorValue, 0xFF123456);
    });

    test('does not map hidden city founded events to particle bursts', () {
      const hiddenCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Hidden',
        center: CityHex(col: 4, row: 4),
      );
      final state = GameClientState(
        activePlayerId: 'player_1',
        playerColors: const {'player_2': 0xFF654321},
        cities: const [hiddenCity],
        fogOfWar: _fog(visible: {const HexCoordinate(col: 0, row: 0)}),
      );

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [
          CityFoundedEvent(cityId: 'city_2', ownerPlayerId: 'player_2'),
        ],
        state: state,
        l10n: l10n,
      );

      expect(effects, isEmpty);
    });

    test('maps claimed hex event to the claimed tile', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 2, row: 3),
      );
      final state = GameClientState(
        playerColors: {'player_1': 0xFF123456},
        cities: [city],
      );

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [CityClaimedHexEvent(cityId: 'city_1', col: 4, row: 5)],
        state: state,
      );

      final effect = effects.single as SpawnParticleBurstEffect;
      expect(effect.kind, ParticleBurstKind.hexClaimed);
      expect(effect.col, 4);
      expect(effect.row, 5);
      expect(effect.colorValue, 0xFF123456);
    });

    test('maps produced unit event to a city spark burst', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 2, row: 3),
      );
      final state = GameClientState(
        playerColors: {'player_1': 0xFF123456},
        cities: [city],
      );

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [
          CityProducedUnitEvent(
            cityId: 'city_1',
            unitType: GameUnitType.warrior,
            producedUnitId: 'warrior_1',
          ),
        ],
        state: state,
        l10n: l10n,
      );

      final effect = effects.single as SpawnParticleBurstEffect;
      expect(effect.kind, ParticleBurstKind.unitProduced);
      expect(effect.col, 2);
      expect(effect.row, 3);
      expect(effect.colorValue, 0xFF123456);
    });

    test('does not map hidden foreign city production for viewer', () {
      const hiddenCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Hidden',
        center: CityHex(col: 8, row: 9),
      );
      final state = GameClientState(
        activePlayerId: 'player_2',
        cities: const [hiddenCity],
        fogOfWar: _fog(visible: {const HexCoordinate(col: 0, row: 0)}),
      );

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [
          CityProducedUnitEvent(
            cityId: 'city_2',
            unitType: GameUnitType.warrior,
            producedUnitId: 'warrior_2',
          ),
        ],
        state: state,
        viewerPlayerId: 'player_1',
      );

      expect(effects, isEmpty);
    });

    test('does not focus a hidden foreign city during combat', () {
      final attacker = GameUnit(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 2,
        row: 3,
      );
      const hiddenCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Hidden',
        center: CityHex(col: 8, row: 9),
      );
      final previousState = GameClientState(
        activePlayerId: 'player_2',
        units: [attacker],
        cities: const [hiddenCity],
        fogOfWar: _fog(visible: {const HexCoordinate(col: 0, row: 0)}),
      );
      final state = previousState.copyWith(units: const []);

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: [
          CombatResolvedEvent(
            attackerUnitId: 'attacker',
            defenderUnitId: 'city_2',
            outcome: CombatOutcome(
              attackerUnitId: 'attacker',
              defenderUnitId: 'city_2',
              attackerHpAfter: 10,
              defenderHpAfter: 7,
              attackerKilled: false,
              defenderKilled: false,
              steps: [AttackStep(damage: 3)],
            ),
          ),
        ],
        state: state,
        previousState: previousState,
        viewerPlayerId: 'player_1',
      );

      expect(effects.whereType<SmoothCameraEffect>(), isEmpty);
      expect(effects.whereType<ShakeCameraEffect>(), isEmpty);
      expect(effects.whereType<ShowCombatHexAlertEffect>(), isEmpty);
      expect(effects.whereType<SpawnParticleBurstEffect>(), isEmpty);
      expect(effects.whereType<ShowFloatingTextEffect>(), isEmpty);
    });

    test('maps unit moved event to a unit movement animation', () {
      final state = GameClientState();

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [
          UnitMovedEvent(
            unitId: 'warrior_1',
            fromCol: 2,
            fromRow: 3,
            toCol: 3,
            toRow: 3,
          ),
        ],
        state: state,
      );

      final effect = effects.single as AnimateUnitMoveEffect;
      expect(effect.unitId, 'warrior_1');
      expect(effect.fromCol, 2);
      expect(effect.fromRow, 3);
      expect(effect.steps.single.col, 3);
      expect(effect.steps.single.row, 3);
    });

    test('skips unit moved event when command effects already animate it', () {
      final state = GameClientState();

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [
          UnitMovedEvent(
            unitId: 'warrior_1',
            fromCol: 2,
            fromRow: 3,
            toCol: 3,
            toRow: 3,
          ),
        ],
        state: state,
        skipUnitMoveIds: const {'warrior_1'},
      );

      expect(effects, isEmpty);
    });

    test('maps killed unit event using previous state position', () {
      final killed = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 4,
        row: 5,
      );
      final previousState = GameClientState(
        playerColors: const {'player_1': 0xFF123456},
        units: [killed],
      );
      final state = GameClientState(playerColors: {'player_1': 0xFF123456});

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [
          UnitKilledEvent(unitId: 'worker_1', ownerPlayerId: 'player_1'),
        ],
        state: state,
        previousState: previousState,
      );

      expect(effects, hasLength(2));
      final burst = effects[0] as SpawnParticleBurstEffect;
      expect(burst.kind, ParticleBurstKind.unitKilled);
      expect(burst.col, 4);
      expect(burst.row, 5);
      expect(burst.colorValue, 0xFF123456);

      final cue = effects[1] as ShowFloatingTextEffect;
      expect(cue.text, 'KO');
      expect(cue.col, 4);
      expect(cue.row, 5);
      expect(cue.colorValue, 0xFFF87171);
      expect(cue.delay, const Duration(milliseconds: 180));
    });

    _registerCityCombatCameraEffectTests();

    test('maps retreat event to a delayed floating cue', () {
      final state = GameClientState();

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [
          UnitRetreatedEvent(
            unitId: 'defender',
            ownerPlayerId: 'player_2',
            fromCol: 4,
            fromRow: 5,
            toCol: 5,
            toRow: 5,
          ),
        ],
        state: state,
        l10n: l10n,
      );

      final cue = effects.single as ShowFloatingTextEffect;
      expect(cue.text, 'Retreat');
      expect(cue.col, 5);
      expect(cue.row, 5);
      expect(cue.colorValue, 0xFFFBBF24);
      expect(cue.delay, const Duration(milliseconds: 180));
    });

    test('keeps combat damage before delayed KO cue in event order', () {
      final attacker = GameUnit(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 2,
        row: 3,
      );
      final defender = GameUnit(
        id: 'defender',
        ownerPlayerId: 'player_2',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 4,
        row: 5,
      );
      final previousState = GameClientState(units: [attacker, defender]);
      final state = GameClientState(
        units: [attacker],
        playerColors: const {'player_2': 0xFF222222},
      );

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: [
          CombatResolvedEvent(
            attackerUnitId: 'attacker',
            defenderUnitId: 'defender',
            outcome: CombatOutcome(
              attackerUnitId: 'attacker',
              defenderUnitId: 'defender',
              attackerHpAfter: 10,
              defenderHpAfter: 0,
              attackerKilled: false,
              defenderKilled: true,
              steps: [AttackStep(damage: 7)],
            ),
          ),
          const UnitKilledEvent(
            unitId: 'defender',
            ownerPlayerId: 'player_2',
            attackerUnitId: 'attacker',
          ),
        ],
        state: state,
        previousState: previousState,
        combatAnimations: const [rendererCombatAnimationFact],
      );

      expect(effects, hasLength(6));
      expect(effects[0], isA<PlayCombatAnimationEffect>());
      expect(effects[1], isA<ShakeCameraEffect>());
      final alerts = effects.whereType<ShowCombatHexAlertEffect>().toList();
      expect(alerts, hasLength(1));
      expect(alerts.single.id, 'attacker:attacker');
      expect(alerts.single.kind, CombatHexAlertKind.attacker);
      final floatingTexts = effects
          .whereType<ShowFloatingTextEffect>()
          .toList();
      final damage = floatingTexts.first;
      final burst = effects.whereType<SpawnParticleBurstEffect>().single;
      final ko = floatingTexts.last;
      expect(damage.text, '-7 HP');
      expect(damage.delay, Duration.zero);
      expect(burst.kind, ParticleBurstKind.unitKilled);
      expect(ko.text, 'KO');
      expect(ko.delay, const Duration(milliseconds: 180));
      expect(effects.indexOf(damage), lessThan(effects.indexOf(ko)));
    });

    test('maps worker completed job event to floating yield text', () {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 1,
        row: 1,
        workerJob: const WorkerJob(
          targetHex: CityHex(col: 4, row: 5),
          improvementType: FieldImprovementType.farm,
          remainingTurns: 1,
          totalTurns: 2,
        ),
      );
      final previousState = GameClientState(units: [worker]);
      final state = GameClientState();

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [WorkerCompletedJobEvent(unitId: 'worker_1')],
        state: state,
        previousState: previousState,
        l10n: l10n,
      );

      final effect = effects.single as ShowFloatingTextEffect;
      expect(effect.text, '+1 FOOD');
      expect(effect.col, 4);
      expect(effect.row, 5);
      expect(effect.colorValue, 0xFF86EFAC);
    });

    test('anchors technology researched burst on player city', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 6, row: 7),
      );
      final state = GameClientState(cities: [city]);

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [
          TechnologyResearchedEvent(
            playerId: 'player_1',
            technologyId: TechnologyId.agriculture,
          ),
        ],
        state: state,
      );

      final effect = effects.single as SpawnParticleBurstEffect;
      expect(effect.kind, ParticleBurstKind.technologyResearched);
      expect(effect.col, 6);
      expect(effect.row, 7);
    });

    test('falls back to a player unit for technology researched burst', () {
      final unit = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 2,
      );
      final state = GameClientState(units: [unit]);

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [
          TechnologyResearchedEvent(
            playerId: 'player_1',
            technologyId: TechnologyId.agriculture,
          ),
        ],
        state: state,
      );

      final effect = effects.single as SpawnParticleBurstEffect;
      expect(effect.kind, ParticleBurstKind.technologyResearched);
      expect(effect.col, 1);
      expect(effect.row, 2);
    });

    test('ignores events without a renderable anchor', () {
      final state = GameClientState();

      final effects = GameEventRendererEffectMapper.effectsFor(
        events: const [
          TurnEndedEvent(playerId: 'player_1'),
          CityFoundedEvent(cityId: 'missing', ownerPlayerId: 'player_1'),
        ],
        state: state,
      );

      expect(effects, isEmpty);
    });
  });
}

FogOfWarState _fog({
  Set<HexCoordinate> discovered = const {},
  Set<HexCoordinate> visible = const {},
}) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}
