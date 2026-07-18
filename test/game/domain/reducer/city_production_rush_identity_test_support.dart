part of 'city_production_rush_identity_test.dart';

void _expectSharedSlices(
  GameState actual,
  GameState before, {
  bool expectUnits = true,
  bool expectWonderRegistry = true,
}) {
  expect(actual.playerColors, same(before.playerColors));
  expect(actual.playerCountries, same(before.playerCountries));
  expect(actual.playerWarWeariness, same(before.playerWarWeariness));
  expect(actual.playerStabilityNet, same(before.playerStabilityNet));
  if (expectUnits) expect(actual.units, same(before.units));
  expect(actual.artifacts, same(before.artifacts));
  expect(actual.fieldImprovements, same(before.fieldImprovements));
  expect(actual.fogOfWar, same(before.fogOfWar));
  expect(actual.research, same(before.research));
  if (expectWonderRegistry) {
    expect(actual.wonderRegistry, same(before.wonderRegistry));
  }
  expect(actual.diplomacy, same(before.diplomacy));
  expect(actual.intendedAttacks, same(before.intendedAttacks));
  expect(actual.resourceTradeAgreements, same(before.resourceTradeAgreements));
  expect(
    actual.dominationHoldTurnsByPlayerId,
    same(before.dominationHoldTurnsByPlayerId),
  );
  expect(
    actual.culturalVictoryHoldTurnsByPlayerId,
    same(before.culturalVictoryHoldTurnsByPlayerId),
  );
  expect(
    actual.mapObjectiveHoldStatesByObjectiveId,
    same(before.mapObjectiveHoldStatesByObjectiveId),
  );
  expect(actual.submittedPlayerIds, same(before.submittedPlayerIds));
  expect(
    actual.timeoutStreaksByPlayerId,
    same(before.timeoutStreaksByPlayerId),
  );
  expect(actual.afkPlayerIds, same(before.afkPlayerIds));
  expect(actual.kickedPlayerIds, same(before.kickedPlayerIds));
  expect(actual.activePlayerId, before.activePlayerId);
  expect(actual.activePlayerCanAct, before.activePlayerCanAct);
  expect(actual.turnStartedAt, same(before.turnStartedAt));
}
