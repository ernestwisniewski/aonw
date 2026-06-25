import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameTextScale {
  standard('standard', 1.0),
  large('large', 1.15),
  extraLarge('extra_large', 1.3);

  final String storageValue;
  final double factor;

  const GameTextScale(this.storageValue, this.factor);

  static GameTextScale fromStorageValue(String? value) {
    for (final scale in values) {
      if (scale.storageValue == value) return scale;
    }
    return GameTextScale.standard;
  }
}

class AccessibilitySettings {
  final GameTextScale textScale;

  const AccessibilitySettings({this.textScale = GameTextScale.standard});

  double get textScaleFactor => textScale.factor;

  AccessibilitySettings copyWith({GameTextScale? textScale}) {
    return AccessibilitySettings(textScale: textScale ?? this.textScale);
  }
}

final accessibilitySettingsProvider =
    NotifierProvider<AccessibilitySettingsController, AccessibilitySettings>(
      AccessibilitySettingsController.new,
    );

class AccessibilitySettingsController extends Notifier<AccessibilitySettings> {
  static const _textScaleKey = 'accessibility.text_scale';

  GameTextScale? _pendingTextScale;

  @override
  AccessibilitySettings build() {
    unawaited(_load());
    return const AccessibilitySettings();
  }

  void setTextScale(GameTextScale textScale) {
    if (state.textScale == textScale) return;
    _pendingTextScale = textScale;
    state = state.copyWith(textScale: textScale);
    unawaited(_saveTextScale(textScale));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_pendingTextScale != null) return;
      final stored = GameTextScale.fromStorageValue(
        prefs.getString(_textScaleKey),
      );
      state = state.copyWith(textScale: stored);
    } on Object {
      return;
    }
  }

  Future<void> _saveTextScale(GameTextScale textScale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_textScaleKey, textScale.storageValue);
      if (_pendingTextScale == textScale) _pendingTextScale = null;
    } on Object {
      return;
    }
  }
}
