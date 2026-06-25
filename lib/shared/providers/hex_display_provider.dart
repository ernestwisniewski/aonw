import 'dart:async';

import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/rendering/map_palette.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'hex_display_provider.g.dart';

class HexDisplaySettings {
  static const defaultHexBorderColor = Color(0x00000000);
  static const defaultSelectedHexColor = HudPalette.goldLight;
  static const defaultWallTintColor = Color(0x00000000);

  final bool showHeightBadge;
  final bool showTerrain;
  final bool showResources;
  final bool showCitySites;
  final bool showCityGrowth;
  final Color hexBorderColor;
  final Color selectedHexColor;
  final Color wallTintColor;

  const HexDisplaySettings({
    this.showHeightBadge = false,
    this.showTerrain = false,
    this.showResources = true,
    this.showCitySites = false,
    this.showCityGrowth = false,
    this.hexBorderColor = defaultHexBorderColor,
    this.selectedHexColor = defaultSelectedHexColor,
    this.wallTintColor = defaultWallTintColor,
  });

  bool get hexOverlayVisible =>
      (hexBorderColor.toARGB32() & 0xFF000000) != 0 ||
      (wallTintColor.toARGB32() & 0xFF000000) != 0;

  bool get hexBordersVisible => (hexBorderColor.toARGB32() & 0xFF000000) != 0;

  bool get heightWallsVisible => (wallTintColor.toARGB32() & 0xFF000000) != 0;

  HexDisplaySettings copyWith({
    bool? showHeightBadge,
    bool? showTerrain,
    bool? showResources,
    bool? showCitySites,
    bool? showCityGrowth,
    Color? hexBorderColor,
    Color? selectedHexColor,
    Color? wallTintColor,
  }) => HexDisplaySettings(
    showHeightBadge: showHeightBadge ?? this.showHeightBadge,
    showTerrain: showTerrain ?? this.showTerrain,
    showResources: showResources ?? this.showResources,
    showCitySites: showCitySites ?? this.showCitySites,
    showCityGrowth: showCityGrowth ?? this.showCityGrowth,
    hexBorderColor: hexBorderColor ?? this.hexBorderColor,
    selectedHexColor: selectedHexColor ?? this.selectedHexColor,
    wallTintColor: wallTintColor ?? this.wallTintColor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HexDisplaySettings &&
          showHeightBadge == other.showHeightBadge &&
          showTerrain == other.showTerrain &&
          showResources == other.showResources &&
          showCitySites == other.showCitySites &&
          showCityGrowth == other.showCityGrowth &&
          hexBorderColor == other.hexBorderColor &&
          selectedHexColor == other.selectedHexColor &&
          wallTintColor == other.wallTintColor;

  @override
  int get hashCode => Object.hash(
    showHeightBadge,
    showTerrain,
    showResources,
    showCitySites,
    showCityGrowth,
    hexBorderColor,
    selectedHexColor,
    wallTintColor,
  );
}

abstract final class HexDisplayPreferenceKeys {
  static const defaultHexBorderColor = 'hex_display.default.hex_border_color';
  static const defaultWallTintColor = 'hex_display.default.wall_tint_color';

  static String hexBorderColorForMap(MapSelection selection) =>
      '${_prefix(selection)}.hex_border_color';

  static String wallTintColorForMap(MapSelection selection) =>
      '${_prefix(selection)}.wall_tint_color';

  static String _prefix(MapSelection selection) {
    final mapName = Uri.encodeComponent(selection.name);
    return 'hex_display.map.${selection.source.name}.$mapName';
  }
}

final hexDisplayDefaultsBootstrapProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  await ref.read(hexDisplayProvider.notifier).loadStandardColors();
});

final hexDisplayMapBootstrapProvider = FutureProvider.autoDispose
    .family<void, MapSelection>((ref, selection) async {
      await ref.read(hexDisplayProvider.notifier).loadMapColors(selection);
    });

@riverpod
class HexDisplayNotifier extends _$HexDisplayNotifier {
  final Map<String, int> _pendingColorSaves = {};

  @override
  HexDisplaySettings build() => const HexDisplaySettings();

  void toggleHeightBadge() =>
      state = state.copyWith(showHeightBadge: !state.showHeightBadge);

  void toggleTerrain() =>
      state = state.copyWith(showTerrain: !state.showTerrain);

  void toggleResources() =>
      state = state.copyWith(showResources: !state.showResources);

  void toggleCitySites() =>
      state = state.copyWith(showCitySites: !state.showCitySites);

  void toggleCityGrowth() =>
      state = state.copyWith(showCityGrowth: !state.showCityGrowth);

  void setHexBorderColor(Color color) {
    state = state.copyWith(hexBorderColor: color);
    unawaited(
      _saveColor(HexDisplayPreferenceKeys.defaultHexBorderColor, color),
    );
  }

  void setSelectedHexColor(Color color) =>
      state = state.copyWith(selectedHexColor: color);

