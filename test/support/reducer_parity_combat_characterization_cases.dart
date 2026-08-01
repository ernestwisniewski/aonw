part of 'reducer_parity_combat_characterization.dart';

List<ReducerParityFixture> _combatRejectionCases(
  ReducerParityFixture template,
) {
  final map = _combatMap(template, cols: 4, rows: 2);
  final visibleFog = _combatVisibleFog(cols: 4, rows: 2);
  return [
    ..._combatAttackerGuardRejectionCases(template, map, visibleFog),
    ..._combatCapabilityRejectionCases(template, map, visibleFog),
    ..._combatTargetPolicyRejectionCases(template, map, visibleFog),
  ];
}

List<ReducerParityFixture> _combatAttackerGuardRejectionCases(
  ReducerParityFixture template,
  WorldMap map,
  FogOfWarState visibleFog,
) {
  return [
    _combatFixture(
      template,
      id: 'combat-characterization-attacker-missing-rejected',
      tickOffset: 301,
      mapData: map,
      state: _combatState(
        template.state,
        units: const [],
        cities: const [],
        fogOfWar: visibleFog,
      ),
      command: const AttackHexCommand('missing_attacker', 9, 9),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-attacker-not-controlled-rejected',
      tickOffset: 302,
      actorPlayerId: _combatOpponentId,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(
            id: 'wrong_actor_attacker',
            col: -1,
            movementPoints: 0,
            excavatingArtifactId: 'wrong_actor_work',
          ),
        ],
        cities: const [],
        fogOfWar: visibleFog,
      ),
      command: const AttackHexCommand('wrong_actor_attacker', 9, 9),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-attacker-unavailable-rejected',
      tickOffset: 303,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(
            id: 'working_attacker',
            col: -1,
            movementPoints: 0,
            excavatingArtifactId: 'combat_work',
          ),
        ],
        cities: const [],
        fogOfWar: visibleFog,
      ),
      command: const AttackHexCommand('working_attacker', 9, 9),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-attacker-exhausted-rejected',
      tickOffset: 304,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(id: 'exhausted_attacker', col: -1, movementPoints: 0),
        ],
        cities: const [],
        fogOfWar: visibleFog,
      ),
      command: const AttackHexCommand('exhausted_attacker', 9, 9),
    ),
  ];
}

List<ReducerParityFixture> _combatCapabilityRejectionCases(
  ReducerParityFixture template,
  WorldMap map,
  FogOfWarState visibleFog,
) {
  return [
    _combatFixture(
      template,
      id: 'combat-characterization-attacker-out-of-bounds-rejected',
      tickOffset: 305,
      mapData: map,
      state: _combatState(
        template.state,
        units: [_combatUnit(id: 'invalid_origin_attacker', col: -1)],
        cities: const [],
        fogOfWar: visibleFog,
      ),
      command: const AttackHexCommand('invalid_origin_attacker', 9, 9),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-target-out-of-bounds-rejected',
      tickOffset: 306,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(
            id: 'invalid_target_attacker',
            type: GameUnitType.settler,
          ),
        ],
        cities: const [],
        fogOfWar: visibleFog,
      ),
      command: const AttackHexCommand('invalid_target_attacker', 9, 9),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-attacker-cannot-attack-rejected',
      tickOffset: 307,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(id: 'civilian_attacker', type: GameUnitType.settler),
        ],
        cities: const [],
        fogOfWar: visibleFog,
      ),
      command: const AttackHexCommand('civilian_attacker', 1, 0),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-target-missing-rejected',
      tickOffset: 308,
      mapData: map,
      state: _combatState(
        template.state,
        units: [_combatUnit(id: 'missing_target_attacker')],
        cities: const [],
        fogOfWar: visibleFog,
      ),
      command: const AttackHexCommand('missing_target_attacker', 1, 0),
    ),
  ];
}

List<ReducerParityFixture> _combatTargetPolicyRejectionCases(
  ReducerParityFixture template,
  WorldMap map,
  FogOfWarState visibleFog,
) {
  return [
    _combatFixture(
      template,
      id: 'combat-characterization-target-not-enemy-rejected',
      tickOffset: 309,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(id: 'friendly_target_attacker'),
          _combatUnit(
            id: 'friendly_target',
            ownerPlayerId: _combatActorId,
            col: 2,
          ),
        ],
        cities: const [],
        fogOfWar: visibleFog,
      ),
      command: const AttackHexCommand('friendly_target_attacker', 2, 0),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-target-protected-by-treaty-rejected',
      tickOffset: 310,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(id: 'truce_attacker'),
          _combatUnit(
            id: 'truce_target',
            ownerPlayerId: _combatOpponentId,
            col: 2,
          ),
        ],
        cities: const [],
        fogOfWar: visibleFog,
        diplomacy: _combatTruceDiplomacy,
      ),
      command: const AttackHexCommand('truce_attacker', 2, 0),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-target-not-visible-rejected',
      tickOffset: 311,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(id: 'hidden_target_attacker'),
          _combatUnit(
            id: 'hidden_target',
            ownerPlayerId: _combatOpponentId,
            col: 2,
          ),
        ],
        cities: const [],
        fogOfWar: _combatFog(
          cols: 4,
          rows: 2,
          actorVisible: {const HexCoordinate(col: 0, row: 0)},
        ),
      ),
      command: const AttackHexCommand('hidden_target_attacker', 2, 0),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-target-out-of-range-rejected',
      tickOffset: 312,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(id: 'distant_target_attacker'),
          _combatUnit(
            id: 'distant_target',
            ownerPlayerId: _combatOpponentId,
            col: 2,
          ),
        ],
        cities: const [],
        fogOfWar: visibleFog,
      ),
      command: const AttackHexCommand('distant_target_attacker', 2, 0),
    ),
  ];
}

