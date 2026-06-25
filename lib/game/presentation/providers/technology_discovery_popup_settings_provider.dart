import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TechnologyDiscoveryPopupSettings {
  final bool loaded;
  final bool showPopup;

  const TechnologyDiscoveryPopupSettings({
    required this.loaded,
    required this.showPopup,
  });

  const TechnologyDiscoveryPopupSettings.loading()
    : loaded = false,
      showPopup = true;

  TechnologyDiscoveryPopupSettings copyWith({bool? loaded, bool? showPopup}) {
    return TechnologyDiscoveryPopupSettings(
      loaded: loaded ?? this.loaded,
      showPopup: showPopup ?? this.showPopup,
    );
  }
}

abstract final class TechnologyDiscoveryPopupSettingsKey {
  static String forSave(String saveId) {
    return 'game.$saveId.technology_discovery_popup.show';
  }

  static String forSavePlayer(String saveId, String playerId) {
    return 'game.$saveId.player.$playerId.technology_discovery_popup.show';
  }
}

final technologyDiscoveryPopupSettingsProvider =
    NotifierProvider.family<
      TechnologyDiscoveryPopupSettingsController,
      TechnologyDiscoveryPopupSettings,
      String
    >(TechnologyDiscoveryPopupSettingsController.new);

class TechnologyDiscoveryPopupSettingsController
    extends Notifier<TechnologyDiscoveryPopupSettings> {
  final String preferenceKey;

  TechnologyDiscoveryPopupSettingsController(this.preferenceKey);

  bool? _pendingShowPopup;

  @override
  TechnologyDiscoveryPopupSettings build() {
    unawaited(_load());
    return const TechnologyDiscoveryPopupSettings.loading();
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
      state = TechnologyDiscoveryPopupSettings(
        loaded: true,
        showPopup: prefs.getBool(preferenceKey) ?? true,
      );
    } on Object {
      if (!ref.mounted) return;
      state = const TechnologyDiscoveryPopupSettings(
        loaded: true,
        showPopup: true,
      );
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
