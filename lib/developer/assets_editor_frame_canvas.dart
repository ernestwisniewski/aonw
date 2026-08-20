part of 'assets_editor_screen.dart';

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
      child: FutureBuilder<_LoadedAssetFrame>(
        future: _AssetFrameLoader.load(model, frameIndex),
        builder: (context, snapshot) {
          final frame = snapshot.data;
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
            image: frame.image,
            model: model,
            onAdjustmentChanged: onAdjustmentChanged,
            sourceRect: frame.sourceRect,
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
  bool shouldRepaint(_AtlasFramePainter oldDelegate) =>
      oldDelegate.adjustment != adjustment ||
      oldDelegate.editMode != editMode ||
      oldDelegate.geometry != geometry ||
      oldDelegate.image != image ||
      oldDelegate.model != model;

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
