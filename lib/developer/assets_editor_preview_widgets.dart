part of 'assets_editor_screen.dart';

class _AssetPreviewTile extends StatelessWidget {
  const _AssetPreviewTile({
    required this.adjustment,
    required this.editMode,
    required this.frameDuration,
    required this.frameIndex,
    required this.model,
    required this.onAdjustmentChanged,
    required this.onFrameSelected,
    required this.onResetAdjustment,
    this.onAnimationFrameDurationChanged,
    this.onResetAnimationFrameDuration,
  });

  final AnimationFrameAdjustment adjustment;
  final bool editMode;
  final double frameDuration;
  final int frameIndex;
  final _AssetPreviewModel model;
  final ValueChanged<AnimationFrameAdjustment> onAdjustmentChanged;
  final ValueChanged<double>? onAnimationFrameDurationChanged;
  final ValueChanged<int> onFrameSelected;
  final VoidCallback? onResetAnimationFrameDuration;
  final VoidCallback onResetAdjustment;

  @override
  Widget build(BuildContext context) {
    final frameCount = model.frameCount;
    final fps = 1 / frameDuration;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.card,
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(70)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.cardTitle,
                  ),
                ),
                _ActionPill(color: model.kindColor, label: model.kindLabel),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _AtlasFramePreview(
                adjustment: adjustment,
                editMode: editMode,
                frameIndex: frameIndex,
                model: model,
                onAdjustmentChanged: onAdjustmentChanged,
              ),
            ),
            const SizedBox(height: 10),
            _FrameStrip(
              frameCount: frameCount,
              selectedFrame: frameIndex,
              onFrameSelected: editMode ? onFrameSelected : null,
            ),
            const SizedBox(height: 9),
            if (editMode)
              _FrameEditPanel(
                adjustment: adjustment,
                frameDuration: frameDuration,
                frameIndex: frameIndex,
                frameCount: frameCount,
                onAnimationFrameDurationChanged:
                    onAnimationFrameDurationChanged,
                onAdjustmentChanged: onAdjustmentChanged,
                onResetAnimationFrameDuration: onResetAnimationFrameDuration,
                onResetAdjustment: onResetAdjustment,
              )
            else
              Row(
                children: [
                  _MetaPill(label: 'Frame ${frameIndex + 1}/$frameCount'),
                  const SizedBox(width: 6),
                  _MetaPill(label: '${fps.toStringAsFixed(1)} FPS'),
                  const SizedBox(width: 6),
                  _MetaPill(label: model.loops ? 'Loop' : 'Shot'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AtlasFramePreview extends StatelessWidget {
  const _AtlasFramePreview({
    required this.adjustment,
    required this.editMode,
    required this.frameIndex,
    required this.model,
    required this.onAdjustmentChanged,
  });

  final AnimationFrameAdjustment adjustment;
  final bool editMode;
  final int frameIndex;
  final _AssetPreviewModel model;
  final ValueChanged<AnimationFrameAdjustment> onAdjustmentChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('assetsEditor.preview.${model.id}'),
      decoration: BoxDecoration(
        color: GameUiTheme.surfaceDeep.withAlpha(230),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(46)),
      ),
      child: FutureBuilder<ui.Image>(
        future: _SpriteImageCache.load(model.assetPath),
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GameUiTheme.gold,
                ),
              ),
            );
          }
          return FutureBuilder<_LoadedAssetFrame>(
            future: _AssetFrameLoader.load(model, image, frameIndex),
            builder: (context, frameSnapshot) {
              final frame = frameSnapshot.data;
              if (frame == null) {
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GameUiTheme.gold,
                    ),
                  ),
                );
              }
              return _InteractiveAtlasFrameCanvas(
                adjustment: adjustment,
                editMode: editMode,
                image: image,
                model: model,
                onAdjustmentChanged: onAdjustmentChanged,
                sourceRect: frame.sourceRect,
              );
            },
          );
        },
      ),
    );
  }
}

