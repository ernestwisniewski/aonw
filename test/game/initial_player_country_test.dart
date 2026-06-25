import 'dart:math' as math;

import 'package:aonw/game/presentation/screens/initial_player_country.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedRandom implements math.Random {
  const _FixedRandom(this.value);

  final int value;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => value % max;
}

void main() {
  group('initial player country', () {
    test('picks a country from the random index', () {
      expect(
        randomInitialPlayerCountry(
          random: _FixedRandom(PlayerCountry.france.index),
        ),
        PlayerCountry.france,
      );
    });

    test('parses explicit country names and leaves missing values unset', () {
      expect(playerCountryFromName('japan'), PlayerCountry.japan);
      expect(playerCountryFromName(null), isNull);
      expect(playerCountryFromName(''), isNull);
      expect(playerCountryFromName('unknown'), isNull);
    });
  });
}
