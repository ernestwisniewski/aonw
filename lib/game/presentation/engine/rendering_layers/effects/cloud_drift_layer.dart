import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

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
  MapData? _mapData;
  Path? _discoveredClipPath;
  Rect _mapBounds = Rect.zero;

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
    required MapData mapData,
    required FogVisibilityQuery visibility,
  }) {
    if (!visibility.isEnabled) {
      _clearClouds();
      _discoveredClipPath = null;
      removeFromParent();
      return;
    }

    ensureAttachedTo(parent);
    if (!identical(_mapData, mapData)) {
      _mapData = mapData;
      _mapBounds = _mapBoundsFor(mapData);
      size = Vector2(_mapBounds.width, _mapBounds.height);
      position = Vector2.zero();
      priority = _priorityFor(mapData);
    }
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

  void _renderCloud(Canvas canvas, _Cloudlet cloud) {
    final progress = (cloud.elapsed / cloud.duration).clamp(0.0, 1.0);
    final opacity = math.sin(progress * math.pi) * cloud.opacity;
    if (opacity <= 0) return;

    final center = cloud.start + (cloud.end - cloud.start) * progress;
    final shadowAlpha = (opacity * 16).round().clamp(0, 255);
    final hazeAlpha = (opacity * 44).round().clamp(0, 255);
    final coreAlpha = (opacity * 34).round().clamp(0, 255);

    _shadowPaint.color = Color.fromARGB(shadowAlpha, 84, 91, 102);
    _hazePaint.color = Color.fromARGB(hazeAlpha, 235, 242, 247);
    _corePaint.color = Color.fromARGB(coreAlpha, 255, 255, 255);

    canvas
      ..save()
      ..translate(center.x, center.y)
      ..rotate(cloud.angle);

    for (final puff in cloud.puffs) {
      final rect = Rect.fromCenter(
        center: Offset(puff.x, puff.y),
        width: puff.width,
        height: puff.height,
      );
      canvas
        ..drawOval(rect.shift(const Offset(18, 22)), _shadowPaint)
        ..drawOval(rect, _hazePaint)
        ..drawOval(rect.deflate(puff.coreInset), _corePaint);
    }

    canvas.restore();
  }

  void _spawnCloudlet() {
    if (_clouds.length >= _maxActiveClouds) return;
    if (_discoveredClipPath == null || _mapBounds.isEmpty) return;

    const hexRadius = MapConfig.defaultHexRadius;
    final cloudWidth = hexRadius * (2.95 + _random.nextDouble() * 1.55);
    final cloudHeight = hexRadius * (1.15 + _random.nextDouble() * 0.65);
    final padding = cloudWidth + hexRadius * 1.4;
    final fromLeft = _random.nextBool();
    final startY =
        _mapBounds.top + _random.nextDouble() * math.max(1, _mapBounds.height);
    final endY =
        (startY + (-0.5 + _random.nextDouble()) * _mapBounds.height * 0.45)
            .clamp(
              _mapBounds.top - padding * 0.25,
              _mapBounds.bottom + padding * 0.25,
            )
            .toDouble();
    final start = Vector2(
      fromLeft ? _mapBounds.left - padding : _mapBounds.right + padding,
      startY,
    );
    final end = Vector2(
      fromLeft ? _mapBounds.right + padding : _mapBounds.left - padding,
      endY,
    );
    final duration = _range(_durationSeconds);

    _clouds.add(
      _createCloudlet(
        start: start,
        end: end,
        duration: duration,
        fromLeft: fromLeft,
        cloudWidth: cloudWidth,
        cloudHeight: cloudHeight,
      ),
    );
    _maybeSpawnCompanionCloudlets(
      start: start,
      end: end,
      duration: duration,
      fromLeft: fromLeft,
      cloudWidth: cloudWidth,
      cloudHeight: cloudHeight,
    );
  }

  _Cloudlet _createCloudlet({
    required Vector2 start,
    required Vector2 end,
    required double duration,
    required bool fromLeft,
    required double cloudWidth,
    required double cloudHeight,
    double opacityScale = 1,
    double initialDelayFraction = 0,
  }) {
    return _Cloudlet(
      start: start,
      end: end,
      duration: duration,
      angle: (fromLeft ? -0.05 : 0.05) + (-0.5 + _random.nextDouble()) * 0.12,
      opacity: (0.66 + _random.nextDouble() * 0.18) * opacityScale,
      puffs: _buildPuffs(cloudWidth: cloudWidth, cloudHeight: cloudHeight),
      elapsed: -duration * initialDelayFraction,
    );
  }

  void _maybeSpawnCompanionCloudlets({
    required Vector2 start,
    required Vector2 end,
    required double duration,
    required bool fromLeft,
    required double cloudWidth,
    required double cloudHeight,
  }) {
    if (_clouds.length >= _maxActiveClouds) return;
    final groupRoll = _random.nextDouble();
    if (groupRoll >= _cloudGroupChance) return;

    final companionCount = groupRoll < _cloudClusterChance ? 2 : 1;
    final travel = end - start;
    final travelLength = travel.length;
    final direction = travelLength <= 0
        ? Vector2(1, 0)
        : Vector2(travel.x / travelLength, travel.y / travelLength);
    final normal = Vector2(-direction.y, direction.x);

    for (var i = 0; i < companionCount; i++) {
      if (_clouds.length >= _maxActiveClouds) return;
      final side = i.isEven ? 1.0 : -1.0;
      final along =
          cloudWidth *
          (0.34 + _random.nextDouble() * 0.52) *
          (_random.nextBool() ? 1 : -1);
      final across = side * cloudHeight * (0.72 + _random.nextDouble() * 0.74);
      final offset = Vector2(
        direction.x * along + normal.x * across,
        direction.y * along + normal.y * across,
      );
      final widthScale = 0.58 + _random.nextDouble() * 0.24;
      final heightScale = 0.70 + _random.nextDouble() * 0.22;
      final durationScale = 0.96 + _random.nextDouble() * 0.12;
      final opacityScale = 0.70 + _random.nextDouble() * 0.18;
      final delay = 0.03 + _random.nextDouble() * 0.08;

      _clouds.add(
        _createCloudlet(
          start: start + offset,
          end: end + offset,
          duration: duration * durationScale,
          fromLeft: fromLeft,
          cloudWidth: cloudWidth * widthScale,
          cloudHeight: cloudHeight * heightScale,
          opacityScale: opacityScale,
          initialDelayFraction: delay,
        ),
      );
    }
  }

  List<_CloudPuff> _buildPuffs({
    required double cloudWidth,
    required double cloudHeight,
  }) {
    final puffs = <_CloudPuff>[
      _puff(-0.42, 0.08, 0.42, 0.58, cloudWidth, cloudHeight),
      _puff(-0.22, -0.16, 0.48, 0.72, cloudWidth, cloudHeight),
      _puff(0.02, -0.08, 0.58, 0.84, cloudWidth, cloudHeight),
      _puff(0.25, 0.10, 0.50, 0.66, cloudWidth, cloudHeight),
      _puff(0.46, -0.06, 0.34, 0.54, cloudWidth, cloudHeight),
      _puff(-0.06, 0.24, 0.82, 0.50, cloudWidth, cloudHeight),
      _puff(-0.32, 0.30, 0.30, 0.40, cloudWidth, cloudHeight),
      _puff(0.32, 0.30, 0.34, 0.42, cloudWidth, cloudHeight),
    ];
    if (_random.nextBool()) {
      puffs.add(_puff(-0.66, 0.18, 0.22, 0.34, cloudWidth, cloudHeight));
    }
    if (_random.nextBool()) {
      puffs.add(_puff(0.68, 0.18, 0.24, 0.36, cloudWidth, cloudHeight));
    }
    if (_random.nextBool()) {
      puffs.add(_puff(0.58, -0.30, 0.20, 0.30, cloudWidth, cloudHeight));
    }
    return puffs;
  }

  _CloudPuff _puff(
    double x,
    double y,
    double width,
    double height,
    double cloudWidth,
    double cloudHeight,
  ) {
    final wobbleX = (-0.5 + _random.nextDouble()) * cloudWidth * 0.04;
    final wobbleY = (-0.5 + _random.nextDouble()) * cloudHeight * 0.06;
    return _CloudPuff(
      x: x * cloudWidth + wobbleX,
      y: y * cloudHeight + wobbleY,
      width: cloudWidth * width,
      height: cloudHeight * height,
      coreInset: 3.0,
    );
  }

  _DiscoveredCloudClip? _buildDiscoveredClip({
    required MapData mapData,
    required FogVisibilityQuery visibility,
  }) {
    final path = Path();
    var hasKnownTile = false;
    for (final tile in mapData.tiles) {
      if (!visibility.visibilityForTile(tile).isKnown) {
        continue;
      }
      path.addPath(_hexPath(tile.col, tile.row), Offset.zero);
      hasKnownTile = true;
    }
    return hasKnownTile ? _DiscoveredCloudClip(path) : null;
  }

  Rect _mapBoundsFor(MapData mapData) {
    if (mapData.tiles.isEmpty) return Rect.zero;

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final tile in mapData.tiles) {
      final corners = HexGeometry.topFaceCorners(
        center: HexGeometry.tilePosition(
          col: tile.col,
          row: tile.row,
          hexRadius: MapConfig.defaultHexRadius,
        ),
        radius: MapConfig.defaultHexRadius,
      );
      for (final corner in corners) {
        final worldCorner = _projectGridPoint(corner);
        minX = math.min(minX, worldCorner.x);
        minY = math.min(minY, worldCorner.y);
        maxX = math.max(maxX, worldCorner.x);
        maxY = math.max(maxY, worldCorner.y);
      }
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Path _hexPath(int col, int row) {
    final center = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: MapConfig.defaultHexRadius,
    );
    final corners = HexGeometry.topFaceCorners(
      center: center,
      radius: MapConfig.defaultHexRadius,
    );
    final firstCorner = _projectGridPoint(corners.first);
    final path = Path()..moveTo(firstCorner.x, firstCorner.y);
    for (final corner in corners.skip(1)) {
      final worldCorner = _projectGridPoint(corner);
      path.lineTo(worldCorner.x, worldCorner.y);
    }
    return path..close();
  }

  Vector2 _projectGridPoint(Vector2 point) {
    return Vector2(point.x, point.y * HexGrid.perspectiveY);
  }

  int _priorityFor(MapData mapData) {
    var maxMarkerPriority = MapPriority.city;
    for (final tile in mapData.tiles) {
      maxMarkerPriority = math.max(
        maxMarkerPriority,
        MapPriority.perTile(MapPriority.city, col: tile.col, row: tile.row),
      );
      maxMarkerPriority = math.max(
        maxMarkerPriority,
        MapPriority.perTileUnit(
          mapRows: mapData.rows,
          col: tile.col,
          row: tile.row,
        ),
      );
    }
    return math.max(MapPriority.cityManagementOverlay, maxMarkerPriority) + 1;
  }

  double _range(({double min, double max}) range) {
    return _randomRange(_random, range);
  }

  static double _randomRange(
    math.Random random,
    ({double min, double max}) range,
  ) {
    final min = range.min;
    final max = range.max;
    if (!min.isFinite || !max.isFinite) return 0;
    if (max <= min) return min;
    return min + random.nextDouble() * (max - min);
  }

  void _clearClouds() {
    _clouds.clear();
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

class _Cloudlet {
  _Cloudlet({
    required this.start,
    required this.end,
    required this.duration,
    required this.angle,
    required this.opacity,
    required this.puffs,
    this.elapsed = 0,
  });

  final Vector2 start;
  final Vector2 end;
  final double duration;
  final double angle;
  final double opacity;
  final List<_CloudPuff> puffs;
  double elapsed;

  Rect get puffBounds {
    if (puffs.isEmpty) return Rect.zero;
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final puff in puffs) {
      minX = math.min(minX, puff.x - puff.width / 2);
      minY = math.min(minY, puff.y - puff.height / 2);
      maxX = math.max(maxX, puff.x + puff.width / 2);
      maxY = math.max(maxY, puff.y + puff.height / 2);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

class _CloudPuff {
  const _CloudPuff({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.coreInset,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double coreInset;
}

class _DiscoveredCloudClip {
  const _DiscoveredCloudClip(this.path);

  final Path path;
}
