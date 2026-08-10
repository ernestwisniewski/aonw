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
  bool operator ==(Object other) =>
      other is _AtlasFrameGeometry &&
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
