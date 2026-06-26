import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/sprite_frame_stabilizer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_definition.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_frame_sequencer.dart';
import 'package:flame/components.dart';

export 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_definition.dart';

class UnitSpriteComponent extends SpriteAnimationComponent {
  final UnitSpriteDefinition definition;
  late final UnitSpriteFrameSequencer _frames;
  ui.Image? _image;
  SpriteFrameStabilizer? _stabilizer;
  AnimationFrameAdjustmentCatalog _adjustments =
      const AnimationFrameAdjustmentCatalog.empty();

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

  UnitSpriteAction get action => _frames.action;

  bool get isReady => animation != null;

  bool get idlePausesEnabled => _frames.idlePausesEnabled;

  set idlePausesEnabled(bool value) {
    _frames.idlePausesEnabled = value;
  }

  int get currentColumn => _frames.currentColumn();

  bool get isMirrored => _frames.mirrored;

  UnitSpriteSize sizeFor({required bool onCity}) =>
      definition.sizeFor(onCity: onCity);

  Future<void> setImage(ui.Image image) async {
    if (identical(_image, image) && animation != null) return;
    _image = image;
    _rebuildAnimation();
    _stabilizer = await SpriteFrameStabilizerCache.analyze(
      cacheKey: definition.assetPath,
      image: image,
      columns: definition.columns,
      rows: definition.rows,
      sourceInset: definition.sourceInset,
    );
    _adjustments = await AnimationFrameAdjustmentCatalogCache.load();
    _rebuildAnimation();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _frames.updateWithFrameDuration(dt, frameDuration: frameDuration);
  }

  void playIdle() {
    _setAction(UnitSpriteAction.idle);
  }

  void playWalkToward({required Vector2 from, required Vector2 to}) {
    if (_frames.playWalkToward(from: from, to: to)) {
      _rebuildAnimation();
    }
  }

  void playAttack() {
    _setAction(UnitSpriteAction.attack);
  }

  void playAttackToward({required Vector2 from, required Vector2 to}) {
    if (_frames.playActionToward(
      action: UnitSpriteAction.attack,
      from: from,
      to: to,
    )) {
      _rebuildAnimation();
    }
  }

  void playWork() {
    _setAction(UnitSpriteAction.work);
  }

  void playDie() {
    _setAction(UnitSpriteAction.die);
  }

  void _setAction(UnitSpriteAction action, {bool forceRebuild = false}) {
    if (_frames.playAction(action, forceRebuild: forceRebuild)) {
      _rebuildAnimation();
    }
  }

  UnitSpriteActionDefinition get actionDefinition => _frames.actionDefinition;

  double get frameDuration {
    final frameDefinition = actionDefinition;
    return _adjustments.frameDurationFor(
      assetPath: definition.assetPath,
      animationId: action.name,
      defaultFrameDuration: frameDefinition.frameDuration,
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
    final stabilizer = _stabilizer;
    if (stabilizer == null) return null;
    return frameOffsetFor(size).dy +
        stabilizer.contentTopFractionForRow(actionDefinition.row) * size.height;
  }

  void _rebuildAnimation() {
    final image = _image;
    if (image == null) {
      animation = null;
      return;
    }

    final frameDefinition = actionDefinition;
    final imageSize = Vector2(image.width.toDouble(), image.height.toDouble());
    final sprites = [
      for (final column in _frames.activeColumns)
        _spriteForFrame(
          image: image,
          imageSize: imageSize,
          frameDefinition: frameDefinition,
          column: column,
        ),
    ];

    animation = SpriteAnimation.spriteList(
      sprites,
      stepTime: frameDuration,
      loop: frameDefinition.loops,
    );
    animationTicker?.currentIndex = _frames.logicalFrameIndex
        .clamp(0, math.max(0, _frames.activeColumns.length - 1))
        .toInt();
  }

  Sprite _spriteForFrame({
    required ui.Image image,
    required Vector2 imageSize,
    required UnitSpriteActionDefinition frameDefinition,
    required int column,
  }) {
    final source = definition.sourceRectFor(
      imageSize: imageSize,
      action: frameDefinition,
      column: column,
    );
    return Sprite(
      image,
      srcPosition: Vector2(source.left, source.top),
      srcSize: Vector2(
        math.max(1.0, source.width),
        math.max(1.0, source.height),
      ),
    );
  }

  @override
  // The default SpriteAnimationComponent renderer stretches cropped source
  // frames back to the full component bounds. Manual rendering preserves scale.
  // ignore: must_call_super
  void render(ui.Canvas canvas) {
    final image = _image;
    if (image == null || animation == null) return;

    final geometry = renderGeometryForCurrentFrame();

    canvas
      ..save()
      ..clipRect(geometry.clipRect)
      ..drawImageRect(
        image,
        geometry.source,
        geometry.destination,
        paint..filterQuality = ui.FilterQuality.medium,
      )
      ..restore();
  }

  UnitSpriteFrameRenderGeometry renderGeometryForCurrentFrame() {
    final image = _image;
    if (image == null) {
      return UnitSpriteFrameRenderGeometry.empty(
        ui.Offset.zero & ui.Size(size.x, size.y),
      );
    }

    final imageSize = Vector2(image.width.toDouble(), image.height.toDouble());
    final baseSource = definition.sourceRectFor(
      imageSize: imageSize,
      action: actionDefinition,
      column: currentColumn,
    );
    final baseDestination = ui.Offset.zero & ui.Size(size.x, size.y);
    final adjustment = _currentAdjustment();
    final offset = adjustment.scaledOffset(
      baseSize: ui.Size(
        definition.normalSize.width,
        definition.normalSize.height,
      ),
      targetSize: baseDestination.size,
    );
    final destination = adjustment
        .adjustedDestinationFor(
          baseSource: baseSource,
          baseDestination: baseDestination,
        )
        .shift(offset);

    return UnitSpriteFrameRenderGeometry(
      source: adjustment.croppedSourceFor(baseSource),
      destination: destination,
      clipRect: baseDestination,
    );
  }

  AnimationFrameAdjustment _currentAdjustment() {
    return _adjustments.adjustmentFor(
      assetPath: definition.assetPath,
      animationId: action.name,
      frameIndex: currentColumn,
    );
  }
}

class UnitSpriteFrameRenderGeometry {
  final ui.Rect source;
  final ui.Rect destination;
  final ui.Rect clipRect;

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
}
