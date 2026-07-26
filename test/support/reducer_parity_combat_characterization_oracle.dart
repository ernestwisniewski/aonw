part of 'reducer_parity_combat_characterization.dart';

const _combatRejectedFixtureIds = <String>{
  'combat-characterization-attacker-missing-rejected',
  'combat-characterization-attacker-not-controlled-rejected',
  'combat-characterization-attacker-unavailable-rejected',
  'combat-characterization-attacker-exhausted-rejected',
  'combat-characterization-attacker-out-of-bounds-rejected',
  'combat-characterization-target-out-of-bounds-rejected',
  'combat-characterization-attacker-cannot-attack-rejected',
  'combat-characterization-target-missing-rejected',
  'combat-characterization-target-not-enemy-rejected',
  'combat-characterization-target-protected-by-treaty-rejected',
  'combat-characterization-target-not-visible-rejected',
  'combat-characterization-target-out-of-range-rejected',
};

PersistentGameState _combatExpectedState(
  String fixtureId,
  PersistentGameState input,
) {
  if (_combatRejectedFixtureIds.contains(fixtureId)) return input;
  return switch (fixtureId) {
    'combat-characterization-unit-accepted' => _combatUnitExpectedState(input),
    'combat-characterization-defended-city-unit-accepted' =>
      _combatDefendedCityUnitExpectedState(input),
    'combat-characterization-retreat-accepted' => _combatRetreatExpectedState(
      input,
    ),
    'combat-characterization-city-capture-accepted' =>
      _combatCityCaptureExpectedState(input),
    'combat-characterization-city-destroy-accepted' =>
      _combatCityDestroyExpectedState(input),
    _ => throw StateError('Unknown combat oracle id: $fixtureId.'),
  };
}

List<GameEvent> _combatExpectedEvents(String fixtureId) {
  if (_combatRejectedFixtureIds.contains(fixtureId)) return const [];
  return switch (fixtureId) {
    'combat-characterization-unit-accepted' => _combatUnitEvents,
    'combat-characterization-defended-city-unit-accepted' =>
      _combatDefendedCityUnitEvents,
    'combat-characterization-retreat-accepted' => _combatRetreatEvents,
    'combat-characterization-city-capture-accepted' => _combatCityCaptureEvents,
    'combat-characterization-city-destroy-accepted' => _combatCityDestroyEvents,
    _ => throw StateError('Unknown combat event oracle id: $fixtureId.'),
  };
}

PersistentGameState _combatUnitExpectedState(PersistentGameState input) {
  final attacker = _combatInputUnit(
    input,
    'combat_attacker',
  ).copyWith(movementPoints: 0, experiencePoints: 1).copyWithHitPoints(7);
  final defender = _combatInputUnit(
    input,
    'combat_defender',
  ).copyWith(experiencePoints: 1).copyWithHitPoints(9);
  return _combatAcceptedState(
    input,
    replacements: [attacker, defender],
    diplomacy: _combatUnitAttackDiplomacy,
  );
}

PersistentGameState _combatDefendedCityUnitExpectedState(
  PersistentGameState input,
) {
  final attacker = _combatInputUnit(
    input,
    'defended_attacker',
  ).copyWith(movementPoints: 0, experiencePoints: 3);
  return _combatAcceptedState(
    input,
    replacements: [attacker],
    removedUnitIds: const {'defended_unit'},
    artifacts: [
      for (final artifact in input.artifacts)
        if (artifact.id == _combatCarriedArtifactId)
          artifact.copyWith(
            location: const WorldArtifactLocation.map(col: 1, row: 0),
          )
        else
          artifact,
    ],
    diplomacy: _combatUnitAttackDiplomacy,
  );
}

PersistentGameState _combatRetreatExpectedState(PersistentGameState input) {
  final attacker = _combatInputUnit(
    input,
    'retreat_attacker',
  ).copyWith(movementPoints: 0, experiencePoints: 1);
  final defender = _combatInputUnit(input, 'retreat_defender')
      .copyWith(col: 1, row: 1, movementPoints: 0, experiencePoints: 1)
      .copyWithHitPoints(1);
  return _combatAcceptedState(
    input,
    replacements: [attacker, defender],
    diplomacy: _combatUnitAttackDiplomacy,
  );
}

