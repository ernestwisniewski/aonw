import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _center = CityHex(col: 0, row: 0);
const _a = CityHex(col: 1, row: 0);
const _b = CityHex(col: 0, row: 1);
const _c = CityHex(col: -1, row: 1);
const _d = CityHex(col: -1, row: 0);
const _outside = CityHex(col: 2, row: 0);

void main() {
  group('worked-hex persistent/domain parity', () {
    for (final scenario in _scenarios) {
      test(scenario.name, () {
        final initialCities = [scenario.city, _companionCity];
        final persistent = _persistentState(initialCities);
        final domain = _domainState(initialCities);

        final persistentResult = const PersistentCityWorkedHexResolver()
            .toggleWorkedHex(
              state: persistent,
              command: scenario.command,
              actorPlayerId: scenario.actorPlayerId,
            );
        final domainResult = const DomainCityWorkedHexResolver()
            .toggleWorkedHex(
              state: domain,
              command: scenario.command,
              actorPlayerId: scenario.actorPlayerId,
            );

        expect(persistentResult.accepted, scenario.accepted);
        expect(domainResult.accepted, scenario.accepted);
        expect(persistentResult.reason, scenario.reason);
        expect(domainResult.reason, scenario.reason);
        expect(persistentResult.state.cities, domainResult.state.cities);
        expect(
          persistentResult.state.cities.first.workedHexes,
          scenario.expectedWorkedHexes,
        );

        if (scenario.accepted) {
          _expectPersistentChangedOnlyCities(
            persistent,
            persistentResult.state,
          );
          _expectDomainChangedOnlyCities(domain, domainResult.state);
          expect(
            identical(persistentResult.state.cities[1], persistent.cities[1]),
            isTrue,
          );
          expect(
            identical(domainResult.state.cities[1], domain.cities[1]),
            isTrue,
          );
          expect(
            () => persistentResult.state.cities.add(_companionCity),
            throwsUnsupportedError,
          );
          expect(
            () => domainResult.state.cities.add(_companionCity),
            throwsUnsupportedError,
          );
        } else {
          expect(identical(persistentResult.state, persistent), isTrue);
          expect(identical(domainResult.state, domain), isTrue);
        }
      });
    }

    test(
      'neutral accept owns cities while reject preserves input identity',
      () {
        final targetControlled = <CityHex>[_a];
        final companionControlled = <CityHex>[_b];
        final source = <GameCity>[
          _city(controlledHexes: targetControlled),
          _city(
            id: 'city_2',
            ownerPlayerId: 'player_2',
            controlledHexes: companionControlled,
          ),
        ];

        final accepted = ToggleWorkedHexResolver.toggleWorkedHex(
          cities: source,
          command: const ToggleWorkedHexCommand('city_1', 1, 0),
          actorPlayerId: 'player_1',
        );
        final rejected = ToggleWorkedHexResolver.toggleWorkedHex(
          cities: source,
          command: const ToggleWorkedHexCommand('missing', 1, 0),
          actorPlayerId: 'player_1',
        );
        expect(identical(rejected.cities, source), isTrue);
        source.clear();
        targetControlled.add(_c);
        companionControlled.add(_d);

        expect(accepted.cities, hasLength(2));
        expect(accepted.cities.first.workedHexes, [_a]);
        expect(accepted.cities[1].controlledHexes, [_b]);
        expect(rejected.cities, isEmpty);
        expect(
          () => accepted.cities.add(_companionCity),
          throwsUnsupportedError,
        );
        expect(
          () => accepted.cities.first.workedHexes.add(_b),
          throwsUnsupportedError,
        );
      },
    );
  });
}

