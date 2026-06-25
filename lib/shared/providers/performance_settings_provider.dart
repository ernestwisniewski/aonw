import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceSettings {
  const PerformanceSettings({this.showFps = false, this.showMapZoom = false});

  final bool showFps;
  final bool showMapZoom;

  PerformanceSettings copyWith({bool? showFps, bool? showMapZoom}) {
    return PerformanceSettings(
      showFps: showFps ?? this.showFps,
      showMapZoom: showMapZoom ?? this.showMapZoom,
    );
  }
}

final performanceSettingsProvider =
    NotifierProvider<PerformanceSettingsController, PerformanceSettings>(
      PerformanceSettingsController.new,
    );

final mapZoomDebugProvider = NotifierProvider<MapZoomDebugController, double?>(
  MapZoomDebugController.new,
);

class MapZoomDebugController extends Notifier<double?> {
  @override
  double? build() => null;

  void setZoom(double? zoom) {
    if (state == zoom) return;
    state = zoom;
  }

  void clear() => setZoom(null);
}

class PerformanceSettingsController extends Notifier<PerformanceSettings> {
  static const _showFpsKey = 'performance.show_fps';
  static const _showMapZoomKey = 'performance.show_map_zoom';

  bool? _pendingShowFps;
  bool? _pendingShowMapZoom;

  @override
  PerformanceSettings build() {
    unawaited(_load());
    return const PerformanceSettings();
  }

  void setShowFps(bool showFps) {
    if (state.showFps == showFps) return;
    _pendingShowFps = showFps;
    state = state.copyWith(showFps: showFps);
    unawaited(_saveShowFps(showFps));
  }

  void setShowMapZoom(bool showMapZoom) {
    if (state.showMapZoom == showMapZoom) return;
    _pendingShowMapZoom = showMapZoom;
    state = state.copyWith(showMapZoom: showMapZoom);
    unawaited(_saveShowMapZoom(showMapZoom));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_pendingShowFps != null || _pendingShowMapZoom != null) {
        return;
      }
      state = state.copyWith(
        showFps: prefs.getBool(_showFpsKey) ?? state.showFps,
        showMapZoom: prefs.getBool(_showMapZoomKey) ?? state.showMapZoom,
      );
    } on Object {
      return;
    }
  }

  Future<void> _saveShowFps(bool showFps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showFpsKey, showFps);
      if (_pendingShowFps == showFps) _pendingShowFps = null;
    } on Object {
      return;
    }
  }

  Future<void> _saveShowMapZoom(bool showMapZoom) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showMapZoomKey, showMapZoom);
      if (_pendingShowMapZoom == showMapZoom) _pendingShowMapZoom = null;
    } on Object {
      return;
    }
  }
}
