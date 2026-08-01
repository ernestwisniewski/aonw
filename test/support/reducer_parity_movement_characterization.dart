import 'package:aonw_core/domain.dart';

import 'reducer_parity_fixture.dart';

part 'reducer_parity_movement_characterization_cases.dart';
part 'reducer_parity_movement_characterization_fixture.dart';
part 'reducer_parity_movement_characterization_oracle.dart';

abstract final class MovementReducerParityCharacterization {
  static List<ReducerParityFixture> extend(List<ReducerParityFixture> corpus) {
    final template = corpus.singleWhere(
      (fixture) => fixture.id == 'movement-adjacent-accepted',
    );
    final characterization = [
      ..._movementRejectionCases(template),
      ..._movementAcceptanceCases(template),
    ];
    _requireExactMovementCharacterization(characterization);

    final ids = <String>{for (final fixture in corpus) fixture.id};
    for (final fixture in characterization) {
      if (!ids.add(fixture.id)) {
        throw StateError('Duplicate movement parity id: ${fixture.id}.');
      }
    }
    return List.unmodifiable([...corpus, ...characterization]);
  }

  static void validateForTest(List<ReducerParityFixture> fixtures) {
    _requireExactMovementCharacterization(fixtures);
  }
}

typedef _MovementRequirement = ({bool accepted, String? reason});

const _requiredMovementCharacterization = <String, _MovementRequirement>{
  'movement-characterization-unit-missing-rejected': (
    accepted: false,
    reason: 'unit_not_found',
  ),
  'movement-characterization-unit-working-rejected': (
    accepted: false,
    reason: 'unit_unavailable',
  ),
  'movement-characterization-fortified-rejected': (
    accepted: false,
    reason: 'unit_unavailable',
  ),
  'movement-characterization-merchant-rejected': (
    accepted: false,
    reason: 'unit_uses_trade_routes',
  ),
  'movement-characterization-current-tile-rejected': (
    accepted: false,
    reason: 'move_target_is_current_tile',
  ),
  'movement-characterization-foreign-city-rejected': (
    accepted: false,
    reason: 'move_target_is_foreign_city_center',
  ),
  'movement-characterization-visible-occupied-rejected': (
    accepted: false,
    reason: 'move_target_occupied',
  ),
  'movement-characterization-path-not-found-rejected': (
    accepted: false,
    reason: 'move_path_not_found',
  ),
  'movement-characterization-capacity-rejected': (
    accepted: false,
    reason: 'unit_movement_capacity_insufficient',
  ),
  'movement-characterization-invalid-origin-rejected': (
    accepted: false,
    reason: 'unit_out_of_bounds',
  ),
  'movement-characterization-far-hidden-rejected': (
    accepted: false,
    reason: 'move_path_not_found',
  ),
  'movement-characterization-no-fog-occupied-rejected': (
    accepted: false,
    reason: 'move_target_occupied',
  ),
  'movement-characterization-partial-queued-accepted': (
    accepted: true,
    reason: null,
  ),
  'movement-characterization-zero-movement-queued-accepted': (
    accepted: true,
    reason: null,
  ),
  'movement-characterization-hidden-target-no-op-accepted': (
    accepted: true,
    reason: null,
  ),
  'movement-characterization-hidden-intermediate-no-op-accepted': (
    accepted: true,
    reason: null,
  ),
  'movement-characterization-hidden-city-no-op-accepted': (
    accepted: true,
    reason: null,
  ),
  'movement-characterization-contact-discovery-accepted': (
    accepted: true,
    reason: null,
  ),
};

void _requireExactMovementCharacterization(
  List<ReducerParityFixture> fixtures,
) {
  final actualIds = {for (final fixture in fixtures) fixture.id};
  final requiredIds = _requiredMovementCharacterization.keys.toSet();
  if (actualIds.length != fixtures.length ||
      !actualIds.containsAll(requiredIds) ||
      !requiredIds.containsAll(actualIds)) {
    throw StateError('Movement parity characterization is incomplete.');
  }

  for (final fixture in fixtures) {
    final required = _requiredMovementCharacterization[fixture.id]!;
    final expectedState = _movementExpectedState(fixture.id, fixture.state);
    final expectedEvents = _movementExpectedEvents(fixture.id);
    if (fixture.family != 'movement' ||
        fixture.command is! MoveUnitCommand ||
        fixture.expectedAccepted != required.accepted ||
        fixture.expectedReason != required.reason ||
        !_movementJsonEquals(
          fixture.expectedSave,
          reducerParitySave(fixture.save),
        ) ||
        !_movementJsonEquals(
          fixture.expectedState,
          CanonicalGameSnapshotCodec.encodeDomainState(expectedState),
        ) ||
        !_movementJsonEquals(
          fixture.expectedEvents,
          reducerParityEvents(expectedEvents),
        )) {
      throw StateError(
        'Movement parity characterization drifted: ${fixture.id}.',
      );
    }
  }
}

bool _movementJsonEquals(Object? left, Object? right) {
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final key in left.keys) {
      if (!right.containsKey(key) ||
          !_movementJsonEquals(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_movementJsonEquals(left[index], right[index])) return false;
    }
    return true;
  }
  return left == right;
}