PersistentGameState _combatCityCaptureExpectedState(PersistentGameState input) {
  final attacker = _combatInputUnit(
    input,
    'capture_attacker',
  ).copyWith(movementPoints: 0, experiencePoints: 3);
  final captured = _combatInputCity(
    input,
    'capture_city',
  ).copyWith(ownerPlayerId: _combatActorId, hitPoints: 8);
  return _combatAcceptedState(
    input,
    replacements: [attacker],
    cityReplacements: [captured],
    diplomacy: _combatCityAttackDiplomacy,
    resourceTradeAgreements: const [_combatUnrelatedTrade],
  );
}

PersistentGameState _combatCityDestroyExpectedState(PersistentGameState input) {
  final attacker = _combatInputUnit(
    input,
    'destroy_attacker',
  ).copyWith(movementPoints: 0, experiencePoints: 3);
  return _combatAcceptedState(
    input,
    replacements: [attacker],
    removedCityIds: const {'destroy_city'},
    artifacts: [
      for (final artifact in input.artifacts)
        if (artifact.id == _combatStoredArtifactId)
          artifact.copyWith(
            location: const WorldArtifactLocation.map(col: 1, row: 0),
          )
        else
          artifact,
    ],
    diplomacy: _combatCityAttackDiplomacy,
    resourceTradeAgreements: const [_combatUnrelatedTrade],
  );
}

PersistentGameState _combatAcceptedState(
  PersistentGameState input, {
  List<GameUnit> replacements = const [],
  Set<String> removedUnitIds = const {},
  List<GameCity> cityReplacements = const [],
  Set<String> removedCityIds = const {},
  List<WorldArtifact>? artifacts,
  required DiplomacyState diplomacy,
  List<ResourceTradeAgreement>? resourceTradeAgreements,
}) {
  final unitsById = {for (final unit in replacements) unit.id: unit};
  final citiesById = {for (final city in cityReplacements) city.id: city};
  return input.copyWith(
    units: [
      for (final unit in input.units)
        if (!removedUnitIds.contains(unit.id)) unitsById[unit.id] ?? unit,
    ],
    cities: [
      for (final city in input.cities)
        if (!removedCityIds.contains(city.id)) citiesById[city.id] ?? city,
    ],
    artifacts: artifacts ?? input.artifacts,
    runtimeState: input.runtimeState.copyWith(
      diplomacy: diplomacy,
      resourceTradeAgreements:
          resourceTradeAgreements ?? input.runtimeState.resourceTradeAgreements,
    ),
  );
}

GameUnit _combatInputUnit(PersistentGameState state, String id) {
  return state.units.singleWhere((unit) => unit.id == id);
}

GameCity _combatInputCity(PersistentGameState state, String id) {
  return state.cities.singleWhere((city) => city.id == id);
}

final _combatUnitAttackDiplomacy = DiplomacyState(
  contactKeys: const {
    'player_1|player_2',
    'player_1|player_3',
    'player_2|player_3',
  },
  relations: const {
    'player_1|player_2': DiplomaticRelation(
      playerAId: _combatActorId,
      playerBId: _combatOpponentId,
      status: DiplomaticRelationStatus.hostile,
      relationScore: -10,
      lastChangedTurn: 7,
      lastChangeReason: DiplomaticRelationChangeReason.unitAttack,
    ),
  },
  scoreHistory: const {
    'player_1|player_2': [
      DiplomaticScoreEntry(
        playerAId: _combatActorId,
        playerBId: _combatOpponentId,
        turn: 7,
        delta: -10,
        scoreAfter: -10,
        reason: DiplomaticScoreChangeReason.unitAttack,
      ),
    ],
  },
);

