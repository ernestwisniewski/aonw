import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_definition.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_frame_sequencer.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw/shared/assets/sprite_frame_repository.dart';
import 'package:flame/components.dart';

export 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_definition.dart';

class UnitSpriteComponent extends SpriteAnimationComponent {
  UnitSpriteComponent(this.definition)
    : super(
        size: Vector2(
          definition.normalSize.width,
          definition.normalSize.height,
        ),
        autoResize: false,
      ) {
    _frames = UnitSpriteFrameSequencer(definition);
  }

  final UnitSpriteDefinition definition;
  late final UnitSpriteFrameSequencer _frames;
  final Map<SpriteFrameId, SpriteFrame> _loadedFrames = {};
  AnimationFrameAdjustmentCatalog _adjustments =
      const AnimationFrameAdjustmentCatalog.empty();

  UnitSpriteAction get action => _frames.action;
  bool get isReady => animation != null;
  bool get idlePausesEnabled => _frames.idlePausesEnabled;
  int get currentColumn => _frames.currentColumn();
  bool get isMirrored => _frames.mirrored;

  set idlePausesEnabled(bool value) {
    _frames.idlePausesEnabled = value;
  }

  UnitSpriteSize sizeFor({required bool onCity}) =>
      definition.sizeFor(onCity: onCity);

  Future<void> setFrames(Iterable<SpriteFrame> frames) async {
    _loadedFrames
      ..clear()
      ..addEntries(frames.map((frame) => MapEntry(frame.id, frame)));
    _adjustments = await AnimationFrameAdjustmentCatalogCache.load();
    _rebuildAnimation();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _frames.updateWithFrameDuration(dt, frameDuration: frameDuration);
  }

  void playIdle() => _setAction(UnitSpriteAction.idle);

  void playWalkToward({required Vector2 from, required Vector2 to}) {
    if (_frames.playWalkToward(from: from, to: to)) _rebuildAnimation();
  }

  void playAttack() => _setAction(UnitSpriteAction.attack);

  void playAttackToward({required Vector2 from, required Vector2 to}) {
    if (_frames.playActionToward(
      action: UnitSpriteAction.attack,
      from: from,
      to: to,
    )) {
      _rebuildAnimation();
    }
  }

  void playWork() => _setAction(UnitSpriteAction.work);
  void playDie() => _setAction(UnitSpriteAction.die);

  void _setAction(UnitSpriteAction action, {bool forceRebuild = false}) {
    if (_frames.playAction(action, forceRebuild: forceRebuild)) {
      _rebuildAnimation();
    }
  }

  UnitSpriteActionDefinition get actionDefinition => _frames.actionDefinition;

  SpriteSequenceId get currentSequenceId => definition.sequenceIdFor(action);

  double get frameDuration {
    return _adjustments.frameDurationFor(
      sequenceId: currentSequenceId,
      defaultFrameDuration: actionDefinition.frameDuration,
    );
  }

  ui.Offset frameOffsetFor(UnitSpriteSize size) {
    return _currentAdjustment().scaledOffset(
      baseSize: ui.Size(
        definition.normalSize.width,
        definition.normalSize.height,
      ),
      targetSize: ui.Size(size.width, size.height),
    );
  }

  double? visibleContentTopOffsetFor(UnitSpriteSize size) {
    final frame = _currentFrame;
    if (frame == null || frame.originalSize.height <= 0) return null;
    return frameOffsetFor(size).dy +
        frame.statusTop / frame.originalSize.height * size.height;
  }

  void _rebuildAnimation() {
    final sequence = currentSequenceId;
    final sprites = <Sprite>[];
    for (final column in _frames.activeColumns) {
      final frame = _loadedFrames[sequence.frame(column)];
      if (frame == null) {
        animation = null;
        return;
      }
      sprites.add(
        Sprite(
          frame.image,
          srcPosition: Vector2(frame.source.left, frame.source.top),
          srcSize: Vector2(frame.source.width, frame.source.height),
        ),
      );
    }
    animation = SpriteAnimation.spriteList(
      sprites,
      stepTime: frameDuration,
      loop: actionDefinition.loops,
    );
    animationTicker?.currentIndex = _frames.logicalFrameIndex
        .clamp(0, math.max(0, _frames.activeColumns.length - 1))
        .toInt();
  }

  SpriteFrame? get _currentFrame =>
      _loadedFrames[currentSequenceId.frame(currentColumn)];

  @override
  // ignore: must_call_super
  void render(ui.Canvas canvas) {
    final frame = _currentFrame;
    if (frame == null || animation == null) return;
    final geometry = renderGeometryForCurrentFrame();
    if (geometry.source.isEmpty || geometry.destination.isEmpty) return;
    canvas
      ..save()
      ..clipRect(geometry.clipRect)
      ..drawImageRect(
        frame.image,
        geometry.source,
        geometry.destination,
        paint..filterQuality = ui.FilterQuality.medium,
      )
      ..restore();
  }

  UnitSpriteFrameRenderGeometry renderGeometryForCurrentFrame() {
    final frame = _currentFrame;
    final clipRect = ui.Offset.zero & ui.Size(size.x, size.y);
    if (frame == null) return UnitSpriteFrameRenderGeometry.empty(clipRect);

    final logicalFrame = ui.Offset.zero & frame.originalSize;
    final adjustment = _currentAdjustment();
    final offset = adjustment.scaledOffset(
      baseSize: ui.Size(
        definition.normalSize.width,
        definition.normalSize.height,
      ),
      targetSize: clipRect.size,
    );
    final logicalSource = adjustment.croppedSourceFor(logicalFrame);
    final adjustedDestination = adjustment
        .adjustedDestinationFor(
          baseSource: logicalFrame,
          baseDestination: clipRect,
        )
        .shift(offset);
    final geometry = frame.geometryFor(
      logicalSource: logicalSource,
      destination: adjustedDestination,
    );
    return UnitSpriteFrameRenderGeometry(
      source: geometry.source,
      destination: geometry.destination,
      clipRect: clipRect,
    );
  }

  AnimationFrameAdjustment _currentAdjustment() {
    return _adjustments.adjustmentFor(
      sequenceId: currentSequenceId,
      frameIndex: currentColumn,
    );
  }
}

class UnitSpriteFrameRenderGeometry {
  const UnitSpriteFrameRenderGeometry({
    required this.source,
    required this.destination,
    required this.clipRect,
  });

  factory UnitSpriteFrameRenderGeometry.empty(ui.Rect frame) {
    return UnitSpriteFrameRenderGeometry(
      source: ui.Rect.zero,
      destination: frame,
      clipRect: frame,
    );
  }

  final ui.Rect source;
  final ui.Rect destination;
  final ui.Rect clipRect;
}
