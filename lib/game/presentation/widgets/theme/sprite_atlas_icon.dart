import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/animation_frame_adjustments.dart';
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
    if (!cropToContent) return sourceRectFor(image);

    final cachedFrame = SpriteAtlasFrameBoundsCache.cachedFrameRectFor(
      cacheKey: assetPath,
      image: image,
      columns: columns,
      rows: rows,
      column: column,
      row: row,
      sourceInset: sourceInset,
      contentPadding: contentPadding,
    );
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

class SpriteAtlasIcon extends StatelessWidget {
  final SpriteAtlasIconData? data;
  final double size;
  final double? width;
  final double? height;
  final Widget? fallback;
  final double opacity;
  final BoxFit fit;
  final Alignment alignment;

  const SpriteAtlasIcon({
    required this.data,
    required this.size,
    this.width,
    this.height,
    this.fallback,
    this.opacity = 1,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final data = this.data;
    if (data == null) return _fallbackBox();

    final cachedImage = UiImageCache.imageFor(data.assetPath);
    final content = FutureBuilder<_LoadedSpriteAtlasIcon>(
      future: cachedImage == null
          ? _loadIconFrame(data)
          : _loadIconFrameFromImage(data, cachedImage),
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        if (loaded == null) return _fallbackBox();
        return _paintedIcon(
          data,
          loaded.image,
          loaded.sourceRect,
          loaded.adjustment,
        );
      },
    );

    if (opacity >= 1) return content;
    return Opacity(opacity: opacity.clamp(0, 1).toDouble(), child: content);
  }

  Future<_LoadedSpriteAtlasIcon> _loadIconFrame(
    SpriteAtlasIconData data,
  ) async {
    final image = await UiImageCache.load(data.assetPath);
    return _loadIconFrameFromImage(data, image);
  }

  Future<_LoadedSpriteAtlasIcon> _loadIconFrameFromImage(
    SpriteAtlasIconData data,
    ui.Image image,
  ) async {
    final sourceRect = await data.resolvedSourceRectFor(image);
    final catalog = await AnimationFrameAdjustmentCatalogCache.load();
    return _LoadedSpriteAtlasIcon(
      adjustment: data.adjustmentFor(catalog),
      image: image,
      sourceRect: sourceRect,
    );
  }

  Widget _paintedIcon(
    SpriteAtlasIconData data,
    ui.Image image,
    ui.Rect sourceRect,
    AnimationFrameAdjustment adjustment,
  ) {
    return SizedBox(
      width: width ?? size,
      height: height ?? size,
      child: CustomPaint(
        painter: _SpriteAtlasIconPainter(
          data,
          image,
          sourceRect,
          adjustment,
          fit,
          alignment,
        ),
      ),
    );
  }

  Widget _fallbackBox() {
    return SizedBox(
      width: width ?? size,
      height: height ?? size,
      child: Center(child: fallback ?? const SizedBox.shrink()),
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