  void setWallTintColor(Color color) {
    state = state.copyWith(wallTintColor: color);
    unawaited(_saveColor(HexDisplayPreferenceKeys.defaultWallTintColor, color));
  }

  Future<void> loadStandardColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      state = state.copyWith(
        hexBorderColor: _standardHexBorderColor(prefs),
        wallTintColor: _standardWallTintColor(prefs),
      );
    } on Object {
      return;
    }
  }

  Future<void> loadMapColors(MapSelection selection) async {
    final borderKey = HexDisplayPreferenceKeys.hexBorderColorForMap(selection);
    final wallKey = HexDisplayPreferenceKeys.wallTintColorForMap(selection);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      final standardBorder = _standardHexBorderColor(prefs);
      final standardWall = _standardWallTintColor(prefs);
      state = state.copyWith(
        hexBorderColor: _storedColor(
          _pendingColorSaves[borderKey] ?? prefs.getInt(borderKey),
          standardBorder,
        ),
        wallTintColor: _storedColor(
          _pendingColorSaves[wallKey] ?? prefs.getInt(wallKey),
          standardWall,
        ),
      );
    } on Object {
      return;
    }
  }

  Future<void> setHexBorderColorForMap(
    MapSelection selection,
    Color color,
  ) async {
    state = state.copyWith(hexBorderColor: color);
    await _saveColor(
      HexDisplayPreferenceKeys.hexBorderColorForMap(selection),
      color,
    );
  }

  Future<void> resetHexBorderColorForMap(MapSelection selection) async {
    final key = HexDisplayPreferenceKeys.hexBorderColorForMap(selection);
    _pendingColorSaves.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      if (!ref.mounted) return;
      state = state.copyWith(hexBorderColor: _standardHexBorderColor(prefs));
    } on Object {
      state = state.copyWith(
        hexBorderColor: HexDisplaySettings.defaultHexBorderColor,
      );
    }
  }

  Future<void> setWallTintColorForMap(
    MapSelection selection,
    Color color,
  ) async {
    state = state.copyWith(wallTintColor: color);
    await _saveColor(
      HexDisplayPreferenceKeys.wallTintColorForMap(selection),
      color,
    );
  }

  Future<void> setHexBordersVisibleForMap(
    MapSelection selection,
    bool visible,
  ) async {
    final borderKey = HexDisplayPreferenceKeys.hexBorderColorForMap(selection);
    final borderColor = visible
        ? const Color(0xFF000000)
        : HexDisplaySettings.defaultHexBorderColor;
    state = state.copyWith(hexBorderColor: borderColor);
    await _saveColor(borderKey, borderColor);
  }

  Future<void> setHeightWallsVisibleForMap(
    MapSelection selection,
    bool visible,
  ) async {
    final wallKey = HexDisplayPreferenceKeys.wallTintColorForMap(selection);
    final wallColor = visible
        ? _withAlpha(
            _nonTransparentBase(
              state.wallTintColor,
              fallback: MapPalette.defaultWallTint,
            ),
            255,
          )
        : HexDisplaySettings.defaultWallTintColor;
    state = state.copyWith(wallTintColor: wallColor);
    await _saveColor(wallKey, wallColor);
  }

  Future<void> resetWallTintColorForMap(MapSelection selection) async {
    final key = HexDisplayPreferenceKeys.wallTintColorForMap(selection);
    _pendingColorSaves.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      if (!ref.mounted) return;
      state = state.copyWith(wallTintColor: _standardWallTintColor(prefs));
    } on Object {
      state = state.copyWith(
        wallTintColor: HexDisplaySettings.defaultWallTintColor,
      );
    }
  }

  Future<void> _saveColor(String key, Color color) async {
    final value = color.toARGB32();
    _pendingColorSaves[key] = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
      if (_pendingColorSaves[key] == value) {
        _pendingColorSaves.remove(key);
      }
    } on Object {
      return;
    }
  }

  Color _storedColor(int? value, Color fallback) {
    if (value == null) return fallback;
    return Color(value);
  }

  Color _nonTransparentBase(Color color, {required Color fallback}) {
    return (color.toARGB32() & 0xFF000000) == 0 ? fallback : color;
  }

  Color _withAlpha(Color color, int alpha) {
    return Color((alpha << 24) | (color.toARGB32() & 0x00FFFFFF));
  }

  Color _standardHexBorderColor(SharedPreferences prefs) {
    return _storedColor(
      _pendingColorSaves[HexDisplayPreferenceKeys.defaultHexBorderColor] ??
          prefs.getInt(HexDisplayPreferenceKeys.defaultHexBorderColor),
      HexDisplaySettings.defaultHexBorderColor,
    );
  }

  Color _standardWallTintColor(SharedPreferences prefs) {
    return _storedColor(
      _pendingColorSaves[HexDisplayPreferenceKeys.defaultWallTintColor] ??
          prefs.getInt(HexDisplayPreferenceKeys.defaultWallTintColor),
      HexDisplaySettings.defaultWallTintColor,
    );
  }
}
