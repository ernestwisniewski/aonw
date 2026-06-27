import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/providers/language_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('follows the system locale by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = container.read(languageSettingsProvider);

    expect(settings.followsSystemLocale, isTrue);
    expect(settings.selectedLanguage, isNull);
    expect(settings.locale, isNull);
  });

  test('persists explicit language selections', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(languageSettingsProvider.notifier)
        .setLanguage(GameLanguage.spanish);

    final prefs = await SharedPreferences.getInstance();

    expect(
      container.read(languageSettingsProvider).selectedLanguage,
      GameLanguage.spanish,
    );
    expect(prefs.getString('language.locale'), 'es');
  });

  test('resolves supported system locales by language code', () {
    expect(
      resolveGameLocale(const [
        Locale('pl', 'PL'),
      ], AppLocalizations.supportedLocales),
      const Locale('pl'),
    );
  });

  test('falls back to English when the system locale is unsupported', () {
    expect(
      resolveGameLocale(const [
        Locale('fr', 'FR'),
      ], AppLocalizations.supportedLocales),
      const Locale('en'),
    );
  });
}