class _InteractiveAtlasFrameCanvas extends StatefulWidget {
  const _InteractiveAtlasFrameCanvas({
    required this.adjustment,
    required this.editMode,
    required this.image,
    required this.model,
    required this.onAdjustmentChanged,
    required this.sourceRect,
  });

  final AnimationFrameAdjustment adjustment;
  final bool editMode;
  final ui.Image image;
  final _AssetPreviewModel model;
  final ValueChanged<AnimationFrameAdjustment> onAdjustmentChanged;
  final ui.Rect sourceRect;

  @override
  State<_InteractiveAtlasFrameCanvas> createState() =>
      _InteractiveAtlasFrameCanvasState();
}

class _InteractiveAtlasFrameCanvasState
    extends State<_InteractiveAtlasFrameCanvas> {
  _FrameDragMode? _dragMode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          math.max(1.0, constraints.maxWidth),
          math.max(1.0, constraints.maxHeight),
        );
        final geometry = _AtlasFrameGeometry.resolve(
          adjustment: widget.adjustment,
          model: widget.model,
          sourceRect: widget.sourceRect,
          size: size,
        );

        return MouseRegion(
          cursor: widget.editMode
              ? SystemMouseCursors.precise
              : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: widget.editMode
                ? (details) {
                    _dragMode = _FrameDragMode.hitTest(
                      details.localPosition,
                      geometry,
                    );
                  }
                : null,
            onPanUpdate: widget.editMode
                ? (details) => _applyDrag(details.delta, geometry)
                : null,
            onPanEnd: widget.editMode ? (_) => _dragMode = null : null,
            onPanCancel: widget.editMode ? () => _dragMode = null : null,
            child: CustomPaint(
              painter: _AtlasFramePainter(
                adjustment: widget.adjustment,
                editMode: widget.editMode,
                geometry: geometry,
                image: widget.image,
                model: widget.model,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  void _applyDrag(Offset delta, _AtlasFrameGeometry geometry) {
    final mode = _dragMode ?? const _FrameDragMode.move();
    final next = switch (mode.action) {
      _FrameDragAction.move => widget.adjustment.nudge(
        dx: delta.dx / geometry.offsetScaleX,
        dy: delta.dy / geometry.offsetScaleY,
      ),
      _FrameDragAction.scale => widget.adjustment.scaleBy(
        dx:
            mode.horizontalSign *
            delta.dx /
            math.max(24.0, geometry.croppedDestination.width),
        dy:
            mode.verticalSign *
            delta.dy /
            math.max(24.0, geometry.croppedDestination.height),
      ),
      _FrameDragAction.cropLeft => widget.adjustment.adjustCrop(
        left: delta.dx / geometry.sourceToDestinationScaleX,
      ),
      _FrameDragAction.cropRight => widget.adjustment.adjustCrop(
        right: -delta.dx / geometry.sourceToDestinationScaleX,
      ),
      _FrameDragAction.cropTop => widget.adjustment.adjustCrop(
        top: delta.dy / geometry.sourceToDestinationScaleY,
      ),
      _FrameDragAction.cropBottom => widget.adjustment.adjustCrop(
        bottom: -delta.dy / geometry.sourceToDestinationScaleY,
      ),
    };
    widget.onAdjustmentChanged(next);
  }
}

class _AtlasFramePainter extends CustomPainter {
  const _AtlasFramePainter({
    required this.adjustment,
    required this.editMode,
    required this.geometry,
    required this.image,
    required this.model,
  });

  final AnimationFrameAdjustment adjustment;
  final bool editMode;
  final _AtlasFrameGeometry geometry;
  final ui.Image image;
  final _AssetPreviewModel model;

  @override
  void paint(Canvas canvas, Size size) {
    final destinationPaint = Paint()
      ..color = GameUiTheme.gold.withAlpha(editMode ? 110 : 0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    if (editMode) {
      canvas.drawRect(geometry.baseDestination, destinationPaint);
    }

    canvas.drawImageRect(
      image,
      geometry.source,
      geometry.destination,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );

    if (editMode) {
      _paintEditHandles(canvas, geometry);
      _paintBoardCenter(canvas, geometry.available.center);
    }
  }

  @override
  bool shouldRepaint(_AtlasFramePainter oldDelegate) {
    return oldDelegate.adjustment != adjustment ||
        oldDelegate.editMode != editMode ||
        oldDelegate.geometry != geometry ||
        oldDelegate.image != image ||
        oldDelegate.model != model;
  }

  void _paintEditHandles(Canvas canvas, _AtlasFrameGeometry geometry) {
    final framePaint = Paint()
      ..color = const Color(0xFF69B7B0)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawRect(geometry.destination, framePaint);

    final cropPaint = Paint()..color = const Color(0xFF28F05E);
    final scalePaint = Paint()..color = GameUiTheme.goldLight;
    for (final center in geometry.edgeHandleCenters) {
      canvas.drawRect(
        Rect.fromCenter(center: center, width: 8, height: 8),
        cropPaint,
      );
    }
    for (final center in geometry.cornerHandleCenters) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 10, height: 10),
          const Radius.circular(2),
        ),
        scalePaint,
      );
    }
  }

  void _paintBoardCenter(Canvas canvas, Offset center) {
    const length = 9.0;
    final paint = Paint()
      ..color = const Color(0xFF28F05E)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(
        center.translate(-length, -length),
        center.translate(length, length),
        paint,
      )
      ..drawLine(
        center.translate(length, -length),
        center.translate(-length, length),
        paint,
      );
  }
}

