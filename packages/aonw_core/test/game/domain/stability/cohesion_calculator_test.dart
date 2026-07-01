import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';
import 'package:aonw_core/game/domain/hex/hex_distance.dart';
import 'package:aonw_core/game/domain/stability/cohesion_calculator.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:test/test.dart';

void main() {
  const ruleset = StabilityRuleset.standard;

  test('city within reach and connected costs nothing', () {
    final cost = CohesionCalculator.cityCohesionCost(
      cityCenter: const HexCoordinate(col: 2, row: 0),
      nearestCoreCenter: const HexCoordinate(col: 0, row: 0),
      isConnected: true,
      ruleset: ruleset,
    );
    expect(cost, 0);
  });

  test('city beyond reach pays per hex over the radius', () {
    const cityCenter = HexCoordinate(col: 7, row: 0);
    const coreCenter = HexCoordinate(col: 0, row: 0);
    final distance = HexDistance.between(cityCenter, coreCenter);

    final cost = CohesionCalculator.cityCohesionCost(
      cityCenter: cityCenter,
      nearestCoreCenter: coreCenter,
      isConnected: true,
      ruleset: ruleset,
    );

    expect(cost, distance - ruleset.reachRadius);
  });

  test('disconnected territory adds the disconnected cost', () {
    final cost = CohesionCalculator.cityCohesionCost(
      cityCenter: const HexCoordinate(col: 2, row: 0),
      nearestCoreCenter: const HexCoordinate(col: 0, row: 0),
      isConnected: false,
      ruleset: ruleset,
    );
    expect(cost, ruleset.disconnectedCityCost);
  });
}
