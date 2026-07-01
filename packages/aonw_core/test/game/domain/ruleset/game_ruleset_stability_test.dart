import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:test/test.dart';

void main() {
  test('standard ruleset exposes stability rules', () {
    expect(GameRuleset.standard().stability, StabilityRuleset.standard);
    expect(GameRuleset.defaults.stability, StabilityRuleset.standard);
  });

  test('copyWith can replace stability rules', () {
    final stability = StabilityRuleset.standard.copyWith(baseOrder: 4);

    expect(
      GameRuleset.standard().copyWith(stability: stability).stability,
      stability,
    );
  });
}
