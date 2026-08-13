import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts without an initial strategic resource distribution', () {
    expect(GameClientState().initialResourceDistribution.placements, isEmpty);
  });

  test('replaces strategic resource production state atomically', () {
    final resources = StrategicResourceAccounts.empty.credit(
      'p1',
      StrategicResourceBundle.oilOne,
    );

    final updated = GameClientState().copyWith(strategicResources: resources);

    expect(updated.strategicResources, resources);
  });
}
