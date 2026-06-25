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

  static GameLanguage fromStorageValue(String? value) {
    for (final language in values) {
      if (language.storageValue == value) return language;
    }
    return GameLanguage.english;
  }
}

class LanguageSettings {
  final GameLanguage language;

  const LanguageSettings({this.language = GameLanguage.english});

  Locale get locale => language.locale;

  LanguageSettings copyWith({GameLanguage? language}) {
    return LanguageSettings(language: language ?? this.language);
  }
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
    if (state.language == language) return;
    _pendingLanguage = language;
    state = state.copyWith(language: language);
    unawaited(_saveLanguage(language));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_pendingLanguage != null) return;
      state = state.copyWith(
        language: GameLanguage.fromStorageValue(prefs.getString(_languageKey)),
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
