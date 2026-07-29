import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('forwards RushProduction engine rejection through simulation', () {
    const command = RushProductionCommand('city_1');
    final result = EconomySimulation.run(
      config: const EconomySimulationConfig(
        turns: 1,
        strategyOverride: _RushStrategy(command),
      ),
    );

    expect(result.appliedCommands, isEmpty);
    final rejection = result.rejectedCommandRecords.single;
    expect(rejection.command, command);
    expect(rejection.reason, 'city_not_found');
  });
}

final class _RushStrategy implements AiStrategy {
  const _RushStrategy(this.command);

  final RushProductionCommand command;

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    return AiTurnPlan(commands: [command]);
  }
}
