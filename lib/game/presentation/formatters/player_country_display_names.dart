import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/player.dart';

abstract final class PlayerCountryDisplayNames {
  static String country(AppLocalizations l10n, PlayerCountry country) {
    return switch (country) {
      PlayerCountry.poland => l10n.countryPoland,
      PlayerCountry.ukraine => l10n.countryUkraine,
      PlayerCountry.germany => l10n.countryGermany,
      PlayerCountry.france => l10n.countryFrance,
      PlayerCountry.unitedKingdom => l10n.countryUnitedKingdom,
      PlayerCountry.italy => l10n.countryItaly,
      PlayerCountry.spain => l10n.countrySpain,
      PlayerCountry.netherlands => l10n.countryNetherlands,
      PlayerCountry.sweden => l10n.countrySweden,
      PlayerCountry.russia => l10n.countryRussia,
      PlayerCountry.unitedStates => l10n.countryUnitedStates,
      PlayerCountry.canada => l10n.countryCanada,
      PlayerCountry.china => l10n.countryChina,
      PlayerCountry.korea => l10n.countryKorea,
      PlayerCountry.japan => l10n.countryJapan,
      PlayerCountry.portugal => l10n.countryPortugal,
      PlayerCountry.india => l10n.countryIndia,
      PlayerCountry.brazil => l10n.countryBrazil,
      PlayerCountry.indonesia => l10n.countryIndonesia,
      PlayerCountry.mexico => l10n.countryMexico,
      PlayerCountry.turkey => l10n.countryTurkey,
      PlayerCountry.saudiArabia => l10n.countrySaudiArabia,
      PlayerCountry.egypt => l10n.countryEgypt,
      PlayerCountry.greece => l10n.countryGreece,
    };
  }

  static List<PlayerCountry> sorted(
    AppLocalizations l10n, {
    Iterable<PlayerCountry> countries = PlayerCountry.values,
  }) {
    return countries.toList()..sort((left, right) {
      final byName = country(
        l10n,
        left,
      ).toLowerCase().compareTo(country(l10n, right).toLowerCase());
      if (byName != 0) return byName;
      return left.name.compareTo(right.name);
    });
  }

  static String leader(AppLocalizations l10n, PlayerCountry country) {
    return switch (country) {
      PlayerCountry.poland => l10n.countryLeaderPoland,
      PlayerCountry.ukraine => l10n.countryLeaderUkraine,
      PlayerCountry.germany => l10n.countryLeaderGermany,
      PlayerCountry.france => l10n.countryLeaderFrance,
      PlayerCountry.unitedKingdom => l10n.countryLeaderUnitedKingdom,
      PlayerCountry.italy => l10n.countryLeaderItaly,
      PlayerCountry.spain => l10n.countryLeaderSpain,
      PlayerCountry.netherlands => l10n.countryLeaderNetherlands,
      PlayerCountry.sweden => l10n.countryLeaderSweden,
      PlayerCountry.russia => l10n.countryLeaderRussia,
      PlayerCountry.unitedStates => l10n.countryLeaderUnitedStates,
      PlayerCountry.canada => l10n.countryLeaderCanada,
      PlayerCountry.china => l10n.countryLeaderChina,
      PlayerCountry.korea => l10n.countryLeaderKorea,
      PlayerCountry.japan => l10n.countryLeaderJapan,
      PlayerCountry.portugal => l10n.countryLeaderPortugal,
      PlayerCountry.india => l10n.countryLeaderIndia,
      PlayerCountry.brazil => l10n.countryLeaderBrazil,
      PlayerCountry.indonesia => l10n.countryLeaderIndonesia,
      PlayerCountry.mexico => l10n.countryLeaderMexico,
      PlayerCountry.turkey => l10n.countryLeaderTurkey,
      PlayerCountry.saudiArabia => l10n.countryLeaderSaudiArabia,
      PlayerCountry.egypt => l10n.countryLeaderEgypt,
      PlayerCountry.greece => l10n.countryLeaderGreece,
    };
  }
}