final _combatCityAttackDiplomacy = DiplomacyState(
  contactKeys: const {
    'player_1|player_2',
    'player_1|player_3',
    'player_2|player_3',
  },
  relations: const {
    'player_1|player_2': DiplomaticRelation(
      playerAId: _combatActorId,
      playerBId: _combatOpponentId,
      status: DiplomaticRelationStatus.war,
      relationScore: -30,
      lastChangedTurn: 7,
      lastChangeReason: DiplomaticRelationChangeReason.cityAttack,
    ),
  },
  scoreHistory: const {
    'player_1|player_2': [
      DiplomaticScoreEntry(
        playerAId: _combatActorId,
        playerBId: _combatOpponentId,
        turn: 7,
        delta: -30,
        scoreAfter: -30,
        reason: DiplomaticScoreChangeReason.cityAttack,
      ),
    ],
  },
);

final _combatUnitOutcome = CombatOutcome(
  attackerUnitId: 'combat_attacker',
  defenderUnitId: 'combat_defender',
  attackerHpAfter: 7,
  defenderHpAfter: 9,
  attackerKilled: false,
  defenderKilled: false,
  steps: [
    const RollStep(seed: 2294949058, value: 0),
    AttackStep(damage: 1),
    const RollStep(seed: 2294949058, value: 2),
    RetaliationStep(damage: 3),
  ],
);

final _combatUnitEvents = <GameEvent>[
  const UnitAttackedEvent(
    attackerUnitId: 'combat_attacker',
    attackerOwnerPlayerId: _combatActorId,
    defenderUnitId: 'combat_defender',
    defenderOwnerPlayerId: _combatOpponentId,
  ),
  CombatResolvedEvent(
    attackerUnitId: 'combat_attacker',
    defenderUnitId: 'combat_defender',
    outcome: _combatUnitOutcome,
  ),
  const UnitGainedExperienceEvent(
    unitId: 'combat_attacker',
    ownerPlayerId: _combatActorId,
    amount: 1,
    totalExperience: 1,
    rank: UnitVeterancyRank.recruit,
    promoted: false,
  ),
  const UnitGainedExperienceEvent(
    unitId: 'combat_defender',
    ownerPlayerId: _combatOpponentId,
    amount: 1,
    totalExperience: 1,
    rank: UnitVeterancyRank.recruit,
    promoted: false,
  ),
];

const _combatDefendedCityModifier = FortificationModifier(
  label: 'city.defended_city.garrison',
  target: CombatStatTarget.defense,
  delta: 1,
);

final _combatDefendedCityUnitOutcome = CombatOutcome(
  attackerUnitId: 'defended_attacker',
  defenderUnitId: 'defended_unit',
  attackerHpAfter: 10,
  defenderHpAfter: 0,
  attackerKilled: false,
  defenderKilled: true,
  steps: [
    const ModifierAppliedStep(_combatDefendedCityModifier),
    const RollStep(seed: 3053409491, value: -1),
    AttackStep(damage: 1),
  ],
);

final _combatDefendedCityUnitEvents = <GameEvent>[
  const UnitAttackedEvent(
    attackerUnitId: 'defended_attacker',
    attackerOwnerPlayerId: _combatActorId,
    defenderUnitId: 'defended_unit',
    defenderOwnerPlayerId: _combatOpponentId,
  ),
  CombatResolvedEvent(
    attackerUnitId: 'defended_attacker',
    defenderUnitId: 'defended_unit',
    outcome: _combatDefendedCityUnitOutcome,
  ),
  const UnitGainedExperienceEvent(
    unitId: 'defended_attacker',
    ownerPlayerId: _combatActorId,
    amount: 3,
    totalExperience: 3,
    rank: UnitVeterancyRank.seasoned,
    promoted: true,
  ),
  const UnitKilledEvent(
    unitId: 'defended_unit',
    ownerPlayerId: _combatOpponentId,
    attackerUnitId: 'defended_attacker',
  ),
];

final _combatRetreatOutcome = CombatOutcome(
  attackerUnitId: 'retreat_attacker',
  defenderUnitId: 'retreat_defender',
  attackerHpAfter: 7,
  defenderHpAfter: 1,
  attackerKilled: false,
  defenderKilled: false,
  defenderRetreated: true,
  steps: [const RollStep(seed: 708054674, value: -1), AttackStep(damage: 1)],
);

