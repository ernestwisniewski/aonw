import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/application/map_interaction_state.dart';
import '../../features/map/presentation/layers/map_canvas_paths.dart';
import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/movement_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import '../presentation/flame_scene_patch.dart';
import 'static_map_layers.dart';

final class MapReachableLayerComponent extends Component with HasVisibility {
  MapReachableLayerComponent({required bool renderEnabled})
    : _renderEnabled = renderEnabled,
      super(priority: 30) {
    isVisible = false;
  }

  final bool _renderEnabled;
  static final ui.Paint _paint = ui.Paint()
    ..color = MapPalette.reachable
    ..style = ui.PaintingStyle.fill;
  ReachableView? _reachable;
  ui.Path? _path;
  var _pathBuildCount = 0;

  @visibleForTesting
  int get debugPathBuildCount => _pathBuildCount;

  void applyReachable(MapStaticRenderCache cache, ReachableView? reachable) {
    if (identical(_reachable, reachable)) return;
    _reachable = reachable;
    if (reachable == null) {
      _path = null;
      isVisible = false;
      return;
    }
    final bounds = cache.geometry.bounds;
    final offset = ui.Offset(-bounds.x, -bounds.y);
    final path = ui.Path();
    for (final tile in reachable.tiles) {
      path.addPath(aonwHexPath(cache.geometry, tile.coordinate), offset);
    }
    _path = path;
    _pathBuildCount += 1;
    isVisible = _renderEnabled;
  }

  void clearLayer() {
    _reachable = null;
    _path = null;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    final path = _path;
    if (path != null) canvas.drawPath(path, _paint);
  }
}

final class MapRouteLayerComponent extends Component with HasVisibility {
  MapRouteLayerComponent({required bool renderEnabled})
    : _renderEnabled = renderEnabled,
      super(priority: 40) {
    isVisible = false;
  }

  final bool _renderEnabled;
  static final ui.Paint _paint = ui.Paint()
    ..color = MapPalette.route
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 7
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  RoutePlanView? _route;
  ui.Path? _path;
  var _pathBuildCount = 0;

  @visibleForTesting
  int get debugPathBuildCount => _pathBuildCount;

  void applyRoute(MapStaticRenderCache cache, RoutePlanView? route) {
    if (identical(_route, route)) return;
    _route = route;
    if (route == null || route.steps.isEmpty) {
      _path = null;
      isVisible = false;
      return;
    }
    final bounds = cache.geometry.bounds;
    final path = ui.Path();
    for (var index = 0; index < route.steps.length; index++) {
      final center = cache.geometry.center(route.steps[index].coordinate);
      final x = center.x - bounds.x;
      final y = center.y - bounds.y;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    _path = path;
    _pathBuildCount += 1;
    isVisible = _renderEnabled;
  }

  void clearLayer() {
    _route = null;
    _path = null;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    final path = _path;
    if (path != null) canvas.drawPath(path, _paint);
  }
}

final class MapUnitLayerComponent extends Component with HasVisibility {
  MapUnitLayerComponent({required bool renderEnabled})
    : _renderEnabled = renderEnabled,
      super(priority: 50) {
    isVisible = renderEnabled;
  }

  final bool _renderEnabled;
  final _unitsById = <String, MapUnitComponent>{};
  var _createdCount = 0;
  var _updatedCount = 0;
  var _removedCount = 0;

  @visibleForTesting
  int get debugUnitCount => _unitsById.length;

  @visibleForTesting
  int get debugCreatedCount => _createdCount;

  @visibleForTesting
  int get debugUpdatedCount => _updatedCount;

  @visibleForTesting
  int get debugRemovedCount => _removedCount;

  @visibleForTesting
  int get debugSharedPaintCount => MapUnitComponent.sharedPaintCount;

  @visibleForTesting
  MapUnitComponent? debugComponentForUnit(String unitId) => _unitsById[unitId];

  MapUnitComponent? componentForUnit(String unitId) => _unitsById[unitId];

  void applyPatch(FlameScenePatch patch, MapStaticRenderCache cache) {
    final animatedIds = {
      for (final movement in patch.movements) movement.unitId,
    };
    for (final unitId in patch.removedUnitIds) {
      final component = _unitsById.remove(unitId);
      if (component != null) {
        component.removeFromParent();
        _removedCount += 1;
      }
    }
    for (final unit in patch.unitUpserts) {
      final center = _center(cache, unit.coordinate);
      final existing = _unitsById[unit.id];
      if (existing == null) {
        final component = MapUnitComponent(
          unit: unit,
          actorPlayerId: patch.snapshot.player.actorPlayerId,
          center: center,
        );
        _unitsById[unit.id] = component;
        add(component);
        _createdCount += 1;
      } else {
        existing.applyUnit(
          unit,
          actorPlayerId: patch.snapshot.player.actorPlayerId,
          center: center,
          preserveVisualPosition: animatedIds.contains(unit.id),
        );
        _updatedCount += 1;
      }
    }
    isVisible = _renderEnabled && _unitsById.isNotEmpty;
  }

