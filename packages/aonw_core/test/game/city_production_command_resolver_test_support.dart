part of 'city_production_command_resolver_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

CityProductionCommandResult _startProject({
  required List<GameCity> cities,
  String actorPlayerId = _playerId,
}) {
  return CityProductionCommandResolver.startCityProject(
    cities: cities,
    command: const StartCityProjectCommand('city_1', CityProjectType.research),
    actorPlayerId: actorPlayerId,
    cityRuleset: CityRulesets.standard,
    paceBalance: PaceBalance.standard60,
  );
}

void _expectProjectRejected({
  required List<GameCity> cities,
  required String reason,
  String actorPlayerId = _playerId,
}) {
  final result = _startProject(cities: cities, actorPlayerId: actorPlayerId);

  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.cities, cities), isTrue);
}

GameCity _productionCity({
  String id = 'city_1',
  String ownerPlayerId = _playerId,
  CityProductionQueue? productionQueue,
  int productionOverflow = 0,
}) {
  return GameCity.snapshot(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: id == 'city_1'
        ? const CityHex(col: 1, row: 1)
        : const CityHex(col: 3, row: 3),
    productionQueue: productionQueue,
    productionOverflow: productionOverflow,
  );
}