class _AtlasFrameGeometry {
  const _AtlasFrameGeometry({
    required this.available,
    required this.baseDestination,
    required this.baseSource,
    required this.croppedDestination,
    required this.destination,
    required this.offsetScaleX,
    required this.offsetScaleY,
    required this.source,
    required this.sourceToDestinationScaleX,
    required this.sourceToDestinationScaleY,
  });

  final Rect available;
  final Rect baseDestination;
  final ui.Rect baseSource;
  final Rect croppedDestination;
  final Rect destination;
  final double offsetScaleX;
  final double offsetScaleY;
  final ui.Rect source;
  final double sourceToDestinationScaleX;
  final double sourceToDestinationScaleY;

  List<Offset> get cornerHandleCenters => [
    destination.topLeft,
    destination.topRight,
    destination.bottomRight,
    destination.bottomLeft,
  ];

  List<Offset> get edgeHandleCenters => [
    Offset(destination.left, destination.center.dy),
    Offset(destination.center.dx, destination.top),
    Offset(destination.right, destination.center.dy),
    Offset(destination.center.dx, destination.bottom),
  ];

  factory _AtlasFrameGeometry.resolve({
    required AnimationFrameAdjustment adjustment,
    required _AssetPreviewModel model,
    required ui.Rect sourceRect,
    required Size size,
  }) {
    final baseSource = sourceRect;
    final source = adjustment.croppedSourceFor(baseSource);
    final available = Offset.zero & size;
    final paddedWidth = math.max(1.0, size.width - 24);
    final paddedHeight = math.max(1.0, size.height - 24);
    final scale = math.min(
      paddedWidth / math.max(1.0, baseSource.width),
      paddedHeight / math.max(1.0, baseSource.height),
    );
    final baseDestination = Rect.fromCenter(
      center: available.center,
      width: baseSource.width * scale,
      height: baseSource.height * scale,
    );
    final offset = adjustment.scaledOffset(
      baseSize: model.adjustmentBaseSizeFor(baseSource),
      targetSize: baseDestination.size,
    );
    final croppedDestination = adjustment.croppedDestinationFor(
      baseSource: baseSource,
      baseDestination: baseDestination,
    );
    final destination = adjustment
        .adjustedDestinationFor(
          baseSource: baseSource,
          baseDestination: baseDestination,
        )
        .shift(offset);
    final adjustmentBaseSize = model.adjustmentBaseSizeFor(baseSource);

    return _AtlasFrameGeometry(
      available: available,
      baseDestination: baseDestination,
      baseSource: baseSource,
      croppedDestination: croppedDestination,
      destination: destination,
      offsetScaleX:
          baseDestination.width / math.max(1.0, adjustmentBaseSize.width),
      offsetScaleY:
          baseDestination.height / math.max(1.0, adjustmentBaseSize.height),
      source: source,
      sourceToDestinationScaleX:
          baseDestination.width / math.max(1.0, baseSource.width),
      sourceToDestinationScaleY:
          baseDestination.height / math.max(1.0, baseSource.height),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _AtlasFrameGeometry &&
        other.available == available &&
        other.baseDestination == baseDestination &&
        other.baseSource == baseSource &&
        other.croppedDestination == croppedDestination &&
        other.destination == destination &&
        other.offsetScaleX == offsetScaleX &&
        other.offsetScaleY == offsetScaleY &&
        other.source == source &&
        other.sourceToDestinationScaleX == sourceToDestinationScaleX &&
        other.sourceToDestinationScaleY == sourceToDestinationScaleY;
  }

  @override
  int get hashCode => Object.hash(
    available,
    baseDestination,
    baseSource,
    croppedDestination,
    destination,
    offsetScaleX,
    offsetScaleY,
    source,
    sourceToDestinationScaleX,
    sourceToDestinationScaleY,
  );
}

enum _FrameDragAction { move, scale, cropLeft, cropRight, cropTop, cropBottom }

class _FrameDragMode {
  const _FrameDragMode._(
    this.action, {
    this.horizontalSign = 0,
    this.verticalSign = 0,
  });

