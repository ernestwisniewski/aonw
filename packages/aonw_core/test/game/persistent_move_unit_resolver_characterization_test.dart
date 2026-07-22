import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'support/persistent_move_unit_acceptance_characterization.dart';
part 'support/persistent_move_unit_characterization_fixture.dart';
part 'support/persistent_move_unit_rejection_characterization.dart';

const _moveResolver = PersistentMoveUnitResolver();

PersistentMoveUnitResult _resolveMove(
  PersistentGameState state,
  MoveUnitCommand command,
  MapTraversalView map, {
  String actorPlayerId = _moveActorId,
}) {
  return _moveResolver.resolve(
    state: state,
    command: command,
    actorPlayerId: actorPlayerId,
    mapData: map,
  );
}

void main() {
  _registerMoveRejectionCharacterizationTests();
  _registerMoveAcceptanceCharacterizationTests();
}
