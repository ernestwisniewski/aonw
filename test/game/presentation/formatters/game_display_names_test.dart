import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/l10n/generated/app_localizations_pl.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameDisplayNames world artifacts', () {
    test('covers every artifact in Polish and English', () {
      final localizations = [AppLocalizationsPl(), AppLocalizationsEn()];

      for (final l10n in localizations) {
        for (final type in WorldArtifactType.values) {
          expect(GameDisplayNames.worldArtifact(l10n, type), isNotEmpty);
          expect(
            GameDisplayNames.worldArtifactShortBonus(l10n, type),
            isNotEmpty,
          );
          expect(
            GameDisplayNames.worldArtifactDescription(l10n, type),
            isNotEmpty,
          );
        }
      }
    });

    test('uses localized artifact names and bonuses', () {
      final pl = AppLocalizationsPl();
      final en = AppLocalizationsEn();

      expect(
        GameDisplayNames.worldArtifact(pl, WorldArtifactType.merchantsSeal),
        isNotEmpty,
      );
      expect(
        GameDisplayNames.worldArtifact(en, WorldArtifactType.merchantsSeal),
        "Merchant's Seal",
      );
      expect(
        GameDisplayNames.worldArtifactShortBonus(
          pl,
          WorldArtifactType.heroSword,
        ),
        isNotEmpty,
      );
      expect(
        GameDisplayNames.worldArtifactShortBonus(
          en,
          WorldArtifactType.heroSword,
        ),
        '+2 XP for produced units',
      );
    });
  });

  group('GameDisplayNames countries', () {
    test('sorts countries alphabetically by localized display name', () {
      final en = AppLocalizationsEn();

      expect(GameDisplayNames.sortedPlayerCountries(en), [
        PlayerCountry.canada,
        PlayerCountry.china,
        PlayerCountry.france,
        PlayerCountry.germany,
        PlayerCountry.italy,
        PlayerCountry.japan,
        PlayerCountry.korea,
        PlayerCountry.netherlands,
        PlayerCountry.poland,
        PlayerCountry.portugal,
        PlayerCountry.russia,
        PlayerCountry.spain,
        PlayerCountry.sweden,
        PlayerCountry.ukraine,
        PlayerCountry.unitedKingdom,
        PlayerCountry.unitedStates,
      ]);
    });

    test(
      'sorts filtered country options without adding unavailable values',
      () {
        final en = AppLocalizationsEn();

        expect(
          GameDisplayNames.sortedPlayerCountries(
            en,
            countries: const [
              PlayerCountry.poland,
              PlayerCountry.canada,
              PlayerCountry.germany,
            ],
          ),
          [PlayerCountry.canada, PlayerCountry.germany, PlayerCountry.poland],
        );
      },
    );

    test('localizes Russia and Catherine', () {
      final pl = AppLocalizationsPl();
      final en = AppLocalizationsEn();

      expect(
        GameDisplayNames.playerCountry(pl, PlayerCountry.russia),
        isNotEmpty,
      );
      expect(
        GameDisplayNames.playerCountryLeader(pl, PlayerCountry.russia),
        isNotEmpty,
      );
      expect(
        GameDisplayNames.playerCountry(en, PlayerCountry.russia),
        'Russia',
      );
      expect(
        GameDisplayNames.playerCountryLeader(en, PlayerCountry.russia),
        'Catherine the Great',
      );
    });

    test('localizes Portugal and Henry the Navigator', () {
      final pl = AppLocalizationsPl();
      final en = AppLocalizationsEn();

      expect(
        GameDisplayNames.playerCountry(pl, PlayerCountry.portugal),
        isNotEmpty,
      );
      expect(
        GameDisplayNames.playerCountryLeader(pl, PlayerCountry.portugal),
        isNotEmpty,
      );
      expect(
        GameDisplayNames.playerCountry(en, PlayerCountry.portugal),
        'Portugal',
      );
      expect(
        GameDisplayNames.playerCountryLeader(en, PlayerCountry.portugal),
        'Henry the Navigator',
      );
    });
  });

  group('GameDisplayNames diplomacy', () {
    test('localizes every relation status', () {
      final localizations = [AppLocalizationsPl(), AppLocalizationsEn()];

      for (final l10n in localizations) {
        for (final status in DiplomaticRelationStatus.values) {
          expect(GameDisplayNames.diplomaticRelation(l10n, status), isNotEmpty);
          expect(
            GameDisplayNames.diplomaticRelationShort(l10n, status),
            isNotEmpty,
          );
        }
      }
    });
  });

  group('GameDisplayNames units', () {
    test('localizes token default unit names', () {
      final pl = AppLocalizationsPl();
      final en = AppLocalizationsEn();
      final defaultWarrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.name,
        col: 0,
        row: 0,
      );
      final defaultScout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: GameUnitType.scout.defaultNameToken,
        col: 1,
        row: 0,
      );
      final namedWarrior = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Guard',
        col: 2,
        row: 0,
      );
      final languageFallbackWarrior = GameUnit(
        id: 'warrior_3',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 3,
        row: 0,
      );

      expect(GameDisplayNames.unit(pl, defaultWarrior), isNotEmpty);
      expect(GameDisplayNames.unit(pl, defaultScout), isNotEmpty);
      expect(GameDisplayNames.unit(en, defaultScout), 'Scout');
      expect(GameDisplayNames.unit(pl, namedWarrior), 'Guard');
      expect(GameDisplayNames.unit(pl, languageFallbackWarrior), 'Warrior');
      expect(GameDisplayNames.unitWithType(pl, defaultWarrior), isNotEmpty);
      expect(
        GameDisplayNames.unitWithType(pl, namedWarrior),
        contains('Guard'),
      );
    });

    test('localizes veterancy ranks', () {
      final pl = AppLocalizationsPl();
      final en = AppLocalizationsEn();

      expect(
        GameDisplayNames.unitVeterancyRank(pl, UnitVeterancyRank.seasoned),
        isNotEmpty,
      );
      expect(
        GameDisplayNames.unitVeterancyRank(en, UnitVeterancyRank.seasoned),
        'Seasoned',
      );
    });
  });
}