  const _FrameDragMode.move() : this._(_FrameDragAction.move);

  final _FrameDragAction action;
  final int horizontalSign;
  final int verticalSign;

  static _FrameDragMode hitTest(Offset position, _AtlasFrameGeometry geometry) {
    final rect = geometry.destination;
    const handleRadius = 13.0;
    const edgeRadius = 9.0;

    if ((position - rect.topLeft).distance <= handleRadius) {
      return const _FrameDragMode._(
        _FrameDragAction.scale,
        horizontalSign: -1,
        verticalSign: -1,
      );
    }
    if ((position - rect.topRight).distance <= handleRadius) {
      return const _FrameDragMode._(
        _FrameDragAction.scale,
        horizontalSign: 1,
        verticalSign: -1,
      );
    }
    if ((position - rect.bottomRight).distance <= handleRadius) {
      return const _FrameDragMode._(
        _FrameDragAction.scale,
        horizontalSign: 1,
        verticalSign: 1,
      );
    }
    if ((position - rect.bottomLeft).distance <= handleRadius) {
      return const _FrameDragMode._(
        _FrameDragAction.scale,
        horizontalSign: -1,
        verticalSign: 1,
      );
    }

    final verticalRange =
        position.dy >= rect.top - edgeRadius &&
        position.dy <= rect.bottom + edgeRadius;
    final horizontalRange =
        position.dx >= rect.left - edgeRadius &&
        position.dx <= rect.right + edgeRadius;
    if (verticalRange && (position.dx - rect.left).abs() <= edgeRadius) {
      return const _FrameDragMode._(_FrameDragAction.cropLeft);
    }
    if (verticalRange && (position.dx - rect.right).abs() <= edgeRadius) {
      return const _FrameDragMode._(_FrameDragAction.cropRight);
    }
    if (horizontalRange && (position.dy - rect.top).abs() <= edgeRadius) {
      return const _FrameDragMode._(_FrameDragAction.cropTop);
    }
    if (horizontalRange && (position.dy - rect.bottom).abs() <= edgeRadius) {
      return const _FrameDragMode._(_FrameDragAction.cropBottom);
    }

    return const _FrameDragMode.move();
  }
}
