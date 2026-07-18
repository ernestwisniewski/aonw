import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('forwards exact StartUnit rejection reason through public API', () {
    const command = StartUnitProductionCommand(
      'missing_city',
      GameUnitType.warrior,
    );
    final result = EconomySimulation.run(
      config: const EconomySimulationConfig(
        turns: 1,
        strategyOverride: _StartUnitStrategy(command),
      ),
    );

    expect(result.appliedCommands, isEmpty);
    final rejection = result.rejectedCommandRecords.single;
    expect(rejection.command, command);
    expect(rejection.reason, 'city_not_found');
  });
}

final class _StartUnitStrategy implements AiStrategy {
  const _StartUnitStrategy(this.command);

  final StartUnitProductionCommand command;

  @override
  AiTurnPlan plan(GameView view, AiContext context) =>
      AiTurnPlan(commands: [command]);
}
