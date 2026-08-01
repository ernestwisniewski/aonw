import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'reducer_parity_fixture.dart';

part 'reducer_parity_combat_characterization_cases.dart';
part 'reducer_parity_combat_characterization_fixture.dart';
part 'reducer_parity_combat_characterization_oracle.dart';

abstract final class CombatReducerParityCharacterization {
  static List<ReducerParityFixture> extend(List<ReducerParityFixture> corpus) {
    final template = corpus.singleWhere(
      (fixture) => fixture.id == 'combat-visible-unit-accepted',
    );
    final characterization = [
      ..._combatRejectionCases(template),
      ..._combatAcceptanceCases(template),
    ];
    _requireExactCombatCharacterization(characterization);

    final ids = <String>{for (final fixture in corpus) fixture.id};
    for (final fixture in characterization) {
      if (!ids.add(fixture.id)) {
        throw StateError('Duplicate combat parity id: ${fixture.id}.');
      }
    }
    return List.unmodifiable([...corpus, ...characterization]);
  }

  static void validateForTest(List<ReducerParityFixture> fixtures) {
    _requireExactCombatCharacterization(fixtures);
  }
}

typedef _CombatRequirement = ({bool accepted, String? reason});

const _requiredCombatCharacterization = <String, _CombatRequirement>{
  'combat-characterization-attacker-missing-rejected': (
    accepted: false,
    reason: 'attacker_not_found',
  ),
  'combat-characterization-attacker-not-controlled-rejected': (
    accepted: false,
    reason: 'attacker_not_controlled',
  ),
  'combat-characterization-attacker-unavailable-rejected': (
    accepted: false,
    reason: 'attacker_unavailable',
  ),
  'combat-characterization-attacker-exhausted-rejected': (
    accepted: false,
    reason: 'attacker_exhausted',
  ),
  'combat-characterization-attacker-out-of-bounds-rejected': (
    accepted: false,
    reason: 'attacker_out_of_bounds',
  ),
  'combat-characterization-target-out-of-bounds-rejected': (
    accepted: false,
    reason: 'attack_target_out_of_bounds',
  ),
  'combat-characterization-attacker-cannot-attack-rejected': (
    accepted: false,
    reason: 'attacker_cannot_attack',
  ),
  'combat-characterization-target-missing-rejected': (
    accepted: false,
    reason: 'attack_target_not_found',
  ),
  'combat-characterization-target-not-enemy-rejected': (
    accepted: false,
    reason: 'attack_target_not_enemy',
  ),
  'combat-characterization-target-protected-by-treaty-rejected': (
    accepted: false,
    reason: 'attack_target_protected_by_treaty',
  ),
  'combat-characterization-target-not-visible-rejected': (
    accepted: false,
    reason: 'attack_target_not_visible',
  ),
  'combat-characterization-target-out-of-range-rejected': (
    accepted: false,
    reason: 'attack_target_out_of_range',
  ),
  'combat-characterization-unit-accepted': (accepted: true, reason: null),
  'combat-characterization-defended-city-unit-accepted': (
    accepted: true,
    reason: null,
  ),
  'combat-characterization-retreat-accepted': (accepted: true, reason: null),
  'combat-characterization-city-capture-accepted': (
    accepted: true,
    reason: null,
  ),
  'combat-characterization-city-destroy-accepted': (
    accepted: true,
    reason: null,
  ),
};

void _requireExactCombatCharacterization(List<ReducerParityFixture> fixtures) {
  final actualIds = {for (final fixture in fixtures) fixture.id};
  final requiredIds = _requiredCombatCharacterization.keys.toSet();
  if (actualIds.length != fixtures.length ||
      !actualIds.containsAll(requiredIds) ||
      !requiredIds.containsAll(actualIds)) {
    throw StateError('Combat parity characterization is incomplete.');
  }

  for (final fixture in fixtures) {
    final required = _requiredCombatCharacterization[fixture.id]!;
    final expectedState = _combatExpectedState(fixture.id, fixture.state);
    final expectedEvents = _combatExpectedEvents(fixture.id);
    if (fixture.family != 'combat' ||
        fixture.command is! AttackHexCommand ||
        fixture.expectedAccepted != required.accepted ||
        fixture.expectedReason != required.reason ||
        !_combatJsonEquals(
          fixture.expectedSave,
          reducerParitySave(fixture.save),
        ) ||
        !_combatJsonEquals(
          fixture.expectedState,
          CanonicalGameSnapshotCodec.encodeDomainState(expectedState),
        ) ||
        !_combatJsonEquals(
          fixture.expectedEvents,
          reducerParityEvents(expectedEvents),
        )) {
      throw StateError(
        'Combat parity characterization drifted: ${fixture.id}.',
      );
    }
  }
}

bool _combatJsonEquals(Object? left, Object? right) {
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final key in left.keys) {
      if (!right.containsKey(key) ||
          !_combatJsonEquals(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_combatJsonEquals(left[index], right[index])) return false;
    }
    return true;
  }
  return left == right;
}
