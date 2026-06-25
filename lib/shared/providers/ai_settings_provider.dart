import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiSettings {
  const AiSettings({this.batterySaver = false});

  final bool batterySaver;

  AiSettings copyWith({bool? batterySaver}) {
    return AiSettings(batterySaver: batterySaver ?? this.batterySaver);
  }
}

final aiSettingsProvider = NotifierProvider<AiSettingsController, AiSettings>(
  AiSettingsController.new,
);

class AiSettingsController extends Notifier<AiSettings> {
  static const _batterySaverKey = 'ai.battery_saver';

  bool? _pendingBatterySaver;

  @override
  AiSettings build() {
    unawaited(_load());
    return const AiSettings();
  }

  void setBatterySaver(bool batterySaver) {
    if (state.batterySaver == batterySaver) return;
    _pendingBatterySaver = batterySaver;
    state = state.copyWith(batterySaver: batterySaver);
    unawaited(_saveBatterySaver(batterySaver));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_pendingBatterySaver != null) return;
      state = state.copyWith(
        batterySaver: prefs.getBool(_batterySaverKey) ?? state.batterySaver,
      );
    } on Object {
      return;
    }
  }

  Future<void> _saveBatterySaver(bool batterySaver) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_batterySaverKey, batterySaver);
      if (_pendingBatterySaver == batterySaver) _pendingBatterySaver = null;
    } on Object {
      return;
    }
  }
}