  void clearLayer() {
    for (final component in _unitsById.values) {
      component.removeFromParent();
    }
    _unitsById.clear();
    isVisible = false;
  }

  ui.Offset centerFor(
    MapStaticRenderCache cache,
    MapHexCoordinate coordinate,
  ) => _center(cache, coordinate);

  static ui.Offset _center(
    MapStaticRenderCache cache,
    MapHexCoordinate coordinate,
  ) {
    final bounds = cache.geometry.bounds;
    final center = cache.geometry.center(coordinate);
    return ui.Offset(center.x - bounds.x, center.y - bounds.y);
  }
}

final class MapUnitComponent extends PositionComponent {
  MapUnitComponent({
    required VisibleUnitView unit,
    required String actorPlayerId,
    required ui.Offset center,
  }) : _unit = unit,
       _controlled = unit.ownerPlayerId == actorPlayerId,
       super(
         position: Vector2(center.dx, center.dy),
         size: Vector2.all(_diameter),
         anchor: Anchor.center,
       );

  static const _radius = 17.0;
  static const _diameter = 46.0;
  static final ui.Paint _controlledPaint = ui.Paint()
    ..color = MapPalette.controlledUnit;
  static final ui.Paint _foreignPaint = ui.Paint()
    ..color = MapPalette.foreignUnit;
  static final ui.Paint _outlinePaint = ui.Paint()
    ..color = MapPalette.unitOutline
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  static const sharedPaintCount = 3;

  VisibleUnitView _unit;
  bool _controlled;

  @visibleForTesting
  VisibleUnitView get debugUnit => _unit;

  @visibleForTesting
  ui.Offset get debugVisualCenter => visualCenter;

  ui.Offset get visualCenter => ui.Offset(position.x, position.y);

  void applyUnit(
    VisibleUnitView unit, {
    required String actorPlayerId,
    required ui.Offset center,
    required bool preserveVisualPosition,
  }) {
    _unit = unit;
    _controlled = unit.ownerPlayerId == actorPlayerId;
    if (!preserveVisualPosition) setVisualCenter(center);
  }

  void setVisualCenter(ui.Offset center) {
    position.setValues(center.dx, center.dy);
  }

  @override
  void render(ui.Canvas canvas) {
    const center = ui.Offset(_diameter / 2, _diameter / 2);
    canvas.drawCircle(
      center,
      _radius,
      _controlled ? _controlledPaint : _foreignPaint,
    );
    canvas.drawCircle(center, _radius, _outlinePaint);
  }
}

final class MapSelectionLayerComponent extends Component with HasVisibility {
  MapSelectionLayerComponent({
    required bool renderEnabled,
    required MapUnitLayerComponent units,
  }) : _renderEnabled = renderEnabled,
       _units = units,
       super(priority: 60) {
    isVisible = false;
  }

  final bool _renderEnabled;
  final MapUnitLayerComponent _units;
  static final ui.Paint _hoverPaint = ui.Paint()
    ..color = MapPalette.hover
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  static final ui.Paint _selectionPaint = ui.Paint()
    ..color = MapPalette.selection
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 5;
  static final ui.Paint _selectedUnitPaint = ui.Paint()
    ..color = MapPalette.selection
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 4;
  ui.Path? _hoverPath;
  ui.Path? _selectionPath;
  String? _selectedUnitId;
  MapInteractionState? _interaction;
  var _updateCount = 0;

  @visibleForTesting
  int get debugUpdateCount => _updateCount;

  void applySelection(
    MapStaticRenderCache cache,
    MapInteractionState interaction,
  ) {
    if (identical(_interaction, interaction)) return;
    _interaction = interaction;
    _hoverPath = _pathFor(cache, interaction.hovered);
    _selectionPath = _pathFor(cache, interaction.selected);
    _selectedUnitId = interaction.selectedUnitId;
    _updateCount += 1;
    isVisible =
        _renderEnabled &&
        (_hoverPath != null ||
            _selectionPath != null ||
            _selectedUnitId != null);
  }

