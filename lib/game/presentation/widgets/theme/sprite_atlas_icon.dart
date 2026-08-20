import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/shared/assets/sprite_atlas_frame_bounds.dart';
import 'package:aonw/shared/assets/sprite_atlas_geometry.dart';
import 'package:aonw/shared/assets/ui_image_cache.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class SpriteAtlasIconData {
  final String assetPath;
  final int columns;
  final int rows;
  final int column;
  final int row;
  final double sourceInset;
  final double contentPadding;
  final bool cropToContent;
  final String? adjustmentId;
  final int adjustmentFrameIndex;
  final ui.Rect Function(ui.Image image)? sourceRectResolver;

  const SpriteAtlasIconData({
    required this.assetPath,
    required this.columns,
    required this.rows,
    required this.column,
    required this.row,
    this.sourceInset = 2.0,
    this.contentPadding = 18.0,
    this.cropToContent = true,
    this.adjustmentId,
    this.adjustmentFrameIndex = 0,
    this.sourceRectResolver,
  });

  ui.Rect sourceRectFor(ui.Image image) {
    final resolver = sourceRectResolver;
    if (resolver != null) return resolver(image);

    return SpriteAtlasGeometry.sourceRectFor(
      imageWidth: image.width,
      imageHeight: image.height,
      columns: columns,
      rows: rows,
      column: column,
      row: row,
      sourceInset: sourceInset,
    );
  }

  Future<ui.Rect> resolvedSourceRectFor(ui.Image image) async {
    final cachedFrame = cachedSourceRectFor(image);
    if (cachedFrame != null) return cachedFrame;

    return SpriteAtlasFrameBoundsCache.frameRectFor(
      cacheKey: assetPath,
      image: image,
      columns: columns,
      rows: rows,
      column: column,
      row: row,
      sourceInset: sourceInset,
      contentPadding: contentPadding,
    );
  }

  ui.Rect? cachedSourceRectFor(ui.Image image) {
    if (!cropToContent) return sourceRectFor(image);
    return SpriteAtlasFrameBoundsCache.cachedFrameRectFor(
      cacheKey: assetPath,
      image: image,
      columns: columns,
      rows: rows,
      column: column,
      row: row,
      sourceInset: sourceInset,
      contentPadding: contentPadding,
    );
  }

  AnimationFrameAdjustment adjustmentFor(
    AnimationFrameAdjustmentCatalog catalog,
  ) {
    final id = adjustmentId;
    if (id == null) return const AnimationFrameAdjustment();
    return catalog.adjustmentFor(
      assetPath: assetPath,
      animationId: id,
      frameIndex: adjustmentFrameIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpriteAtlasIconData &&
        other.assetPath == assetPath &&
        other.columns == columns &&
        other.rows == rows &&
        other.column == column &&
        other.row == row &&
        other.sourceInset == sourceInset &&
        other.contentPadding == contentPadding &&
        other.cropToContent == cropToContent &&
        other.adjustmentId == adjustmentId &&
        other.adjustmentFrameIndex == adjustmentFrameIndex &&
        other.sourceRectResolver == sourceRectResolver;
  }

  @override
  int get hashCode => Object.hash(
    assetPath,
    columns,
    rows,
    column,
    row,
    sourceInset,
    contentPadding,
    cropToContent,
    adjustmentId,
    adjustmentFrameIndex,
    sourceRectResolver,
  );
}

class SpriteAtlasIcon extends StatefulWidget {
  final SpriteAtlasIconData? data;
  final double size;
  final double? width;
  final double? height;
  final double opacity;
  final BoxFit fit;
  final Alignment alignment;

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
    final image =
        UiImageCache.imageFor(data.assetPath) ??
        await UiImageCache.load(data.assetPath);
    return _loadIconFrameFromImage(data, image);
  }

  Future<_LoadedSpriteAtlasIcon> _loadIconFrameFromImage(
    SpriteAtlasIconData data,
    ui.Image image,
  ) async {
    final sourceRect = await data.resolvedSourceRectFor(image);
    return _LoadedSpriteAtlasIcon(
      adjustment: await _adjustmentFor(data),
      image: image,
      sourceRect: sourceRect,
    );
  }

  _LoadedSpriteAtlasIcon? _frameFromCaches(SpriteAtlasIconData data) {
    final image = UiImageCache.imageFor(data.assetPath);
    if (image == null) return null;
    final sourceRect = data.cachedSourceRectFor(image);
    if (sourceRect == null) return null;
    final adjustment = _cachedAdjustmentFor(data);
    if (adjustment == null) return null;
    return _LoadedSpriteAtlasIcon(
      adjustment: adjustment,
      image: image,
      sourceRect: sourceRect,
    );
  }

  AnimationFrameAdjustment? _cachedAdjustmentFor(SpriteAtlasIconData data) {
    if (data.adjustmentId == null) {
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
          loaded.image,
          loaded.sourceRect,
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
  final AnimationFrameAdjustment adjustment;
  final ui.Image image;
  final ui.Rect sourceRect;

  const _LoadedSpriteAtlasIcon({
    required this.adjustment,
    required this.image,
    required this.sourceRect,
  });
}

class _SpriteAtlasIconPainter extends CustomPainter {
  final SpriteAtlasIconData data;
  final ui.Image image;
  final ui.Rect sourceRect;
  final AnimationFrameAdjustment adjustment;
  final BoxFit fit;
  final Alignment alignment;

  const _SpriteAtlasIconPainter(
    this.data,
    this.image,
    this.sourceRect,
    this.adjustment,
    this.fit,
    this.alignment,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(fit, sourceRect.size, size);
    final fittedSourceRect = alignment.inscribe(fitted.source, sourceRect);
    final baseDestinationRect = alignment.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final offset = adjustment.scaledOffset(
      baseSize: fittedSourceRect.size,
      targetSize: baseDestinationRect.size,
    );
    final adjustedSourceRect = adjustment.croppedSourceFor(fittedSourceRect);
    final destinationRect = adjustment
        .adjustedDestinationFor(
          baseSource: fittedSourceRect,
          baseDestination: baseDestinationRect,
        )
        .shift(offset);
    final shadowOffset = Offset(0, size.shortestSide * 0.035);
    final shadowPaint = Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = ColorFilter.mode(
        SurfaceElevation.flat.fill(background: Colors.black, alpha: 100),
        BlendMode.srcIn,
      );
    canvas.drawImageRect(
      image,
      adjustedSourceRect,
      destinationRect.shift(shadowOffset),
      shadowPaint,
    );

    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(image, adjustedSourceRect, destinationRect, paint);
  }

  @override
  bool shouldRepaint(covariant _SpriteAtlasIconPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.data != data ||
        oldDelegate.sourceRect != sourceRect ||
        oldDelegate.adjustment != adjustment ||
        oldDelegate.fit != fit ||
        oldDelegate.alignment != alignment;
  }
}
