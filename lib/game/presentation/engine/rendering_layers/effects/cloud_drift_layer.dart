import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

part 'cloud_drift_rendering.dart';
part 'cloud_drift_spawning.dart';
part 'cloud_drift_visibility.dart';

class CloudDriftLayer extends PositionComponent with LayerAttachment {
  static const _defaultInitialDelay = (min: 10.0, max: 22.0);
  static const _defaultSpawnGap = (min: 38.0, max: 70.0);
  static const _defaultDuration = (min: 34.0, max: 52.0);
  static const _maxActiveClouds = 3;
  static const _cloudGroupChance = 0.28;
  static const _cloudClusterChance = 0.06;

  final math.Random _random;
  final ({double min, double max}) _spawnGapSeconds;
  final ({double min, double max}) _durationSeconds;
  final List<_Cloudlet> _clouds = [];
  bool _reduceMotion;
  double _spawnCountdown;
  WorldMap? _mapData;
  Path? _discoveredClipPath;
  Rect _mapBounds = Rect.zero;
  FogOfWarState? _lastVisibilityState;
  String? _lastVisibilityPlayerId;
  @visibleForTesting
  bool fastRendering = false;

  final Paint _hazePaint = Paint()
    ..isAntiAlias = true
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 14);
  final Paint _corePaint = Paint()
    ..isAntiAlias = true
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
  final Paint _shadowPaint = Paint()
    ..isAntiAlias = true
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 20);

  factory CloudDriftLayer({
    math.Random? random,
    bool reduceMotion = false,
    double? initialDelaySeconds,
    ({double min, double max})? spawnGapSeconds,
    ({double min, double max})? durationSeconds,
  }) {
    final resolvedRandom = random ?? math.Random();
    return CloudDriftLayer._(
      random: resolvedRandom,
      reduceMotion: reduceMotion,
      initialDelaySeconds:
          initialDelaySeconds ??
          _randomRange(resolvedRandom, _defaultInitialDelay),
      spawnGapSeconds: spawnGapSeconds ?? _defaultSpawnGap,
      durationSeconds: durationSeconds ?? _defaultDuration,
    );
  }

  CloudDriftLayer._({
    required math.Random random,
    required bool reduceMotion,
    required double initialDelaySeconds,
    required ({double min, double max}) spawnGapSeconds,
    required ({double min, double max}) durationSeconds,
  }) : _random = random,
       _reduceMotion = reduceMotion,
       _spawnGapSeconds = spawnGapSeconds,
       _durationSeconds = durationSeconds,
       _spawnCountdown = initialDelaySeconds {
    priority = MapPriority.cityManagementOverlay + 1;
  }

  bool get reduceMotion => _reduceMotion;

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    if (_reduceMotion) _clearClouds();
  }

  void sync({
    required Component parent,
    required WorldMap mapData,
    required FogVisibilityQuery visibility,
  }) {
    if (!visibility.isEnabled) {
      _clearClouds();
      _discoveredClipPath = null;
      _lastVisibilityState = null;
      _lastVisibilityPlayerId = null;
      removeFromParent();
      return;
    }

    ensureAttachedTo(parent);
    final mapChanged = !identical(_mapData, mapData);
    if (mapChanged) {
      _mapData = mapData;
      _mapBounds = _mapBoundsFor(mapData);
      size = Vector2(_mapBounds.width, _mapBounds.height);
      position = Vector2.zero();
      priority = _priorityFor(mapData);
    }
    if (!mapChanged &&
        _lastVisibilityPlayerId == visibility.playerId &&
        (identical(_lastVisibilityState, visibility.state) ||
            _lastVisibilityState == visibility.state)) {
      return;
    }
    _lastVisibilityState = visibility.state;
    _lastVisibilityPlayerId = visibility.playerId;
    final discoveredClip = _buildDiscoveredClip(
      mapData: mapData,
      visibility: visibility,
    );
    _discoveredClipPath = discoveredClip?.path;
    if (_discoveredClipPath == null) {
      _clearClouds();
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) => false;

  @override
  void update(double dt) {
    super.update(dt);
    if (_reduceMotion || _mapBounds.isEmpty || _discoveredClipPath == null) {
      _clearClouds();
      return;
    }

    final hadActiveClouds = _clouds.isNotEmpty;
    for (final cloud in _clouds) {
      cloud.elapsed += dt;
    }
    _clouds.removeWhere((cloud) => cloud.elapsed >= cloud.duration);

    if (_clouds.isNotEmpty) return;
    if (hadActiveClouds) return;

    _spawnCountdown -= dt;
    if (_spawnCountdown > 0) return;

    _spawnCloudlet();
    _spawnCountdown = _range(_spawnGapSeconds);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_reduceMotion || _clouds.isEmpty) return;
    final clipPath = _discoveredClipPath;
    if (clipPath == null) return;

    canvas
      ..save()
      ..clipPath(clipPath, doAntiAlias: true);
    for (final cloud in _clouds) {
      _renderCloud(canvas, cloud);
    }
    canvas.restore();
  }

  @visibleForTesting
  int get activeCloudCountForTesting => _clouds.length;

  @visibleForTesting
  double get spawnCountdownForTesting => _spawnCountdown;

  @visibleForTesting
  bool get hasDiscoveredClipForTesting => _discoveredClipPath != null;

  @visibleForTesting
  int get activePuffCountForTesting =>
      _clouds.isEmpty ? 0 : _clouds.first.puffs.length;

  @visibleForTesting
  double get activeCloudWidthForTesting =>
      _clouds.isEmpty ? 0 : _clouds.first.puffBounds.width;

  @visibleForTesting
  double get activeCloudTravelDistanceForTesting =>
      _clouds.isEmpty ? 0 : (_clouds.first.end - _clouds.first.start).length;

  @visibleForTesting
  double get mapWidthForTesting => _mapBounds.width;
}
