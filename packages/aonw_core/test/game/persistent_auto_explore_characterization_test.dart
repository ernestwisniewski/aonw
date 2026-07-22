import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'support/auto_explore_acceptance_characterization.dart';
part 'support/auto_explore_characterization_fixture.dart';
part 'support/auto_explore_characterization_oracle.dart';
part 'support/auto_explore_rejection_characterization.dart';

const _autoExploreResolver = PersistentAutoExploreCommandResolver();

PersistentAutoExploreCommandResult _resolveAutoExplore(
  PersistentGameState state,
  MapTraversalView map, {
  String unitId = _autoExploreUnitId,
  String actorPlayerId = _autoExploreActorId,
}) {
  return _autoExploreResolver.resolve(
    state: state,
    command: AutoExploreUnitCommand(unitId),
    actorPlayerId: actorPlayerId,
    mapData: map,
    phase: AutoExploreCommandPhase.direct,
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
      'PersistentAutoExploreCommandResolver',
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
