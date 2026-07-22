import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'support/auto_explore_acceptance_characterization.dart';
part 'support/auto_explore_characterization_fixture.dart';
part 'support/auto_explore_characterization_oracle.dart';
part 'support/auto_explore_rejection_characterization.dart';

const _autoExploreResolver = PersistentUnitActionResolver();

PersistentUnitActionResult _resolveAutoExplore(
  PersistentGameState state,
  MapTraversalView map, {
  String unitId = _autoExploreUnitId,
  String actorPlayerId = _autoExploreActorId,
}) {
  return _autoExploreResolver.autoExploreUnit(
    state: state,
    command: AutoExploreUnitCommand(unitId),
    actorPlayerId: actorPlayerId,
    mapData: map,
  );
}

void main() {
  _registerAutoExploreRejectionCharacterizationTests();
  _registerAutoExploreAcceptanceCharacterizationTests();

  test('manual expectation sources cannot call production calculators', () {
    final sources = [
      File('test/game/support/auto_explore_characterization_fixture.dart'),
      File('test/game/support/auto_explore_characterization_oracle.dart'),
    ];
    const forbidden = [
      'PersistentUnitActionResolver',
      'PersistentMoveUnitResolver',
      'ScoutAutoExplorePlanner',
      'MovementCommandResolver',
      'UnitMovementPathfinder',
      'FogOfWarService',
      'FogRevealCalculator',
      'DiplomaticContact',
    ];
    for (final source in sources) {
      final contents = source.readAsStringSync();
      for (final token in forbidden) {
        expect(contents, isNot(contains(token)), reason: source.path);
      }
    }
  });
}
