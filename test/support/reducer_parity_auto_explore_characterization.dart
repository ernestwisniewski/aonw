import 'package:aonw_core/domain.dart';

import 'reducer_parity_fixture.dart';

part 'reducer_parity_auto_explore_characterization_cases.dart';
part 'reducer_parity_auto_explore_characterization_fixture.dart';
part 'reducer_parity_auto_explore_characterization_oracle.dart';

abstract final class AutoExploreReducerParityCharacterization {
  static List<ReducerParityFixture> extend(List<ReducerParityFixture> corpus) {
    final template = corpus.singleWhere(
      (fixture) => fixture.id == 'auto-explore-adjacent-accepted',
    );
    final characterization = [
      ..._autoExploreRejectionCases(template),
      ..._autoExploreAcceptanceCases(template),
    ];
    _requireExactAutoExploreCharacterization(characterization);

    final ids = <String>{for (final fixture in corpus) fixture.id};
    for (final fixture in characterization) {
      if (!ids.add(fixture.id)) {
        throw StateError('Duplicate auto-explore parity id: ${fixture.id}.');
      }
    }
    return List.unmodifiable([...corpus, ...characterization]);
  }

  static void validateForTest(List<ReducerParityFixture> fixtures) {
    _requireExactAutoExploreCharacterization(fixtures);
  }
}

typedef _AutoExploreRequirement = ({bool accepted, String? reason});

const _requiredAutoExploreCharacterization = <String, _AutoExploreRequirement>{
  'auto-explore-characterization-unit-missing-rejected': (
    accepted: false,
    reason: 'unit_not_found',
  ),
  'auto-explore-characterization-wrong-actor-precedence-rejected': (
    accepted: false,
    reason: 'unit_not_controlled',
  ),
  'auto-explore-characterization-non-scout-precedence-rejected': (
    accepted: false,
    reason: 'unit_not_scout',
  ),
  'auto-explore-characterization-working-precedence-rejected': (
    accepted: false,
    reason: 'unit_busy',
  ),
  'auto-explore-characterization-fortified-precedence-rejected': (
    accepted: false,
    reason: 'unit_busy',
  ),
  'auto-explore-characterization-exhausted-precedence-rejected': (
    accepted: false,
    reason: 'unit_exhausted',
  ),
  'auto-explore-characterization-queued-path-rejected': (
    accepted: false,
    reason: 'unit_has_path',
  ),
  'auto-explore-characterization-partial-queued-accepted': (
    accepted: true,
    reason: null,
  ),
  'auto-explore-characterization-tie-break-accepted': (
    accepted: true,
    reason: null,
  ),
  'auto-explore-characterization-no-fog-accepted': (
    accepted: true,
    reason: null,
  ),
  'auto-explore-characterization-hidden-city-no-op-accepted': (
    accepted: true,
    reason: null,
  ),
  'auto-explore-characterization-contact-discovery-accepted': (
    accepted: true,
    reason: null,
  ),
};

void _requireExactAutoExploreCharacterization(
  List<ReducerParityFixture> fixtures,
) {
  final actualIds = {for (final fixture in fixtures) fixture.id};
  final requiredIds = _requiredAutoExploreCharacterization.keys.toSet();
  if (actualIds.length != fixtures.length ||
      !actualIds.containsAll(requiredIds) ||
      !requiredIds.containsAll(actualIds)) {
    throw StateError('Auto-explore parity characterization is incomplete.');
  }

  for (final fixture in fixtures) {
    final required = _requiredAutoExploreCharacterization[fixture.id]!;
    final expectedState = _autoExploreExpectedState(fixture.id, fixture.state);
    final expectedEvents = _autoExploreExpectedEvents(fixture.id);
    if (fixture.family != 'auto-explore' ||
        fixture.command is! AutoExploreUnitCommand ||
        fixture.expectedAccepted != required.accepted ||
        fixture.expectedReason != required.reason ||
        !_autoExploreJsonEquals(
          fixture.expectedSave,
          reducerParitySave(fixture.save),
        ) ||
        !_autoExploreJsonEquals(
          fixture.expectedState,
          expectedState.toJson(),
        ) ||
        !_autoExploreJsonEquals(
          fixture.expectedEvents,
          reducerParityEvents(expectedEvents),
        )) {
      throw StateError(
        'Auto-explore parity characterization drifted: ${fixture.id}.',
      );
    }
  }
}

bool _autoExploreJsonEquals(Object? left, Object? right) {
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final key in left.keys) {
      if (!right.containsKey(key) ||
          !_autoExploreJsonEquals(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_autoExploreJsonEquals(left[index], right[index])) return false;
    }
    return true;
  }
  return left == right;
}
