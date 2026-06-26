import 'dart:math' as math;

import 'package:aonw_core/game/domain/player.dart';

PlayerCountry randomInitialPlayerCountry({math.Random? random}) {
  const countries = PlayerCountry.values;
  return countries[(random ?? math.Random()).nextInt(countries.length)];
}

PlayerCountry? playerCountryFromName(String? value) {
  if (value == null || value.isEmpty) return null;
  for (final country in PlayerCountry.values) {
    if (country.name == value) return country;
  }
  return null;
}
