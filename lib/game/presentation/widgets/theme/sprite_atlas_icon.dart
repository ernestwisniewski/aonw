import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw/shared/assets/sprite_frame_repository.dart';
import 'package:aonw/shared/assets/sprite_frames.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class SpriteAtlasIconData {
  const SpriteAtlasIconData({
    required this.frameId,
    this.adjustmentSequenceId,
    this.adjustmentFrameIndex = 0,
    this.cropToContent = true,
  });

  final SpriteFrameId frameId;
  final SpriteSequenceId? adjustmentSequenceId;
  final int adjustmentFrameIndex;
  final bool cropToContent;

  AnimationFrameAdjustment adjustmentFor(
    AnimationFrameAdjustmentCatalog catalog,
  ) {
    final sequenceId = adjustmentSequenceId;
    if (sequenceId == null) return const AnimationFrameAdjustment();
    return catalog.adjustmentFor(
      sequenceId: sequenceId,
      frameIndex: adjustmentFrameIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpriteAtlasIconData &&
        other.frameId == frameId &&
        other.adjustmentSequenceId == adjustmentSequenceId &&
        other.adjustmentFrameIndex == adjustmentFrameIndex &&
        other.cropToContent == cropToContent;
  }

  @override
  int get hashCode => Object.hash(
    frameId,
    adjustmentSequenceId,
    adjustmentFrameIndex,
    cropToContent,
  );
}

class SpriteAtlasIcon extends StatefulWidget {
  const SpriteAtlasIcon({
    required this.data,
    required this.size,
    this.width,
    this.height,
    this.opacity = 1,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    super.key,
  });

  final SpriteAtlasIconData? data;
  final double size;
  final double? width;
  final double? height;
  final double opacity;
  final BoxFit fit;
  final Alignment alignment;

  @override
  State<SpriteAtlasIcon> createState() => _SpriteAtlasIconState();
}

class _SpriteAtlasIconState extends State<SpriteAtlasIcon> {
  Future<_LoadedSpriteAtlasIcon>? _pendingFrame;

  @override
  void didUpdateWidget(covariant SpriteAtlasIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _pendingFrame = null;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data == null) return _emptyBox();

    final readyFrame = _frameFromCaches(data);
    final content = readyFrame == null
        ? FutureBuilder<_LoadedSpriteAtlasIcon>(
            future: _pendingFrame ??= _loadIconFrame(data),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorWidget(
                  snapshot.error ?? StateError('Could not load sprite icon'),
                );
              }
              final loaded = snapshot.data;
              if (loaded == null) return _emptyBox();
              return _paintedIcon(data, loaded);
            },
          )
        : _paintedIcon(data, readyFrame);

    if (widget.opacity >= 1) return content;
    return Opacity(
      opacity: widget.opacity.clamp(0, 1).toDouble(),
      child: content,
    );
  }

  Future<_LoadedSpriteAtlasIcon> _loadIconFrame(
    SpriteAtlasIconData data,
  ) async {
    final frame = await SpriteFrames.load(data.frameId);
    return _LoadedSpriteAtlasIcon(
      adjustment: await _adjustmentFor(data),
      frame: frame,
    );
  }

  _LoadedSpriteAtlasIcon? _frameFromCaches(SpriteAtlasIconData data) {
    final frame = SpriteFrames.cached(data.frameId);
    if (frame == null) return null;
    final adjustment = _cachedAdjustmentFor(data);
    if (adjustment == null) return null;
    return _LoadedSpriteAtlasIcon(adjustment: adjustment, frame: frame);
  }

  AnimationFrameAdjustment? _cachedAdjustmentFor(SpriteAtlasIconData data) {
    if (data.adjustmentSequenceId == null) {
      return const AnimationFrameAdjustment();
    }
    final catalog = AnimationFrameAdjustmentCatalogCache.cached;
    return catalog == null ? null : data.adjustmentFor(catalog);
  }

  Future<AnimationFrameAdjustment> _adjustmentFor(
    SpriteAtlasIconData data,
  ) async {
    final cached = _cachedAdjustmentFor(data);
    if (cached != null) return cached;
    final catalog = await AnimationFrameAdjustmentCatalogCache.load();
    return data.adjustmentFor(catalog);
  }

  Widget _paintedIcon(SpriteAtlasIconData data, _LoadedSpriteAtlasIcon loaded) {
    return SizedBox(
      width: widget.width ?? widget.size,
      height: widget.height ?? widget.size,
      child: CustomPaint(
        painter: _SpriteAtlasIconPainter(
          data,
          loaded.frame,
          loaded.adjustment,
          widget.fit,
          widget.alignment,
        ),
      ),
    );
  }

  Widget _emptyBox() {
    return SizedBox(
      width: widget.width ?? widget.size,
      height: widget.height ?? widget.size,
    );
  }
}

class _LoadedSpriteAtlasIcon {
  const _LoadedSpriteAtlasIcon({required this.adjustment, required this.frame});

  final AnimationFrameAdjustment adjustment;
  final SpriteFrame frame;
}

class _SpriteAtlasIconPainter extends CustomPainter {
  const _SpriteAtlasIconPainter(
    this.data,
    this.frame,
    this.adjustment,
    this.fit,
    this.alignment,
  );

  final SpriteAtlasIconData data;
  final SpriteFrame frame;
  final AnimationFrameAdjustment adjustment;
  final BoxFit fit;
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final fullLogicalRect = ui.Offset.zero & frame.originalSize;
    final fitSource = data.cropToContent
        ? frame.contentBounds
        : fullLogicalRect;
    final fitted = applyBoxFit(fit, fitSource.size, size);
    final fittedLogicalSource = alignment.inscribe(fitted.source, fitSource);
    final baseDestination = alignment.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final offset = adjustment.scaledOffset(
      baseSize: fittedLogicalSource.size,
      targetSize: baseDestination.size,
    );
    final logicalSource = adjustment.croppedSourceFor(fittedLogicalSource);
    final destination = adjustment
        .adjustedDestinationFor(
          baseSource: fittedLogicalSource,
          baseDestination: baseDestination,
        )
        .shift(offset);
    final geometry = frame.geometryFor(
      logicalSource: logicalSource,
      destination: destination,
    );
    if (geometry.source.isEmpty || geometry.destination.isEmpty) return;

    final shadowOffset = Offset(0, size.shortestSide * 0.035);
    final shadowPaint = Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = ColorFilter.mode(
        SurfaceElevation.flat.fill(background: Colors.black, alpha: 100),
        BlendMode.srcIn,
      );
    canvas
      ..drawImageRect(
        frame.image,
        geometry.source,
        geometry.destination.shift(shadowOffset),
        shadowPaint,
      )
      ..drawImageRect(
        frame.image,
        geometry.source,
        geometry.destination,
        Paint()..filterQuality = FilterQuality.high,
      );
  }

  @override
  bool shouldRepaint(covariant _SpriteAtlasIconPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.data != data ||
        oldDelegate.adjustment != adjustment ||
        oldDelegate.fit != fit ||
        oldDelegate.alignment != alignment;
  }
}
