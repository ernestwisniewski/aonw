import 'package:aonw_core/ai/civilization/civilization_profile.dart';
import 'package:aonw_core/ai/civilization/civilization_profiles.dart';
import 'package:aonw_core/game/domain/player.dart';

class CivilizationProfileRegistry {
  const CivilizationProfileRegistry();

  CivilizationProfile profileFor(PlayerCountry country) {
    final profile = CivilizationProfiles.all[country];
    if (profile == null) {
      throw StateError('No CivilizationProfile registered for $country');
    }
    return profile;
  }
}