List<ReducerParityFixture> _combatAcceptanceCases(
  ReducerParityFixture template,
) {
  final map = _combatMap(template, cols: 3, rows: 2);
  final fog = _combatVisibleFog(cols: 3, rows: 2);
  return [
    ..._combatUnitAcceptanceCases(template, map, fog),
    ..._combatCityAcceptanceCases(template, map, fog),
  ];
}

List<ReducerParityFixture> _combatUnitAcceptanceCases(
  ReducerParityFixture template,
  WorldMap map,
  FogOfWarState fog,
) {
  return [
    _combatFixture(
      template,
      id: 'combat-characterization-unit-accepted',
      tickOffset: 321,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(id: 'combat_attacker'),
          _combatUnit(
            id: 'combat_defender',
            ownerPlayerId: _combatOpponentId,
            col: 1,
          ),
        ],
        cities: const [],
        fogOfWar: fog,
      ),
      command: const AttackHexCommand('combat_attacker', 1, 0),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-defended-city-unit-accepted',
      tickOffset: 322,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(id: 'defended_attacker'),
          _combatUnit(
            id: 'defended_unit',
            ownerPlayerId: _combatOpponentId,
            type: GameUnitType.settler,
            col: 1,
            carriedArtifactId: _combatCarriedArtifactId,
          ),
        ],
        cities: const [
          GameCity(
            id: 'defended_city',
            ownerPlayerId: _combatOpponentId,
            name: 'Defended city',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        artifacts: const [_combatSentinelArtifact, _combatCarriedArtifact],
        fogOfWar: fog,
      ),
      command: const AttackHexCommand('defended_attacker', 1, 0),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-retreat-accepted',
      tickOffset: 323,
      mapData: map,
      state: _combatState(
        template.state,
        units: [
          _combatUnit(id: 'retreat_attacker', type: GameUnitType.archer),
          _combatUnit(
            id: 'retreat_defender',
            ownerPlayerId: _combatOpponentId,
            col: 1,
            hitPoints: 2,
          ),
        ],
        cities: const [],
        fogOfWar: fog,
      ),
      command: const AttackHexCommand('retreat_attacker', 1, 0),
    ),
  ];
}

List<ReducerParityFixture> _combatCityAcceptanceCases(
  ReducerParityFixture template,
  WorldMap map,
  FogOfWarState fog,
) {
  return [
    _combatFixture(
      template,
      id: 'combat-characterization-city-capture-accepted',
      tickOffset: 324,
      mapData: map,
      state: _combatState(
        template.state,
        units: [_combatUnit(id: 'capture_attacker')],
        cities: const [
          GameCity(
            id: 'capture_city',
            ownerPlayerId: _combatOpponentId,
            foundingOwnerPlayerId: _combatOpponentId,
            name: 'Capture city',
            center: CityHex(col: 1, row: 0),
            hitPoints: 1,
          ),
        ],
        artifacts: const [
          _combatSentinelArtifact,
          WorldArtifact(
            id: _combatStoredArtifactId,
            type: WorldArtifactType.astronomersTablets,
            location: WorldArtifactLocation.stored(cityId: 'capture_city'),
          ),
        ],
        fogOfWar: fog,
      ),
      command: const AttackHexCommand('capture_attacker', 1, 0),
    ),
    _combatFixture(
      template,
      id: 'combat-characterization-city-destroy-accepted',
      tickOffset: 325,
      mapData: map,
      state: _combatState(
        template.state,
        units: [_combatUnit(id: 'destroy_attacker')],
        cities: const [
          GameCity(
            id: 'destroy_city',
            ownerPlayerId: _combatOpponentId,
            foundingOwnerPlayerId: _combatOpponentId,
            name: 'Destroy city',
            center: CityHex(col: 1, row: 0),
            hitPoints: 1,
          ),
        ],
        artifacts: const [
          _combatSentinelArtifact,
          WorldArtifact(
            id: _combatStoredArtifactId,
            type: WorldArtifactType.astronomersTablets,
            location: WorldArtifactLocation.stored(cityId: 'destroy_city'),
          ),
        ],
        fogOfWar: fog,
      ),
      command: const AttackHexCommand(
        'destroy_attacker',
        1,
        0,
        cityConquestAction: CityConquestAction.destroy,
      ),
    ),
  ];
}
