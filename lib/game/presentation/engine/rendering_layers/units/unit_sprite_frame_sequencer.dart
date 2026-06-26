import 'dart:math' as math;

import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_definition.dart';
import 'package:flame/components.dart';

class UnitSpriteFrameSequencer {
  UnitSpriteFrameSequencer(
    this.definition, {
    math.Random? random,
    double Function()? idlePauseDurationFactory,
  }) : _direction = definition.defaultDirection,
       _random = random ?? math.Random(),
       _idlePauseDurationFactory = idlePauseDurationFactory {
    _mirrored = _shouldMirror(_direction);
    _syncFrameColumns();
  }

  static const double maxIdlePauseSeconds = 1.0;

  final UnitSpriteDefinition definition;
  final math.Random _random;
  final double Function()? _idlePauseDurationFactory;
  UnitSpriteAction _action = UnitSpriteAction.idle;
  UnitSpriteDirection _direction;
  bool _mirrored = false;
  List<int> _activeColumns = const [];
  int _logicalFrameIndex = 0;
  double _logicalFrameElapsed = 0;
  double _idlePauseRemaining = 0;
  bool _idlePausesEnabled = true;

  UnitSpriteAction get action => _action;

  UnitSpriteActionDefinition get actionDefinition =>
      definition.actionDefinition(_action);

  List<int> get activeColumns => _activeColumns;

  bool get mirrored => _mirrored;

  int get logicalFrameIndex => _logicalFrameIndex;

  bool get idlePausesEnabled => _idlePausesEnabled;

  set idlePausesEnabled(bool value) {
    if (_idlePausesEnabled == value) return;
    _idlePausesEnabled = value;
    if (!value) {
      _idlePauseRemaining = 0;
    }
  }

  double get idlePauseRemainingForTesting => _idlePauseRemaining;

  int currentColumn() {
    if (_activeColumns.isEmpty) return 0;
    final index = _logicalFrameIndex
        .clamp(0, _activeColumns.length - 1)
        .toInt();
    return _activeColumns[index];
  }

  bool playAction(UnitSpriteAction action, {bool forceRebuild = false}) {
    final supportedAction = definition.supportedAction(action);
    if (_action == supportedAction && !forceRebuild) return false;
    final actionChanged = _action != supportedAction;
    _action = supportedAction;
    if (actionChanged) {
      _resetLogicalTimeline();
    }
    _syncFrameColumns();
    return true;
  }

  bool playWalkToward({required Vector2 from, required Vector2 to}) {
    final nextDirection = UnitSpriteDirection.fromDelta(to - from);
    final directionChanged = _direction != nextDirection;
    final nextMirrored = _mirrorForDelta(delta: to - from, fallback: _mirrored);
    final mirrorChanged = _mirrored != nextMirrored;
    _direction = nextDirection;
    _mirrored = nextMirrored;
    return playAction(
      UnitSpriteAction.walk,
      forceRebuild: directionChanged || mirrorChanged,
    );
  }

  bool playActionToward({
    required UnitSpriteAction action,
    required Vector2 from,
    required Vector2 to,
  }) {
    final nextDirection = UnitSpriteDirection.fromDelta(to - from);
    final directionChanged = _direction != nextDirection;
    final nextMirrored = _mirrorForDelta(delta: to - from, fallback: _mirrored);
    final mirrorChanged = _mirrored != nextMirrored;
    _direction = nextDirection;
    _mirrored = nextMirrored;
    return playAction(action, forceRebuild: directionChanged || mirrorChanged);
  }

  void update(double dt) {
    updateWithFrameDuration(dt, frameDuration: actionDefinition.frameDuration);
  }

  void updateWithFrameDuration(double dt, {required double frameDuration}) {
    if (_activeColumns.length <= 1) return;
    final safeFrameDuration = frameDuration.isFinite && frameDuration > 0
        ? frameDuration
        : actionDefinition.frameDuration;
    var remainingDt = dt;

    if (_isIdle && _idlePausesEnabled && _idlePauseRemaining > 0) {
      _idlePauseRemaining -= remainingDt;
      if (_idlePauseRemaining > 0) return;
      remainingDt = -_idlePauseRemaining;
      _idlePauseRemaining = 0;
    }

    final definition = actionDefinition;
    _logicalFrameElapsed += remainingDt;
    while (_logicalFrameElapsed >= safeFrameDuration) {
      _logicalFrameElapsed -= safeFrameDuration;
      if (definition.loops) {
        final nextFrameIndex = _logicalFrameIndex + 1;
        if (_isIdle &&
            _idlePausesEnabled &&
            nextFrameIndex >= _activeColumns.length) {
          _logicalFrameIndex = 0;
          _logicalFrameElapsed = 0;
          _idlePauseRemaining = _nextIdlePauseDuration();
          return;
        }
        _logicalFrameIndex = nextFrameIndex % _activeColumns.length;
      } else if (_logicalFrameIndex < _activeColumns.length - 1) {
        _logicalFrameIndex += 1;
      }
    }
  }

  void _syncFrameColumns() {
    final definition = actionDefinition;
    _activeColumns = [for (var i = 0; i < definition.frameCount; i++) i];
  }

  void _resetLogicalTimeline() {
    _logicalFrameIndex = 0;
    _logicalFrameElapsed = 0;
    _idlePauseRemaining = 0;
  }

  bool get _isIdle => _action == UnitSpriteAction.idle;

  double _nextIdlePauseDuration() {
    final duration =
        _idlePauseDurationFactory?.call() ??
        _random.nextDouble() * maxIdlePauseSeconds;
    return duration.isFinite
        ? duration.clamp(0.0, maxIdlePauseSeconds).toDouble()
        : 0.0;
  }

  static bool _shouldMirror(UnitSpriteDirection direction) {
    return switch (direction) {
      UnitSpriteDirection.sw ||
      UnitSpriteDirection.w ||
      UnitSpriteDirection.nw => true,
      UnitSpriteDirection.s ||
      UnitSpriteDirection.n ||
      UnitSpriteDirection.ne ||
      UnitSpriteDirection.e ||
      UnitSpriteDirection.se => false,
    };
  }

  static bool _mirrorForDelta({
    required Vector2 delta,
    required bool fallback,
  }) {
    const epsilon = 0.001;
    if (delta.x < -epsilon) return true;
    if (delta.x > epsilon) return false;
    return fallback;
  }
}