  void clearLayer() {
    _interaction = null;
    _hoverPath = null;
    _selectionPath = null;
    _selectedUnitId = null;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    final hover = _hoverPath;
    if (hover != null) canvas.drawPath(hover, _hoverPaint);
    final selection = _selectionPath;
    if (selection != null) canvas.drawPath(selection, _selectionPaint);
    final selectedUnit = _selectedUnitId == null
        ? null
        : _units.componentForUnit(_selectedUnitId!);
    if (selectedUnit != null) {
      canvas.drawCircle(selectedUnit.visualCenter, 23, _selectedUnitPaint);
    }
  }

  static ui.Path? _pathFor(
    MapStaticRenderCache cache,
    MapHexCoordinate? coordinate,
  ) {
    if (coordinate == null) return null;
    final bounds = cache.geometry.bounds;
    return ui.Path()..addPath(
      aonwHexPath(cache.geometry, coordinate),
      ui.Offset(-bounds.x, -bounds.y),
    );
  }
}

typedef MapEffectActivitySink = void Function(bool active);

final class MapEffectHostComponent extends Component {
  MapEffectHostComponent({required MapUnitLayerComponent units})
    : _units = units,
      super(priority: 70);

  static const _movementDurationSeconds = 0.24;

  final MapUnitLayerComponent _units;
  final _movements = <String, _ActiveUnitMovement>{};
  MapEffectActivitySink? onActivityChanged;
  var _reducedMotion = false;
  var _playbackSpeed = 1.0;
  var _activeUpdateCount = 0;
  var _completedMovementCount = 0;

  @visibleForTesting
  int get debugActiveEffectCount => _movements.length;

  @visibleForTesting
  int get debugActiveUpdateCount => _activeUpdateCount;

  @visibleForTesting
  int get debugCompletedMovementCount => _completedMovementCount;

  @visibleForTesting
  double get debugPlaybackSpeed => _playbackSpeed;

  @visibleForTesting
  bool get debugReducedMotion => _reducedMotion;

  void applyPatch(FlameScenePatch patch, MapStaticRenderCache cache) {
    final transitionedIds = {
      for (final movement in patch.movements) movement.unitId,
    };
    for (final unitId in patch.removedUnitIds) {
      _movements.remove(unitId);
    }
    for (final unit in patch.unitUpserts) {
      if (!transitionedIds.contains(unit.id)) _movements.remove(unit.id);
    }
    for (final movement in patch.movements) {
      final unit = _units.componentForUnit(movement.unitId);
      if (unit == null) continue;
      final target = _units.centerFor(cache, movement.to);
      if (_reducedMotion) {
        unit.setVisualCenter(target);
        _completedMovementCount += 1;
      } else {
        _movements[movement.unitId] = _ActiveUnitMovement(
          unit: unit,
          start: unit.visualCenter,
          target: target,
        );
      }
    }
    _notifyActivity();
  }

  void setReducedMotion(bool enabled) {
    if (_reducedMotion == enabled) return;
    _reducedMotion = enabled;
    if (enabled) skipAll();
  }

  void setPlaybackSpeed(double speed) {
    if (!speed.isFinite || speed <= 0) {
      throw ArgumentError.value(speed, 'speed', 'must be finite and positive');
    }
    _playbackSpeed = speed;
  }

  void skipAll() {
    if (_movements.isEmpty) return;
    for (final movement in _movements.values) {
      movement.unit.setVisualCenter(movement.target);
      _completedMovementCount += 1;
    }
    _movements.clear();
    _notifyActivity();
  }

  void clearEffects() {
    _movements.clear();
    _notifyActivity();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_movements.isEmpty) return;
    _activeUpdateCount += 1;
    final completed = <String>[];
    for (final entry in _movements.entries) {
      final movement = entry.value;
      movement.elapsed += dt * _playbackSpeed;
      final linear = (movement.elapsed / _movementDurationSeconds).clamp(
        0.0,
        1.0,
      );
      final eased = linear * linear * (3 - 2 * linear);
      movement.unit.setVisualCenter(
        ui.Offset.lerp(movement.start, movement.target, eased)!,
      );
      if (linear >= 1) completed.add(entry.key);
    }
    for (final unitId in completed) {
      _movements.remove(unitId);
      _completedMovementCount += 1;
    }
    if (completed.isNotEmpty) _notifyActivity();
  }

  void _notifyActivity() => onActivityChanged?.call(_movements.isNotEmpty);
}

final class _ActiveUnitMovement {
  _ActiveUnitMovement({
    required this.unit,
    required this.start,
    required this.target,
  });

  final MapUnitComponent unit;
  final ui.Offset start;
  final ui.Offset target;
  var elapsed = 0.0;
}
