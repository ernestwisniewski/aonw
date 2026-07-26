part of '../server_command_reducer_test.dart';

void _registerServerCommandReducerCombatTests() {
  _registerServerCommandReducerCombatCommandTests();
  _registerServerCommandReducerCombatPrivacyTests();
}

void _registerServerCommandReducerCombatCommandTests() {
  group('ServerCommandReducer combat commands', () {
    test('resolves a unit attack instead of rejecting the command', () async {
      final reduction =
          await ServerCommandReducer(
            mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
          ).reduce(
            match: _runningMatch(),
            snapshot: _snapshot(
              _combatState(
                units: [
                  _combatUnit('attacker', 'player_1', 0, 0),
                  _combatUnit(
                    'defender',
                    'player_2',
                    1,
                    0,
                    type: GameUnitType.settler,
                  ),
                ],
              ),
            ),
            wireCommand: _wireCommand(const AttackHexCommand('attacker', 1, 0)),
            actorPlayerId: 'player_1',
            now: DateTime.utc(2026, 6, 30, 12),
          );
      final state = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(reduction.reason, isNull);
      expect(reduction.events.whereType<UnitAttackedEvent>(), hasLength(1));
      expect(reduction.events.whereType<CombatResolvedEvent>(), hasLength(1));
      expect(state.units.byId('attacker')?.movementPoints, 0);
    });

    test('honors city destruction in an authoritative attack', () async {
      final reduction =
          await ServerCommandReducer(
            mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
          ).reduce(
            match: _runningMatch(),
            snapshot: _snapshot(
              _combatState(
                units: [_combatUnit('attacker', 'player_1', 0, 0)],
                cities: const [
                  GameCity(
                    id: 'city_2',
                    ownerPlayerId: 'player_2',
                    name: 'City 2',
                    center: CityHex(col: 1, row: 0),
                    hitPoints: 1,
                  ),
                ],
              ),
            ),
            wireCommand: _wireCommand(
              const AttackHexCommand(
                'attacker',
                1,
                0,
                cityConquestAction: CityConquestAction.destroy,
              ),
            ),
            actorPlayerId: 'player_1',
            now: DateTime.utc(2026, 6, 30, 12),
          );
      final state = PersistentGameState.fromJson(reduction.snapshot.state);

      expect(reduction.accepted, isTrue);
      expect(state.cities, isEmpty);
      expect(reduction.events.whereType<CityAttackedEvent>(), hasLength(1));
      expect(reduction.events.whereType<CityDestroyedEvent>(), hasLength(1));
    });
  });
}

void _registerServerCommandReducerCombatPrivacyTests() {
  group('ServerCommandReducer combat privacy', () {
    final cases = <_CombatPrivacyCase>[
      const _CombatPrivacyCase(name: 'empty cell'),
      _CombatPrivacyCase(
        name: 'hidden hostile unit',
        units: [_combatUnit('target', 'player_2', 1, 0)],
        diplomacy: _combatPrivacyDiplomacy(DiplomaticRelationStatus.hostile),
      ),
      _CombatPrivacyCase(
        name: 'hidden friendly unit',
        units: [_combatUnit('target', 'player_1', 1, 0)],
      ),
      _CombatPrivacyCase(
        name: 'hidden truce unit',
        units: [_combatUnit('target', 'player_2', 1, 0)],
        diplomacy: _combatPrivacyDiplomacy(DiplomaticRelationStatus.truce),
      ),
      _CombatPrivacyCase(
        name: 'hidden hostile city',
        cities: const [
          GameCity(
            id: 'target_city',
            ownerPlayerId: 'player_2',
            name: 'Hidden city',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        diplomacy: _combatPrivacyDiplomacy(DiplomaticRelationStatus.hostile),
      ),
    ];

    for (final privacyCase in cases) {
      test(
        'does not disclose ${privacyCase.name} through a forged attack',
        () async {
          final state = _combatPrivacyState(privacyCase);
          final snapshot = _snapshot(state);
          final reduction =
              await ServerCommandReducer(
                mapCatalog: _FakeMapCatalog(_resourceTradeMap()),
              ).reduce(
                match: _runningMatch(),
                snapshot: snapshot,
                wireCommand: _wireCommand(
                  const AttackHexCommand('attacker', 1, 0),
                ),
                actorPlayerId: 'player_1',
                now: DateTime.utc(2026, 6, 30, 12),
              );

          expect(reduction.accepted, isFalse);
          expect(reduction.reason, 'attack_target_not_visible');
          expect(reduction.snapshot, same(snapshot));
          expect(reduction.snapshot.toJson(), snapshot.toJson());
          expect(reduction.events, isEmpty);
          expect(reduction.movementExecutions, isEmpty);
          expect(reduction.previousState, isNull);
          expect(reduction.state, isNull);
        },
      );
    }
  });
}

final class _CombatPrivacyCase {
  const _CombatPrivacyCase({
    required this.name,
    this.units = const [],
    this.cities = const [],
    this.diplomacy = DiplomacyState.empty,
  });

  final String name;
  final List<GameUnit> units;
  final List<GameCity> cities;
  final DiplomacyState diplomacy;
}

PersistentGameState _combatPrivacyState(_CombatPrivacyCase privacyCase) {
  return PersistentGameState.snapshot(
    playerColors: const {'player_1': 0xFF3D5FA8, 'player_2': 0xFFB83A3A},
    units: [_combatUnit('attacker', 'player_1', 0, 0), ...privacyCase.units],
    cities: privacyCase.cities,
    fogOfWar: FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          visibleHexes: {const HexCoordinate(col: 0, row: 0)},
        ),
        'player_2': PlayerFogOfWar(
          playerId: 'player_2',
          visibleHexes: {
            const HexCoordinate(col: 0, row: 0),
            const HexCoordinate(col: 1, row: 0),
          },
        ),
      },
    ),
    runtimeState: GameRuntimeState(diplomacy: privacyCase.diplomacy),
  );
}

DiplomacyState _combatPrivacyDiplomacy(DiplomaticRelationStatus status) {
  const actorPlayerId = 'player_1';
  const opponentPlayerId = 'player_2';
  final relation = DiplomaticRelation.between(
    playerAId: actorPlayerId,
    playerBId: opponentPlayerId,
    status: status,
  );
  return DiplomacyState(
    relations: {relation.key: relation},
    contactKeys: {relation.key},
  );
}