final _combatRetreatEvents = <GameEvent>[
  const UnitAttackedEvent(
    attackerUnitId: 'retreat_attacker',
    attackerOwnerPlayerId: _combatActorId,
    defenderUnitId: 'retreat_defender',
    defenderOwnerPlayerId: _combatOpponentId,
  ),
  CombatResolvedEvent(
    attackerUnitId: 'retreat_attacker',
    defenderUnitId: 'retreat_defender',
    outcome: _combatRetreatOutcome,
  ),
  const UnitRetreatedEvent(
    unitId: 'retreat_defender',
    ownerPlayerId: _combatOpponentId,
    fromCol: 1,
    fromRow: 0,
    toCol: 1,
    toRow: 1,
  ),
  const UnitGainedExperienceEvent(
    unitId: 'retreat_attacker',
    ownerPlayerId: _combatActorId,
    amount: 1,
    totalExperience: 1,
    rank: UnitVeterancyRank.recruit,
    promoted: false,
  ),
  const UnitGainedExperienceEvent(
    unitId: 'retreat_defender',
    ownerPlayerId: _combatOpponentId,
    amount: 1,
    totalExperience: 1,
    rank: UnitVeterancyRank.recruit,
    promoted: false,
  ),
];

final _combatCityCaptureOutcome = CombatOutcome(
  attackerUnitId: 'capture_attacker',
  defenderUnitId: 'capture_city',
  attackerHpAfter: 10,
  defenderHpAfter: -1,
  attackerKilled: false,
  defenderKilled: true,
  steps: [const RollStep(seed: 2551497194, value: 0), AttackStep(damage: 2)],
);

final _combatCityCaptureEvents = <GameEvent>[
  const CityAttackedEvent(
    attackerUnitId: 'capture_attacker',
    attackerOwnerPlayerId: _combatActorId,
    cityId: 'capture_city',
    cityOwnerPlayerId: _combatOpponentId,
  ),
  CombatResolvedEvent(
    attackerUnitId: 'capture_attacker',
    defenderUnitId: 'capture_city',
    outcome: _combatCityCaptureOutcome,
  ),
  const UnitGainedExperienceEvent(
    unitId: 'capture_attacker',
    ownerPlayerId: _combatActorId,
    amount: 3,
    totalExperience: 3,
    rank: UnitVeterancyRank.seasoned,
    promoted: true,
  ),
  const CityCapturedEvent(
    cityId: 'capture_city',
    previousOwnerPlayerId: _combatOpponentId,
    newOwnerPlayerId: _combatActorId,
  ),
];

final _combatCityDestroyOutcome = CombatOutcome(
  attackerUnitId: 'destroy_attacker',
  defenderUnitId: 'destroy_city',
  attackerHpAfter: 10,
  defenderHpAfter: -1,
  attackerKilled: false,
  defenderKilled: true,
  steps: [const RollStep(seed: 308218106, value: 0), AttackStep(damage: 2)],
);

final _combatCityDestroyEvents = <GameEvent>[
  const CityAttackedEvent(
    attackerUnitId: 'destroy_attacker',
    attackerOwnerPlayerId: _combatActorId,
    cityId: 'destroy_city',
    cityOwnerPlayerId: _combatOpponentId,
  ),
  CombatResolvedEvent(
    attackerUnitId: 'destroy_attacker',
    defenderUnitId: 'destroy_city',
    outcome: _combatCityDestroyOutcome,
  ),
  const UnitGainedExperienceEvent(
    unitId: 'destroy_attacker',
    ownerPlayerId: _combatActorId,
    amount: 3,
    totalExperience: 3,
    rank: UnitVeterancyRank.seasoned,
    promoted: true,
  ),
  const CityDestroyedEvent(
    cityId: 'destroy_city',
    previousOwnerPlayerId: _combatOpponentId,
    attackerOwnerPlayerId: _combatActorId,
  ),
];