const _scenarios = <_Scenario>[
  _Scenario(
    name: 'accept adds after ordered center outside and duplicate cleanup',
    city: GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      population: 3,
      center: _center,
      controlledHexes: [_a, _b, _c, _d],
      workedHexes: [_center, _outside, _b, _b, _a],
    ),
    command: ToggleWorkedHexCommand('city_1', -1, 1),
    actorPlayerId: 'player_1',
    accepted: true,
    expectedWorkedHexes: [_b, _a, _c],
  ),
  _Scenario(
    name: 'accept removes after ordered dedup and limit normalization',
    city: GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      population: 3,
      center: _center,
      controlledHexes: [_a, _b, _c, _d],
      workedHexes: [_center, _outside, _b, _b, _a, _d, _c],
    ),
    command: ToggleWorkedHexCommand('city_1', 1, 0),
    actorPlayerId: 'player_1',
    accepted: true,
    expectedWorkedHexes: [_b, _d],
  ),
  _Scenario(
    name: 'rejects missing city with exact reason',
    city: GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: _center,
      controlledHexes: [_a],
    ),
    command: ToggleWorkedHexCommand('missing', 1, 0),
    actorPlayerId: 'player_1',
    accepted: false,
    reason: 'city_not_found',
    expectedWorkedHexes: [],
  ),
  _Scenario(
    name: 'rejects another player city with exact reason',
    city: GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_2',
      name: 'City',
      center: _center,
      controlledHexes: [_a],
    ),
    command: ToggleWorkedHexCommand('city_1', 1, 0),
    actorPlayerId: 'player_1',
    accepted: false,
    reason: 'city_not_controlled',
    expectedWorkedHexes: [],
  ),
  _Scenario(
    name: 'rejects city center with exact reason',
    city: GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: _center,
      controlledHexes: [_a],
    ),
    command: ToggleWorkedHexCommand('city_1', 0, 0),
    actorPlayerId: 'player_1',
    accepted: false,
    reason: 'worked_hex_unavailable',
    expectedWorkedHexes: [],
  ),
  _Scenario(
    name: 'rejects outside hex with exact reason',
    city: GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: _center,
      controlledHexes: [_a],
    ),
    command: ToggleWorkedHexCommand('city_1', 2, 0),
    actorPlayerId: 'player_1',
    accepted: false,
    reason: 'worked_hex_unavailable',
    expectedWorkedHexes: [],
  ),
  _Scenario(
    name: 'rejects addition at population limit with exact reason',
    city: GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      population: 1,
      center: _center,
      controlledHexes: [_a, _b],
      workedHexes: [_b],
    ),
    command: ToggleWorkedHexCommand('city_1', 1, 0),
    actorPlayerId: 'player_1',
    accepted: false,
    reason: 'worked_hex_limit_reached',
    expectedWorkedHexes: [_b],
  ),
];

final class _Scenario {
  const _Scenario({
    required this.name,
    required this.city,
    required this.command,
    required this.actorPlayerId,
    required this.accepted,
    required this.expectedWorkedHexes,
    this.reason,
  });

  final String name;
  final GameCity city;
  final ToggleWorkedHexCommand command;
  final String actorPlayerId;
  final bool accepted;
  final String? reason;
  final List<CityHex> expectedWorkedHexes;
}

const _companionCity = GameCity(
  id: 'city_2',
  ownerPlayerId: 'player_2',
  name: 'Companion',
  center: CityHex(col: 10, row: 10),
  controlledHexes: [CityHex(col: 11, row: 10)],
);

GameCity _city({
  String id = 'city_1',
  String ownerPlayerId = 'player_1',
  List<CityHex> controlledHexes = const [_a],
}) {
  return GameCity(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    population: 3,
    center: _center,
    controlledHexes: controlledHexes,
  );
}

PersistentGameState _persistentState(List<GameCity> cities) {
  return PersistentGameState.snapshot(
    playerColors: const {'player_1': 1, 'player_2': 2},
    playerCountries: const {
      'player_1': PlayerCountry.poland,
      'player_2': PlayerCountry.france,
    },
    playerGold: const {'player_1': 17},
    playerWarWeariness: const {'player_1': 2},
    playerStabilityNet: const {'player_1': 3},
    units: [GameUnit.startingWarrior(ownerPlayerId: 'player_1')],
    cities: cities,
  );
}

