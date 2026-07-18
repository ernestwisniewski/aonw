import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('forwards StartWonder rejection through persistent simulation', () {
    const command = StartWonderCommand('missing_city', WonderType.greatLibrary);
    final result = EconomySimulation.run(
      config: const EconomySimulationConfig(
        turns: 1,
        ruleset: _wonderSmokeGameRuleset,
        strategyOverride: _StartWonderStrategy(command),
      ),
    );

    expect(result.appliedCommands, isEmpty);
    final rejection = result.rejectedCommandRecords.single;
    expect(rejection.command, command);
    expect(rejection.reason, 'city_not_found');
  });
}

const _wonderSmokeGameRuleset = GameRuleset(
  city: CityRulesets.standard,
  technology: TechnologyRulesets.standard,
  paceBalance: PaceBalance.standard60,
  wonders: WonderRuleset(
    wonders: {
      WonderType.greatLibrary: WonderDefinition(
        type: WonderType.greatLibrary,
        productionCost: 20,
        unlockTech: TechnologyId.writing,
        requirements: [
          WonderHostTerrainRequirement({TerrainType.desert}),
        ],
      ),
    },
  ),
);

final class _StartWonderStrategy implements AiStrategy {
  const _StartWonderStrategy(this.command);

  final StartWonderCommand command;

  @override
  AiTurnPlan plan(GameView view, AiContext context) =>
      AiTurnPlan(commands: [command]);
}
