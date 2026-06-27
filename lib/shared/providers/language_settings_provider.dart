import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameLanguage {
  polish('pl', Locale('pl')),
  english('en', Locale('en')),
  german('de', Locale('de')),
  spanish('es', Locale('es')),
  dutch('nl', Locale('nl'));

  final String storageValue;
  final Locale locale;

  const GameLanguage(this.storageValue, this.locale);

  static GameLanguage? fromStorageValue(String? value) {
    for (final language in values) {
      if (language.storageValue == value) return language;
    }
    return null;
  }

  static GameLanguage? fromLocale(Locale locale) {
    for (final language in values) {
      if (language.locale.languageCode == locale.languageCode) return language;
    }
    return null;
  }
}

const gameFallbackLocale = Locale('en');

Locale resolveGameLocale(
  Iterable<Locale>? preferredLocales,
  Iterable<Locale> supportedLocales, {
  Locale fallbackLocale = gameFallbackLocale,
}) {
  for (final locale in preferredLocales ?? const <Locale>[]) {
    final supported = _supportedLocaleFor(locale, supportedLocales);
    if (supported != null) return supported;
  }
  final supportedFallback = _supportedLocaleFor(
    fallbackLocale,
    supportedLocales,
  );
  if (supportedFallback != null) return supportedFallback;
  for (final supported in supportedLocales) {
    return supported;
  }
  return fallbackLocale;
}

Locale? _supportedLocaleFor(Locale locale, Iterable<Locale> supportedLocales) {
  for (final supported in supportedLocales) {
    if (supported.languageCode == locale.languageCode) return supported;
  }
  return null;
}

class LanguageSettings {
  final GameLanguage? selectedLanguage;

  const LanguageSettings({this.selectedLanguage});

  Locale? get locale => selectedLanguage?.locale;

  bool get followsSystemLocale => selectedLanguage == null;
}

final languageSettingsProvider =
    NotifierProvider<LanguageSettingsController, LanguageSettings>(
      LanguageSettingsController.new,
    );

class LanguageSettingsController extends Notifier<LanguageSettings> {
  static const _languageKey = 'language.locale';

  GameLanguage? _pendingLanguage;

  @override
  LanguageSettings build() {
    unawaited(_load());
    return const LanguageSettings();
  }

  void setLanguage(GameLanguage language) {
    if (state.selectedLanguage == language) return;
    _pendingLanguage = language;
    state = LanguageSettings(selectedLanguage: language);
    unawaited(_saveLanguage(language));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_pendingLanguage != null) return;
      state = LanguageSettings(
        selectedLanguage: GameLanguage.fromStorageValue(
          prefs.getString(_languageKey),
        ),
      );
    } on Object {
      return;
    }
  }

  Future<void> _saveLanguage(GameLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.storageValue);
      if (_pendingLanguage == language) _pendingLanguage = null;
    } on Object {
      return;
    }
  }
}