DomainState _domainState(List<GameCity> cities) {
  return DomainState.snapshot(
    turn: 7,
    matchRules: MatchRules.standard,
    participants: const [
      Player(
        id: 'player_1',
        name: 'One',
        colorValue: 1,
        country: PlayerCountry.poland,
      ),
      Player(
        id: 'player_2',
        name: 'Two',
        colorValue: 2,
        country: PlayerCountry.france,
      ),
    ],
    playerGold: const {'player_1': 17},
    playerWarWeariness: const {'player_1': 2},
    playerStabilityNet: const {'player_1': 3},
    units: [GameUnit.startingWarrior(ownerPlayerId: 'player_1')],
    cities: cities,
  );
}

void _expectPersistentChangedOnlyCities(
  PersistentGameState before,
  PersistentGameState after,
) {
  expect(identical(after, before), isFalse);
  expect(identical(after.cities, before.cities), isFalse);
  expect(identical(after.playerColors, before.playerColors), isTrue);
  expect(identical(after.playerCountries, before.playerCountries), isTrue);
  expect(identical(after.playerGold, before.playerGold), isTrue);
  expect(
    identical(after.playerWarWeariness, before.playerWarWeariness),
    isTrue,
  );
  expect(
    identical(after.playerStabilityNet, before.playerStabilityNet),
    isTrue,
  );
  expect(identical(after.units, before.units), isTrue);
  expect(identical(after.artifacts, before.artifacts), isTrue);
  expect(identical(after.fieldImprovements, before.fieldImprovements), isTrue);
  expect(identical(after.fogOfWar, before.fogOfWar), isTrue);
  expect(identical(after.research, before.research), isTrue);
  expect(identical(after.runtimeState, before.runtimeState), isTrue);
  expect(identical(after.wonderRegistry, before.wonderRegistry), isTrue);
}

void _expectDomainChangedOnlyCities(DomainState before, DomainState after) {
  expect(identical(after, before), isFalse);
  expect(identical(after.cities, before.cities), isFalse);
  expect(after.turn, before.turn);
  expect(identical(after.matchRules, before.matchRules), isTrue);
  expect(identical(after.participants, before.participants), isTrue);
  expect(identical(after.playerColors, before.playerColors), isTrue);
  expect(identical(after.playerCountries, before.playerCountries), isTrue);
  expect(identical(after.playerGold, before.playerGold), isTrue);
  expect(
    identical(after.playerWarWeariness, before.playerWarWeariness),
    isTrue,
  );
  expect(
    identical(after.playerStabilityNet, before.playerStabilityNet),
    isTrue,
  );
  expect(identical(after.units, before.units), isTrue);
  expect(identical(after.artifacts, before.artifacts), isTrue);
  expect(identical(after.fieldImprovements, before.fieldImprovements), isTrue);
  expect(identical(after.fogOfWar, before.fogOfWar), isTrue);
  expect(identical(after.research, before.research), isTrue);
  expect(identical(after.wonderRegistry, before.wonderRegistry), isTrue);
  expect(identical(after.intendedAttacks, before.intendedAttacks), isTrue);
  expect(identical(after.diplomacy, before.diplomacy), isTrue);
  expect(
    identical(after.resourceTradeAgreements, before.resourceTradeAgreements),
    isTrue,
  );
  expect(
    identical(
      after.dominationHoldTurnsByPlayerId,
      before.dominationHoldTurnsByPlayerId,
    ),
    isTrue,
  );
  expect(
    identical(
      after.culturalVictoryHoldTurnsByPlayerId,
      before.culturalVictoryHoldTurnsByPlayerId,
    ),
    isTrue,
  );
  expect(
    identical(
      after.mapObjectiveHoldStatesByObjectiveId,
      before.mapObjectiveHoldStatesByObjectiveId,
    ),
    isTrue,
  );
}
