import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CivilizationMetPopupSettings {
  final bool loaded;
  final bool showPopup;

  const CivilizationMetPopupSettings({
    required this.loaded,
    required this.showPopup,
  });

  const CivilizationMetPopupSettings.loading()
    : loaded = false,
      showPopup = true;

  CivilizationMetPopupSettings copyWith({bool? loaded, bool? showPopup}) {
    return CivilizationMetPopupSettings(
      loaded: loaded ?? this.loaded,
      showPopup: showPopup ?? this.showPopup,
    );
  }
}

abstract final class CivilizationMetPopupSettingsKey {
  static String forSavePlayer(String saveId, String playerId) {
    return 'game.$saveId.player.$playerId.civilization_met_popup.show';
  }
}

final civilizationMetPopupSettingsProvider =
    NotifierProvider.family<
      CivilizationMetPopupSettingsController,
      CivilizationMetPopupSettings,
      String
    >(CivilizationMetPopupSettingsController.new);

class CivilizationMetPopupSettingsController
    extends Notifier<CivilizationMetPopupSettings> {
  final String preferenceKey;

  CivilizationMetPopupSettingsController(this.preferenceKey);

  bool? _pendingShowPopup;

  @override
  CivilizationMetPopupSettings build() {
    unawaited(_load());
    return const CivilizationMetPopupSettings.loading();
  }

  void setShowPopup(bool value) {
    if (state.loaded && state.showPopup == value) return;
    _pendingShowPopup = value;
    state = state.copyWith(loaded: true, showPopup: value);
    unawaited(_save(value));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted || _pendingShowPopup != null) return;
      state = CivilizationMetPopupSettings(
        loaded: true,
        showPopup: prefs.getBool(preferenceKey) ?? true,
      );
    } on Object {
      if (!ref.mounted) return;
      state = const CivilizationMetPopupSettings(loaded: true, showPopup: true);
    }
  }

  Future<void> _save(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(preferenceKey, value);
      if (_pendingShowPopup == value) _pendingShowPopup = null;
    } on Object {
      return;
    }
  }
}
