part of 'game_event_renderer_effect_mapper_test.dart';

void _registerCityCombatCameraEffectTests() {
  test('maps combat resolved event to camera shake and damage text', () {
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
    final retreatedDefender = defender.copyWith(col: 6, row: 7);
    final state = GameState(units: [attacker, retreatedDefender]);
    final previousState = GameState(units: [attacker, defender]);

    final effects = GameEventRendererEffectMapper.effectsFor(
      events: [
        CombatResolvedEvent(
          attackerUnitId: 'attacker',
          defenderUnitId: 'defender',
          outcome: CombatOutcome(
            attackerUnitId: 'attacker',
            defenderUnitId: 'defender',
            attackerHpAfter: 3,
            defenderHpAfter: 1,
            attackerKilled: false,
            defenderKilled: false,
            steps: [AttackStep(damage: 2), RetaliationStep(damage: 1)],
          ),
        ),
      ],
      state: state,
      previousState: previousState,
      turn: 31,
    );

    final combat = effects[0] as PlayCombatAnimationEffect;
    expect(combat.attackerUnitId, 'attacker');
    expect(combat.defenderUnitId, 'defender');
    expect(combat.defenderRetaliated, isTrue);

    final shake = effects[1] as ShakeCameraEffect;
    expect(shake.intensity, 8.0);
    expect(shake.duration, 0.28);

    final alerts = effects.whereType<ShowCombatHexAlertEffect>().toList();
    expect(alerts, hasLength(2));
    expect(alerts[0].id, 'attacker:attacker');
    expect(alerts[0].unitId, 'attacker');
    expect(alerts[0].kind, CombatHexAlertKind.attacker);
    expect(alerts[0].turn, 31);
    expect(alerts[0].col, 2);
    expect(alerts[0].row, 3);
    expect(alerts[1].id, 'defender:defender');
    expect(alerts[1].unitId, 'defender');
    expect(alerts[1].kind, CombatHexAlertKind.attacked);
    expect(alerts[1].turn, 31);
    expect(alerts[1].col, 6);
    expect(alerts[1].row, 7);

    final damageTexts = effects.whereType<ShowFloatingTextEffect>().toList();
    final defenderDamage = damageTexts[0];
    expect(defenderDamage.text, '-2 HP');
    expect(defenderDamage.col, 4);
    expect(defenderDamage.row, 5);
    expect(defenderDamage.colorValue, 0xFFF87171);

    final attackerDamage = damageTexts[1];
    expect(attackerDamage.text, '-1 HP');
    expect(attackerDamage.col, 2);
    expect(attackerDamage.row, 3);
    expect(attackerDamage.colorValue, 0xFFF87171);
    expect(attackerDamage.delay, Duration.zero);
  });

  test('keeps camera on a visible city attacker and spawns particles', () {
    final attacker = GameUnit(
      id: 'attacker',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 2,
      row: 3,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: CityHex(col: 4, row: 5),
    );
    final previousState = GameState(
      activePlayerId: 'player_1',
      units: [attacker],
      cities: const [city],
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [attacker],
      cities: const [city],
    );

    final effects = GameEventRendererEffectMapper.effectsFor(
      events: [
        CombatResolvedEvent(
          attackerUnitId: 'attacker',
          defenderUnitId: 'city_1',
          outcome: CombatOutcome(
            attackerUnitId: 'attacker',
            defenderUnitId: 'city_1',
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
    );

    expect(effects[0], isA<PlayCombatAnimationEffect>());
    expect(effects.whereType<SmoothCameraEffect>(), isEmpty);
    expect(effects[1], isA<ShakeCameraEffect>());

    final burst = effects.whereType<SpawnParticleBurstEffect>().single;
    expect(burst.kind, ParticleBurstKind.cityAttacked);
    expect(burst.col, 4);
    expect(burst.row, 5);
    expect(burst.colorValue, 0xFFF87171);

    final alerts = effects.whereType<ShowCombatHexAlertEffect>().toList();
    expect(alerts, hasLength(2));
    expect(alerts[0].id, 'attacker:attacker');
    expect(alerts[0].unitId, 'attacker');
    expect(alerts[0].kind, CombatHexAlertKind.attacker);
    final cityAlert = alerts[1];
    expect(cityAlert.id, 'city:city_1');
    expect(cityAlert.unitId, isNull);
    expect(cityAlert.cityId, 'city_1');
    expect(cityAlert.ownerPlayerId, 'player_1');
    expect(cityAlert.col, 4);
    expect(cityAlert.row, 5);
    expect(cityAlert.kind, CombatHexAlertKind.attacked);
    expect(cityAlert.ownerSubmittedAtAttack, isFalse);

    final damage = effects.whereType<ShowFloatingTextEffect>().single;
    expect(damage.text, '-3 HP');
    expect(damage.col, 4);
    expect(damage.row, 5);
  });

  test('focuses a visible city before combat with a hidden attacker', () {
    final attacker = GameUnit(
      id: 'attacker',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 2,
      row: 3,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      center: CityHex(col: 4, row: 5),
    );
    final fog = FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          visibleHexes: {const HexCoordinate(col: 4, row: 5)},
        ),
      },
    );
    final previousState = GameState(
      activePlayerId: 'player_1',
      units: [attacker],
      cities: const [city],
      fogOfWar: fog,
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [attacker],
      cities: const [city],
      fogOfWar: fog,
    );

    final effects = GameEventRendererEffectMapper.effectsFor(
      events: [
        CombatResolvedEvent(
          attackerUnitId: 'attacker',
          defenderUnitId: 'city_1',
          outcome: CombatOutcome(
            attackerUnitId: 'attacker',
            defenderUnitId: 'city_1',
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
    );

    final focus = effects[0] as SmoothCameraEffect;
    expect(focus.col, 4);
    expect(focus.row, 5);
    expect(focus.duration, 0.36);
    expect(effects[1], isA<PlayCombatAnimationEffect>());
    expect(effects[2], isA<ShakeCameraEffect>());
  });
}
