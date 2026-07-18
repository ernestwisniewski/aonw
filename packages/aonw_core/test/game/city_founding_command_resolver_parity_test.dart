import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'city_founding_command_resolver_parity_test_support.dart';

void main() {
  group('city founding kernel/persistent/domain parity', () {
    test('accepted command has exact state-boundary parity', () {
      final matchingDraft = _parityDraft(_founderId);
      final before = _parityStates(cityFoundingDraft: matchingDraft);

      final results = _resolveParity(before);

      _expectAcceptedParity(before, results);
      expect(results.kernel.cityFoundingDraft, isNull);
      expect(results.persistent.state.runtimeState.cityFoundingDraft, isNull);
      expect(results.domain.interaction.cityFoundingDraft, isNull);
      expect(
        identical(
          results.domain.interaction.pendingAction,
          before.interaction.pendingAction,
        ),
        isTrue,
      );
      expect(
        identical(
          results.persistent.state.runtimeState.pendingAction,
          before.persistent.runtimeState.pendingAction,
        ),
        isTrue,
      );
    });

    test('accepted command preserves an unrelated interaction draft', () {
      final unrelatedDraft = _parityDraft('unrelated_settler');
      final before = _parityStates(cityFoundingDraft: unrelatedDraft);

      final results = _resolveParity(before);

      _expectAcceptedParity(before, results);
      expect(
        identical(
          results.kernel.cityFoundingDraft,
          before.interaction.cityFoundingDraft,
        ),
        isTrue,
      );
      expect(identical(results.domain.interaction, before.interaction), isTrue);
      expect(
        identical(
          results.persistent.state.runtimeState,
          before.persistent.runtimeState,
        ),
        isTrue,
      );
    });

    test('reject preserves every input boundary identity', () {
      final before = _parityStates(cityFoundingDraft: _parityDraft(_founderId));

      final results = _resolveParity(before, actorPlayerId: _otherPlayerId);

      expect(results.kernel.accepted, isFalse);
      expect(results.persistent.accepted, isFalse);
      expect(results.domain.accepted, isFalse);
      expect(results.kernel.reason, 'city_founder_not_controlled');
      expect(results.persistent.reason, results.kernel.reason);
      expect(results.domain.reason, results.kernel.reason);
      expect(identical(results.kernel.units, before.domain.units), isTrue);
      expect(
        identical(
          results.kernel.cityFoundingDraft,
          before.interaction.cityFoundingDraft,
        ),
        isTrue,
      );
      expect(identical(results.persistent.state, before.persistent), isTrue);
      expect(identical(results.domain.state, before.domain), isTrue);
      expect(identical(results.domain.interaction, before.interaction), isTrue);
      expect(results.persistent.events, isEmpty);
    });
  });
}
