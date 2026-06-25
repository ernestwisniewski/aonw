import 'dart:math' as math;

import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

const _scrollbarTrackAlpha = 156;
const _scrollbarTrackBorderAlpha = 72;
const _scrollbarTrackShadowAlpha = 92;
const _scrollbarTrackGlowAlpha = 18;
const _scrollbarGrooveAlpha = 82;
const _scrollbarThumbStartAlpha = 235;
const _scrollbarThumbEndAlpha = 200;
const _scrollbarThumbBorderAlpha = 118;

class TechnologyTreeHorizontalScrollbar extends StatefulWidget {
  const TechnologyTreeHorizontalScrollbar({
    required this.controller,
    required this.compact,
    super.key,
  });

  final ScrollController controller;
  final bool compact;

  @override
  State<TechnologyTreeHorizontalScrollbar> createState() =>
      _TechnologyTreeHorizontalScrollbarState();
}

class _TechnologyTreeHorizontalScrollbarState
    extends State<TechnologyTreeHorizontalScrollbar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback(_syncAfterLayout);
  }

  @override
  void didUpdateWidget(covariant TechnologyTreeHorizontalScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback(_syncAfterLayout);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _syncAfterLayout(Duration _) {
    if (mounted) setState(() {});
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.hasClients) return const SizedBox.shrink();
    final position = widget.controller.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      return const SizedBox.shrink();
    }

    final height = widget.compact ? 12.0 : 14.0;
    return SizedBox(
      key: const Key('technologyTreeBoard.horizontalScrollbar'),
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          if (trackWidth <= 0) return const SizedBox.shrink();

          final thumb = _TechnologyTreeScrollbarGeometry.fromPosition(
            position: position,
            trackWidth: trackWidth,
            minThumbWidth: widget.compact ? 36 : 48,
          );
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _jumpNear(details.localPosition.dx, thumb),
            onHorizontalDragUpdate: (details) =>
                _dragBy(details.delta.dx, thumb),
            child: DecoratedBox(
              key: const Key('technologyTreeBoard.horizontalScrollbar.track'),
              decoration: ShapeDecoration(
                color: GameUiTheme.surfaceDeep.withAlpha(_scrollbarTrackAlpha),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GameUiTheme.radiusPill),
                  side: BorderSide(
                    color: GameUiTheme.scienceAccent.withAlpha(
                      _scrollbarTrackBorderAlpha,
                    ),
                  ),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withAlpha(_scrollbarTrackShadowAlpha),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: GameUiTheme.scienceAccent.withAlpha(
                      _scrollbarTrackGlowAlpha,
                    ),
                    blurRadius: 9,
                  ),
                ],
              ),
              child: _TechnologyTreeScrollbarThumb(thumb: thumb),
            ),
          );
        },
      ),
    );
  }

  void _jumpNear(double localDx, _TechnologyTreeScrollbarGeometry thumb) {
    _jumpToThumbLeft(localDx - thumb.width / 2, thumb);
  }

  void _dragBy(double deltaDx, _TechnologyTreeScrollbarGeometry thumb) {
    _jumpToThumbLeft(thumb.left + deltaDx, thumb);
  }

  void _jumpToThumbLeft(
    double thumbLeft,
    _TechnologyTreeScrollbarGeometry thumb,
  ) {
    final travel = thumb.travel;
    if (travel <= 0) return;
    final ratio = (thumbLeft / travel).clamp(0.0, 1.0);
    widget.controller.jumpTo(
      ratio * widget.controller.position.maxScrollExtent,
    );
  }
}

class _TechnologyTreeScrollbarThumb extends StatelessWidget {
  const _TechnologyTreeScrollbarThumb({required this.thumb});

  final _TechnologyTreeScrollbarGeometry thumb;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: Colors.black.withAlpha(_scrollbarGrooveAlpha),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GameUiTheme.radiusPill),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: thumb.left,
          top: 3,
          bottom: 3,
          width: thumb.width,
          child: DecoratedBox(
            key: const Key('technologyTreeBoard.horizontalScrollbar.thumb'),
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                colors: [
                  GameUiTheme.scienceAccent.withAlpha(
                    _scrollbarThumbStartAlpha,
                  ),
                  GameUiTheme.goldLight.withAlpha(_scrollbarThumbEndAlpha),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GameUiTheme.radiusPill),
                side: BorderSide(
                  color: GameUiTheme.goldLight.withAlpha(
                    _scrollbarThumbBorderAlpha,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TechnologyTreeScrollbarGeometry {
  const _TechnologyTreeScrollbarGeometry({
    required this.left,
    required this.width,
    required this.travel,
  });

  final double left;
  final double width;
  final double travel;

  static _TechnologyTreeScrollbarGeometry fromPosition({
    required ScrollPosition position,
    required double trackWidth,
    required double minThumbWidth,
  }) {
    final contentExtent = position.maxScrollExtent + position.viewportDimension;
    final visibleRatio = position.viewportDimension / contentExtent;
    final width = (trackWidth * visibleRatio).clamp(minThumbWidth, trackWidth);
    final travel = math.max(0.0, trackWidth - width);
    final scrollRatio = position.maxScrollExtent <= 0
        ? 0.0
        : (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
    return _TechnologyTreeScrollbarGeometry(
      left: travel * scrollRatio,
      width: width,
      travel: travel,
    );
  }
}
