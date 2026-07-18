import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'city_expansion_command_resolver_parity_test_support.dart';

void main() {
  group('city expansion persistent/domain adapter parity', () {
    test('selection has exact state-boundary parity', () {
      final states = _expansionStates(
        city: _parityCity(maxHexes: 2),
        research: _urbanizationResearch(),
      );

      final results = _resolveBoth(states);

      expect(results.persistent.accepted, isTrue);
      expect(results.domain.accepted, isTrue);
      expect(results.persistent.reason, isNull);
      expect(results.domain.reason, isNull);
      expect(results.persistent.state.cities, results.domain.state.cities);
      expect(
        results.persistent.state,
        states.persistent.copyWith(cities: results.persistent.state.cities),
      );
      expect(
        results.domain.state,
        states.domain.copyWith(cities: results.domain.state.cities),
      );
      expect(
        results.persistent.state.cities.first.preferredExpansionHex,
        const CityHex(col: 1, row: 2),
      );
      expect(
        identical(
          results.persistent.state.runtimeState,
          states.persistent.runtimeState,
        ),
        isTrue,
      );
      expect(
        identical(results.domain.state.research, states.domain.research),
        isTrue,
      );
      expect(
        identical(
          results.persistent.state.cities.last,
          states.persistent.cities.last,
        ),
        isTrue,
      );
      expect(
        identical(results.domain.state.cities.last, states.domain.cities.last),
        isTrue,
      );
    });

    test('reject preserves both complete state identities', () {
      final states = _expansionStates(city: _parityCity());

      final results = _resolveBoth(states, actorPlayerId: _otherPlayerId);

      expect(results.persistent.accepted, isFalse);
      expect(results.domain.accepted, isFalse);
      expect(results.persistent.reason, 'city_not_controlled');
      expect(results.domain.reason, 'city_not_controlled');
      expect(identical(results.persistent.state, states.persistent), isTrue);
      expect(identical(results.domain.state, states.domain), isTrue);
    });

    test('accepted semantic no-op preserves both state identities', () {
      final states = _expansionStates(
        city: _parityCity(preferredExpansionHex: const CityHex(col: 1, row: 2)),
      );

      final results = _resolveBoth(states);

      expect(results.persistent.accepted, isTrue);
      expect(results.domain.accepted, isTrue);
      expect(identical(results.persistent.state, states.persistent), isTrue);
      expect(identical(results.domain.state, states.domain), isTrue);
    });
  });
}
